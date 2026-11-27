local _, ns = ...
local L = ns.L
local ticker, events, window, current, shownAt
local treasures, requestedDungeon, requestedAt
local followUps = {}
local quietUntil = 0
local PICKUP_YARDS, ENTRANCE_YARDS = 200, 400
local clock = GetServerTime or time

function ns.RememberDungeonRequest(id)
    requestedDungeon, requestedAt = id, GetTime()
end

local function Nearby(place, maps, radius)
    if not place or not maps[place.uiMap] then return end
    local yards = ns.ArrowGeometry(place).yards
    if yards and yards <= radius then return yards end
end

local function CanRemind()
    return ns.GetOption("reminders") and not (InCombatLockdown and InCombatLockdown())
        and not (IsInInstance and IsInInstance()) and not (UnitIsDeadOrGhost and UnitIsDeadOrGhost("player"))
        and not (UnitOnTaxi and UnitOnTaxi("player"))
end

local function OfferGroups(offer)
    if IsInGroup() or (ns.trustInviter and GetTime() - ns.trustInviter.t < 90) then return end
    for _, group in ipairs(ns.GroupEntries()) do
        if group.haveQuest and group.fits and not group.mine and (group.members or 1) + (group.pending or 0) < 5
            and not ns.IsSearching(group.questID) and not ns.IsReadyToTurnIn(group.questID)
            and ns.QuestState(group.questID) == "inlog" and ns.GroupNeedsMatch(group) then
            local key = "join:" .. group.questID .. ":" .. group.host
            offer("join", group.questID, key, 2, 0, L["Quest group"],
                string.format(L["%s is recruiting for %s (%d/5)."], group.host, group.title, group.members or 1), nil, group)
        end
    end
    local id = ns.UnmatchedQuestSearch()
    if id and ns.QuestLogIndex(id) then
        offer("host", id, "host:" .. id, 3, 0, L["No one found yet"], ns.AnyQuestTitle(id))
    end
end

local function OfferTurnIns(offer, maps)
    if not next(maps) then return end
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        local id = info and not info.isHeader and not info.isHidden and info.questID
        if id and ns.IsReadyToTurnIn(id) and ns.QuestState(id) == "inlog" then
            local places = ns.RewardDestinations({ id = id, state = "inlog", ready = true })
            for _, place in ipairs(places) do
                local yards = Nearby(place, maps, PICKUP_YARDS)
                if yards and not ns.IsSnoozedPlace(place) then
                    local reward = ns.TurnInGear(id)
                    if reward then
                        offer("turnin", id, "turnin:" .. id, 1, yards, reward.name,
                            string.format(L["Turn in %s to %s."], info.title or ns.AnyQuestTitle(id), place.name), place)
                    end
                end
            end
        end
    end
end

local function OfferFollowUps(offer, maps)
    for id, expires in pairs(followUps) do
        local state = ns.QuestState(id)
        if GetTime() >= expires or state == "done" or state == "inlog" then
            followUps[id] = nil
        elseif state == "available" then
            local place = ns.QuestGiver(id)
            if place then
                place.uiMap = ns.UiMapForArea(place.area)
                if maps[place.uiMap] and not ns.IsSnoozedPlace(place) then
                    local yards = ns.ArrowGeometry(place).yards
                    offer("pin", id, "pickup:" .. id, 3, yards or math.huge, L["Quest follow-up"],
                        string.format(L["Pick up %s from %s"], ns.AnyQuestTitle(id), place.name), place)
                end
            end
        end
    end
end

function ns.NextSmartReminder()
    if not CanRemind() then return end
    local now, maps = clock(), ns.CurrentZoneMaps()
    local best
    local function Offer(kind, id, key, rank, distance, title, detail, place, group)
        if QuestynatorReminderSnoozes and (QuestynatorReminderSnoozes[key] or 0) > now then return end
        if best and (rank > best.rank or (rank == best.rank and (distance > best.distance
            or (distance == best.distance and key >= best.key)))) then return end
        best = { kind = kind, id = id, key = key, rank = rank, distance = distance,
            title = title, detail = detail, place = place, group = group }
    end
    OfferGroups(Offer)
    OfferTurnIns(Offer, maps)
    if C_QuestLog.IsQuestLogFull and C_QuestLog.IsQuestLogFull() then return best end
    OfferFollowUps(Offer, maps)
    local mine = ns.MyDungeon()
    local intended = QuestynatorPrepDungeon or (mine and mine.id)
        or (requestedAt and GetTime() - requestedAt < 120 and requestedDungeon)
    local level = UnitLevel("player") or 0
    local faction = ns.PlayerFaction()
    for _, d in ipairs(ns.DUNGEONS) do
        if ns.HasDungeonPrep(d.id) and
            (intended == d.id or (not intended and level >= d.min - 3 and level <= d.max
                and (not d.faction or d.faction == faction))) then
            local entrance = { uiMap = ns.UiMapForArea(d.zone), area = d.zone, x = d.x, y = d.y }
            local preparing = intended == d.id or Nearby(entrance, maps, ENTRANCE_YARDS)
            local pickups = {}
            local dungeon = ns.DungeonName(d.id)
            for _, row in ipairs(ns.DungeonPrepRows(d.id)) do
                if row.state == "available" then
                    local name = ns.ZoneQuest(row.id).name
                    if row.sharer then
                        Offer("share", row.id, "share:" .. row.id, 1, 0, dungeon,
                            string.format(L["%s can share %s."], row.sharer, name))
                    end
                    if row.place and not QuestynatorPrepDungeon and not ns.IsSnoozedPlace(row.place) then
                        pickups[row.id] = name
                        local yards = Nearby(row.place, maps, PICKUP_YARDS)
                        if yards then
                            Offer("pin", row.id, "pickup:" .. row.id, 4, yards, dungeon,
                                string.format(L["Pick up %s from %s"], name, row.place.name), row.place)
                        end
                    end
                end
            end
            if preparing and next(pickups) then
                local ids = {}
                for id in pairs(pickups) do ids[#ids + 1] = id end
                table.sort(ids)
                local detail = #ids == 1 and string.format(L["Still to pick up: %s"], pickups[ids[1]])
                    or string.format(L["%d dungeon quest pickups are available."], #ids)
                Offer("route", d.id, "prep:" .. d.id .. ":" .. table.concat(ids, ","), 5, 0, dungeon, detail)
            end
        end
    end
    if best then return best end
    if not next(maps) then return end
    treasures = treasures or ns.TreasureList()
    for _, e in ipairs(treasures) do
        if e.status == "available" and e.area then
            local place = { area = e.area, uiMap = ns.UiMapForArea(e.area), x = e.x, y = e.y, name = e.giver }
            local yards = Nearby(place, maps, PICKUP_YARDS)
            if yards and not ns.IsSnoozedPlace(place) and ns.QuestState(e.step) == "available" then
                Offer("pin", e.step, "pickup:" .. e.step, 4, yards, e.reward,
                    string.format(L["Pick up %s from %s"], e.questName or ("#" .. e.step), e.giver), place)
            end
        end
    end
    return best
end

local function Hide()
    current = nil
    if window then window:Hide() end
end

local function Dismiss()
    if current then
        QuestynatorReminderSnoozes = QuestynatorReminderSnoozes or {}
        QuestynatorReminderSnoozes[current.key] = clock() + 1800
        quietUntil = GetTime() + 45
    end
    Hide()
end

local function Act()
    local live = ns.NextSmartReminder()
    if not live or not current or live.key ~= current.key then Hide(); return end
    Dismiss()
    if live.kind == "share" then ns.RequestPrepShare(live.id)
    elseif live.kind == "route" then ns.SetDungeonPrepRoute(live.id)
    elseif live.kind == "join" then ns.JoinGroup(live.group)
    elseif live.kind == "host" then ns.QuickHostQuest(live.id)
    else
        local p = live.place
        local q = ns.ZoneQuest(live.id)
        ns.Waypoint(p.area, p.x, p.y, ns.AnyQuestTitle(live.id, q and q.name), true, { questID = live.id, who = p.name })
    end
end

local buttons = { share = "Request share", route = "Route to pickups", pin = "Pin pickup",
    join = "Request invite", host = "Host LFG", turnin = "Pin turn-in" }

local function Refresh()
    if GetTime() < quietUntil then return end
    local candidate = ns.NextSmartReminder()
    if not candidate then Hide(); return end
    if not window then
        window = ns.UI.Window("QuestynatorSmartReminder", 318, 88)
        window:SetPoint("TOP", UIParent, "TOP", 0, -60)
        window:SetClampedToScreen(true)
        window.CloseButton:SetScript("OnClick", Dismiss)
        window.text = ns.UI.Text(window, 12, "text")
        window.text:SetPoint("TOPLEFT", 12, -30)
        window.text:SetWidth(294)
        window.text:SetJustifyH("LEFT")
        window.act = ns.UI.Button(window, 150, 21, "primary")
        window.act:SetPoint("BOTTOMLEFT", 12, 8)
        window.act:SetScript("OnClick", Act)
        window.later = ns.UI.Button(window, 108, 21, "ghost")
        window.later:SetPoint("LEFT", window.act, "RIGHT", 6, 0)
        window.later:SetText(L["Later (30 min)"])
        window.later:SetScript("OnClick", Dismiss)
    end
    if not current or current.key ~= candidate.key then shownAt = GetTime() end
    current = candidate
    if GetTime() - shownAt >= 25 and not window:IsMouseOver() then Dismiss(); return end
    window.TitleText:SetText("Questynator · " .. candidate.title)
    window.text:SetText(candidate.detail)
    window.act:SetText(L[buttons[candidate.kind]])
    window:Show()
    window:SetHeight(68 + math.ceil(window.text:GetStringHeight()))
end

function ns.StartSmartReminders()
    treasures = nil
    if not ns.GetOption("reminders") then
        followUps = {}
        if ticker then ticker:Cancel(); ticker = nil end
        if events then events:UnregisterAllEvents() end
        Hide()
        return
    end
    if ticker then return end
    if type(QuestynatorReminderSnoozes) ~= "table" then QuestynatorReminderSnoozes = {} end
    for key, expires in pairs(QuestynatorReminderSnoozes) do
        if type(expires) ~= "number" or expires <= clock() then QuestynatorReminderSnoozes[key] = nil end
    end
    events = events or CreateFrame("Frame")
    for _, name in ipairs({ "QUEST_LOG_UPDATE", "QUEST_TURNED_IN", "PLAYER_LEVEL_UP",
        "PLAYER_REGEN_DISABLED", "PLAYER_LEAVING_WORLD" }) do events:RegisterEvent(name) end
    events:SetScript("OnEvent", function(_, event, questID)
        if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_LEAVING_WORLD" then Hide()
        else
            treasures = nil
            if event == "QUEST_TURNED_IN" and questID then
                for _, quest in ipairs(ns.NextQuests(questID, math.huge)) do
                    followUps[quest.id] = GetTime() + 600
                end
            end
        end
    end)
    -- Players can pass a giver without a quest or zone event.
    ticker = C_Timer.NewTicker(5, Refresh)
end
