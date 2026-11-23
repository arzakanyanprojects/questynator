-- Quest Routes and the Route Planner: the stops to visit in this zone, reward and dungeon-prep routes,
-- snoozing, and the planner window. Questynator.lua exposes the helpers used here through ns.
local _, ns = ...
local L = ns.L
local PlayerWorld, PlaceDistance, RefPlace = ns.PlayerWorld, ns.PlaceDistance, ns.RefPlace
local IsReady, TrackedQuest, QuestTitle = ns.IsReadyToTurnIn, ns.TrackedQuest, ns.QuestTitle
local ZoneName, RefreshPanel = ns.ZoneName, ns.RefreshPanel

-- Keep stops fixed until replanning or completing an objective or quest. An objective can have several
-- candidate locations, but only one is needed and it may share a stop with other objectives.
local ROUTE_LIMIT, ROUTE_RADIUS, PICKUP_RADIUS = 10, 60, 300
local route
-- The zone chosen with "Route there". It lasts until you arrive, so it is not saved.
local travel

-- Leveling routes leave out dungeon and battleground quest pickups. A dungeon quest has every objective
-- inside a dungeon. A battleground quest needs Marks of Honor or has its objectives in a battleground.
-- Dungeon prep and reward pursuit still route to them because the player asked for them.
local BATTLEGROUND_AREAS = { [2597] = true, [3277] = true, [3358] = true }   -- Alterac Valley, Warsong Gulch, Arathi Basin
local questKinds, dungeonAreas = {}, nil
local function RefArea(ref)
    local D = ns.QDATA
    local kind, id = ref:match("^([no])(%d+)$")
    local raw = kind and D[kind] and D[kind][tonumber(id)]
    return raw and tonumber(raw:match("^([^,]*)"))
end

-- "dungeon", "battleground", or false for an ordinary quest
local function InstanceKind(qid)
    local known = questKinds[qid]
    if known ~= nil then return known end
    if not dungeonAreas then
        dungeonAreas = {}
        for _, d in ipairs(ns.DUNGEONS or {}) do dungeonAreas[d.id] = true end
    end
    local q, D = ns.BundledQuest(qid), ns.QDATA
    local refs, kind = {}, false
    if q then
        for _, ref in ipairs(q.mobs) do refs[#refs + 1] = ref end
        for _, ref in ipairs(q.objects) do refs[#refs + 1] = ref end
        for _, item in ipairs(q.items) do
            local srcs, name = tostring(D.i and D.i[item] or ""):match("^([^;]*);(.*)$")
            if name and name:find("Mark of Honor$") then kind = "battleground" end
            for ref in (srcs or ""):gmatch("[no]%d+") do refs[#refs + 1] = ref end
        end
    end
    if not kind then
        for _, ref in ipairs(refs) do
            local area = RefArea(ref)
            if area then
                if BATTLEGROUND_AREAS[area] then kind = "battleground"
                elseif not dungeonAreas[area] then kind = false; break
                elseif not kind then kind = "dungeon" end
            end
        end
    end
    questKinds[qid] = kind
    return kind
end

function ns.IsDungeonQuest(qid) return InstanceKind(qid) == "dungeon" end
function ns.IsBattlegroundQuest(qid) return InstanceKind(qid) == "battleground" end

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
            if maps[uiMap] and quest.x >= 0 and quest.x <= 100 and quest.y >= 0 and quest.y <= 100
                and not InstanceKind(quest.questID) then
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

-- Stops are chained nearest first: each next stop is the closest place to the one before it.
local function BuildStops(tasks, origin)
    local plan = { stops = {}, index = 1 }
    while #tasks > 0 and #plan.stops < ROUTE_LIMIT do
        local target, score, lead
        for _, task in ipairs(tasks) do
            for _, place in ipairs(task.places) do
                local cost = RouteDistance(origin, place)
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
        target.questID = lead.questID
        target.title = #stop.tasks == 1 and stop.tasks[1].title or string.format(L["Route stop %d"], #plan.stops + 1)
        target.routeStop = true
        plan.stops[#plan.stops + 1] = stop
        tasks, origin = remaining, target
    end
    return plan
end

-- Work outside the current zone, grouped by zone: pickups that fit your level (no dungeon quests)
-- and quests in your log. Used for "Best next" when this zone has nothing left, and for "Route there".
local function ZoneWork(inst, wx, wy)
    local here, zones = ns.CurrentZoneMaps(), {}
    local function Add(task, places, kind)
        local byArea = {}
        for _, place in ipairs(places) do
            local uiMap = place and place.area and (place.uiMap or ns.UiMapForArea(place.area))
            if uiMap and not here[uiMap] then
                place.uiMap = uiMap
                byArea[place.area] = byArea[place.area] or {}
                table.insert(byArea[place.area], place)
            end
        end
        for area, list in pairs(byArea) do
            local z = zones[area]
            if not z then
                z = { area = area, name = ZoneName(area) or ("#" .. area), pickups = 0, turnins = 0, active = 0,
                      tasks = {}, seen = {} }
                zones[area] = z
            end
            for _, place in ipairs(list) do
                local yards = PlaceDistance(place, inst, wx, wy)
                if not z.yards or yards < z.yards then z.yards = yards end
            end
            z.tasks[#z.tasks + 1] = {
                questID = task.questID, title = task.title, index = task.index,
                pickup = task.pickup, delivery = task.delivery, places = list,
            }
            if not z.seen[kind .. task.questID] then
                z.seen[kind .. task.questID] = true
                z[kind] = z[kind] + 1
            end
        end
    end
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        local id = info and not info.isHeader and not info.isHidden and info.questID
        local title = id and (info.title or QuestTitle(id))
        if id and IsReady(id) then
            local q = ns.BundledQuest(id)
            local place = q and RefPlace(q.finish)
            if place then Add({ questID = id, title = title }, { place }, "turnins") end
        elseif id then
            local places, _, delivery = ns.RewardDestinations({ id = id, state = "inlog" })
            if delivery then
                Add({ questID = id, title = title, delivery = true }, places, "active")
            else
                local byIndex = {}
                for _, place in ipairs(places) do
                    byIndex[place.objectiveIndex] = byIndex[place.objectiveIndex] or {}
                    table.insert(byIndex[place.objectiveIndex], place)
                end
                for index, candidates in pairs(byIndex) do
                    Add({ questID = id, title = title, index = index }, candidates, "active")
                end
            end
        end
    end
    if not (C_QuestLog.IsQuestLogFull and C_QuestLog.IsQuestLogFull()) then
        for _, quest in ipairs(ns.AvailableQuests()) do
            if quest.x >= 0 and quest.x <= 100 and quest.y >= 0 and quest.y <= 100
                and not InstanceKind(quest.questID) then
                local giver = { name = quest.giver, area = quest.area, x = quest.x, y = quest.y }
                Add({ questID = quest.questID, title = quest.name, pickup = true }, { giver }, "pickups")
            end
        end
    end
    return zones
end

-- The zone with the most work. A zone on another continent counts half, so a nearby zone wins a close call.
local function BestZone(zones)
    local best, bestScore
    for _, z in pairs(zones) do
        local near = z.yards and z.yards < 1e9
        local score = (z.pickups + z.turnins + z.active) * (near and 1 or 0.5)
        local yards, bestYards = z.yards or math.huge, best and best.yards or math.huge
        if not best or score > bestScore or (score == bestScore and (yards < bestYards
            or (yards == bestYards and z.area < best.area))) then
            best, bestScore = z, score
        end
    end
    return best
end

function ns.PlanRoute()
    UpdateVisit()
    local inst, wx, wy = PlayerWorld()
    local origin = { wInst = inst, wx = wx, wy = wy }
    -- A starter guide you chose leads: only its current trip, in the guide's order of trips.
    local guide = ns.ActiveGuide and ns.ActiveGuide()
    if guide then
        local tasks, trip, message = ns.GuideTasks(guide)
        if tasks then
            for _, task in ipairs(tasks) do
                for _, place in ipairs(task.places) do PlaceDistance(place, inst, wx, wy) end
            end
            route = BuildStops(tasks, origin)
            route.guide, route.guideTrip, route.guideTrips, route.message = guide.name, trip, #guide.trips, message
            return
        end
        if route and route.guide then route = nil end      -- finished: plan the usual way below
    end
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
    if route and (route.reward or route.prep or route.travel or route.guide) then route = nil end
    if travel and inst then
        local zone = not ns.CurrentZoneMaps()[ns.UiMapForArea(travel)] and ZoneWork(inst, wx, wy)[travel]
        if zone then
            route = BuildStops(zone.tasks, origin)
            route.travel = zone.name
            return
        end
        travel = nil                 -- arrived, or nothing left there
    end
    if not inst or not next(ns.CurrentZoneMaps()) then
        route = nil
        return
    end
    route = BuildStops(RouteTasks(origin), origin)
    if #route.stops == 0 then route.suggest = BestZone(ZoneWork(inst, wx, wy)) end
end

-- What the planner shows when this zone has nothing left: { area, name, pickups, turnins, active }.
function ns.RouteSuggestion()
    return route and not route.stops[route.index] and route.suggest or nil
end

-- A route you started yourself, and its label for the planner. nil for ordinary leveling.
function ns.RouteMode()
    if not route then return nil end
    if route.guide then
        return "guide", string.format(L["Guide: %s · trip %d of %d"], route.guide, route.guideTrip or route.guideTrips,
            route.guideTrips)
    end
    if route.prep then return "prep", string.format(L["Dungeon prep: %s"], route.prep) end
    if route.reward then return "reward", string.format(L["Reward: %s"], route.reward) end
    if route.travel then return "travel", string.format(L["Traveling to %s"], route.travel) end
end

local function RouteChanged()
    ns.ArrowUndismiss()
    ns.ArrowRefresh()
    ns.RequestRefresh()
end

function ns.TravelToZone(area)
    travel = area
    if area and ns.ActiveGuide() then ns.SetActiveGuide(nil) end
    ns.PlanRoute()
    RouteChanged()
    local target = travel and ns.RouteTarget()
    if target then ns.Waypoint(target.area, target.x, target.y, target.title, TrackedQuest() ~= nil) end
end

-- The planner's Stop button: end the starter guide, dungeon prep, reward pursuit or zone trip shown in the planner.
function ns.StopRouteMode()
    local mode = ns.RouteMode()
    if mode == "guide" then ns.SetGuide(nil)
    elseif mode == "prep" then ns.SetDungeonPrepRoute(nil)
    elseif mode == "reward" then ns.SetRewardPursuit(nil)
    elseif mode == "travel" then ns.TravelToZone(nil) end
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
    if task.loot then
        return ns.QuestLogIndex(task.questID) ~= nil or ns.QuestState(task.questID) == "done"
    end
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

-- Always head for the nearest stop. As you move, a later stop that is now clearly closer than the
-- current one (by more than REORDER_MARGIN yards, so the arrow doesn't flicker between two stops)
-- takes over, and the remaining stops are chained nearest first again from where you stand.
local REORDER_MARGIN = 40
local function ReorderRoute()
    if not route or route.paused or route.reward then return end
    local n = #route.stops
    if route.index >= n then return end
    local inst, wx, wy = PlayerWorld()
    if not inst then return end
    local here = { wInst = inst, wx = wx, wy = wy }
    local currentYards, closest = RouteDistance(here, route.stops[route.index].target), math.huge
    for i = route.index + 1, n do
        closest = math.min(closest, RouteDistance(here, route.stops[i].target))
    end
    if closest + REORDER_MARGIN >= currentYards then return end
    local rest, from = {}, here
    for i = route.index, n do rest[#rest + 1] = route.stops[i] end
    for i = route.index, n do
        local pick, pickYards
        for j, stop in ipairs(rest) do
            local yards = RouteDistance(from, stop.target)
            if not pickYards or yards < pickYards then pick, pickYards = j, yards end
        end
        route.stops[i] = table.remove(rest, pick)
        from = route.stops[i].target
    end
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
        ns.PlanRoute()
        if not route then ns.StartInitialRoute() end
    end
    if not route then return end
    local stop = route.stops[route.index]
    while stop do
        local open = false
        for _, task in ipairs(stop.tasks) do
            if not RouteTaskDone(task) then open = true; break end
        end
        if open then break end
        route.index = route.index + 1
        stop = route.stops[route.index]
        if not stop then ns.QueueRouteReplan() end
    end
    ReorderRoute()
    ns.FollowRoutePin()
end

function ns.RouteTarget()
    local stop = route and not route.paused and route.stops[route.index]
    return stop and stop.target
end

function ns.RoutePaused() return route and route.paused end

-- What the in-world marker shows for the current stop: "pickup", "turnin" or "objective", the
-- quest title and who or where (nil without a current stop).
local StopSummary

function ns.RouteStopSummary()
    local stop = route and not route.paused and route.stops[route.index]
    return stop and StopSummary(stop) or nil
end

StopSummary = function(stop)
    local task
    for _, t in ipairs(stop.tasks) do
        if not RouteTaskDone(t) then task = t; break end
    end
    task = task or stop.tasks[1]
    local kind = task.pickup and "pickup" or ((task.index or task.delivery) and "objective" or "turnin")
    local target = stop.target
    local who = target.name and target.name ~= "" and target.name or ZoneName(target.area)
    local more = 0
    for _, t in ipairs(stop.tasks) do if t ~= task and not RouteTaskDone(t) then more = more + 1 end end
    -- the card near the stop lists this task's objectives: just its own for an objective stop, all of
    -- them for a turn-in (none for a pickup, it isn't in the log yet)
    local lines = {}
    if not task.pickup and task.questID then
        local objectives = (C_QuestLog.GetQuestObjectives and C_QuestLog.GetQuestObjectives(task.questID)) or {}
        for i, o in ipairs(objectives) do
            if (not task.index or task.index == i) and o.text and o.text ~= "" then
                lines[#lines + 1] = { text = o.text, done = o.finished and true or false }
            end
        end
    end
    return { kind = kind, title = task.title, who = who, more = more, target = target, lines = lines }
end

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

-- Pin a place; questID lets the in-world waypoint say what to do there (pick up, objective, turn in).
-- A route pin follows the route (FollowPin); quiet moves it without a chat line.
local function MarkPlace(place, title, questID, quiet)
    if place then
        ns.Waypoint(place.area, place.x, place.y, title, TrackedQuest() ~= nil,
            { questID = questID or place.questID, who = place.name, route = true, quiet = quiet })
    end
end

local function NearPin(place, pin)
    return place and place.uiMap == pin.uiMap and math.abs(place.x - pin.x) < 0.5 and math.abs(place.y - pin.y) < 0.5
end

-- A pin you set on a route step moves on with the route: once its step is done, it goes to the step
-- you're on now. Pinned a later step? It waits there. Removed or moved the pin? It stays as you left it.
local function FollowPin()
    local db = ns.DB and ns.DB()
    local pin = db and db.pinInfo
    if not (pin and pin.route and C_Map and C_Map.GetUserWaypoint) then return end
    local w = C_Map.GetUserWaypoint()
    if not (w and w.position and w.uiMapID == pin.uiMap and math.abs(w.position.x * 100 - pin.x) < 0.5
        and math.abs(w.position.y * 100 - pin.y) < 0.5) then return end
    local stop = route and not route.paused and route.stops[route.index]
    if not stop then return end
    local other
    for i = route.index, #route.stops do
        for _, task in ipairs(route.stops[i].tasks) do
            if not RouteTaskDone(task) and NearPin(task.destination, pin) then
                if task.questID == pin.questID then return end            -- the pinned step is still ahead
                other = other or task
            end
        end
    end
    if other then                                                         -- same spot, the next task there
        pin.questID, pin.title, pin.who = other.questID, other.title, other.destination.name
        return
    end
    for _, task in ipairs(stop.tasks) do
        if not RouteTaskDone(task) then MarkPlace(task.destination, task.title, task.questID, true); return end
    end
end
ns.FollowRoutePin = FollowPin

-- Start a starter guide (nil stops it). One route mode at a time: it ends prep, reward and zone trips.
-- Starting a route mode (guide, reward, prep) places no map pin: the in-world marker already shows
-- each stop, and a pin would take its place. Pin on map is still there for when you want one.
function ns.SetGuide(id)
    if id then QuestynatorPrepDungeon, QuestynatorRewardGoal, travel = nil, nil, nil end
    ns.SetActiveGuide(id)
    ns.PlanRoute()
    ns.ArrowUndismiss()
    ns.ArrowRefresh()
    ns.RequestRefresh()
end

function ns.SetRewardPursuit(item)
    if item then
        QuestynatorPrepDungeon, travel = nil, nil
        if ns.ActiveGuide() then ns.SetActiveGuide(nil) end
    end
    QuestynatorRewardGoal = item
    ns.PlanRoute()
    ns.ArrowUndismiss()
    ns.ArrowRefresh()
    ns.RequestRefresh()
end

function ns.SetDungeonPrepRoute(id)
    QuestynatorPrepDungeon = id
    if id then
        travel = nil
        if ns.ActiveGuide() then ns.SetActiveGuide(nil) end
    end
    ns.PlanRoute()
    ns.ArrowUndismiss()
    ns.ArrowRefresh()
    ns.RequestRefresh()
end

-- The Quests tab's left column: the route as a timeline with the current stop as a card on top,
-- and the quest log rewards at the bottom (Questynator.lua builds those into view.rewards).
local ROUTE_W, TEXT_W, NEXT_ROWS = 210, 176, 3

function ns.BuildRouteView(p)
    local UI = ns.UI
    local view = CreateFrame("Frame", nil, p.questView)
    p.routeView = view
    view:SetPoint("TOPLEFT", p.questView, "TOPLEFT", 6, -6)
    view:SetPoint("BOTTOMLEFT", p.questView, "BOTTOMLEFT", 6, 4)
    view:SetWidth(ROUTE_W)
    UI.Flat(view, { 0.078, 0.094, 0.118, 1 }, UI.C.line)

    local function Changed()
        ns.ArrowUndismiss()
        ns.ArrowRefresh()
        RefreshPanel()
    end
    local function Button(parent, width, text, kind, onClick)
        local button = UI.Button(parent, width, 20, kind)
        button:SetText(text)
        button:SetScript("OnClick", onClick)
        return button
    end
    local function Line(parent, size, color, weight, width)
        local fs = UI.Text(parent, size, color, nil, weight)
        fs:SetJustifyH("LEFT")
        fs:SetWidth(width or TEXT_W)
        return fs
    end

    view.head = Line(view, 9, "accent", "bold", 84)
    view.head:SetWordWrap(false)
    view.replan = Button(view, 48, L["Replan"], "ghost", function() ns.PlanRoute(); Changed() end)
    view.replan:SetHeight(18)
    view.replan:SetPoint("TOPRIGHT", view, "TOPRIGHT", -8, -7)
    view.pause = Button(view, 48, L["Pause"], "ghost", function()
        if route then route.paused = not route.paused end
        Changed()
    end)
    view.pause:SetHeight(18)
    view.pause:SetPoint("RIGHT", view.replan, "LEFT", -4, 0)
    view.mode = Line(view, 10, "text", "medium", 130)
    view.modeStop = Button(view, 48, L["Stop"], "ghost", function() ns.StopRouteMode() end)
    view.modeStop:SetHeight(18)

    -- the current stop
    local card = CreateFrame("Frame", nil, view)
    view.card = card
    UI.Flat(card, { 0.086, 0.137, 0.165, 1 }, { 0.17, 0.29, 0.3, 1 })
    card.when = Line(card, 10, "accent", "medium")
    card.title = Line(card, 13, "text", "bold")
    card.where = Line(card, 10, "muted")
    card.detail = Line(card, 10, "muted")
    card.extra = Line(card, 10, "text")
    card.pin = Button(card, 78, L["Pin on map"], "primary", function()
        local stop = route and route.stops[route.index]
        if stop then MarkPlace(stop.target, stop.target.title) end
    end)
    card.snooze = Button(card, 58, L["Snooze"], "ghost", function() ns.SnoozeRouteStop(false) end)
    card.snooze.tip = L["Hide this stop until you leave the zone."]
    card.snooze:SetScript("OnEnter", UI.ShowTip)
    card.snooze:SetScript("OnLeave", function() GameTooltip:Hide() end)
    card.undo = Button(card, 46, L["Undo"], "ghost", function() ns.SnoozeRouteStop(true) end)

    -- later stops: a dot, the distance, what to do there
    view.next = {}
    for i = 1, NEXT_ROWS do
        local row = {}
        row.dot = view:CreateTexture(nil, "ARTWORK")
        row.dot:SetSize(7, 7)
        row.dist = Line(view, 9, "muted", "medium", TEXT_W - 14)
        row.text = Line(view, 11, "text", nil, TEXT_W - 14)
        view.next[i] = row
    end

    -- nothing to show: a message and up to two buttons (Plan My Route, Route there, Show zones)
    view.msg = Line(view, 12, "text", "medium")
    view.sub = Line(view, 10, "muted")
    view.go = Button(view, 100, L["Plan My Route"], "primary", function(self)
        if self.area then ns.TravelToZone(self.area)
        elseif self.undo then ns.SnoozeRouteStop(true)
        else ns.PlanRoute() end
        Changed()
    end)
    view.zones = Button(view, 84, L["Show zones"], "ghost", function() ns.SelectTab(5) end)

    view.rule = view:CreateTexture(nil, "ARTWORK")
    view.rule:SetHeight(1)
    view.rule:SetColorTexture(UI.C.line[1], UI.C.line[2], UI.C.line[3], 1)
    view.rewards = CreateFrame("Frame", nil, view)
    view.rewards:SetPoint("BOTTOMLEFT", view, "BOTTOMLEFT", 12, 10)
    view.rewards:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", -12, 10)
    view.rewards:SetHeight(84)
    view.rule:SetPoint("BOTTOMLEFT", view.rewards, "TOPLEFT", 0, 8)
    view.rule:SetPoint("BOTTOMRIGHT", view.rewards, "TOPRIGHT", 0, 8)
end

local function StopDestination(stop)
    local target = stop.target
    if target.name and target.name ~= "" then return target.name end
    return ZoneName(target.area) or stop.tasks[1].title
end

local function RouteTaskText(task)
    if task.loot then
        local from = task.destination or task.places[1]
        return string.format(L["Loot %s from %s"], task.loot, from.name)
    end
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

local SEP = "  |cff5b606b·|r  "

-- "9 pickups, 2 turn-ins" for a Best next suggestion
local function SuggestionCounts(suggest)
    local parts = {}
    local function Part(count, one, many)
        if count > 0 then parts[#parts + 1] = string.format(count == 1 and L[one] or L[many], count) end
    end
    Part(suggest.pickups, "%d pickup", "%d pickups")
    Part(suggest.turnins, "%d turn-in", "%d turn-ins")
    Part(suggest.active, "%d in progress", "%d in progress")
    return table.concat(parts, ", ")
end

local function Where(place)
    local zone = ZoneName(place.area)
    return string.format("%s (%s%d, %d)", place.name, zone and (zone .. " ") or "",
        math.floor(place.x + 0.5), math.floor(place.y + 0.5))
end

-- What a quest you haven't picked up yet will ask for, from the bundled data: up to two objectives.
local function PickupObjectives(qid)
    local q, D = ns.BundledQuest(qid), ns.QDATA
    if not q then return nil end
    local parts, seen = {}, {}
    local function Add(text)
        if text and not seen[text] then seen[text] = true; parts[#parts + 1] = text end
    end
    for _, item in ipairs(q.items) do
        local srcs, name = tostring(D.i and D.i[item] or ""):match("^([^;]*);(.*)$")
        if name and name ~= "" then
            local source = RefPlace(srcs:match("[no]%d+") or "")
            Add(source and string.format(L["Get %s from %s"], name, Where(source)) or string.format(L["Get %s"], name))
        end
    end
    for _, ref in ipairs(q.mobs) do
        local mob = RefPlace(ref)
        if mob then Add(string.format(L["Kill %s"], mob.name)) end
    end
    for _, ref in ipairs(q.objects) do
        local object = RefPlace(ref)
        if object then Add(string.format(L["Use %s"], Where(object))) end
    end
    if #parts == 0 then return nil end
    local more = #parts > 2 and (" " .. string.format(L["+%d more"], #parts - 2)) or ""
    return table.concat(parts, "; ", 1, math.min(#parts, 2)) .. more
end

-- The grey line under a planner action: level, XP, Elite or group tag, what a pickup asks for,
-- and how far away a later stop is.
function ns.RouteTaskDetail(task, yards)
    local qid, parts = task.questID, {}
    local quest = ns.ZoneQuest(qid)
    if quest and quest.level > 0 then parts[#parts + 1] = string.format(L["Lvl %d"], quest.level) end
    local xp = ns.QuestXP(qid)
    if xp and xp > 0 then parts[#parts + 1] = "|cffb48ef9" .. ns.FormatNumber(xp) .. " " .. L["XP"] .. "|r" end
    local tag = ns.GroupInfo(qid) or (quest and quest.elite and L["Elite"])
    if tag then parts[#parts + 1] = "|cffff9c40" .. tag .. "|r" end
    if task.pickup then parts[#parts + 1] = PickupObjectives(qid) end
    if yards then parts[#parts + 1] = string.format(L["%d yd"], math.floor(yards + 0.5)) end
    return table.concat(parts, SEP)
end

-- The floating Route Planner (style A): a header, the route mode with Stop (a guide also shows its trips
-- as a segmented bar), the current task as a card with a quest badge, the next tasks under "Then", and
-- a footer with More, Undo and Host LFG.
local planner
local PLANNER_W, PAD, MAX_SEGS = 320, 12, 14

-- what the card says about a task: the verb with the distance, the quest, and who or what
local function TaskParts(task)
    local where = task.destination or task.places[1]
    if task.loot then return "pickup", L["Loot"], task.title, string.format(L["%s from %s"], task.loot, where.name) end
    if task.pickup then return "pickup", L["Pick up"], task.title, where.name end
    if task.delivery then return "objective", L["Deliver"], task.title, where.name end
    if not task.index then return "turnin", L["Turn in"], task.title, where.name end
    return "objective", L["Objective"], task.title, RouteTaskText(task)
end

local function ThenRow(i)
    local row = planner.rows[i]
    if row then return row end
    row = CreateFrame("Button", nil, planner)
    row:SetSize(PLANNER_W - 2 * PAD - 10, 30)
    row.dist = ns.UI.Text(row, 10, "muted", nil, "medium")
    row.dist:SetPoint("TOPLEFT", 0, 0)
    row.dist:SetJustifyH("LEFT")
    row.text = ns.UI.Text(row, 11, "text")
    row.text:SetPoint("TOPLEFT", row.dist, "BOTTOMLEFT", 0, -1)
    row.text:SetWidth(PLANNER_W - 2 * PAD - 10)
    row.text:SetJustifyH("LEFT")
    row.tip = L["Mark on map"]
    row:SetScript("OnEnter", ns.UI.ShowTip)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row:SetScript("OnClick", function(self)
        local task = self.task
        if task and not RouteTaskDone(task) then MarkPlace(task.destination, task.title, task.questID) end
    end)
    planner.rows[i] = row
    return row
end

local function LineHeight(fs, least) return math.max(least or 0, math.ceil(tonumber(fs:GetStringHeight()) or 12)) end

function ns.RefreshPlanner()
    if not planner or not planner:IsShown() then return end
    local stop = route and route.stops[route.index]
    local selected, selectedIndex = TrackedQuest()
    planner.resume = stop and (selectedIndex or route.paused)
    planner.plan:SetText(planner.resume and L["Resume"] or (stop and L["Pause"] or L["Replan"]))
    local kind, mode = ns.RouteMode()
    local suggest = ns.RouteSuggestion()
    local inner = PLANNER_W - 2 * PAD
    local top = 36

    -- the route mode you started, with Stop; a guide's trips as segments
    local stoppable = mode ~= nil and not (stop and selectedIndex)
    planner.mode:SetShown(mode ~= nil)
    planner.stopMode:SetShown(stoppable)
    local segs = 0
    if mode then
        local label = mode
        if kind == "guide" then label = string.format(L["Guide · %s"], route.guide) end
        planner.mode:SetText(label)
        planner.mode:SetWidth(inner - (stoppable and 60 or 0))
        planner.mode:SetPoint("TOPLEFT", PAD, -top)
        planner.stopMode:SetPoint("TOPRIGHT", -PAD, -top + 2)
        top = top + math.max(LineHeight(planner.mode), 18) + 4
        if kind == "guide" and route.guideTrips then
            segs = math.min(route.guideTrips, MAX_SEGS)
            local current = math.min(route.guideTrip or segs, segs)
            local gap = 3
            local width = (inner - gap * (segs - 1)) / segs
            for i = 1, segs do
                local seg = planner.segs[i]
                seg:ClearAllPoints()
                seg:SetPoint("TOPLEFT", PAD + (i - 1) * (width + gap), -top)
                seg:SetSize(width, 4)
                local c = i <= current and ns.UI.C.accent or ns.UI.C.line
                seg:SetColorTexture(c[1], c[2], c[3], i == current and 0.55 or 1)
                seg:Show()
            end
            top = top + 12
        end
    end
    for i = segs + 1, MAX_SEGS do planner.segs[i]:Hide() end

    -- paused, or a quest picked in the tracker; plain leveling shows its stop count
    local context
    if stop and selectedIndex then context = L["Selected quest"] .. " · " .. QuestTitle(selected)
    elseif stop and route.paused then context = L["Route paused"]
    elseif stop and not mode then context = string.format(L["Stop %d of %d"], route.index, #route.stops) end
    planner.context:SetShown(context ~= nil)
    if context then
        planner.context:SetText(context)
        planner.context:SetPoint("TOPLEFT", PAD, -top)
        top = top + LineHeight(planner.context) + 5
    end

    -- the card: the current task, or what to do when there is none
    local card = planner.card
    local pending = {}
    if stop then
        for i = route.index, #route.stops do
            for _, task in ipairs(route.stops[i].tasks) do
                if not RouteTaskDone(task) then pending[#pending + 1] = { task = task, stop = i } end
            end
        end
    end
    local first = pending[1] and pending[1].task or (stop and stop.tasks[1])
    local cy = 10
    local function Place(fs, x, width, gap)
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", card, "TOPLEFT", x, -cy)
        fs:SetWidth(width)
        fs:Show()
        cy = cy + LineHeight(fs) + (gap or 2)
    end
    for _, w in ipairs({ card.badge, card.kind, card.sub, card.detail, card.suggest, card.pin, card.snooze,
                         planner.travel, planner.zones }) do w:Hide() end
    if first then
        local badge, verb, title, sub = TaskParts(first)
        ns.SetQuestBadge(card.badge, badge)
        card.badge:Show()
        local yards = ns.ArrowGeometry(stop.target).yards
        card.kind:SetText(yards and (verb .. " · " .. string.format(L["%d yd"], math.floor(yards + 0.5))) or verb)
        Place(card.kind, 48, inner - 58, 1)
        card.title:SetText(title)
        Place(card.title, 48, inner - 58, 1)
        card.sub:SetText(sub or "")
        Place(card.sub, 48, inner - 58, 6)
        cy = math.max(cy, 46)
        local detail = ns.RouteTaskDetail(first)
        card.detail:SetText(detail)
        if detail ~= "" then Place(card.detail, 10, inner - 20, 8) end
        card.pin:SetText(ns.PinLabel(first.pickup, first.index or first.delivery))
        card.pin:ClearAllPoints()
        card.pin:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -cy)
        card.pin:Show()
        card.snooze:ClearAllPoints()
        card.snooze:SetPoint("LEFT", card.pin, "RIGHT", 6, 0)
        card.snooze:SetShown(not route.travel and not route.guide)
        cy = cy + 30
        card:SetAlpha((route.paused or selectedIndex) and 0.6 or 1)
    else
        card:SetAlpha(1)
        local heading = L["Waiting for quest and map data"]
        if route then
            heading = route.message or (QuestynatorRouteSnoozes and L["No other stops found. Undo snooze to restore a stop."])
                or (suggest and string.format(L["Nothing left here for level %d"], UnitLevel("player") or 1))
                or L["No eligible pickups or known quest stops in this zone."]
        end
        card.title:SetText(heading)
        Place(card.title, 10, inner - 20, 4)
        if suggest then
            card.suggest:SetText(string.format(L["Best next: %s"], suggest.name) .. " · " .. SuggestionCounts(suggest))
            Place(card.suggest, 10, inner - 20, 8)
            planner.travel.area = suggest.area
            planner.travel:ClearAllPoints()
            planner.travel:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -cy)
            planner.travel:Show()
            planner.zones:ClearAllPoints()
            planner.zones:SetPoint("LEFT", planner.travel, "RIGHT", 6, 0)
            planner.zones:Show()
            cy = cy + 30
        else
            cy = cy + 6
        end
    end
    card:ClearAllPoints()
    card:SetPoint("TOPLEFT", PAD, -top)
    card:SetSize(inner, cy)
    top = top + cy + 10

    -- then: the next tasks, the same stop first; click one to mark it on the map
    local limit = ns.DB().plannerExpanded and 4 or 2
    local shown = 0
    for n = 2, #pending do
        if shown >= limit then break end
        local entry = pending[n]
        shown = shown + 1
        local row = ThenRow(shown)
        row.task = entry.task
        local yards = entry.stop > route.index and entry.task.destination and ns.ArrowGeometry(entry.task.destination).yards
        local label = entry.stop == route.index and L["Same stop"] or L["Then"]
        row.dist:SetText(yards and (label .. " · " .. string.format(L["%d yd"], math.floor(yards + 0.5))) or label)
        row.text:SetText(RouteTaskText(entry.task))
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", PAD + 10, -top)
        local h = LineHeight(row.dist) + 1 + LineHeight(row.text)
        row:SetHeight(h)
        row:Show()
        top = top + h + 6
    end
    for i = shown + 1, #planner.rows do
        planner.rows[i].task = nil
        planner.rows[i]:Hide()
    end
    planner.thenRule:SetShown(shown > 0)
    if shown > 0 then
        planner.thenRule:ClearAllPoints()
        planner.thenRule:SetPoint("TOPLEFT", planner.rows[1], "TOPLEFT", -10, 0)
        planner.thenRule:SetPoint("BOTTOMLEFT", planner.rows[shown], "BOTTOMLEFT", -10, 0)
        top = top + 4
    end

    -- footer: More or Less, Undo snooze, Host LFG
    local more = #pending - 1 > 2
    planner.expand:SetText(ns.DB().plannerExpanded and L["Less"] or L["More"])
    planner.expand:SetShown(more)
    planner.expand:ClearAllPoints()
    planner.expand:SetPoint("TOPLEFT", PAD, -top)
    planner.undo:SetShown(QuestynatorRouteSnoozes ~= nil)
    planner.undo:ClearAllPoints()
    planner.undo:SetPoint("TOPLEFT", PAD + (more and 60 or 0), -top)
    local hosted, hostContext = ns.PaintHostButton(planner.host)
    planner.host:ClearAllPoints()
    planner.host:SetPoint("TOPRIGHT", -PAD, -top)
    -- the starter guides, while they still fit your level (or one is running)
    local guides = ns.ShowGuideChooser and ((UnitLevel("player") or 1) <= 10 or kind == "guide")
    planner.guides:SetShown(guides)
    planner.guides:ClearAllPoints()
    planner.guides:SetPoint("RIGHT", planner.host, "LEFT", -6, 0)
    top = top + 26
    planner.hosting:SetShown(hosted ~= nil)
    if hosted then
        planner.hosting:SetPoint("TOPLEFT", PAD, -top)
        planner.hosting:SetText(string.format(L["Hosting: %s"], hostContext))
        top = top + LineHeight(planner.hosting) + 2
    end
    planner:SetHeight(top + 8)
end

function ns.ShowPlanner(shown)
    ns.DB().plannerHidden = not shown
    if not shown then
        if planner then planner:Hide() end
        return
    end
    if not planner then
        local UI = ns.UI
        planner = UI.Window("QuestynatorPlanner", PLANNER_W, 34)
        planner.logo = planner:CreateTexture(nil, "ARTWORK")
        planner.logo:SetTexture("Interface\\AddOns\\Questynator\\Media\\Icon")
        planner.logo:SetSize(16, 16)
        planner.logo:SetPoint("TOPLEFT", PAD, -9)
        planner.TitleText:ClearAllPoints()
        planner.TitleText:SetPoint("LEFT", planner.logo, "RIGHT", 6, 0)
        planner.TitleText:SetText(L["Route Planner"])
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
        planner.plan = UI.Button(planner, 64, 20, "ghost")
        planner.plan:SetPoint("RIGHT", planner.CloseButton, "LEFT", -4, 0)
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
        planner.mode = UI.Text(planner, 11, "accent", nil, "medium")
        planner.mode:SetJustifyH("LEFT")
        planner.stopMode = UI.Button(planner, 52, 18, "outline")
        planner.stopMode:SetText(L["Stop"])
        planner.stopMode:SetScript("OnClick", function() ns.StopRouteMode() end)
        planner.segs = {}
        for i = 1, MAX_SEGS do
            planner.segs[i] = planner:CreateTexture(nil, "ARTWORK")
            planner.segs[i]:Hide()
        end
        planner.context = UI.Text(planner, 10, "accent", nil, "medium")
        planner.context:SetWidth(PLANNER_W - 2 * PAD)
        planner.context:SetJustifyH("LEFT")

        local card = CreateFrame("Frame", nil, planner)
        planner.card = card
        UI.Flat(card, { 0.086, 0.137, 0.165, 1 }, { 0.17, 0.29, 0.3, 1 })
        card.badge = ns.QuestBadge(card, 30)
        card.badge:SetPoint("TOPLEFT", 10, -10)
        card.kind = UI.Text(card, 10, "accent", nil, "medium")
        card.title = UI.Text(card, 13, "text", nil, "bold")
        card.sub = UI.Text(card, 11, "muted")
        card.detail = UI.Text(card, 10, "muted")
        card.suggest = UI.Text(card, 11, "text")
        for _, fs in ipairs({ card.kind, card.title, card.sub, card.detail, card.suggest }) do fs:SetJustifyH("LEFT") end
        card.pin = UI.Button(card, 96, 20, "primary")
        card.pin:SetScript("OnClick", function()
            local stop = route and route.stops[route.index]
            if not stop then return end
            for _, task in ipairs(stop.tasks) do
                if not RouteTaskDone(task) then MarkPlace(task.destination, task.title, task.questID); return end
            end
            MarkPlace(stop.target, stop.target.title)
        end)
        card.snooze = UI.Button(card, 64, 20, "ghost")
        card.snooze:SetText(L["Snooze"])
        card.snooze.tip = L["Hide this stop until you leave the zone."]
        card.snooze:SetScript("OnEnter", UI.ShowTip)
        card.snooze:SetScript("OnLeave", function() GameTooltip:Hide() end)
        card.snooze:SetScript("OnClick", function() ns.SnoozeRouteStop(false) end)
        planner.heading, planner.suggest = card.title, card.suggest
        planner.travel = UI.Button(card, 100, 20, "primary")
        planner.travel:SetText(L["Route there"])
        planner.travel:SetScript("OnClick", function(self) ns.TravelToZone(self.area) end)
        planner.zones = UI.Button(card, 90, 20, "outline")
        planner.zones:SetText(L["Show zones"])
        planner.zones:SetScript("OnClick", function()
            ns.ShowPanel()
            ns.SelectTab(5)
        end)

        planner.thenRule = planner:CreateTexture(nil, "ARTWORK")
        planner.thenRule:SetWidth(1)
        planner.thenRule:SetColorTexture(UI.C.line[1] + 0.08, UI.C.line[2] + 0.08, UI.C.line[3] + 0.08, 1)
        planner.rows = {}

        planner.expand = UI.Button(planner, 54, 20, "ghost")
        planner.expand:SetScript("OnClick", function()
            ns.DB().plannerExpanded = not ns.DB().plannerExpanded
            ns.RefreshPlanner()
        end)
        planner.undo = UI.Button(planner, 64, 20, "outline")
        planner.undo:SetText(L["Undo"])
        planner.undo.tip = L["Undo snooze"]
        planner.undo:SetScript("OnEnter", UI.ShowTip)
        planner.undo:SetScript("OnLeave", function() GameTooltip:Hide() end)
        planner.undo:SetScript("OnClick", function() ns.SnoozeRouteStop(true) end)
        planner.host = ns.MakeHostButton(planner)
        planner.guides = UI.Button(planner, 64, 22, "ghost")
        planner.guides:SetText(L["Guides"])
        planner.guides.tip = L["Starter guides for the starting areas, levels 1 to 6."]
        planner.guides:SetScript("OnEnter", UI.ShowTip)
        planner.guides:SetScript("OnLeave", function() GameTooltip:Hide() end)
        planner.guides:SetScript("OnClick", function() ns.ShowGuideChooser() end)
        planner.hosting = UI.Text(planner, 11, "accent")
        planner.hosting:SetWidth(PLANNER_W - 2 * PAD)
        planner.hosting:SetJustifyH("LEFT")
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

local function Height(fs) return math.ceil(tonumber(fs:GetStringHeight()) or 12) end

local function Yards(place)
    local yards = place and ns.ArrowGeometry(place).yards
    return yards and string.format(L["%d yd"], math.floor(yards + 0.5))
end

local function PendingTasks(stop)
    local list = {}
    for _, task in ipairs(stop.tasks) do
        if not RouteTaskDone(task) then list[#list + 1] = task end
    end
    return list
end

-- What the route column says when there is no current stop: message, line under it, button text,
-- and what the button does ("travel" to an area, "undo" a snooze, or replan).
local function EmptyRouteState()
    if not route then return L["Waiting for quest and map data"], nil, L["Plan My Route"] end
    if route.message then return route.message, nil, L["Replan"] end
    local suggest = ns.RouteSuggestion()
    if suggest then
        return string.format(L["Nothing left here for level %d"], UnitLevel("player") or 1),
            string.format(L["Best next: %s"], suggest.name) .. " · " .. SuggestionCounts(suggest),
            L["Route there"], "travel", suggest.area
    end
    if QuestynatorRouteSnoozes then return L["No other stops found. Undo snooze to restore a stop."], nil, L["Undo"], "undo" end
    if #route.stops == 0 then return L["No quest stops found in this zone"], nil, L["Replan"] end
    return L["Route ended"], nil, L["Replan"]
end

function ns.RefreshRouteView(p)
    local view = p.routeView
    if not view then return end
    local count = route and #route.stops or 0
    local stop = route and route.stops[route.index]
    local paused = route and route.paused
    local remaining = stop and (count - route.index + 1) or 0
    local _, modeLabel = ns.RouteMode()

    local y = 10
    view.head:ClearAllPoints()
    view.head:SetPoint("TOPLEFT", view, "TOPLEFT", 12, -(y + 4))
    local head = remaining > 0
        and string.format(remaining == 1 and L["Route · %d stop"] or L["Route · %d stops"], remaining) or L["Route"]
    view.head:SetText((head:gsub("[^·]+", function(part) return ns.UI.Caps(part) end)))
    view.pause:SetShown(stop ~= nil)
    view.pause:SetText(paused and L["Resume"] or L["Pause"])
    view.replan:SetShown(route ~= nil)
    y = y + 22
    if modeLabel then
        view.mode:SetText(modeLabel)
        view.mode:ClearAllPoints()
        view.mode:SetPoint("TOPLEFT", view, "TOPLEFT", 12, -(y + 3))
        view.mode:Show()
        view.modeStop:ClearAllPoints()
        view.modeStop:SetPoint("TOPRIGHT", view, "TOPRIGHT", -8, -y)
        view.modeStop:Show()
        y = y + math.max(22, Height(view.mode) + 8)
    else
        view.mode:Hide()
        view.modeStop:Hide()
    end

    local card = view.card
    for _, row in ipairs(view.next) do row.dot:Hide(); row.dist:Hide(); row.text:Hide() end
    view.msg:Hide(); view.sub:Hide(); view.go:Hide(); view.zones:Hide()
    card:SetShown(stop ~= nil)

    if stop then
        local tasks = PendingTasks(stop)
        if #tasks == 0 then tasks = { stop.tasks[1] } end
        local first, cy = tasks[1], 9
        local function Place(fs, gap)
            fs:ClearAllPoints()
            fs:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -cy)
            fs:Show()
            cy = cy + Height(fs) + (gap or 3)
        end
        local yards, when = Yards(stop.target), paused and L["Route paused"] or L["Now"]
        card.when:SetText(yards and (when .. " · " .. yards) or when)
        Place(card.when, 4)
        card.title:SetText(RouteTaskText(first))
        Place(card.title)
        local target = stop.target
        card.where:SetText(target.x and string.format("%s (%d, %d)", StopDestination(stop),
            math.floor(target.x + 0.5), math.floor(target.y + 0.5)) or StopDestination(stop))
        Place(card.where, 4)
        local detail = ns.RouteTaskDetail(first)
        card.detail:SetText(detail)
        if detail ~= "" then Place(card.detail, 4) else card.detail:Hide() end
        local others = {}
        for i = 2, #tasks do others[#others + 1] = "+ " .. RouteTaskText(tasks[i]) end
        card.extra:SetText(table.concat(others, "\n"))
        if #others > 0 then Place(card.extra, 4) else card.extra:Hide() end
        cy = cy + 4
        local snoozable = not route.reward and not route.travel and not route.guide
        card.pin:ClearAllPoints()
        card.pin:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -cy)
        card.snooze:SetShown(snoozable)
        card.snooze:ClearAllPoints()
        card.snooze:SetPoint("LEFT", card.pin, "RIGHT", 6, 0)
        card.undo:SetShown(QuestynatorRouteSnoozes ~= nil)
        card.undo:ClearAllPoints()
        card.undo:SetPoint("LEFT", snoozable and card.snooze or card.pin, "RIGHT", 6, 0)
        cy = cy + 30
        card:ClearAllPoints()
        card:SetPoint("TOPLEFT", view, "TOPLEFT", 8, -y)
        card:SetPoint("TOPRIGHT", view, "TOPRIGHT", -8, -y)
        card:SetHeight(cy)
        card:SetAlpha(paused and 0.6 or 1)
        y = y + cy + 12

        -- later stops, as many as fit above the rewards
        -- the column's height is 0 until the game first lays the window out: assume the usual 460
        local tall = tonumber(view:GetHeight()) or 0
        local bottom = (tall >= 200 and tall or 460) - 84 - 30
        local shown, accent = 0, ns.UI.C.accent
        for i = route.index + 1, count do
            if shown >= NEXT_ROWS then break end
            local pending = PendingTasks(route.stops[i])[1]
            if pending then
                local row = view.next[shown + 1]
                local yards = Yards(route.stops[i].target)
                row.dist:SetText(shown == 0 and (yards and (L["Then"] .. " · " .. yards) or L["Then"]) or (yards or ""))
                row.text:SetText(RouteTaskText(pending))
                local h = Height(row.dist) + 2 + Height(row.text)
                if y + h > bottom then break end
                shown = shown + 1
                row.dot:ClearAllPoints()
                row.dot:SetPoint("TOPLEFT", view, "TOPLEFT", 16, -(y + 3))
                row.dot:SetColorTexture(accent[1], accent[2], accent[3], shown == 1 and 0.7 or 0.35)
                row.dist:ClearAllPoints()
                row.dist:SetPoint("TOPLEFT", view, "TOPLEFT", 30, -y)
                row.text:ClearAllPoints()
                row.text:SetPoint("TOPLEFT", row.dist, "BOTTOMLEFT", 0, -2)
                row.dot:Show(); row.dist:Show(); row.text:Show()
                y = y + h + 10
            end
        end
        -- one-stop routes are common (pickups count only within 300 yards): say so instead of leaving a gap
        if shown == 0 then
            local row = view.next[1]
            row.dist:SetText(L["Then"])
            row.text:SetText(L["No other stops in this zone yet. New ones appear as you pick up quests."])
            row.dot:ClearAllPoints()
            row.dot:SetPoint("TOPLEFT", view, "TOPLEFT", 16, -(y + 3))
            row.dot:SetColorTexture(accent[1], accent[2], accent[3], 0.2)
            row.dist:ClearAllPoints()
            row.dist:SetPoint("TOPLEFT", view, "TOPLEFT", 30, -y)
            row.text:ClearAllPoints()
            row.text:SetPoint("TOPLEFT", row.dist, "BOTTOMLEFT", 0, -2)
            row.dot:Show(); row.dist:Show(); row.text:Show()
        end
        return
    end

    local msg, sub, go, action, area = EmptyRouteState()
    view.msg:SetText(msg)
    view.msg:ClearAllPoints()
    view.msg:SetPoint("TOPLEFT", view, "TOPLEFT", 12, -(y + 4))
    view.msg:Show()
    y = y + 4 + Height(view.msg) + 6
    if sub then
        view.sub:SetText(sub)
        view.sub:ClearAllPoints()
        view.sub:SetPoint("TOPLEFT", view, "TOPLEFT", 12, -y)
        view.sub:Show()
        y = y + Height(view.sub) + 8
    end
    view.go:SetText(go)
    view.go:SetWidth((tonumber(view.go.label:GetStringWidth()) or 70) + 24)
    view.go.area, view.go.undo = action == "travel" and area or nil, action == "undo"
    view.go:ClearAllPoints()
    view.go:SetPoint("TOPLEFT", view, "TOPLEFT", 12, -y)
    view.go:Show()
    view.zones:SetShown(action == "travel")
    view.zones:ClearAllPoints()
    view.zones:SetPoint("LEFT", view.go, "RIGHT", 6, 0)
end
