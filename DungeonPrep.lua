local _, ns = ...
local L = ns.L

-- Dungeon objectives with pickups outside the instance. Keep the IDs here and
-- read eligibility, prerequisite links, givers and rewards from the shared DB.
local dungeons = {
    [796] = { 1050, 1053, 1048, 1049, 1113, 1160, 1951 },
}

function ns.HasDungeonPrep(id) return dungeons[id] ~= nil end

local function Title(id)
    return ns.AnyQuestTitle(id, ns.ZoneQuest(id).name)
end

-- The curated paths are linear. Never choose a branch on the player's behalf.
local function NextStep(id, state)
    local depth, seen = 0, { [id] = true }
    while state == "locked" do
        local quest = ns.ZoneQuest(id)
        if #quest.pre + #quest.preAny ~= 1 then break end
        local pre = quest.pre[1] or quest.preAny[1]
        if seen[pre] then break end
        local prior = ns.QuestState(pre)
        if prior == "done" or prior == "hidden" or prior == "unknown" then break end
        id, state, depth, seen[pre] = pre, prior, depth + 1, true
    end
    return id, state, depth
end

function ns.DungeonPrepRows(dungeon)
    local rows = {}
    for _, final in ipairs(dungeons[dungeon] or {}) do
        local state = ns.QuestState(final)
        if state ~= "hidden" and state ~= "done" and state ~= "unknown" then
            local id, current, depth = NextStep(final, state)
            local row = { final = final, id = id, state = current, depth = depth }
            if current == "available" then
                local giver = ns.QuestGiver(id)
                if giver then
                    giver.uiMap = ns.UiMapForArea(giver.area)
                    if giver.uiMap then row.place = giver end
                end
                row.sharer = ns.PrepShareSource(id)
            elseif current == "inlog" then
                row.ready = ns.IsReadyToTurnIn(id)
            end
            rows[#rows + 1] = row
        end
    end
    return rows
end

function ns.PrepPickupTasks(dungeon)
    local tasks, seen, snoozed = {}, {}, false
    for _, row in ipairs(ns.DungeonPrepRows(dungeon)) do
        if row.place and not seen[row.id] then
            if C_QuestLog.IsQuestLogFull and C_QuestLog.IsQuestLogFull() then
                return {}, L["Quest log full"]
            end
            if ns.IsSnoozedPlace(row.place) then
                snoozed = true
            else
                tasks[#tasks + 1] = { questID = row.id, title = Title(row.id), pickup = true, places = { row.place } }
            end
            seen[row.id] = true
        end
    end
    if #tasks == 0 and snoozed then return tasks, L["Dungeon pickups snoozed"] end
    return tasks
end

function ns.RequestPrepShare(id)
    if ns.QuestState(id) ~= "available" or (C_QuestLog.IsQuestLogFull and C_QuestLog.IsQuestLogFull()) then return end
    local who = ns.PrepShareSource(id)
    if who then SendChatMessage(string.format(L["Could you share %s?"], ns.QuestChatLink(id, Title(id))), "WHISPER", nil, who) end
end

local rewards = {}
for _, ids in pairs(dungeons) do
    for _, id in ipairs(ids) do rewards[id] = {} end
end
for _, reward in pairs(ns.RewardCatalog) do
    local options = rewards[reward.steps[#reward.steps]]
    if options then options[#options + 1] = reward end
end
for _, options in pairs(rewards) do
    table.sort(options, function(a, b) return a.name < b.name end)
end

local function Details(row)
    local lines = { "|cffffffff" .. Title(row.final) .. "|r" }
    if row.depth > 0 then
        lines[#lines + 1] = string.format(L["Prerequisites left: %d. Next: %s"], row.depth, Title(row.id))
    end
    if row.state == "inlog" then
        lines[#lines + 1] = row.ready and L["Ready to turn in"] or L["In your log"]
        if not row.ready then
            for _, objective in ipairs((C_QuestLog.GetQuestObjectives and C_QuestLog.GetQuestObjectives(row.id)) or {}) do
                if not objective.finished and objective.text then lines[#lines + 1] = objective.text end
            end
        end
    elseif row.state == "available" then
        local place = row.place
        local area = place and C_Map and C_Map.GetAreaInfo and C_Map.GetAreaInfo(place.area)
        lines[#lines + 1] = place and (L["Pick up"] .. " · " .. place.name .. (area and (" · " .. area) or "")) or L["Location unknown"]
        if row.sharer then lines[#lines + 1] = string.format(L["%s can share this quest."], row.sharer) end
    else
        lines[#lines + 1] = ns.RewardStepLabel(row)
    end
    local names = {}
    for _, reward in ipairs(rewards[row.final]) do
        names[#names + 1] = string.format("|Hitem:%d|h[%s]|h", reward.item, reward.name)
    end
    if #names > 0 then lines[#lines + 1] = "|cffffd100" .. L["Rewards"] .. " · " .. table.concat(names, ", ") .. "|r" end
    return table.concat(lines, "\n")
end

local function MakeCard(view, width)
    local card = ns.UI.Card(view.content, width - 12, 1)
    card.rows = {}
    card.title = ns.UI.Text(card, 12, "accent", nil, "bold")
    card.title:SetPoint("TOPLEFT", 10, -8)
    card.title:SetText(L["Dungeon Prep"])
    card.count = ns.UI.Text(card, 10, "dim")
    card.count:SetPoint("TOPRIGHT", -10, -9)
    card.empty = ns.UI.Text(card, 11, "muted")
    card.empty:SetPoint("TOPLEFT", 10, -30)
    card.empty:SetText(L["No remaining prep quests for your character."])
    card.route = ns.UI.Button(card, 170, 22, "primary")
    card.route:SetPoint("BOTTOMLEFT", 10, 8)
    card.route:SetScript("OnClick", function()
        ns.SetDungeonPrepRoute(QuestynatorPrepDungeon ~= card.dungeon and card.dungeon or nil)
    end)
    return card
end

local function MakeRow(card, width)
    local row = CreateFrame("Frame", nil, card)
    row:SetWidth(width)
    row.text = ns.UI.Text(row, 11, "muted")
    row.text:SetPoint("TOPLEFT")
    row.text:SetWidth(width - 108)
    row.text:SetJustifyH("LEFT")
    row.text:SetSpacing(2)
    if row.SetHyperlinksEnabled then
        row:SetHyperlinksEnabled(true)
        row:SetScript("OnHyperlinkEnter", function(self, link)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(link)
            GameTooltip:Show()
            if GameTooltip_ShowCompareItem then GameTooltip_ShowCompareItem(GameTooltip) end
        end)
        row:SetScript("OnHyperlinkLeave", function() GameTooltip:Hide() end)
    end
    row.pin = ns.UI.Button(row, 98, 20, "ghost")
    row.pin:SetPoint("TOPRIGHT")
    row.pin:SetText(L["Pin pickup"])
    row.pin:SetScript("OnClick", function()
        local p = row.entry.place
        if p then ns.Waypoint(p.area, p.x, p.y, Title(row.entry.id), true, { questID = row.entry.id, who = p.name }) end
    end)
    row.share = ns.UI.Button(row, 98, 20, "outline")
    row.share:SetPoint("TOPRIGHT", 0, -24)
    row.share:SetText(L["Request share"])
    row.share:SetScript("OnClick", function() ns.RequestPrepShare(row.entry.id) end)
    return row
end

function ns.DrawDungeonPrep(view, dungeon, width, y)
    local card = view.prepCard or MakeCard(view, width)
    view.prepCard, card.dungeon = card, dungeon
    card:ClearAllPoints()
    card:SetPoint("TOPLEFT", view.content, "TOPLEFT", 12, -y)
    card:Show()
    local rows, top, hasPickup = ns.DungeonPrepRows(dungeon), 30, false
    local inLog, available = 0, 0
    local full = C_QuestLog.IsQuestLogFull and C_QuestLog.IsQuestLogFull()
    card.empty:SetShown(#rows == 0)
    for i, entry in ipairs(rows) do
        local row = card.rows[i] or MakeRow(card, width - 32)
        card.rows[i], row.entry = row, entry
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -top)
        row:Show()
        row.text:SetText(Details(entry))
        row.pin:SetShown(entry.place ~= nil)
        row.share:SetShown(entry.sharer ~= nil)
        if full then row.share:Disable() else row.share:Enable() end
        local height = math.max(math.ceil(row.text:GetStringHeight()), entry.sharer and 44 or 20)
        row:SetHeight(height)
        top = top + height + 10
        if entry.place then hasPickup = true end
        if entry.depth == 0 then
            if entry.state == "inlog" then inLog = inLog + 1
            elseif entry.state == "available" then available = available + 1 end
        end
    end
    for i = #rows + 1, #card.rows do card.rows[i]:Hide() end
    local active = QuestynatorPrepDungeon == dungeon
    card.count:SetText(#rows > 0 and string.format(L["%d in log · %d ready to pick up"], inLog, available) or "")
    card.route:SetShown(active or hasPickup)
    card.route:SetText(active and L["Stop prep route"] or (full and L["Quest log full"] or L["Route to missing pickups"]))
    if full and not active then card.route:Disable() else card.route:Enable() end
    local height = top + (#rows == 0 and 24 or 0) + ((active or hasPickup) and 30 or 0)
    card:SetHeight(height)
    return y + height
end
