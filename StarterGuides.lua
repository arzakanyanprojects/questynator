-- Starter valley guides: which guide is running, what its current trip asks for, and the window that
-- offers a guide to a new character. Routes.lua turns the tasks into planner stops (the "guide" mode).
local _, ns = ...
local L = ns.L

local function Saved()
    if type(QuestynatorGuide) ~= "table" then QuestynatorGuide = {} end
    return QuestynatorGuide
end

local function Print(text) print("|cff33ccffQuestynator|r: " .. text) end

function ns.GuideByID(id)
    for _, guide in ipairs(ns.STARTER_GUIDES or {}) do
        if guide.id == id then return guide end
    end
end

function ns.ActiveGuide()
    local saved = QuestynatorGuide
    return type(saved) == "table" and saved.active and ns.GuideByID(saved.active) or nil
end

function ns.SetActiveGuide(id)
    local saved = Saved()
    saved.active, saved.offered = id, true
end

-- guides this character can follow: its own faction's valleys and the ones open to both
function ns.GuidesForPlayer()
    local faction, list = ns.PlayerFaction(), {}
    for _, guide in ipairs(ns.STARTER_GUIDES or {}) do
        if not guide.faction or not faction or guide.faction == faction then list[#list + 1] = guide end
    end
    return list
end

-- the guide for the valley you stand in
function ns.GuideHere()
    local maps = ns.CurrentZoneMaps()
    for _, guide in ipairs(ns.GuidesForPlayer()) do
        local uiMap = ns.UiMapForArea(guide.area)
        if uiMap and maps[uiMap] then
            local box = guide.box
            if not box then return guide end
            local pos = C_Map and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(uiMap, "player")
            local x, y
            if pos then
                if pos.GetXY then x, y = pos:GetXY() else x, y = pos.x, pos.y end
            end
            if not (x and y) then return guide end
            x, y = x * 100, y * 100
            if x >= box[1] and x <= box[2] and y >= box[3] and y <= box[4] then return guide end
        end
    end
end

local function Applies(step)
    return not step.race or select(2, UnitRace("player")) == step.race
end

local function AtPlace(at)
    local uiMap = ns.UiMapForArea(at[1])
    return uiMap and { area = at[1], x = at[2], y = at[3], name = at[4], uiMap = uiMap } or nil
end

local function GiverPlace(step)
    if step.at then return AtPlace(step.at) end
    local giver = ns.QuestGiver(step[2])
    local uiMap = giver and ns.UiMapForArea(giver.area)
    return uiMap and { area = giver.area, x = giver.x, y = giver.y, name = giver.name, uiMap = uiMap } or nil
end

local function FinishPlace(step)
    if step.at then return AtPlace(step.at) end
    local q = ns.BundledQuest(step[2])
    return q and ns.RefPlace(q.finish)
end

-- a quest started by an item: where the item drops
local function LootTask(qid, title)
    local q = ns.BundledQuest(qid)
    local itemID = q and q.start and tonumber(q.start:match("^i(%d+)$"))
    local raw = itemID and ns.QDATA.i and ns.QDATA.i[itemID]
    if not raw then return nil end
    local sources, name = raw:match("^([^;]*);(.*)$")
    local places = {}
    for ref in (sources or ""):gmatch("[no]%d+") do
        local place = ns.RefPlace(ref)
        if place then places[#places + 1] = place end
    end
    if #places == 0 then return nil end
    return { questID = qid, title = title, pickup = true, loot = name, places = places }
end

-- One step for you right now: "done", the tasks to do now, "wait" (an earlier step or the game comes
-- first), or "level" and the level it needs.
local function StepNow(step)
    local qid, kind = step[2], step[1]
    local state, need = ns.QuestState(qid)
    if state == "done" or state == "hidden" then return "done" end
    local title = ns.QuestTitle(qid)
    if kind == "accept" then
        if state == "inlog" then return "done" end
        if state == "available" then
            local place = GiverPlace(step)
            return place and { { questID = qid, title = title, pickup = true, places = { place } } } or "wait"
        end
        if state == "locked" and need and need > (UnitLevel("player") or 1) then return "level", need end
        if state == "unknown" then
            local task = LootTask(qid, title)
            return task and { task } or "wait"
        end
        return "wait"
    end
    if state ~= "inlog" then return "wait" end
    local ready = ns.IsReadyToTurnIn(qid)
    if kind == "complete" then
        if ready then return "done" end
        local places, _, delivery = ns.RewardDestinations({ id = qid, state = "inlog" })
        if delivery then return "wait" end
        local byIndex, tasks = {}, {}
        for _, place in ipairs(places) do
            local index = place.objectiveIndex
            if not byIndex[index] then
                byIndex[index] = { questID = qid, title = title, index = index, places = {} }
                tasks[#tasks + 1] = byIndex[index]
            end
            table.insert(byIndex[index].places, place)
        end
        return #tasks > 0 and tasks or "wait"
    end
    if not ready then return "wait" end
    local place = FinishPlace(step)
    return place and { { questID = qid, title = title, places = { place } } } or "wait"
end

-- What the guide asks for now: the tasks from the first trip that has something to do (and anything
-- left over from earlier trips), that trip's number, and a message when nothing can be done yet.
-- Returns nil once every step is done; the guide then ends and the Route Planner takes over.
function ns.GuideTasks(guide)
    local tasks, pendingTrip, blocked, waiting = {}, nil, nil, nil
    for t, trip in ipairs(guide.trips) do
        for i = 2, #trip do
            local step = trip[i]
            if Applies(step) then
                local now, need = StepNow(step)
                if type(now) == "table" then
                    for _, task in ipairs(now) do
                        task.guideTrip = trip[1]
                        tasks[#tasks + 1] = task
                    end
                elseif now ~= "done" and not step.opt then
                    pendingTrip = pendingTrip or t
                    if now == "level" then
                        if not blocked or need < blocked.need then blocked = { need = need, qid = step[2] } end
                    else
                        waiting = waiting or step
                    end
                end
            end
        end
        if #tasks > 0 then return tasks, t end
    end
    if blocked then
        return tasks, pendingTrip, string.format(L["Reach level %d for %s"], blocked.need, ns.QuestTitle(blocked.qid))
    end
    if waiting then
        return tasks, pendingTrip, string.format(L["Guide waiting for %s"], ns.QuestTitle(waiting[2]))
    end
    local saved = Saved()
    saved.active, saved.finished = nil, guide.id
    Print(string.format(L["Starter guide finished: %s. The Route Planner takes over from here."], guide.name))
    return nil
end

---------------------------------------------------------------------------
-- the guide window: offered once to a new character, and on /qn guide
---------------------------------------------------------------------------
local chooser

local function Choose(id)
    if chooser then chooser:Hide() end
    ns.SetGuide(id)
    local guide = id and ns.GuideByID(id)
    if guide then Print(string.format(L["Starter guide started: %s. Stop it any time in the Route Planner."], guide.name)) end
end

-- The offer counts as answered once you pick a guide, click Not now or close the window. A reload
-- before that (the WaypointUI question reloads) brings it back next login.
function ns.ShowGuideChooser(first)
    local UI = ns.UI
    if not chooser then
        chooser = UI.Window("QuestynatorGuideChooser", 320, 100)
        chooser:SetFrameStrata("DIALOG")
        chooser:SetToplevel(true)
        chooser:SetClampedToScreen(true)
        chooser:SetMovable(true)
        chooser:EnableMouse(true)
        chooser:RegisterForDrag("LeftButton")
        chooser:SetScript("OnDragStart", chooser.StartMoving)
        chooser:SetScript("OnDragStop", chooser.StopMovingOrSizing)
        chooser:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
        chooser.TitleText:SetText(L["Questynator : Starter guide"])
        chooser.intro = UI.Text(chooser, 11, "text")
        chooser.intro:SetWidth(296)
        chooser.intro:SetJustifyH("LEFT")
        chooser.label = UI.Text(chooser, 10, "muted", nil, "medium")
        chooser.label:SetJustifyH("LEFT")
        chooser.note = UI.Text(chooser, 10, "muted")
        chooser.note:SetWidth(190)
        chooser.note:SetJustifyH("LEFT")
        chooser.here = UI.Button(chooser, 296, 24, "primary")
        chooser.here:SetScript("OnClick", function(self) Choose(self.id) end)
        chooser.stop = UI.Button(chooser, 296, 22, "outline")
        chooser.stop:SetText(L["Stop the guide"])
        chooser.stop:SetScript("OnClick", function() Choose(nil) end)
        chooser.later = UI.Button(chooser, 96, 22, "ghost")
        chooser.later:SetText(L["Not now"])
        chooser.later:SetScript("OnClick", function() Saved().offered = true; chooser:Hide() end)
        chooser:SetScript("OnHide", function() Saved().offered = true end)
        chooser.buttons = {}
        if UISpecialFrames then tinsert(UISpecialFrames, "QuestynatorGuideChooser") end
    end
    local here, active = ns.GuideHere(), ns.ActiveGuide()
    local y = 36
    local function Place(widget, height, gap)
        widget:ClearAllPoints()
        widget:SetPoint("TOPLEFT", chooser, "TOPLEFT", 12, -y)
        widget:Show()
        y = y + height + (gap or 6)
    end
    chooser.intro:SetText(first and L["New here? Follow a quest guide through your starting area. It takes you to every quest in order up to about level 6, then the Route Planner takes over."]
        or L["Quest guides for the starting areas, levels 1 to 6. The guide points the Route Planner at each quest in order."])
    Place(chooser.intro, math.ceil(tonumber(chooser.intro:GetStringHeight()) or 40), 10)
    chooser.here:Hide()
    chooser.stop:Hide()
    if active then
        chooser.stop:SetText(string.format(L["Stop the guide: %s"], active.name))
        Place(chooser.stop, 22, 10)
    elseif here then
        chooser.here.id = here.id
        chooser.here:SetText(string.format(L["Start guide: %s"], here.name))
        Place(chooser.here, 24, 10)
    end
    chooser.label:SetText(here and not active and L["Or choose a starting area:"] or L["Choose a starting area:"])
    Place(chooser.label, 12, 6)
    local shown = 0
    for _, guide in ipairs(ns.GuidesForPlayer()) do
        if not (here and guide.id == here.id and not active) then
            shown = shown + 1
            local button = chooser.buttons[shown]
            if not button then
                button = UI.Button(chooser, 296, 22, "outline")
                button:SetScript("OnClick", function(self) Choose(self.id) end)
                chooser.buttons[shown] = button
            end
            button.id = guide.id
            local text = guide.name .. "  |cff8b8f96" .. guide.races .. "|r"
            if active and guide.id == active.id then text = text .. "  |cff4fd1c5" .. L["(running)"] .. "|r" end
            button:SetText(text)
            Place(button, 22, 4)
        end
    end
    for i = shown + 1, #chooser.buttons do chooser.buttons[i]:Hide() end
    y = y + 8
    chooser.later:ClearAllPoints()
    chooser.later:SetPoint("TOPRIGHT", chooser, "TOPRIGHT", -12, -y)
    chooser.later:Show()
    chooser.note:SetText(L["Type /qn guide to open this again."])
    y = y + 5
    Place(chooser.note, 12, 0)
    y = y + 5
    chooser:SetHeight(y + 12)
    chooser:Show()
end

-- On entering the world: offer the guide once to a character that has just been made.
local offerQueued, events
function ns.GuideWorldEntry()
    if not events and CreateFrame then
        events = CreateFrame("Frame")
        pcall(events.RegisterEvent, events, "QUEST_ACCEPTED")
        events:SetScript("OnEvent", function()
            if ns.ActiveGuide() then ns.QueueRouteReplan() end
        end)
    end
    local saved = Saved()
    if saved.offered or saved.active or offerQueued then return end
    if (UnitLevel("player") or 1) > 2 then return end
    offerQueued = true
    -- a new character's intro movie plays first, and the WaypointUI question sits in the same spot:
    -- wait for both to close
    local tries = 0
    local function Offer()
        local busy = (CinematicFrame and CinematicFrame:IsShown()) or (MovieFrame and MovieFrame:IsShown())
            or (QuestynatorPinChoice and QuestynatorPinChoice:IsShown())
        tries = tries + 1
        if busy and tries < 150 then C_Timer.After(2, Offer); return end
        offerQueued = false
        if not Saved().offered then ns.ShowGuideChooser(true) end
    end
    C_Timer.After(4, Offer)
end
