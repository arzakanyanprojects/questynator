-- Quest Routes and the Route Planner: the stops to visit in this zone, reward and dungeon-prep routes,
-- snoozing, and the planner window. Questynator.lua exposes the helpers used here through ns.
local _, ns = ...
local L = ns.L
local PlayerWorld, PlaceDistance, RefPlace = ns.PlayerWorld, ns.PlaceDistance, ns.RefPlace
local IsReady, TrackedQuest, QuestTitle = ns.IsReadyToTurnIn, ns.TrackedQuest, ns.QuestTitle
local ZoneName, RefreshPanel, ROW_W = ns.ZoneName, ns.RefreshPanel, ns.ROW_W

-- Keep stops fixed until replanning or completing an objective or quest. An objective can have several
-- candidate locations, but only one is needed and it may share a stop with other objectives.
local ROUTE_LIMIT, ROUTE_RADIUS, PICKUP_RADIUS = 10, 60, 300
local route

local function VisitZone()
    local id = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    for _ = 1, 6 do
        if not id or id == 0 then return end
        local info = C_Map.GetMapInfo and C_Map.GetMapInfo(id)
        if not info or not info.mapType or info.mapType < 3 then return end
        if info.mapType <= 4 then return id end
        id = info.parentMapID
    end
end

local function UpdateVisit()
    local zone = VisitZone()
    if zone and QuestynatorRouteSnoozes and QuestynatorRouteSnoozes.zone ~= zone then
        QuestynatorRouteSnoozes = nil
    end
    return zone
end

function ns.IsSnoozedPlace(place)
    local visit = QuestynatorRouteSnoozes
    if not visit then return false end
    for _, stop in ipairs(visit.stops) do
        for _, spot in ipairs(stop) do
            if spot.uiMap == place.uiMap and spot.x == place.x and spot.y == place.y then return true end
        end
    end
    return false
end

local function RouteDistance(a, b)
    if a == b or (a.uiMap and a.uiMap == b.uiMap and a.x == b.x and a.y == b.y) then return 0 end
    if not a.wx or not b.wx or not a.wInst or a.wInst ~= b.wInst then return math.huge end
    return math.sqrt((a.wx - b.wx) ^ 2 + (a.wy - b.wy) ^ 2)
end

local function RouteTasks(origin)
    local tasks, maps = {}, ns.CurrentZoneMaps()
    local fallback, fallbackDistance
    local function Add(info, index, places, pickup, delivery)
        local localPlaces = {}
        for _, place in ipairs(places) do
            if maps[place.uiMap] and not ns.IsSnoozedPlace(place) then
                local yards = PlaceDistance(place, origin.wInst, origin.wx, origin.wy)
                if place.wInst == origin.wInst and place.wx and place.wy then
                    if pickup and yards > PICKUP_RADIUS then
                        if not fallback or yards < fallbackDistance or
                            (yards == fallbackDistance and info.questID < fallback.questID) then
                            fallback = { questID = info.questID, title = info.title, pickup = true, places = { place } }
                            fallbackDistance = yards
                        end
                    else
                        localPlaces[#localPlaces + 1] = place
                    end
                end
            end
        end
        if #localPlaces > 0 then
            tasks[#tasks + 1] = {
                questID = info.questID, title = info.title or QuestTitle(info.questID),
                index = index, places = localPlaces, pickup = pickup, delivery = delivery,
            }
        end
    end
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        local id = info and not info.isHeader and not info.isHidden and info.questID
        if id and IsReady(id) then
            local q = ns.BundledQuest(id)
            local place = q and RefPlace(q.finish)
            if place then Add(info, nil, { place }) end
        elseif id then
            local places, _, delivery = ns.RewardDestinations({ id = id, state = "inlog" })
            if delivery then
                Add(info, nil, places, false, true)
            else
                local byIndex = {}
                for _, place in ipairs(places) do
                    local index = place.objectiveIndex
                    byIndex[index] = byIndex[index] or {}
                    table.insert(byIndex[index], place)
                end
                for index, candidates in pairs(byIndex) do Add(info, index, candidates) end
            end
        end
    end
    if not (C_QuestLog.IsQuestLogFull and C_QuestLog.IsQuestLogFull()) then
        for _, quest in ipairs(ns.AvailableQuests()) do
            local uiMap = ns.UiMapForArea(quest.area)
            if maps[uiMap] and quest.x >= 0 and quest.x <= 100 and quest.y >= 0 and quest.y <= 100 then
                local giver = { name = quest.giver, area = quest.area, uiMap = uiMap, x = quest.x, y = quest.y }
                Add({ questID = quest.questID, title = quest.name }, nil, { giver }, true)
            end
        end
    end
    if #tasks == 0 and fallback then tasks[1] = fallback end
    return tasks
end

-- Both the browser and the planner use the destinations for the current step.
function ns.RewardDestinations(entry)
    local qid = entry.id
    local quest = ns.BundledQuest(qid)
    if entry.state == "locked" then
        return {}, ns.RewardStepLabel(entry)
    elseif entry.state == "available" then
        if C_QuestLog.IsQuestLogFull and C_QuestLog.IsQuestLogFull() then
            return {}, L["Quest log full"]
        end
        return { quest and RefPlace(quest.start) }
    elseif entry.ready then
        return { quest and RefPlace(quest.finish) }
    end
    local places = {}
    for index, objective in ipairs((C_QuestLog.GetQuestObjectives and C_QuestLog.GetQuestObjectives(qid)) or {}) do
        if not objective.finished then
            for _, candidate in ipairs(ns.ObjectiveSpots(qid, index)) do
                candidate.objectiveIndex = index
                places[#places + 1] = candidate
            end
        end
    end
    if #places == 0 and quest and #quest.mobs == 0 and #quest.objects == 0 and #quest.items == 0 then
        return { RefPlace(quest.finish) }, nil, true
    end
    return places
end

function ns.RewardDestination(entry, omitSnoozed)
    local places, message, delivery = ns.RewardDestinations(entry)
    local maps = ns.CurrentZoneMaps()
    local inst, wx, wy = PlayerWorld()
    local place, nearest, localStop
    for _, candidate in ipairs(places) do
        if not omitSnoozed or not ns.IsSnoozedPlace(candidate) then
            local inZone = maps[candidate.uiMap] == true
            local distance = PlaceDistance(candidate, inst, wx, wy)
            if not place or (inZone and not localStop) or (inZone == localStop and distance < nearest) then
                place, nearest, localStop = candidate, distance, inZone
            end
        end
    end
    return place, message, delivery, not place and #places > 0
end

function ns.PinLabel(pickup, objective)
    return pickup and L["Pin pickup"] or (objective and L["Pin objective"] or L["Pin turn-in"])
end

local function RewardPlan(entry)
    local plan = { stops = {}, index = 1, reward = entry.reward.name }
    local qid = entry.id
    local task = { questID = qid, title = ns.ZoneQuest(qid).name, pickup = entry.state == "available" }
    local place, message, delivery, snoozed = ns.RewardDestination(entry, true)
    if snoozed then return nil end
    plan.message, task.delivery = message, delivery
    if place then
        task.index = place.objectiveIndex
        task.places, task.destination = { place }, place
        place.questID, place.title, place.routeStop = qid, task.title, true
        place.rewardItem = entry.reward.item
        plan.stops[1] = { target = place, tasks = { task } }
    else
        plan.message = (plan.message or L["Location unknown"]) .. " · " .. task.title
    end
    return plan
end

local function BuildStops(tasks, origin, currentTask, ordinary)
    local plan = { stops = {}, index = 1 }
    while #tasks > 0 and #plan.stops < ROUTE_LIMIT do
        local target, score, lead
        for _, task in ipairs(tasks) do
            for _, place in ipairs(task.places) do
                local yards = RouteDistance(origin, place)
                -- Let an accepted task win over a pickup within a short detour.
                local cost = yards + (ordinary and task.pickup and 150 or 0)
                if currentTask and task.questID == currentTask.questID and task.index == currentTask.index
                    and task.pickup == currentTask.pickup and task.delivery == currentTask.delivery
                    and RouteDistance(currentTask.destination, place) == 0 then cost = -1 end
                if not target or cost < score or (cost == score and
                    (task.questID < lead.questID or (task.questID == lead.questID and (task.index or 0) < (lead.index or 0)))) then
                    target, score, lead = place, cost, task
                end
            end
        end
        local stop, remaining = { target = target, tasks = {} }, {}
        for _, task in ipairs(tasks) do
            local nearest, nearestYards
            for _, place in ipairs(task.places) do
                local yards = RouteDistance(target, place)
                if yards <= ROUTE_RADIUS and (not nearestYards or yards < nearestYards) then
                    nearest, nearestYards = place, yards
                end
            end
            task.destination = nearest
            local list = nearest and stop.tasks or remaining
            list[#list + 1] = task
        end
        table.sort(stop.tasks, function(a, b)
            if a == b then return false end
            if a == lead or b == lead then return a == lead end
            if (not not a.pickup) ~= (not not b.pickup) then return not a.pickup end
            if a.questID ~= b.questID then return a.questID < b.questID end
            return (a.index or 0) < (b.index or 0)
        end)
        currentTask = nil
        target.questID = lead.questID
        target.title = #stop.tasks == 1 and stop.tasks[1].title or string.format(L["Route stop %d"], #plan.stops + 1)
        target.routeStop = true
        plan.stops[#plan.stops + 1] = stop
        tasks, origin = remaining, target
    end
    return plan
end

function ns.PlanRoute(currentTask)
    UpdateVisit()
    local inst, wx, wy = PlayerWorld()
    local origin = { wInst = inst, wx = wx, wy = wy }
    if QuestynatorPrepDungeon then
        local tasks, message = ns.PrepPickupTasks(QuestynatorPrepDungeon)
        if #tasks > 0 or message then
            for _, task in ipairs(tasks) do PlaceDistance(task.places[1], inst, wx, wy) end
            route = BuildStops(tasks, origin)
            route.prep, route.message = ns.DungeonName(QuestynatorPrepDungeon), message
            return
        end
        QuestynatorPrepDungeon = nil
    end
    if QuestynatorRewardGoal then
        local reward = ns.RewardCatalog[QuestynatorRewardGoal]
        local entry = reward and ns.RewardProgress(reward)
        if entry then
            local plan = RewardPlan(entry)
            if plan then route = plan; return end
        else
            QuestynatorRewardGoal = nil
        end
    end
    if route and (route.reward or route.prep) then route = nil end
    if not inst or not next(ns.CurrentZoneMaps()) then
        route = nil
        return
    end
    route = BuildStops(RouteTasks(origin), origin, currentTask, true)
end

local enteredWorld, startupQueued
function ns.StartInitialRoute(onEntry)
    if onEntry then enteredWorld = true end
    if route or not enteredWorld or startupQueued then return end
    startupQueued = true
    local attempts = 0
    local function TryStart()
        if not route and C_QuestLog.GetNumQuestLogEntries() ~= nil then
            ns.PlanRoute()
            if route then
                ns.ArrowRefresh()
                ns.RequestRefresh()
            end
        end
        attempts = attempts + 1
        if not route and attempts < 6 then
            C_Timer.After(1, TryStart)
        else
            startupQueued = false
        end
    end
    C_Timer.After(0, TryStart)
end

function ns.QueueRouteReplan(turnedInID)
    UpdateVisit()
    local reward = turnedInID and ns.RewardCatalog[QuestynatorRewardGoal]
    if reward and turnedInID == reward.steps[#reward.steps] then
        QuestynatorRewardGoal = nil
        if route then route.paused = false end
    end
    -- No route yet (left an instance, crossed open water): plan from scratch.
    if not route then ns.StartInitialRoute(); return end
    if turnedInID then
        route.awaitingRemoval = route.awaitingRemoval or {}
        route.awaitingRemoval[turnedInID] = true
    end
    if route.replanQueued or route.needsReplan then return end
    local pending = route
    pending.replanQueued = true
    C_Timer.After(0, function()
        if route ~= pending then return end
        pending.replanQueued = nil
        pending.needsReplan = true
        ns.ArrowRefresh()
        ns.RequestRefresh()
    end)
end

local function RouteTaskDone(task)
    if task.pickup then
        return ns.QuestState(task.questID) ~= "available" or (C_QuestLog.IsQuestLogFull and C_QuestLog.IsQuestLogFull())
    end
    local index = ns.QuestLogIndex(task.questID)
    if not index then return true end
    if not task.index then return false end
    if IsReady(task.questID) then return true end
    local objectives = C_QuestLog.GetQuestObjectives(task.questID)
    return objectives and objectives[task.index] and objectives[task.index].finished
end

function ns.UpdateRoute()
    if not route or route.paused then return end
    if route.needsReplan then
        -- QUEST_TURNED_IN can arrive before the log drops the old quest.
        -- Keep the request pending until a subsequent refresh sees the removal.
        if route.awaitingRemoval then
            for id in pairs(route.awaitingRemoval) do
                if ns.QuestLogIndex(id) then return end
            end
        end
        local stop = route.stops[route.index]
        local keep
        if stop and not route.reward and not route.prep then
            for _, task in ipairs(stop.tasks) do
                if not RouteTaskDone(task) then keep = task; break end
            end
        end
        ns.PlanRoute(keep)
        if not route then ns.StartInitialRoute() end
    end
    if not route then return end
    local stop = route.stops[route.index]
    while stop do
        for _, task in ipairs(stop.tasks) do
            if not RouteTaskDone(task) then return end
        end
        route.index = route.index + 1
        stop = route.stops[route.index]
        if not stop then ns.QueueRouteReplan() end
    end
end

function ns.RouteTarget()
    local stop = route and not route.paused and route.stops[route.index]
    return stop and stop.target
end

function ns.RoutePaused() return route and route.paused end

function ns.SnoozeRouteStop(undo)
    local zone = UpdateVisit()
    local visit = QuestynatorRouteSnoozes
    if undo then
        if not visit then return end
        table.remove(visit.stops)
        if #visit.stops == 0 then QuestynatorRouteSnoozes = nil end
    else
        local stop = route and route.stops[route.index]
        if not zone or not stop then return end
        local spots = {}
        for _, task in ipairs(stop.tasks) do
            local p = task.destination
            spots[#spots + 1] = { uiMap = p.uiMap, x = p.x, y = p.y }
        end
        visit = visit or { zone = zone, stops = {} }
        visit.stops[#visit.stops + 1] = spots
        QuestynatorRouteSnoozes = visit
    end
    local paused = route and route.paused
    route = nil
    ns.PlanRoute()
    if route then route.paused = paused end
    ns.ArrowUndismiss()
    ns.ArrowRefresh()
    ns.RequestRefresh()
end

local function MarkPlace(place, title)
    if place then
        ns.Waypoint(place.area, place.x, place.y, title, TrackedQuest() ~= nil)
    end
end

function ns.SetRewardPursuit(item)
    if item then QuestynatorPrepDungeon = nil end
    QuestynatorRewardGoal = item
    ns.PlanRoute()
    ns.ArrowUndismiss()
    ns.ArrowRefresh()
    ns.RequestRefresh()
    local target = item and ns.RouteTarget()
    if target then MarkPlace(target, target.title) end
end

function ns.SetDungeonPrepRoute(id)
    QuestynatorPrepDungeon = id
    ns.PlanRoute()
    ns.ArrowUndismiss()
    ns.ArrowRefresh()
    ns.RequestRefresh()
    local target = QuestynatorPrepDungeon and ns.RouteTarget()
    if target then MarkPlace(target, target.title) end
end

function ns.BuildRouteView(p)
    local view = CreateFrame("Frame", nil, p.questView)
    p.routeView = view
    view:SetPoint("TOPLEFT", p.questView, "TOPLEFT", 0, -32)
    view:SetPoint("TOPRIGHT", p.questView, "TOPRIGHT", 0, -32)
    view:SetHeight(26)

    local function Changed()
        p.questScroll:SetVerticalScroll(0)
        ns.ArrowUndismiss()
        ns.ArrowRefresh()
        RefreshPanel()
    end
    local function RouteButton(width, text, onClick, kind)
        local button = ns.UI.Button(view, width, 20, kind)
        button:SetText(text)
        button:SetScript("OnClick", onClick)
        return button
    end
    view.plan = RouteButton(110, L["Plan My Route"], function()
        ns.PlanRoute()
        Changed()
    end, "primary")
    view.plan:SetPoint("TOPLEFT", 10, 0)
    view.pause = RouteButton(66, L["Pause"], function()
        route.paused = not route.paused
        Changed()
    end)
    view.pause:SetPoint("LEFT", view.plan, "RIGHT", 6, 0)
    view.skip = RouteButton(88, L["Snooze stop"], function()
        ns.SnoozeRouteStop(false)
    end)
    view.skip:SetPoint("LEFT", view.pause, "RIGHT", 6, 0)
    view.mark = RouteButton(104, L["Mark on map"], function()
        local stop = route and route.stops[route.index]
        if stop then MarkPlace(stop.target, stop.target.title) end
    end, "outline")
    view.mark:SetPoint("TOPRIGHT", -10, 0)
    view.mark:SetScript("OnEnter", ns.UI.ShowTip)
    view.mark:SetScript("OnLeave", function() GameTooltip:Hide() end)
    view.mark:Hide()
    view.status = ns.UI.Text(view, 10, "muted")
end

local function StopDestination(stop)
    local target = stop.target
    if target.name and target.name ~= "" then return target.name end
    return ZoneName(target.area) or stop.tasks[1].title
end

local function RouteTaskText(task)
    if task.pickup then
        return string.format(L["Pick up %s from %s"], task.title, task.places[1].name)
    end
    if task.delivery then return string.format(L["Speak to %s"], task.destination.name) end
    if not task.index then return string.format(L["Turn in %s"], task.title) end
    local objectives = C_QuestLog.GetQuestObjectives(task.questID)
    local o = objectives and objectives[task.index]
    if not o then return task.title end
    local label = o.text and o.text ~= "" and o.text or task.title
    local have, need = tonumber(o.numFulfilled), tonumber(o.numRequired)
    if have and need and need > 0 and not label:find("%d+%s*/%s*%d+") and not label:find("%%") then
        label = string.format("%s  %d/%d", label, have, need)
    end
    return o.finished and ("|cff72c990" .. label .. "|r") or label
end

local planner

local function PlannerRow(i)
    local row = planner.rows[i]
    if row then return row end
    row = CreateFrame("Frame", nil, planner)
    row:SetWidth(planner:GetWidth() - 24)
    row.pin = ns.UI.Button(row, 91, 20, "outline")
    row.pin:SetPoint("RIGHT")
    row.pin.tip = L["Mark on map"]
    row.pin:SetScript("OnEnter", ns.UI.ShowTip)
    row.pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row.pin:SetScript("OnClick", function()
        local task = row.task
        if task and not RouteTaskDone(task) then MarkPlace(task.destination, task.title) end
    end)
    row.text = ns.UI.Text(row, i == 1 and 13 or 11, i == 1 and "text" or "muted")
    row.text:SetPoint("LEFT")
    row.text:SetWidth(row:GetWidth() - row.pin:GetWidth() - 8)
    row.text:SetJustifyH("LEFT")
    planner.rows[i] = row
    return row
end

function ns.RefreshPlanner()
    if not planner or not planner:IsShown() then return end
    local stop = route and route.stops[route.index]
    local selected, selectedIndex = TrackedQuest()
    planner.resume = stop and (selectedIndex or route.paused)
    planner.plan:SetText(planner.resume and L["Resume route"] or (stop and L["Pause"] or L["Replan"]))
    local heading = L["Waiting for quest and map data"]
    local context = ""
    if stop then
        context = route.prep or route.reward or string.format(L["Stop %d of %d"], route.index, #route.stops)
        heading = StopDestination(stop)
        if selectedIndex then
            context = L["Selected quest"] .. " · " .. QuestTitle(selected)
            heading = L["Up next when you resume"] .. " · " .. heading
        elseif route.paused then
            context = L["Route paused"] .. " · " .. context
        end
    elseif route then
        heading = route.message or (QuestynatorRouteSnoozes and L["No other stops found. Undo snooze to restore a stop."]
            or L["No eligible pickups or known quest stops in this zone."])
    end
    local top = 31
    if context ~= "" then
        planner.context:SetText(context)
        planner.context:Show()
        top = top + math.ceil(planner.context:GetStringHeight()) + 3
    else
        planner.context:Hide()
    end
    planner.heading:SetText(heading)
    planner.heading:SetPoint("TOPLEFT", 12, -top)
    top = top + math.ceil(planner.heading:GetStringHeight()) + 4
    local used, total = 0, 0
    local limit = ns.DB().plannerExpanded and 3 or 1
    if stop then
        for i = route.index, #route.stops do
            for _, task in ipairs(route.stops[i].tasks) do
                if not RouteTaskDone(task) then
                    total = total + 1
                    if used < limit then
                    used = used + 1
                    local row = PlannerRow(used)
                    row.task = task
                    row.pin:SetText(ns.PinLabel(task.pickup, task.index or task.delivery))
                    local label = RouteTaskText(task)
                    if i > route.index then label = string.format(L["Up next: %s"], label) end
                    row.text:SetText(label)
                    row:SetPoint("TOPLEFT", 12, -top)
                    row:SetHeight(math.max(20, math.ceil(row.text:GetStringHeight())))
                    row:Show()
                    top = top + row:GetHeight() + 2
                    end
                end
            end
            if total > limit then break end
        end
    end
    for i = used + 1, #planner.rows do
        planner.rows[i].task = nil
        planner.rows[i]:Hide()
    end
    planner.expand:SetText(ns.DB().plannerExpanded and L["Less"] or L["More"])
    planner.expand:SetShown(total > 1 or stop ~= nil)
    planner.expand:SetPoint("TOPLEFT", 12, -top)
    planner.snooze:SetShown(stop ~= nil and ns.DB().plannerExpanded == true)
    planner.undo:SetShown(QuestynatorRouteSnoozes ~= nil)
    planner.snooze:SetPoint("TOPLEFT", 72, -top)
    planner.undo:SetPoint("TOPLEFT", stop and (ns.DB().plannerExpanded and 175 or 72) or 12, -top)
    local hosted, hostContext = ns.PaintHostButton(planner.host)
    planner.host:SetPoint("TOPRIGHT", -12, -top)
    top = top + 23
    planner.hosting:SetShown(hosted ~= nil)
    if hosted then
        planner.hosting:SetPoint("TOPLEFT", 12, -top)
        planner.hosting:SetText(string.format(L["Hosting: %s"], hostContext))
        top = top + math.ceil(planner.hosting:GetStringHeight()) + 2
    end
    planner:SetHeight(top + 6)
end

function ns.ShowPlanner(shown)
    ns.DB().plannerHidden = not shown
    if not shown then
        if planner then planner:Hide() end
        return
    end
    if not planner then
        planner = ns.UI.Window("QuestynatorPlanner", 360, 34)
        planner.TitleText:SetText("Questynator : Route Planner")
        planner:SetClampedToScreen(true)
        planner:SetMovable(true)
        planner:EnableMouse(true)
        planner:RegisterForDrag("LeftButton")
        planner:SetScript("OnDragStart", planner.StartMoving)
        planner:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local point, _, relative, x, y = self:GetPoint()
            ns.DB().plannerPos = { point, relative, x, y }
        end)
        local pos = ns.DB().plannerPos
        if pos then planner:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
        else planner:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 24, -180) end
        planner.CloseButton:SetScript("OnClick", function() ns.SetOption("planner", false) end)
        planner.plan = ns.UI.Button(planner, 110, 20, "outline")
        planner.plan:SetPoint("RIGHT", planner.CloseButton, "LEFT", -6, 0)
        planner.plan:SetScript("OnClick", function()
            if planner.resume then
                local _, selectedIndex = TrackedQuest()
                if selectedIndex then C_SuperTrack.SetSuperTrackedQuestID(0) end
                if route then route.paused = false end
            elseif route and route.stops[route.index] then
                route.paused = true
            else
                ns.PlanRoute()
            end
            ns.ArrowUndismiss()
            ns.ArrowRefresh()
            RefreshPanel()
        end)
        planner.context = ns.UI.Text(planner, 10, "accent", nil, "medium")
        planner.context:SetPoint("TOPLEFT", 12, -31)
        planner.context:SetWidth(planner:GetWidth() - 24)
        planner.context:SetJustifyH("LEFT")
        planner.heading = ns.UI.Text(planner, 13, "text", nil, "bold")
        planner.heading:SetPoint("TOPLEFT", 12, -30)
        planner.heading:SetWidth(planner:GetWidth() - 24)
        planner.heading:SetJustifyH("LEFT")
        planner.expand = ns.UI.Button(planner, 54, 20, "ghost")
        planner.expand:SetScript("OnClick", function()
            ns.DB().plannerExpanded = not ns.DB().plannerExpanded
            ns.RefreshPlanner()
        end)
        planner.snooze = ns.UI.Button(planner, 98, 20, "outline")
        planner.snooze:SetText(L["Snooze stop"])
        planner.snooze.tip = L["Hide this stop until you leave the zone."]
        planner.snooze:SetScript("OnEnter", ns.UI.ShowTip)
        planner.snooze:SetScript("OnLeave", function() GameTooltip:Hide() end)
        planner.snooze:SetScript("OnClick", function() ns.SnoozeRouteStop(false) end)
        planner.undo = ns.UI.Button(planner, 64, 20, "outline")
        planner.undo:SetText(L["Undo"])
        planner.undo.tip = L["Undo snooze"]
        planner.undo:SetScript("OnEnter", ns.UI.ShowTip)
        planner.undo:SetScript("OnLeave", function() GameTooltip:Hide() end)
        planner.undo:SetScript("OnClick", function() ns.SnoozeRouteStop(true) end)
        planner.host = ns.MakeHostButton(planner)
        planner.hosting = ns.UI.Text(planner, 11, "accent")
        planner.hosting:SetWidth(planner:GetWidth() - 24)
        planner.hosting:SetJustifyH("LEFT")
        planner.rows = {}
    end
    planner:Show()
    ns.RefreshPlanner()
end

function ns.AddRouteTooltip(tt)
    local stop = route and route.stops[route.index]
    if not stop then return end
    local status = route.paused and L["Route paused"] or string.format(L["Stop %d of %d"], route.index, #route.stops)
    tt:AddLine(status, 0.31, 0.82, 0.77)
    local target = stop.target
    local geometry = ns.ArrowGeometry(target)
    if geometry.yards then
        tt:AddDoubleLine(target.name, string.format(L["%d yd"], math.floor(geometry.yards + 0.5)), 1, 1, 1, 0.7, 0.7, 0.7)
    else
        tt:AddLine(target.name, 1, 1, 1, true)
    end
    for _, task in ipairs(stop.tasks) do
        if (task.pickup and not RouteTaskDone(task)) or (task.index and ns.QuestLogIndex(task.questID)) then
            tt:AddLine(RouteTaskText(task), 1, 1, 1, true)
        end
    end
end

function ns.RefreshRouteView(p)
    local view = p.routeView
    local count = route and #route.stops or 0
    local active = route and route.index <= count
    view.plan:SetText(route and L["Replan"] or L["Plan My Route"])
    view.pause:SetShown(not not active)
    view.skip:SetShown(active and not route.reward or false)
    view.pause:SetText(route and route.paused and L["Resume"] or L["Pause"])
    local status = ""
    if active and route.paused then
        status = L["Route paused"]
    elseif route and not active then
        status = route.message or (count == 0 and L["No quest stops found in this zone"] or L["Route ended"])
    end
    view.status:ClearAllPoints()
    view.status:SetPoint("LEFT", active and (route.reward and view.pause or view.skip) or view.plan, "RIGHT", 10, 0)
    view.status:SetText(status)
    if not active then
        view.mark:Hide()
        if view.details then view.details:Hide() end
        return 0
    end

    -- Share the quest list's scroll area so a crowded stop can show every objective.
    if not view.details then
        local content = ns.QuestContent()
        view.details = ns.UI.Text(content, 12, "text")
        view.details:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -3)
        view.details:SetWidth(ROW_W - 16)
        view.details:SetJustifyH("LEFT")
        view.details:SetSpacing(3)
    end
    local stop = route.stops[route.index]
    local heading = (route.prep or route.reward or string.format(L["Stop %d of %d"], route.index, count)) .. " · " .. StopDestination(stop)
    local yards = ns.ArrowGeometry(stop.target).yards
    if yards then
        heading = heading .. " · " .. string.format(L["%d yd away"], math.floor(yards + 0.5))
    end
    local lines = { "|cff53d1c5" .. heading .. "|r" }
    for _, task in ipairs(stop.tasks) do
        if (task.pickup and not RouteTaskDone(task)) or (not task.pickup and ns.QuestLogIndex(task.questID)) then
            lines[#lines + 1] = RouteTaskText(task)
        end
    end
    for i = route.index + 1, count do
        local upcoming = route.stops[i]
        local pending
        for _, task in ipairs(upcoming.tasks) do
            if not RouteTaskDone(task) then pending = task; break end
        end
        if pending then
            local destination = StopDestination(upcoming)
            if pending.pickup then
                destination = RouteTaskText(pending)
            elseif not pending.index then
                destination = string.format(L["Turn in at %s"], destination)
            end
            lines[#lines + 1] = "|cffb4bec8" .. string.format(L["Up next: %s"], destination) .. "|r"
            break
        end
    end
    local first = stop.tasks[1]
    view.mark:SetText(#stop.tasks > 1 and L["Pin stop"] or ns.PinLabel(first.pickup, first.index or first.delivery))
    view.mark.tip = StopDestination(stop)
    view.mark:Show()
    view.details:SetText(table.concat(lines, "\n"))
    view.details:Show()
    return math.ceil(view.details:GetStringHeight()) + 12
end
