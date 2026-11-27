-- Run from the addon directory with Lua 5.1: lua tests/review.lua
-- Each case loads the installed addon code in a fresh simulated client.
local passed, failed = 0, 0
local function noop() end

-- Use the shipped loading order. The simulated client supplies Blizzard APIs
-- and skips embedded UI libraries, which tools/qa.py checks separately.
local addonFiles = {}
for line in io.lines("Questynator.toc") do
    local path = line:match("^%s*(.-)%s*$"):gsub("\\", "/")
    if path:sub(1, 1) ~= "#" and path:match("%.lua$") and not path:match("^Libs/") then
        addonFiles[#addonFiles + 1] = path
    end
end

local function client(savedSnoozes)
    local ns, env = {}, setmetatable({}, { __index = _G })
    env._G, env.SlashCmdList = env, {}
    env.QuestynatorRouteSnoozes = savedSnoozes
    env.now, env.level, env.xp = 100, 31, 0
    env.party, env.leader, env.messages = {}, true, {}
    env.CreateFrame = function()
        local frame = { RegisterEvent = noop, UnregisterEvent = noop }
        function frame:SetScript(key, fn) self[key] = fn end
        env.eventFrame = frame
        return frame
    end
    env.GetTime = function() return env.now end
    env.GetServerTime = function() return 100000 + env.now end
    env.UnitLevel = function() return env.level end
    env.UnitXP = function() return env.xp end
    env.UnitXPMax = function() return 10000 end
    env.UnitName = function(unit) return unit == "player" and "Tester" or env.party[unit] end
    env.UnitExists = function(unit) return env.UnitName(unit) ~= nil end
    env.UnitRace = function() return "Human", "Human", 1 end
    env.UnitClass = function() return "Warrior", "WARRIOR", 1 end
    env.Ambiguate = function(name) return name end
    env.UnitIsGroupLeader = function() return env.leader end
    env.IsInGroup = function() return next(env.party) ~= nil end
    env.GetNumGroupMembers = function()
        local count = 1
        for _ in pairs(env.party) do count = count + 1 end
        return count
    end
    env.GetChannelName = function() return 1 end
    env.SendAddonMessage = function(_, msg) table.insert(env.messages, msg) end
    env.C_Timer = { After = noop, NewTicker = function() return { Cancel = noop } end }
    env.print = noop
    env.C_QuestLog = {
        GetLogIndexForQuestID = function() return 0 end,
        GetNumQuestLogEntries = function() return 0 end,
        GetQuestObjectives = function() return {} end,
        IsComplete = function() return false end,
        ReadyForTurnIn = function() return false end,
    }
    for _, path in ipairs(addonFiles) do
        setfenv(assert(loadfile(path)), env)("Questynator", ns)
    end
    env.eventFrame:OnEvent("ADDON_LOADED", "Questynator")
    return ns, env
end

local function case(name, check)
    local ok, why = pcall(function() check(client()) end)
    if ok then passed = passed + 1 else failed = failed + 1 end
    print((ok and "PASS " or "FAIL ") .. name .. (ok and "" or (" -- " .. tostring(why))))
end

case("every reward chain references known quests once", function(ns)
    for _, reward in pairs(ns.RewardCatalog) do
        local seen = {}
        assert(#reward.steps > 0)
        for _, id in ipairs(reward.steps) do
            assert(not seen[id] and ns.ZoneQuest(id) and ns.BundledQuest(id), reward.name)
            seen[id] = true
        end
    end
end)

case("an accepted downstream reward step advances the pursuit", function(ns, env)
    local reward = ns.RewardCatalog[2041]
    env.C_QuestLog.GetLogIndexForQuestID = function(id) return id == 155 and 1 or 0 end
    assert(ns.RewardProgress(reward).id == 155)
    ns.RecordQuestTurnIn(166)
    assert(ns.RewardProgress(reward) == nil)
end)

case("Skyborne starter journals respect faction and race", function(ns, env)
    env.UnitRace = function() return "Skyborne", "Skyborne", 95 end
    assert(ns.QuestState(96652) == "hidden")
    env.UnitRace = function() return "Skyborne", "Skyborne", 96 end
    assert(ns.QuestState(96630) == "hidden")
    assert(ns.QuestGiver(96630).name == "Lost Journal" and ns.QuestGiver(96652).name == "Lost Journal")
end)

case("an explicitly completed quest is ready for turn-in", function(ns, env)
    env.C_QuestLog.IsComplete = function() return true end
    assert(ns.IsReadyToTurnIn(170))
end)

case("new and existing saved settings load without changing a disabled option", function(ns, env)
    assert(env.QuestynatorDB.autoAccept and env.QuestynatorDB.stats.groups == 0)
    env.QuestynatorDB = { autoAccept = false, stats = { groups = "4" } }
    env.eventFrame:OnEvent("ADDON_LOADED", "Questynator")
    assert(env.QuestynatorDB.autoAccept == false and env.QuestynatorDB.stats.groups == 4)
    assert(env.QuestynatorDB.stats.quests == 0 and type(env.QuestynatorDB.minimap) == "table")
end)

case("out-of-order chunks of one party update assemble before showing progress", function(ns, env)
    env.party.party1 = "PlayerTwo"
    ns.OnGroupMessage("P|1|2|2|170:4:6:0", "PlayerTwo")
    assert(not ns.PartyHasAddon())
    ns.OnGroupMessage("P|1|1|2|65:1:1:1", "PlayerTwo")
    assert(ns.PartyHasAddon() and ns.PartyLine(170):find("4/6", 1, true))
    assert(ns.PartyLine(65):find("done", 1, true))
end)

case("dungeon host listing drops when the host loses party lead", function(ns, env)
    ns.StartDungeon(721, "host")
    env.party.party1, env.leader = "Leader", false
    env.eventFrame:OnEvent("PARTY_LEADER_CHANGED")
    assert(ns.MyDungeon() == nil)
end)

case("empty objectives do not override an explicit negative turn-in state", function(ns)
    assert(not ns.IsReadyToTurnIn(170), "A New Threat was marked ready")
end)

case("only the unfinished trogg type is suggested", function(ns, env)
    env.C_QuestLog.GetQuestObjectives = function() return {
        { text = "Rockjaw Trogg slain: 6/6", finished = true },
        { text = "Burly Rockjaw Trogg slain: 0/6", finished = false },
    } end
    local spots = ns.ObjectiveSpots(170, 2)
    assert(#spots > 0)
    for _, spot in ipairs(spots) do assert(spot.name == "Burly Rockjaw Trogg", "suggested " .. spot.name) end
end)

case("expired dungeon listings disappear", function(ns, env)
    ns.OnDungeonBeacon("Tank", 721, 31, "H", "HD", "test", "WARRIOR", 1)
    assert(ns.DungeonActivity() == 1)
    env.now = env.now + 91
    assert(ns.DungeonActivity() == 0)
end)

case("a quest host who loses leadership stops advertising as host", function(ns, env)
    ns.Start(170)
    ns.CreateListing(170, { min = 25, max = 37, want = 0, autoInvite = true })
    assert(ns.GroupEntries()[1].mine)
    env.party.party1, env.leader, env.now = "Leader", false, env.now + 5
    env.eventFrame:OnEvent("PARTY_LEADER_CHANGED")
    assert(#ns.GroupEntries() == 0, "listing still visible, last message " .. tostring(env.messages[#env.messages]))
end)

case("a tank/healer host can heal when a dedicated tank joins", function(ns, env)
    env.QuestynatorDB.roles = { T = true, H = true, D = false }
    ns.StartDungeon(721, "host")
    env.party.party1 = "Tank"
    ns.OnDungeonJoinInfo("Tank", "T")
    assert(ns.NeedText() == "3 DPS", "advertising " .. ns.NeedText())
end)

case("XP per hour expires during an idle hour", function(ns, env)
    ns.OnXPChange()
    env.now, env.xp = 400, 100
    ns.OnXPChange()
    assert(ns.XPRate() == 1200)
    env.now = 4001
    assert(ns.XPRate() == 0, "still reporting " .. ns.XPRate() .. " XP/hour")
end)

local function routeFixture(ns, env)
    env.map = ns.UiMapForArea(40)
    env.QuestynatorDB.arrow = false
    env.C_Map = {
        GetBestMapForUnit = function() return env.map end,
        GetMapInfo = function() return { mapType = 3 } end,
        GetWorldPosFromMapPos = function(_, pos) return 1, { x = pos.x * 1000, y = pos.y * 1000 } end,
    }
    env.UnitPosition = function() return 0, 0, 0, 1 end
    env.CreateVector2D = function(x, y) return { x = x, y = y } end
    ns.AvailableQuests = function() return {
        { questID = 1, name = "A", giver = "First", area = 40, x = 2, y = 2, level = 30 },
        { questID = 2, name = "B", giver = "Neighbor", area = 40, x = 3, y = 2, level = 30 },
        { questID = 3, name = "C", giver = "Second", area = 40, x = 16, y = 2, level = 31 },
    } end
    ns.QuestState = function() return "available" end
end

case("snooze skips a grouped stop through replans, supports undo, and expires on zone exit", function(ns, env)
    routeFixture(ns, env)
    ns.PlanRoute()
    assert(ns.RouteTarget().name == "First")
    ns.SnoozeRouteStop(false)
    ns.PlanRoute()
    assert(ns.RouteTarget().name == "Second")
    ns.SnoozeRouteStop(false)
    assert(not ns.RouteTarget())
    ns.SnoozeRouteStop(true)
    assert(ns.RouteTarget().name == "Second")
    ns.SnoozeRouteStop(true)
    assert(ns.RouteTarget().name == "First" and not env.QuestynatorRouteSnoozes)
    ns.SnoozeRouteStop(false)
    env.map = ns.UiMapForArea(44)
    ns.PlanRoute()
    assert(not env.QuestynatorRouteSnoozes)
end)

case("the route always heads for the nearest stop as you move", function(ns, env)
    routeFixture(ns, env)
    ns.PlanRoute()
    assert(ns.RouteTarget().name == "First")
    env.UnitPosition = function() return 150, 20, 0, 1 end          -- walked next to Second
    ns.UpdateRoute()
    assert(ns.RouteTarget().name == "Second", "still heading to " .. ns.RouteTarget().name)
    env.UnitPosition = function() return 95, 20, 0, 1 end           -- halfway back: no flip-flop
    ns.UpdateRoute()
    assert(ns.RouteTarget().name == "Second")
end)

case("snoozing a reward uses ordinary stops until undo restores the pursuit", function(ns, env)
    routeFixture(ns, env)
    env.QuestynatorRewardGoal = 2041
    ns.PlanRoute()
    assert(ns.RouteTarget().rewardItem == 2041)
    ns.SnoozeRouteStop(false)
    assert(env.QuestynatorRewardGoal == 2041 and ns.RouteTarget().name == "First")
    ns.SnoozeRouteStop(true)
    assert(ns.RouteTarget().rewardItem == 2041)
end)

case("a same-zone reload keeps snoozed stops and their undo history", function(ns, env)
    routeFixture(ns, env)
    ns.PlanRoute()
    ns.SnoozeRouteStop(false)
    local fresh, login = client(env.QuestynatorRouteSnoozes)
    routeFixture(fresh, login)
    fresh.PlanRoute()
    assert(fresh.RouteTarget().name == "Second")
    fresh.SnoozeRouteStop(true)
    assert(fresh.RouteTarget().name == "First")
end)

case("the Defias turn-in resolves to Wiley in both reward detail and pursuit", function(ns, env)
    routeFixture(ns, env)
    env.QuestynatorRewardGoal = 2041
    ns.QuestState = function(id) return id == 65 and "inlog" or "available" end
    env.C_QuestLog.ReadyForTurnIn = function(id) return id == 65 end
    local entry = ns.RewardProgress(ns.RewardCatalog[2041])
    local pin = ns.RewardDestination(entry)
    ns.PlanRoute()
    local target = ns.RouteTarget()
    assert(pin.name == "Wiley the Black" and pin.uiMap == target.uiMap and pin.x == target.x and pin.y == target.y)
end)

case("leveling routes leave out dungeon quest pickups", function(ns, env)
    routeFixture(ns, env)
    assert(ns.IsDungeonQuest(1050) and ns.IsDungeonQuest(166) and not ns.IsDungeonQuest(170) and not ns.IsDungeonQuest(261))
    ns.AvailableQuests = function() return {
        { questID = 1050, name = "Mythology of the Titans", giver = "Librarian", area = 40, x = 2, y = 2 },
        { questID = 3, name = "C", giver = "Second", area = 40, x = 16, y = 2 },
    } end
    ns.PlanRoute()
    assert(ns.RouteTarget().name == "Second")
end)

case("leveling routes leave out battleground quest pickups", function(ns, env)
    routeFixture(ns, env)
    -- Conquering Arathi Basin and Battle of Warsong Gulch need Marks of Honor; The Battle for Arathi Basin! is in Arathi Basin
    assert(ns.IsBattlegroundQuest(8390) and ns.IsBattlegroundQuest(8389) and ns.IsBattlegroundQuest(8105))
    assert(not ns.IsBattlegroundQuest(857) and not ns.IsBattlegroundQuest(1050) and not ns.IsDungeonQuest(8390))
    ns.AvailableQuests = function() return {
        { questID = 8390, name = "Conquering Arathi Basin", giver = "Horde Warbringer", area = 40, x = 2, y = 2 },
        { questID = 3, name = "C", giver = "Second", area = 40, x = 16, y = 2 },
        { questID = 8389, name = "Battle of Warsong Gulch", giver = "Horde Warbringer", area = 44, x = 50, y = 50 },
    } end
    ns.PlanRoute()
    assert(ns.RouteTarget().name == "Second")
    env.map = ns.UiMapForArea(10)
    ns.PlanRoute()
    local suggest = ns.RouteSuggestion()
    assert(not ns.RouteTarget() and suggest.area == 40 and suggest.pickups == 1, "a battleground pickup counted toward Best next")
end)

local function emptyZoneFixture(ns, env)
    routeFixture(ns, env)
    ns.AvailableQuests = function() return {
        { questID = 1, name = "A", giver = "Far", area = 44, x = 50, y = 50 },
        { questID = 2, name = "B", giver = "Farther", area = 44, x = 60, y = 50 },
        { questID = 1050, name = "Dungeon", giver = "Librarian", area = 44, x = 40, y = 50 },
        { questID = 3, name = "C", giver = "Elsewhere", area = 10, x = 50, y = 50 },
    } end
end

case("an empty zone suggests the best next zone and Route there lasts until you arrive", function(ns, env)
    emptyZoneFixture(ns, env)
    ns.PlanRoute()
    local suggest = ns.RouteSuggestion()
    assert(not ns.RouteTarget() and not ns.RouteMode())
    assert(suggest.area == 44 and suggest.pickups == 2 and suggest.turnins == 0 and suggest.active == 0)
    ns.TravelToZone(44)
    assert(ns.RouteMode() == "travel" and ns.RouteTarget().name == "Far" and not ns.RouteSuggestion())
    ns.PlanRoute()
    assert(ns.RouteMode() == "travel", "a replan on the way dropped the trip")
    env.map = ns.UiMapForArea(44)
    ns.PlanRoute()
    assert(not ns.RouteMode() and ns.RouteTarget().name == "Far")
    env.map = ns.UiMapForArea(40)
    ns.PlanRoute()
    assert(not ns.RouteMode() and ns.RouteSuggestion(), "the finished trip came back")
end)

case("Route there takes over from an active reward pursuit", function(ns, env)
    emptyZoneFixture(ns, env)
    ns.SetRewardPursuit(2041)
    assert(ns.RouteMode() == "reward")
    ns.TravelToZone(44)
    assert(ns.RouteMode() == "travel", "Route there left the planner in " .. tostring(ns.RouteMode()) .. " mode")
    assert(ns.RouteTarget().area == 44)
end)

case("the planner's Stop ends dungeon prep, then the saved reward pursuit", function(ns, env)
    env.QuestynatorDB.arrow = false
    env.level = 34
    env.QuestynatorRewardGoal = 2041
    ns.SetDungeonPrepRoute(796)
    local kind, label = ns.RouteMode()
    assert(kind == "prep" and label:find("Scarlet Monastery", 1, true))
    ns.StopRouteMode()
    assert(not env.QuestynatorPrepDungeon and ns.RouteMode() == "reward")
    ns.StopRouteMode()
    assert(not env.QuestynatorRewardGoal and not ns.RouteMode())
end)

case("the planner window shows the suggestion, starts the trip and offers Stop", function(ns, env)
    emptyZoneFixture(ns, env)
    local window
    local function widget()
        return setmetatable({}, { __index = function(_, key)
            if key == "SetScript" then return function(self, script, fn) self[script] = fn end end
            if key == "SetText" then return function(self, value) self.text = value end end
            if key == "SetShown" then return function(self, on) self.shown = not not on end end
            if key == "Show" then return function(self) self.shown = true end end
            if key == "Hide" then return function(self) self.shown = false end end
            if key == "IsShown" then return function(self) return self.shown ~= false end end
            if key == "GetWidth" then return function() return 360 end end
            if key == "GetHeight" or key == "GetStringHeight" then return function() return 16 end end
            if key:match("^Create") then return function() return widget() end end
            if key:match("^[A-Z]") then return noop end
        end })
    end
    ns.UI.Window = function()
        window = widget()
        window.TitleText, window.CloseButton = widget(), widget()
        return window
    end
    ns.UI.Text = widget
    ns.UI.Button = function() local b = widget(); b.label = widget(); return b end
    env.CreateFrame = widget
    ns.PlanRoute()
    ns.ShowPlanner(true)
    assert(window.suggest.shown and window.travel.shown and not window.stopMode.shown)
    assert(window.heading.text == "Nothing left here for level 31", window.heading.text)
    assert(window.suggest.text == "Best next: #44 · 2 pickups", window.suggest.text)
    window.travel:OnClick()
    ns.RefreshPlanner()
    assert(window.stopMode.shown and window.mode.text == "Traveling to #44" and not window.suggest.shown, window.mode.text)
    local card = window.card
    assert(card.badge.glyph.text == "!" and card.kind.text:find("^Pick up · %d+ yd$"), tostring(card.kind.text))
    assert(card.title.text == "A" and card.sub.text == "Far" and card.pin.text == "Pin pickup", tostring(card.sub.text))
    assert(window.rows[1].shown and window.rows[1].text.text == "Pick up B from Farther", "no Then row for the next stop")
    window.stopMode:OnClick()
    ns.RefreshPlanner()
    assert(not window.stopMode.shown and window.suggest.shown)
end)

case("planner details show level, XP, what a pickup asks for, and later-stop distance", function(ns)
    local detail = ns.RouteTaskDetail({ questID = 857, pickup = true })
    assert(detail:find("Lvl 30", 1, true) and detail:find("2450 XP", 1, true), detail)
    assert(detail:find("Get Tear of the Moons from General Twinbraid's Strongbox (", 1, true) and detail:find("49, 84)", 1, true), detail)
    detail = ns.RouteTaskDetail({ questID = 857 }, 619.6)
    assert(not detail:find("Get ", 1, true) and detail:find("620 yd", 1, true), detail)
end)

-- A stand-in for the game's UI: every frame accepts any method, remembers its text and visibility.
local function fakeUI(env)
    env.widgets = {}
    local function new(name)
        local w = { shown = true }
        env.widgets[#env.widgets + 1] = w
        if name then env[name] = w end
        return setmetatable(w, { __index = function(_, k)
            if k == "SetText" then return function(self, v) self.text = v end end
            if k == "GetText" then return function(self) return self.text end end
            if k == "SetShown" then return function(self, on) self.shown = not not on end end
            if k == "Show" then return function(self) self.shown = true end end
            if k == "Hide" then return function(self) self.shown = false end end
            if k == "IsShown" or k == "IsVisible" then return function(self) return self.shown end end
            if k == "SetScript" then return function(self, s, fn) rawset(self, s, fn) end end
            if k == "GetScript" then return function(self, s) return rawget(self, s) end end
            if k == "SetID" then return function(self, v) rawset(self, "id", v) end end
            if k == "GetID" then return function(self) return rawget(self, "id") or 0 end end
            if k:match("^Create") then return function() return new() end end
            if k == "GetStringHeight" then return function() return 12 end end
            if k == "GetStringWidth" then return function() return 60 end end
            if k:match("^Get") and (k:match("Width$") or k:match("Height$")) then return function() return 100 end end
            if k == "GetFrameLevel" then return function() return 1 end end
            if k == "GetPoint" then return function() return "CENTER", nil, "CENTER", 0, 0 end end
            if k == "Enable" then return function(self) self.enabled = true end end
            if k == "Disable" then return function(self) self.enabled = false end end
            if k == "SetEnabled" then return function(self, on) self.enabled = not not on end end
            if k == "IsEnabled" then return function(self) return self.enabled ~= false end end
            if k:match("^[A-Z]") then return noop end
        end })
    end
    env.CreateFrame = function(_, name) return new(name) end
    env.UIParent = new()
    env.GameTooltip = new()
    env.tinsert = table.insert
    env.date = os.date
    function env.find(text)
        for _, w in ipairs(env.widgets) do
            if type(rawget(w, "text")) == "string" and w.text:find(text, 1, true) and w.shown then return w end
        end
    end
end

local function questLogFixture(env)
    local log = {
        { questID = 65, title = "The Defias Brotherhood", level = 14 },
        { questID = 170, title = "A New Threat", level = 5 },
        { questID = 166, title = "The Defias Brotherhood", level = 22 },
    }
    env.C_QuestLog.GetNumQuestLogEntries = function() return #log end
    env.C_QuestLog.GetInfo = function(i) return log[i] end
    env.C_QuestLog.GetLogIndexForQuestID = function(id)
        for i, q in ipairs(log) do if q.questID == id then return i end end
        return 0
    end
    env.C_QuestLog.ReadyForTurnIn = function(id) return id == 166 end
    env.C_QuestLog.GetQuestObjectives = function(id)
        if id == 170 then return {
            { text = "Rockjaw Trogg slain: 6/6", finished = true },
            { text = "Burly Rockjaw Trogg slain: 2/6", finished = false, numFulfilled = 2, numRequired = 6 },
        } end
        if id == 65 then return { { text = "0/6 Scavenger Paw", finished = false, numFulfilled = 0, numRequired = 6 } } end
        return {}
    end
end

case("the Quests tab shows the route column, ready quests first, and filter chips", function(ns, env)
    routeFixture(ns, env)
    questLogFixture(env)
    fakeUI(env)
    ns.PlanRoute()
    ns.ShowPanel()
    local view = env.QuestynatorPanel.routeView
    assert(view.card.shown and view.card.title.text == "Pick up A from First", tostring(view.card.title.text))
    assert(view.card.when.text:find("^Now") and view.card.pin.shown and view.head.text == "ROUTE · 3 STOPS", view.head.text)
    assert(view.next[1].text.shown and view.next[1].dist.text:find("^Then"), "later stops missing")
    local list, counts = ns.BuildEntries()
    assert(list[1].questID == 166 and list[2].questID == 170 and list[3].questID == 65)
    assert(counts.all == 3 and counts.ready == 1)
    assert(env.find("Ready to turn in") and env.find("Burly Rockjaw Trogg slain") and env.find("2/6"))
    assert(env.find("Pin turn-in") and env.find("All 3") and env.find("Ready 1"))
    local split = false
    for _, w in ipairs(env.widgets) do if rawget(w, "text") == "Scavenger Paw" then split = true end end
    assert(split, "a count-first objective kept its count in the text")
    env.QuestynatorPanel.questChips[3]:OnClick()
    list = ns.BuildEntries()
    assert(#list == 1 and list[1].questID == 166)
    ns.questChip = nil
end)

local function openDungeonBoard(ns, env, mode)
    fakeUI(env)
    ns.BuildDungeonsView({}, env.UIParent)
    ns.StartDungeon(721, mode)
end

local function inviteSeeker(env, name)
    for _, row in ipairs(env.widgets) do
        if rawget(row, "who") == name and row.action == "invite" then
            if row:IsShown() and row.btn:IsShown() and row.btn:IsEnabled() then row.btn:OnClick() end
            return
        end
    end
    error("Missing Invite row for " .. name)
end

case("dungeon board reserves the last seat for only one seeker", function(ns, env)
    env.party = { party1 = "One", party2 = "Two", party3 = "Three" }
    local calls = 0
    env.C_PartyInfo = { InviteUnit = function() calls = calls + 1 end }
    openDungeonBoard(ns, env, "host")
    for _, name in ipairs({ "FirstMage", "SecondMage" }) do
        ns.OnDungeonBeacon(name, 721, 31, "S", "D", "fixture", "MAGE", 1, 0)
    end
    ns.RefreshDungeons()
    inviteSeeker(env, "FirstMage")
    inviteSeeker(env, "SecondMage")
    assert(calls == 1 and ns.PendingHostInvites() == 1, calls .. " invites for one seat")
end)

case("dungeon board invite preserves the seeker's advertised role on joining", function(ns, env)
    env.QuestynatorDB.roles = { D = true }
    local invited
    env.C_PartyInfo = { InviteUnit = function(name) invited = name end }
    openDungeonBoard(ns, env, "host")
    ns.OnDungeonBeacon("TestHealer", 721, 31, "S", "H", "fixture", "PRIEST", 1, 0)
    ns.RefreshDungeons()
    inviteSeeker(env, "TestHealer")
    assert(invited == "TestHealer")
    env.party.party1 = invited
    ns.UpdateDungeonComposition()
    assert(ns.NeedText() == "Tank, 2 DPS", "advertising " .. ns.NeedText())
end)

case("dungeon Looking sidebar shows the seeker's selected roles", function(ns, env)
    env.QuestynatorDB.roles = { T = true, H = true }
    openDungeonBoard(ns, env, "seek")
    ns.RefreshDungeons()
    for _, card in ipairs(env.widgets) do
        if rawget(card, "mode") and rawget(card, "need") and card.mode.text == "Looking" then
            assert(card.need.text == "Tank, Healer", "role summary was '" .. tostring(card.need.text) .. "'")
            return
        end
    end
    error("Missing Looking sidebar")
end)

case("every tab opens in the two-column layout with its left column filled", function(ns, env)
    routeFixture(ns, env)
    questLogFixture(env)
    fakeUI(env)
    ns.ShowPanel()
    local p = env.QuestynatorPanel
    for _, tab in ipairs({ 5, 2, 3, 4, 6, 8, 7, 1 }) do ns.SelectTab(tab) end
    ns.SelectTab(5)
    assert(env.find("Level 31") and env.find("quests to pick up in"), "Zones column empty")
    ns.SelectTab(2)
    assert(p.nearbySide.title.text:find("YOUR SEARCHES", 1, true) and p.nearbySide.body.text ~= "", "Nearby column empty")
    ns.SelectTab(3)
    assert(p.groupsSide.title.text == "YOUR GROUP" and p.groupsSide.body.text:find("not hosting", 1, true), "Groups column empty")
    ns.SelectTab(6)
    assert(env.find("collected"), "Treasures column empty")
    ns.SelectTab(8)
    assert(env.find("PURSUING") and env.find("Nothing yet."), "Rewards column empty")
end)

case("the Quests tab route column offers Best next and shows the trip with Stop", function(ns, env)
    emptyZoneFixture(ns, env)
    fakeUI(env)
    ns.PlanRoute()
    ns.ShowPanel()
    local view = env.QuestynatorPanel.routeView
    assert(not view.card.shown and view.msg.text == "Nothing left here for level 31", tostring(view.msg.text))
    assert(view.sub.text:find("Best next: #44", 1, true) and view.go.text == "Route there" and view.zones.shown)
    view.go:OnClick()
    assert(view.card.shown and view.mode.text == "Traveling to #44" and view.modeStop.shown)
    view.modeStop:OnClick()
    ns.RefreshPanel()
    assert(not view.card.shown and view.go.text == "Route there")
end)

case("Attack on Camp Narache is offered at the Dirt-stained Map in the Mulgore cave", function(ns, env)
    env.level = 4
    env.UnitRace = function() return "Tauren", "Tauren", 6 end
    assert(ns.QuestState(781) == "available")
    local giver = ns.QuestGiver(781)
    assert(giver.name == "Dirt-stained Map" and giver.area == 215 and giver.x == 59.8, tostring(giver and giver.name))
    local found
    for _, q in ipairs(ns.AvailableQuests()) do if q.questID == 781 then found = q end end
    assert(found and found.name == "Attack on Camp Narache")
end)

case("the in-world marker sits on the game's navigation frame and never moves the player's own pin", function(ns, env)
    routeFixture(ns, env)
    fakeUI(env)
    local pin, tracked, cleared = nil, false, 0
    local nav = env.CreateFrame()
    env.C_Navigation = { GetFrame = function() return nav end, GetDistance = function() return 140 end,
                         WasClampedToScreen = function() return false end }
    env.UiMapPoint = { CreateFromCoordinates = function(map, x, y) return { uiMapID = map, position = { x = x, y = y } } end }
    local sets = 0
    env.C_Map.SetUserWaypoint = function(p)                  -- the game fires USER_WAYPOINT_UPDATED right away
        pin, sets = p, sets + 1
        assert(sets < 50, "placing the waypoint loops")
        ns.WorldMarkerRefresh()
    end
    env.C_Map.GetUserWaypoint = function() return pin end
    env.C_Map.ClearUserWaypoint = function() pin = nil; cleared = cleared + 1 end
    env.C_SuperTrack = { SetSuperTrackedUserWaypoint = function(on) tracked = on end, GetSuperTrackedQuestID = function() return 0 end }
    env.GetUnitSpeed = function() return 7 end
    local mapPin = { alpha = 1, mouse = true }                                  -- the world map's waypoint pin
    function mapPin:SetAlpha(a) self.alpha = a end
    function mapPin:EnableMouse(on) self.mouse = on end
    env.WorldMapFrame = { EnumeratePinsByTemplate = function(_, template)
        local done = template ~= "WaypointLocationPinTemplate"
        return function() if not done then done = true; return mapPin end end
    end }
    ns.PlanRoute()
    ns.WorldMarkerRefresh()
    assert(mapPin.alpha == 0 and not mapPin.mouse, "our waypoint shows a pin on the world map")
    local m = env.QuestynatorWorldMarker
    assert(m and m.shown and m.mode == "far" and m.far.shown, "marker missing or not in far mode")
    assert(m.far.badge.glyph.text == "!" and m.far.title.text == "A" and m.near.title.text == "A", "badge or title missing")
    assert(m.far.dist.text == "140 yd" and m.far.eta.text == "~0:20" and m.near.sub.text:find("^Pickup"), m.far.dist.text .. " " .. m.far.eta.text)
    local secret = setmetatable({}, { __lt = function() error("compared a secret value") end })
    env.issecretvalue = function(v) return v == secret end
    env.GetUnitSpeed = function() return secret end                               -- hidden in combat/instances
    ns.WorldMarkerUpdate()
    assert(m.far.eta.text == "~0:20", "secret speed: " .. tostring(m.far.eta.text))
    env.GetUnitSpeed = function() return 7 end
    local far = env.C_Navigation.GetDistance
    env.C_Navigation.GetDistance = function() return 60 end                      -- under 100 yd: the card
    ns.WorldMarkerUpdate()
    assert(m.mode == "far", "switched to the card without waiting")
    env.now = env.now + 0.5
    ns.WorldMarkerUpdate()
    assert(m.mode == "near" and m.near.shown and m.near.dist.text == "60 yd", "no near card at 60 yd")
    env.C_Navigation.GetDistance = function() return 105 end                     -- inside the gap: stays a card
    env.now = env.now + 0.5
    ns.WorldMarkerUpdate()
    assert(m.mode == "near", "flipped back to the beam inside the 95-110 yd gap")
    env.C_Navigation.GetDistance = function() return 20 end
    ns.WorldMarkerUpdate()
    assert(m.shown and m.near.dist.text == "20 yd" and m.near.dim < 1, "the card doesn't fade near the target")
    env.C_Navigation.GetDistance = function() return 5 end                       -- on the spot: fades out of the way
    ns.WorldMarkerUpdate()
    assert(m.shown and m.showTo == 0, "the marker vanished at once instead of fading")
    m:OnUpdate(0.3)
    assert(m.shown and m.show > 0 and m.show < 1, "no fade on arrival: " .. tostring(m.show))
    m:OnUpdate(0.4)
    assert(not m.shown, "the marker covers the spot you're standing on")
    env.C_Navigation.GetDistance = function() return 12 end                      -- a step back: still hidden
    ns.WorldMarkerUpdate()
    assert(not m.shown, "the marker flickers back at the edge of the spot")
    env.C_Navigation.GetDistance = function() return 30 end                      -- walked away: fades back in
    ns.WorldMarkerUpdate()
    assert(m.shown and m.show == 0 and m.mode == "near" and m.near.dist.text == "30 yd", "the marker didn't come back")
    m:OnUpdate(0.3)
    assert(m.show > 0 and m.show < 1, "popped back instead of fading in")
    m:OnUpdate(0.4)
    assert(m.show == 1)
    env.InCombatLockdown = function() return true end                           -- combat: fades to 10%
    m:OnUpdate(0.3)
    assert(m.shown and m.combat < 1 and m.combat > 0.1, "no fade into combat: " .. tostring(m.combat))
    m:OnUpdate(0.4)
    assert(math.abs(m.combat - 0.1) < 1e-9, "not at 10% in combat: " .. tostring(m.combat))
    env.InCombatLockdown = function() return false end                          -- out of combat: back
    m:OnUpdate(0.7)
    assert(m.combat == 1, "didn't come back after combat")
    env.C_Navigation.WasClampedToScreen = function() return true end
    ns.WorldMarkerUpdate()
    assert(m.mode == "near", "flipped to the orbit without waiting")             -- a brief flip is ignored
    env.now = env.now + 0.5
    ns.WorldMarkerUpdate()
    assert(m.mode == "orbit" and m.orbit.shown and m.orbit.dist.text == "30 yd", "no off-screen badge")
    nav.GetCenter = function() return 1800, 900 end                              -- up and right of the middle
    env.UIParent.GetCenter = function() return 960, 540 end
    for _ = 1, 3 do m:OnUpdate(0.05) end                                         -- animation frames
    assert(m.orbit.x > 0 and m.orbit.y > 0 and m.orbit.angle > 0 and m.orbit.angle < math.pi / 2,
        "off-screen badge not on the target's side of the screen")
    env.C_Navigation.WasClampedToScreen = function() return false end            -- still at the screen edge
    env.now = env.now + 0.5
    ns.WorldMarkerUpdate()
    assert(m.mode == "orbit", "left the orbit while the spot is at the screen edge")
    local navFrame = env.C_Navigation.GetFrame
    env.C_Navigation.GetFrame = function() return nil end                          -- the game rebuilds its frame
    ns.WorldMarkerUpdate()
    assert(m.shown, "hid during a brief navigation-frame rebuild")
    env.C_Navigation.GetFrame = navFrame
    nav.GetCenter = nil
    env.C_Navigation.GetDistance = far
    ns.WorldMarkerUpdate()
    env.now = env.now + 0.5
    ns.WorldMarkerUpdate()
    assert(m.mode == "far", "didn't return to the beam on screen at 140 yd")
    for _ = 1, 3 do m:OnUpdate(0.05) end
    assert(pin and math.abs(pin.position.x - 0.02) < 1e-6 and tracked, "route stop not placed on the map")
    local placed = pin
    pin = nil                                                                    -- the player removes the pin
    ns.WorldMarkerUpdate()
    assert(not m.shown, "marker stayed frozen after the pin was removed")
    ns.WorldMarkerRefresh()
    assert(pin == nil and not m.shown, "put back a pin the player removed")
    pin = placed                                                                 -- e.g. Pin on map
    ns.WorldMarkerUpdate()
    assert(m.shown, "marker didn't come back with the pin")
    pin = { uiMapID = pin.uiMapID, position = { x = 0.5, y = 0.5 } }        -- the player pins somewhere else
    tracked = false
    env.UnitPosition = function() return 150, 20, 0, 1 end
    ns.UpdateRoute()
    ns.WorldMarkerRefresh()
    assert(pin.position.x == 0.5, "the player's own pin was replaced")
    assert(mapPin.alpha == 1 and mapPin.mouse, "the player's own pin is hidden on the world map")
    assert(m.shown and m.source == "pin" and tracked, "no world pin on the player's own map pin")
    assert(m.far.title.text == "Map pin" and m.near.sub.text == "Map pin" and m.far.badge.glyph.text == "", m.far.title.text)
    -- a ready quest picked in the tracker: the game guides to its turn-in NPC, and our pin shows it there
    env.C_SuperTrack.GetSuperTrackedQuestID = function() return 170 end
    ns.ArrowTarget = function()
        return { questID = 170, title = "The Fargodeep Mine", name = "Marshal Dughan", area = 40, x = 5, y = 5,
                 selectedQuest = true }
    end
    ns.IsReadyToTurnIn = function(id) return id == 170 end
    local objectives = env.C_QuestLog.GetQuestObjectives
    env.C_QuestLog.GetQuestObjectives = function(id)
        return id == 170 and { { text = "Kobold Miner slain: 8/8", finished = true } } or {}
    end
    env.C_Navigation.GetDistance = function() return 64 end
    ns.WorldMarkerUpdate()
    assert(m.shown and m.source == "quest" and m.near.badge.glyph.text == "?" and m.near.title.text == "The Fargodeep Mine",
        "no pin for the quest picked in the tracker")
    assert(m.near.sub.text:find("Turn in", 1, true) and m.near.sub.text:find("Marshal Dughan", 1, true)
        and m.near.lines[1].text == "Kobold Miner slain: 8/8", m.near.sub.text)
    assert(pin.position.x == 0.5, "picking a quest moved the player's own pin")
    env.C_SuperTrack.GetSuperTrackedQuestID = function() return 0 end         -- selection cleared
    env.C_QuestLog.GetQuestObjectives = objectives
    ns.WorldMarkerUpdate()
    assert(m.source == "pin" and m.shown, "didn't go back to the player's map pin after the selection was cleared")
    ns.SetOption("worldMarker", false)
    assert(not m.shown and cleared == 0 and pin.position.x == 0.5, "turning the pin off cleared the player's own pin")
    ns.SetOption("worldMarker", true)
    assert(m.shown and m.source == "pin", "turning it back on didn't show the player's pin")
    pin = nil                                                                    -- the player removes their pin
    ns.WorldMarkerUpdate()
    assert(m.source == "route" and pin and pin.position.x ~= 0.5 and mapPin.alpha == 0,
        "the route stop didn't come back after the player's pin was removed")
end)

case("a pin from Questynator tells the in-world waypoint the quest and who to see", function(ns, env)
    routeFixture(ns, env)
    fakeUI(env)
    local pin
    local nav = env.CreateFrame()
    env.C_Navigation = { GetFrame = function() return nav end, GetDistance = function() return 60 end,
                         WasClampedToScreen = function() return false end }
    env.UiMapPoint = { CreateFromCoordinates = function(map, x, y) return { uiMapID = map, position = { x = x, y = y } } end }
    env.C_Map.SetUserWaypoint = function(p) pin = p; ns.WorldMarkerRefresh() end
    env.C_Map.GetUserWaypoint = function() return pin end
    env.C_Map.GetMapInfo = function() return { mapType = 3, name = "Westfall" } end
    env.C_SuperTrack = { SetSuperTrackedUserWaypoint = noop, GetSuperTrackedQuestID = function() return 0 end }
    env.GetUnitSpeed = function() return 7 end
    ns.Waypoint(40, 44.7, 44.5, "The Problem With Prideclaws", nil, { questID = 92515, who = "Indari Sunseam" })
    local m = env.QuestynatorWorldMarker
    assert(m and m.source == "pin", "no waypoint on the pin")
    assert(m.far.title.text == "The Problem With Prideclaws" and m.far.badge.glyph.text == "!", tostring(m.far.title.text))
    assert(m.near.sub.text:find("^Pickup") and m.near.sub.text:find("Indari Sunseam", 1, true), tostring(m.near.sub.text))
    env.C_QuestLog.GetLogIndexForQuestID = function(id) return id == 92515 and 1 or 0 end    -- picked up and done
    env.C_QuestLog.ReadyForTurnIn = function(id) return id == 92515 end
    ns.WorldMarkerRefresh()
    assert(m.far.badge.glyph.text == "?" and m.near.sub.text:find("^Turn in"), tostring(m.near.sub.text))
    ns.pinInfo = nil                                                                   -- /reload: the pin stays
    ns.WorldMarkerRefresh()
    assert(m.far.title.text == "The Problem With Prideclaws", "the pin forgot its quest after a reload")
    pin = { uiMapID = pin.uiMapID, position = { x = 0.1, y = 0.1 } }                    -- a pin of the player's own
    ns.WorldMarkerRefresh()
    assert(m.far.title.text == "Westfall" and m.near.sub.text == "Map pin", tostring(m.far.title.text))
end)

case("a pin set on a route step moves on to the next step once it's done", function(ns, env)
    routeFixture(ns, env)
    local pin, said = nil, 0
    env.UiMapPoint = { CreateFromCoordinates = function(map, x, y) return { uiMapID = map, position = { x = x, y = y } } end }
    env.C_Map.SetUserWaypoint = function(p) pin = p end
    env.C_Map.GetUserWaypoint = function() return pin end
    env.C_SuperTrack = { SetSuperTrackedUserWaypoint = noop, GetSuperTrackedQuestID = function() return 0 end }
    env.print = function() said = said + 1 end
    local taken = {}
    ns.QuestState = function(id) return taken[id] and "inlog" or "available" end
    ns.AvailableQuests = function() return {
        { questID = 1, name = "A", giver = "First", area = 40, x = 2, y = 2, level = 30 },
        { questID = 2, name = "B", giver = "First", area = 40, x = 2, y = 2, level = 30 },   -- same NPC
        { questID = 3, name = "C", giver = "Second", area = 40, x = 16, y = 2, level = 31 },
    } end
    ns.PlanRoute()
    local first = ns.RouteTarget()
    assert(first.name == "First")
    ns.Waypoint(40, first.x, first.y, "A", nil, { questID = 1, who = "First", route = true })   -- Pin pickup
    said = 0
    taken[1] = true                                       -- A picked up: B is still at the same spot
    ns.UpdateRoute()
    assert(pin.position.x == 0.02 and env.QuestynatorDB.pinInfo.questID == 2, "the pin left a spot with work left")
    taken[2] = true                                       -- that stop is done
    ns.UpdateRoute()
    assert(math.abs(pin.position.x - 0.16) < 1e-6 and env.QuestynatorDB.pinInfo.questID == 3, "the pin didn't move on")
    assert(said == 0, "moving the pin printed to chat")
    pin = { uiMapID = pin.uiMapID, position = { x = 0.5, y = 0.5 } }   -- the player pins somewhere else
    taken[3] = true
    ns.UpdateRoute()
    assert(pin.position.x == 0.5, "moved a pin the player placed")
end)

case("the window's gear opens Questynator's options, and the bottom line says who made it", function(ns, env)
    fakeUI(env)
    local opened, copied = 0, 0
    ns.OpenOptions = function() opened = opened + 1 end
    ns.ShowCopyBattleTag = function() copied = copied + 1 end
    ns.ShowPanel()
    local p = env.QuestynatorPanel
    assert(p.optionsBtn and not p.statsView and not p.statsBtn, "the Stats view is still there")
    p.optionsBtn:OnClick()
    assert(opened == 1, "the gear didn't open Options > AddOns > Questynator")
    local made = p.madeBy
    assert(made and made.text.text:find("^Made by ") and made.text.text:find("Valacas#21304", 1, true), "no Made by line")
    made:OnClick()
    assert(copied == 1, "Made by doesn't offer the BattleTag")
end)

case("with WaypointUI also on, the player is asked to keep one world pin", function(ns, env)
    fakeUI(env)
    local disabled, reloaded
    env.C_Navigation = { GetFrame = function() return nil end }
    env.UiMapPoint = { CreateFromCoordinates = function() return {} end }
    env.C_Map = { SetUserWaypoint = function() end }
    env.C_SuperTrack = { GetSuperTrackedQuestID = function() return 0 end }
    local saved = 0
    env.C_AddOns = { IsAddOnLoaded = function(name) return name == "WaypointUI" end,
                     DisableAddOn = function(name) disabled = name end,
                     SaveAddOns = function() saved = saved + 1 end }
    env.ReloadUI = function() reloaded = true end
    assert(ns.WorldPinConflict(), "both pins on, but no conflict seen")
    local panel = ns.BuildOptionsPanel()
    panel.refresh()
    assert(panel.pinNote and panel.pinNote.shown and panel.pinNote.text == "WaypointUI is also on.", "no note in settings")
    panel.pinPick:OnClick()
    assert(env.QuestynatorPinChoice.shown, "Choose one didn't open the prompt")
    env.QuestynatorPinChoice:Hide()
    ns.CheckWorldPinConflict()
    local ask = env.QuestynatorPinChoice
    assert(ask and ask.shown and ask.TitleText.text == "Two world pins are on", "not asked")
    ask:Hide()                                                    -- closed with x: not asked on every reload
    ns.CheckWorldPinConflict()
    assert(not ask.shown, "asked again on the next login after closing it")
    panel.pinPick:OnClick()                                       -- still there under Options
    assert(ask.shown, "Choose one stopped working after the prompt was closed")
    assert(ask.reload, "no secure /reload button over Use Questynator's")
    ask.reload:PreClick()
    -- ReloadUI is protected on this client: addon code calling it is blocked, the button's macro reloads
    assert(disabled == "WaypointUI" and not reloaded and not ask.shown, "keeping ours didn't turn WaypointUI off")
    assert(saved > 0, "the addon list wasn't saved, so the reload brings WaypointUI back")
    disabled, saved = nil, 0                                      -- next login: WaypointUI still running
    ns.CheckWorldPinConflict()
    assert(disabled == "WaypointUI" and saved > 0 and not ask.shown, "picked ours, but WaypointUI stayed on")
    ns.ShowWorldPinChoice()
    ask.theirs:OnClick()
    assert(not ns.GetOption("worldMarker") and not ns.WorldPinConflict(), "keeping theirs left our pin on")
    panel.refresh()
    assert(not panel.pinNote.shown, "settings note stayed after choosing")
    ns.CheckWorldPinConflict()
    assert(not ask.shown, "asked again after choosing")
end)

case("quest tips show in how-to-complete text", function(ns, env)
    env.C_QuestLog.GetLogIndexForQuestID = function(id) return id == 781 and 1 or 0 end
    assert(ns.QuestTips[781] and ns.QuestDetails(781):find("respawns slower", 1, true))
end)

local function prepRow(ns, final, dungeon)
    for _, row in ipairs(ns.DungeonPrepRows(dungeon or 796)) do
        if row.final == final then return row end
    end
end

case("Scarlet Monastery shows this warrior's pickups and the first unfinished prerequisite", function(ns, env)
    assert(ns.HasDungeonPrep(796) and not ns.HasDungeonPrep(-1))
    assert(prepRow(ns, 1050).place.name == "Librarian Mae Paledust")
    local chain = prepRow(ns, 1053)
    assert(chain.id == 261 and chain.state == "locked" and chain.depth == 2 and not chain.place)
    env.level = 34
    assert(prepRow(ns, 1053).place.name == "Brother Anton")
    env.C_QuestLog.GetLogIndexForQuestID = function(id) return id == 1052 and 3 or 0 end
    chain = prepRow(ns, 1053)
    assert(chain.id == 1052 and chain.state == "inlog" and chain.depth == 1)
    ns.RecordQuestTurnIn(1052)
    assert(prepRow(ns, 1053).place.name == "Raleigh the Devout")
    ns.RecordQuestTurnIn(1053)
    assert(not prepRow(ns, 1053))
end)

case("every dungeon checklist contains distinct quests with mapped outdoor pickups", function(ns)
    -- Inspect every catalog entry, including class or faction quests this character cannot take.
    ns.QuestState = function() return "available" end
    local dungeons = {}
    for _, dungeon in ipairs(ns.DUNGEONS) do
        assert(not dungeons[dungeon.id] and ns.HasDungeonPrep(dungeon.id), dungeon.name)
        dungeons[dungeon.id] = true
        assert(ns.UiMapForArea(dungeon.zone), dungeon.name .. " has no entrance map")
        local rows, seen = ns.DungeonPrepRows(dungeon.id), {}
        assert(#rows > 0, dungeon.name)
        for _, row in ipairs(rows) do
            local label = dungeon.name .. " quest " .. row.final
            assert(not seen[row.final] and ns.ZoneQuest(row.final) and ns.BundledQuest(row.final), label)
            seen[row.final] = true
            local p = row.place
            assert(p and not ns.HasDungeonPrep(p.area) and p.x >= 0 and p.x <= 100 and p.y >= 0 and p.y <= 100, label)
        end
    end
    for _, id in ipairs({1581, 718, 16919, 16611, 16732, 16544, 16550, 16842, 16620, 16554, 16667}) do
        assert(dungeons[id], "missing dungeon " .. id)
    end
end)

case("Deadmines and Wailing Caverns prep respect faction and completion", function(ns, env)
    env.level = 22
    assert(prepRow(ns, 167, 1581).place.name == "Wilder Thistlenettle")
    assert(not prepRow(ns, 962, 718))
    env.UnitRace = function() return "Orc", "Orc", 2 end
    assert(not prepRow(ns, 167, 1581))
    assert(prepRow(ns, 962, 718).place)
    ns.RecordQuestTurnIn(962)
    assert(not prepRow(ns, 962, 718))
end)

case("a Forever dungeon can be prepared from the board and prompted when hosting", function(ns, env)
    env.level = 58
    env.QuestynatorDB.arrow = false
    fakeUI(env)
    ns.BuildDungeonsView({}, env.UIParent)
    ns.StartDungeon(16667, "host")
    ns.RefreshDungeons()
    local reminder = ns.NextSmartReminder()
    assert(reminder and reminder.kind == "route" and reminder.id == 16667)
    local header
    for _, w in ipairs(env.widgets) do
        if w.id == 16667 and rawget(w, "prep") then header = w; break end
    end
    assert(header and header.prep:IsShown())
    header.prep:OnClick()
    local button = assert(env.find("Route to missing pickups"))
    button:OnClick()
    assert(env.QuestynatorPrepDungeon == 16667 and ns.RouteMode() == "prep")
    assert(ns.RouteTarget() and ns.RouteTarget().area == 1537)
end)

case("Blackmaw prep follows the faction's prerequisite and advances after turn-in", function(ns, env)
    env.level = 55
    assert(prepRow(ns, 92344, 16554).id == 92345)
    assert(not prepRow(ns, 92343, 16554))
    env.UnitRace = function() return "Orc", "Orc", 2 end
    local row = prepRow(ns, 92343, 16554)
    assert(row.id == 92346 and row.depth == 1 and row.place.name == "Jediga")
    ns.RecordQuestTurnIn(92346)
    assert(prepRow(ns, 92343, 16554).id == 92343 and not prepRow(ns, 92344, 16554))
end)

case("prep respects Horde race and mage restrictions", function(ns, env)
    env.UnitRace = function() return "Undead", "Scourge", 5 end
    assert(not prepRow(ns, 1050) and not prepRow(ns, 1049) and not prepRow(ns, 1951))
    env.UnitRace = function() return "Troll", "Troll", 8 end
    assert(prepRow(ns, 1049).place and prepRow(ns, 1113).id == 1109)
    assert(prepRow(ns, 1160).id == 1149 and prepRow(ns, 1160).depth == 7)
    env.UnitClass = function() return "Mage", "MAGE", 8 end
    assert(prepRow(ns, 1951).id == 1947)
end)

case("only a present party member advertising shareability receives the request", function(ns, env)
    env.party.party1 = "Friend"
    ns.OnGroupMessage("P|1|1|1|1050:0:1:0", "Friend")
    assert(not prepRow(ns, 1050).sharer)
    ns.OnGroupMessage("P|2|1|1|1050:0:1:0s", "Friend")
    assert(prepRow(ns, 1050).sharer == "Friend")
    local sent = 0
    env.SendChatMessage = function(text, channel, _, who)
        assert(text:find("Mythology of the Titans", 1, true) and channel == "WHISPER" and who == "Friend")
        sent = sent + 1
    end
    ns.RequestPrepShare(1050)
    env.C_QuestLog.IsQuestLogFull = function() return true end
    ns.RequestPrepShare(1050)
    env.C_QuestLog.IsQuestLogFull = nil
    env.party.party1 = nil
    ns.RequestPrepShare(1050)
    assert(sent == 1)
end)

case("outbound party progress preserves the legacy fields and marks only shareable quests", function(ns, env)
    env.party.party1 = "Friend"
    env.C_QuestLog.GetNumQuestLogEntries = function() return 2 end
    env.C_QuestLog.GetInfo = function(i) return { questID = 1049 + i } end
    env.C_QuestLog.IsPushableQuest = function(id) return id == 1050 end
    ns.SendPartyProgress()
    assert(env.messages[1]:find("1050:0:0:0s,1051:0:0:0", 1, true))
end)

case("prep advances across zones, waits for log space and restores the saved reward", function(ns, env)
    env.QuestynatorDB.arrow = false
    env.level = 34
    env.QuestynatorRewardGoal = 2041
    ns.SetDungeonPrepRoute(796)
    assert(ns.RouteTarget().questID == 261 and env.QuestynatorRewardGoal == 2041)
    env.C_QuestLog.IsQuestLogFull = function() return true end
    ns.PlanRoute()
    assert(not ns.RouteTarget() and env.QuestynatorPrepDungeon == 796)
    env.C_QuestLog.IsQuestLogFull = nil
    env.C_QuestLog.GetLogIndexForQuestID = function(id) return id == 261 and 1 or 0 end
    ns.PlanRoute()
    assert(ns.RouteTarget().questID == 1050)
    env.C_QuestLog.GetLogIndexForQuestID = function(id) return (id == 261 or id == 1050) and 1 or 0 end
    ns.PlanRoute()
    assert(ns.RouteTarget().questID == 96800, "Past Due should be the remaining Scarlet pickup")
    env.C_QuestLog.GetLogIndexForQuestID = function(id) return (id == 261 or id == 1050 or id == 96800) and 1 or 0 end
    ns.PlanRoute()
    assert(not env.QuestynatorPrepDungeon and ns.RouteTarget().rewardItem == 2041)
end)

case("reminders find a nearby Scarlet pickup without opening any panels", function(ns, env)
    local ironforge = ns.UiMapForArea(1537)
    ns.CurrentZoneMaps = function() return { [ironforge] = true } end
    ns.ArrowGeometry = function() return { yards = 160 } end
    local r = ns.NextSmartReminder()
    assert(r.kind == "pin" and r.id == 1050 and r.place.name == "Librarian Mae Paledust")
    ns.ArrowGeometry = function() return { yards = 220 } end
    assert(not ns.NextSmartReminder())
    ns.CurrentZoneMaps = function() return {} end
    ns.MyDungeon = function() return { id = 796 } end
    assert(ns.NextSmartReminder().kind == "route")
    env.party.party1 = "Friend"
    ns.OnGroupMessage("P|1|1|1|1050:0:1:0s", "Friend")
    assert(ns.NextSmartReminder().kind == "share")
    env.C_QuestLog.IsQuestLogFull = function() return true end
    assert(not ns.NextSmartReminder())
end)

case("reminders recognize the entrance and a recent join request", function(ns, env)
    ns.CurrentZoneMaps = function() return { [ns.UiMapForArea(85)] = true } end
    ns.ArrowGeometry = function() return { yards = 350 } end
    assert(ns.NextSmartReminder().kind == "route")
    ns.ArrowGeometry = function() return {} end
    assert(not ns.NextSmartReminder())
    ns.RememberDungeonRequest(796)
    assert(ns.NextSmartReminder().kind == "route")
    env.now = env.now + 121
    assert(not ns.NextSmartReminder())
end)

case("nearby treasure reminders honor character progress, snooze, combat and settings", function(ns, env)
    ns.CurrentZoneMaps = function() return { [ns.UiMapForArea(40)] = true } end
    ns.ArrowGeometry = function() return { yards = 70 } end
    local available = { step = 151, status = "available", area = 40, x = 1, y = 2,
        questName = "Poor Old Blanchy", giver = "Verna Furlbrow", reward = "Old Blanchy's Feed Pouch" }
    ns.TreasureList = function() return { available } end
    local r = ns.NextSmartReminder()
    assert(r.kind == "pin" and r.id == 151 and r.title == available.reward)
    env.QuestynatorReminderSnoozes = { [r.key] = env.GetServerTime() + 30 }
    assert(not ns.NextSmartReminder())
    env.now = env.now + 31
    assert(ns.NextSmartReminder())
    env.InCombatLockdown = function() return true end
    assert(not ns.NextSmartReminder())
    env.InCombatLockdown = nil
    ns.SetOption("reminders", false)
    assert(not ns.NextSmartReminder())
    ns.SetOption("reminders", true)
    ns.RecordQuestTurnIn(151)
    assert(not ns.NextSmartReminder())
end)

case("a reminder click rechecks eligibility and the snooze survives reload", function(ns, env)
    local tick, cancel, card, marked
    local function widget()
        return setmetatable({}, { __index = function(_, k)
            if k == "SetScript" then return function(self, key, cb) self[key] = cb end end
            if k == "GetStringHeight" then return function() return 16 end end
            if k == "Hide" then return function(self) self.visible = false end end
            if k == "Show" then return function(self) self.visible = true end end
            return noop
        end })
    end
    ns.UI.Window = function()
        card = widget()
        card.CloseButton, card.TitleText = widget(), widget()
        return card
    end
    ns.UI.Text, ns.UI.Button = widget, widget
    env.C_Timer.NewTicker = function(_, fn)
        tick = fn
        return { Cancel = function() cancel = true end }
    end
    local createFrame = env.CreateFrame
    env.CreateFrame = function(...)
        local f = createFrame(...)
        f.UnregisterAllEvents = noop
        return f
    end
    ns.CurrentZoneMaps = function() return { [ns.UiMapForArea(1537)] = true } end
    ns.ArrowGeometry = function() return { yards = 100 } end
    ns.Waypoint = function(area, _, _, _, keep) assert(area == 1537 and keep); marked = true end
    ns.StartSmartReminders()
    tick()
    assert(card.visible)
    env.IsInInstance = function() return true end
    card.act.OnClick()
    assert(not marked and not card.visible)
    env.IsInInstance = nil
    tick()
    card.act.OnClick()
    assert(marked and not card.visible)
    ns.SetOption("reminders", false)
    assert(cancel)
    local fresh, login = client()
    login.QuestynatorReminderSnoozes = env.QuestynatorReminderSnoozes
    fresh.CurrentZoneMaps, fresh.ArrowGeometry = ns.CurrentZoneMaps, ns.ArrowGeometry
    local nextPickup = fresh.NextSmartReminder()
    assert(nextPickup and nextPickup.key ~= "pickup:1050", "only the dismissed pickup should be snoozed")
    login.now = login.now + 1801
    assert(fresh.NextSmartReminder().id == 1050)
end)

case("quest group reminders require a live eligible listing with an unreserved seat", function(ns, env)
    env.C_QuestLog.GetLogIndexForQuestID = function(id) return id == 170 and 1 or 0 end
    env.C_QuestLog.IsQuestLogFull = function() return true end
    local listing = { level = 31, min = 29, max = 32, members = 4, pending = 1 }
    ns.RecordGroup("Host", 170, listing)
    assert(not ns.NextSmartReminder())
    listing.pending = 0
    ns.RecordGroup("Host", 170, listing)
    local r = ns.NextSmartReminder()
    assert(r.kind == "join" and r.group.host == "Host" and #env.messages == 0)
    env.C_QuestLog.ReadyForTurnIn = function() return true end
    assert(not ns.NextSmartReminder())
    env.C_QuestLog.ReadyForTurnIn = function() return false end
    env.level = 33
    assert(not ns.NextSmartReminder())
    env.level, env.now = 31, env.now + 76
    assert(not ns.NextSmartReminder())
end)

case("unmatched quest search offers quick hosting only after its search delay", function(ns, env)
    env.C_QuestLog.GetLogIndexForQuestID = function(id) return id == 170 and 1 or 0 end
    ns.Start(170)
    assert(not ns.NextSmartReminder())
    env.now = env.now + 11
    assert(ns.NextSmartReminder().kind == "host")
    ns.CreateListing(170, { min = 25, max = 35, want = 0, autoInvite = true })
    assert(not ns.NextSmartReminder())
end)

case("reward turn-in uses wearable equipment and works with a full quest log", function(ns, env)
    env.C_QuestLog.GetNumQuestLogEntries = function() return 1 end
    env.C_QuestLog.GetInfo = function() return { questID = 166, title = "The Defias Brotherhood" } end
    env.C_QuestLog.GetLogIndexForQuestID = function(id) return id == 166 and 1 or 0 end
    env.C_QuestLog.ReadyForTurnIn = function(id) return id == 166 end
    env.C_QuestLog.IsQuestLogFull = function() return true end
    env.C_Item = { GetItemInfo = function(id)
        return "Legs", nil, 2, 20, 16, nil, "Mail", nil, "INVTYPE_LEGS", nil, nil, 4, id == 6087 and 3 or 2
    end }
    env.IsPlayerSpell = function() return true end
    ns.CurrentZoneMaps = function() return { [ns.UiMapForArea(40)] = true } end
    ns.ArrowGeometry = function() return { yards = 150 } end
    local r = ns.NextSmartReminder()
    assert(r.kind == "turnin" and r.id == 166 and r.title == "Chausses of Westfall")
    env.IsPlayerSpell = function() return false end
    assert(not ns.NextSmartReminder())
end)

case("a turn-in surfaces an eligible local follow-up and acceptance removes it", function(ns, env)
    env.level = 35
    ns.StartSmartReminders()
    ns.RecordQuestTurnIn(1052)
    env.eventFrame:OnEvent("QUEST_TURNED_IN", 1052)
    ns.CurrentZoneMaps = function() return {} end
    assert(not ns.NextSmartReminder())
    ns.CurrentZoneMaps = function() return { [ns.UiMapForArea(267)] = true } end
    ns.ArrowGeometry = function() return { yards = 800 } end
    local r = ns.NextSmartReminder()
    assert(r.id == 1053 and r.kind == "pin" and r.place.name == "Raleigh the Devout")
    env.C_QuestLog.GetLogIndexForQuestID = function(id) return id == 1053 and 1 or 0 end
    assert(not ns.NextSmartReminder())
end)

case("quest and dungeon hosts share reservations and retry after unanswered invites", function(ns, env)
    local sent = {}
    env.GetNormalizedRealmName = function() return "Realm" end
    env.C_PartyInfo = { InviteUnit = function(name) sent[#sent + 1] = name end }
    env.party = { party1 = "Tank", party2 = "Healer", party3 = "Rogue" }
    ns.Start(170)
    ns.CreateListing(170, { min = 25, max = 37, want = 0, autoInvite = true })
    env.eventFrame:OnEvent("CHAT_MSG_WHISPER", "+", "Fourth")
    env.eventFrame:OnEvent("CHAT_MSG_WHISPER", "+", "Fourth-Realm")
    ns.StartDungeon(721, "host")
    ns.OnDungeonWhisper("Fifth", "+")
    assert(#sent == 1 and ns.PendingHostInvites() == 1)
    env.now = env.now + 61
    ns.OnDungeonWhisper("Fifth", "+")
    assert(#sent == 2 and sent[2] == "Fifth")
    env.party.party4 = "Fifth"
    local count, joined = ns.PendingHostInvites("Fifth-Realm")
    assert(count == 0 and joined)
    env.party.party3 = nil
    ns.OnDungeonWhisper("Fifth", "+")
    assert(#sent == 2)
    ns.OnDungeonWhisper("Replacement", "+")
    assert(#sent == 3 and ns.PendingHostInvites() == 1)
end)

case("failed calls and waiting for our own invite do not claim host slots", function(ns, env)
    ns.StartDungeon(721, "host")
    env.C_PartyInfo = { InviteUnit = function() error("client unavailable") end }
    ns.OnDungeonWhisper("Tank", "+")
    assert(ns.PendingHostInvites() == 0 and not ns.MyDungeon().inviteCount.Tank)
    env.C_PartyInfo.InviteUnit = noop
    ns.trustInviter = { who = "OtherHost", t = env.now }
    ns.OnDungeonWhisper("Tank", "+")
    assert(ns.PendingHostInvites() == 0)
    env.now = env.now + 91
    ns.OnDungeonWhisper("Tank", "+")
    assert(ns.MyDungeon().inviteCount.Tank == 1 and ns.PendingHostInvites() == 1)
end)

case("Host LFG starts the selected quest, uses unfinished objectives, and stops it after a selection change", function(ns, env)
    env.C_QuestLog.GetLogIndexForQuestID = function(id) return (id == 170 or id == 166) and 1 or 0 end
    local selected = 170
    env.C_SuperTrack = { GetSuperTrackedQuestID = function() return selected end }
    env.C_QuestLog.GetQuestObjectives = function() return {{ finished = true }, { finished = false }} end
    ns.ToggleQuestHost()
    local listing = ns.GroupEntries()[1]
    assert(ns.HostedQuest() == 170 and listing.mine and listing.min == 25 and listing.max == 37)
    local beacon = env.messages[#env.messages]
    assert(beacon:find("|1|25|37|2|2|", 1, true))
    selected = 166
    ns.ToggleQuestHost()
    assert(not ns.HostedQuest() and not ns.IsSearching(170))
    env.party.party1, env.leader = "Leader", false
    ns.ToggleQuestHost()
    assert(not ns.HostedQuest())
end)

case("quest picker pages, rechecks rows, and shows the hosted quest on the button", function(ns, env)
    local ids, picker = { 65, 132, 135, 141, 142, 155 }, nil
    env.C_QuestLog.GetNumQuestLogEntries = function() return #ids end
    env.C_QuestLog.GetInfo = function(i) return {questID = ids[i]} end
    env.C_QuestLog.GetLogIndexForQuestID = function(id)
        for i, candidate in ipairs(ids) do if candidate == id then return i end end
        return 0
    end
    local function widget()
        return setmetatable({}, { __index = function(_, key)
            if key == "SetScript" then return function(self, script, fn) self[script] = fn end end
            if key == "SetText" then return function(self, value) self.text = value end end
            if key == "SetShown" then return function(self, on) self.shown = on end end
            if key == "SetKind" then return function(self, value) self.kind = value end end
            if key:match("^[A-Z]") then return noop end
        end })
    end
    ns.UI.Window = function()
        picker = widget()
        picker.TitleText, picker.CloseButton = widget(), widget()
        return picker
    end
    ns.UI.Button = function() local b = widget(); b.label = widget(); return b end
    local control = ns.MakeHostButton(widget())
    ns.PaintHostButton(control)
    assert(control.text == "Host LFG")
    control.OnClick()
    assert(not ns.HostedQuest() and picker.rows[5].id == 142 and picker.next.shown)
    picker.next.OnClick()
    assert(picker.rows[1].id == 155 and not picker.rows[2].shown and picker.prev.shown)
    env.C_QuestLog.IsComplete = function(id) return id == 155 end
    picker.rows[1]:OnClick()
    assert(not ns.HostedQuest())
    ids = { 155, 170 }
    control.OnClick()
    local hosted, context = ns.PaintHostButton(control)
    assert(hosted == 170 and context == "A New Threat" and control.text == "Stop hosting")
    control.OnClick()
    assert(not ns.HostedQuest())
end)

case("dungeon boards accept both old beacons and reserved seats", function(ns)
    ns.OnDungeonBeacon("Tank", 721, 31, "H", "HD", "test", "WARRIOR", 4, 1)
    ns.OnDungeonBeacon("Healer", 721, 31, "H", "D", "legacy", "PRIEST", 2)
    for _, d in ipairs(ns.DungeonList()) do
        if d.id == 721 then
            assert(d.hosts[1].members == 4 and d.hosts[1].pending == 1 and d.hosts[2].pending == 0)
            return
        end
    end
    error("missing dungeon")
end)

case("translated objectives keep guidance after one objective is finished", function(ns, env)
    env.C_QuestLog.GetQuestObjectives = function() return {
        { text = "Felsenkiefertrogg getötet: 6/6", finished = true },
        { text = "Kräftiger Felsenkiefertrogg getötet: 0/6", finished = false },
    } end
    assert(#ns.ObjectiveSpots(170) > 0, "selected quest lost its spots")
    assert(#ns.ObjectiveSpots(170, 2) > 0, "first open objective lost its spots")
    assert(#ns.ObjectiveSpots(170, 1) == 0, "finished objective still has spots")
end)

case("a quest-wide fallback skips spots named by a finished objective", function(ns, env)
    env.C_QuestLog.GetQuestObjectives = function() return {
        { text = "Rockjaw Trogg slain: 6/6", finished = true },
        { text = "Something unrelated: 0/1", finished = false },
    } end
    local spots = ns.ObjectiveSpots(170)
    assert(#spots > 0)
    for _, spot in ipairs(spots) do assert(spot.name ~= "Rockjaw Trogg", "suggested a finished objective") end
end)

case("stopping a quick host keeps a search the player started earlier", function(ns, env)
    env.C_QuestLog.GetLogIndexForQuestID = function(id) return id == 170 and 1 or 0 end
    env.C_SuperTrack = { GetSuperTrackedQuestID = function() return 170 end }
    env.C_QuestLog.GetQuestObjectives = function() return {{ finished = false }} end
    ns.Start(170)
    ns.ToggleQuestHost()
    assert(ns.HostedQuest() == 170)
    env.now = env.now + 5
    ns.ToggleQuestHost()
    assert(not ns.HostedQuest() and ns.IsSearching(170), "the earlier search ended with the listing")
    assert(env.messages[#env.messages]:find("|170|31|0|0|0|0|0|", 1, true), "listing was not withdrawn")
end)

case("a German client sees the newer feature strings translated", function()
    GetLocale = function() return "deDE" end
    local ok, ns = pcall(client)
    GetLocale = nil
    assert(ok, ns)
    assert(ns.L["Reward Hunting"] == "Belohnungsjagd" and ns.L["Hosting stopped"] == "Gruppenleitung beendet")
    assert(ns.L["%d in log · %d ready to pick up"]:find("Questlog", 1, true))
end)

-- Starter guides: a level 1 Human Warrior standing in Northshire. env.log holds the quests in the log
-- ({ ready = true } once its objectives are done) and env.done the quests already turned in.
local function guideFixture(ns, env)
    env.QuestynatorDB.arrow = false
    env.level = 1
    env.map = ns.UiMapForArea(12)
    env.C_Map = {
        GetBestMapForUnit = function() return env.map end,
        GetMapInfo = function() return { mapType = 3 } end,
        GetWorldPosFromMapPos = function(_, pos) return 1, { x = pos.x * 1000, y = pos.y * 1000 } end,
        GetPlayerMapPosition = function() return { x = 0.48, y = 0.43 } end,
    }
    env.UnitPosition = function() return 482, 429, 0, 1 end      -- next to Deputy Willem
    env.CreateVector2D = function(x, y) return { x = x, y = y } end
    env.log, env.done = {}, {}
    local log = env.C_QuestLog
    log.GetLogIndexForQuestID = function(id) return env.log[id] and 1 or 0 end
    log.ReadyForTurnIn = function(id) return env.log[id] ~= nil and env.log[id].ready == true end
    log.IsComplete = log.ReadyForTurnIn
    log.IsQuestFlaggedCompleted = function(id) return env.done[id] == true end
    log.GetQuestObjectives = function(id)
        local q = env.log[id]
        return q and not q.ready and { { text = "objective", finished = false, numFulfilled = 0, numRequired = 1 } } or {}
    end
end

local function questSet(tasks)
    local set = {}
    for _, task in ipairs(tasks or {}) do set[task.questID] = true end
    return set
end

case("every starter guide step names a known quest, and turn-ins follow their pickup", function(ns)
    local D, kinds = ns.QDATA, { accept = true, complete = true, turnin = true }
    assert(#ns.STARTER_GUIDES == 7)
    for _, guide in ipairs(ns.STARTER_GUIDES) do
        assert(ns.UiMapForArea(guide.area), guide.id .. ": unknown area")
        local accepted = {}
        for _, trip in ipairs(guide.trips) do
            assert(type(trip[1]) == "string" and #trip > 1, guide.id .. ": trip without a name or steps")
            for i = 2, #trip do
                local step = trip[i]
                local where = guide.id .. " " .. tostring(step[1]) .. " " .. tostring(step[2])
                assert(kinds[step[1]] and (D.q[step[2]] or D.h[step[2]]), where .. ": unknown quest")
                assert(not step.at or ns.UiMapForArea(step.at[1]), where .. ": unknown place")
                if step[1] == "accept" then accepted[step[2]] = true
                else assert(accepted[step[2]], where .. ": no pickup before it") end
            end
        end
    end
end)

case("the Northshire guide leads a new Human Warrior step by step", function(ns, env)
    guideFixture(ns, env)
    ns.Waypoint = function() error("starting the guide placed a map pin") end
    ns.SetGuide("northshire")
    local kind, label = ns.RouteMode()
    assert(kind == "guide" and label == "Guide: Northshire · trip 1 of 10", label)
    assert(ns.RouteTarget().name == "Deputy Willem" and ns.RouteStopSummary().kind == "pickup")
    env.log[783] = { ready = true }
    ns.PlanRoute()
    assert(ns.RouteTarget().name == "Marshal McBride" and ns.RouteStopSummary().kind == "turnin")
    env.log[783], env.done[783] = nil, true
    local tasks, trip = ns.GuideTasks(ns.ActiveGuide())
    local set = questSet(tasks)
    assert(trip == 1 and set[7] and set[5261] and set[33] and #tasks == 3)
    -- the first two trips done: trip 3 offers this class's letter only, and holds Brotherhood of Thieves for level 2
    for _, id in ipairs({ 7, 5261, 33, 91741, 92124 }) do env.done[id] = true end
    tasks, trip = ns.GuideTasks(ns.ActiveGuide())
    set = questSet(tasks)
    assert(trip == 3 and set[91743] and set[15] and set[3100], "trip " .. tostring(trip))
    assert(not set[3101] and not set[3105] and not set[1598] and not set[18])
    env.level = 2
    assert(questSet(ns.GuideTasks(ns.ActiveGuide()))[18])
end)

case("the planner names a running guide and shows its trips as segments", function(ns, env)
    guideFixture(ns, env)
    fakeUI(env)
    ns.SetGuide("northshire")
    ns.ShowPlanner(true)
    local p = env.QuestynatorPlanner
    assert(p.mode.text == "Guide · Northshire" and p.stopMode.shown, tostring(p.mode.text))
    local lit = 0
    for _, seg in ipairs(p.segs) do if seg.shown then lit = lit + 1 end end
    assert(lit == 10, lit .. " segments for 10 trips")
    assert(p.card.title.text == "A Threat Within" and p.card.badge.glyph.text == "!" and not p.card.snooze.shown)
    p.stopMode:OnClick()
    ns.RefreshPlanner()
    assert(not p.mode.shown and not p.segs[1].shown, "the guide's bar stayed after Stop")
    assert(p.guides.shown and p.guides.text == "Guides", "no Guides button for a level 1 character")
    p.guides:OnClick()
    assert(env.find("Start guide: Northshire"), "Guides didn't open the starter guides")
    env.level = 11
    ns.RefreshPlanner()
    assert(not p.guides.shown, "Guides still shown past level 10")
end)

case("a guide waits for the level a step needs, then ends and hands over to the planner", function(ns, env)
    guideFixture(ns, env)
    local test = { id = "test", name = "Test", area = 12, trips = { { "Abbey", { "accept", 18 } } } }
    table.insert(ns.STARTER_GUIDES, test)
    env.done[783] = true
    ns.SetGuide("test")
    assert(ns.RouteMode() == "guide" and not ns.RouteTarget())
    local tasks, _, why = ns.GuideTasks(test)
    assert(#tasks == 0 and why == "Reach level 2 for Brotherhood of Thieves", why)
    env.done[18] = true
    ns.PlanRoute()
    assert(not ns.ActiveGuide() and env.QuestynatorGuide.finished == "test" and ns.RouteMode() ~= "guide")
end)

case("a starter guide with a full log waits without repeatedly scheduling replans", function(ns, env)
    guideFixture(ns, env)
    env.C_QuestLog.IsQuestLogFull = function() return true end
    local nextFrame = {}
    env.C_Timer.After = function(delay, fn)
        if delay == 0 then nextFrame[#nextFrame + 1] = fn end
    end
    ns.SetGuide("northshire")
    for _ = 1, 8 do
        if #nextFrame == 0 then break end
        local pending = nextFrame
        nextFrame = {}
        for _, fn in ipairs(pending) do fn() end
    end
    assert(#nextFrame == 0, "still scheduling next-frame work with no quest or player state change")
    assert(ns.ActiveGuide() and not ns.RouteTarget(), "guide offered a pickup with a full log")
    env.C_QuestLog.IsQuestLogFull = function() return false end
    ns.PlanRoute()
    assert(ns.RouteTarget() and ns.RouteTarget().questID == 783, "pickup did not resume")
end)

case("an item-started guide quest sends you to the mobs that drop it", function(ns, env)
    guideFixture(ns, env)
    table.insert(ns.STARTER_GUIDES, { id = "loot", name = "Loot", area = 12, trips = { { "Camp", { "accept", 91741 } } } })
    ns.SetGuide("loot")
    assert(ns.RouteStopSummary().kind == "pickup")
    local lines = {}
    ns.AddRouteTooltip({ AddLine = function(_, text) lines[#lines + 1] = text end, AddDoubleLine = noop })
    assert(lines[2] and lines[2]:find("^Loot Nibbled%-On Book from Kobold"), tostring(lines[2]))
    env.log[91741] = {}
    ns.UpdateRoute()
    assert(not ns.RouteTarget())
end)

case("one route mode at a time: a guide and a reward pursuit replace each other, Stop ends the guide", function(ns, env)
    guideFixture(ns, env)
    ns.Waypoint = function() error("starting a route mode placed a map pin") end
    ns.SetGuide("northshire")
    ns.SetRewardPursuit(2041)
    ns.SetDungeonPrepRoute(796)                 -- (prep keeps the saved pursuit to resume after it)
    ns.SetDungeonPrepRoute(nil)
    ns.SetRewardPursuit(2041)
    assert(not ns.ActiveGuide() and ns.RouteMode() == "reward")
    ns.SetGuide("northshire")
    assert(not env.QuestynatorRewardGoal and ns.RouteMode() == "guide")
    ns.StopRouteMode()
    assert(not ns.ActiveGuide() and not ns.RouteMode())
end)

case("race-only guide steps are skipped for other races", function(ns, env)
    guideFixture(ns, env)
    env.level = 2
    local test = { id = "sky", name = "Sky", area = 16593, trips = { { "Camp", { "accept", 92474, race = "Skyborne" } } } }
    table.insert(ns.STARTER_GUIDES, test)
    env.QuestynatorGuide = { active = "sky" }
    assert(ns.GuideTasks(test) == nil)
    env.UnitRace = function() return "Skyborne", "Skyborne", 95 end
    env.QuestynatorGuide = { active = "sky" }
    assert(questSet(ns.GuideTasks(test))[92474])
end)

case("a new character is offered the guide for its valley once", function(ns, env)
    guideFixture(ns, env)
    fakeUI(env)
    local later = {}
    env.C_Timer.After = function(_, fn) later[#later + 1] = fn end
    local function run() local list = later; later = {}; for _, fn in ipairs(list) do fn() end end
    env.QuestynatorPinChoice = { IsShown = function() return true end }     -- the WaypointUI question is up
    ns.GuideWorldEntry()
    run(); run()
    assert(not env.find("Start guide: Northshire"), "the guide offer opened on top of the WaypointUI question")
    env.QuestynatorPinChoice = nil                                          -- answered (it reloads)
    run()
    assert(env.find("Start guide: Northshire"), "no guide offer after the WaypointUI question closed")
    assert(not env.QuestynatorGuide.offered, "counted as answered while still open: a reload would lose it")
    env.C_Timer.After = function(_, fn) fn() end
    local start = env.find("Start guide: Northshire")
    assert(start and env.find("Coldridge Valley") and not env.find("Valley of Trials") and env.find("Zephras Isle"))
    start:OnClick()
    assert(ns.ActiveGuide().id == "northshire" and ns.RouteMode() == "guide")
    ns.SetGuide(nil)
    start.shown = false
    ns.GuideWorldEntry()
    assert(not env.find("Start guide: Northshire"), "offered twice")
end)

case("a character past level 2 is not offered a guide on login", function(ns, env)
    guideFixture(ns, env)
    fakeUI(env)
    env.C_Timer.After = function(_, fn) fn() end
    env.level = 5
    ns.GuideWorldEntry()
    assert(not env.find("Start guide") and not (env.QuestynatorGuide and env.QuestynatorGuide.offered))
end)

print(string.format("%d passed, %d failed", passed, failed))
if failed > 0 then os.exit(1) end
