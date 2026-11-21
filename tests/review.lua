-- Run from the addon directory with Lua 5.1: lua tests/review.lua
-- Each case loads the installed addon code in a fresh simulated client.
local passed, failed = 0, 0
local function noop() end

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
    for _, path in ipairs({ "Data/QuestData.lua", "Data/JournalPickups.lua", "Data/RewardCatalog.lua",
                            "Questynator.lua", "RewardHunting.lua", "DungeonPrep.lua", "SmartReminders.lua" }) do
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
        { questID = 1, name = "A", giver = "First", area = 40, x = 2, y = 2 },
        { questID = 2, name = "B", giver = "Neighbor", area = 40, x = 3, y = 2 },
        { questID = 3, name = "C", giver = "Second", area = 40, x = 16, y = 2 },
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

local function prepRow(ns, final)
    for _, row in ipairs(ns.DungeonPrepRows(796)) do
        if row.final == final then return row end
    end
end

case("Scarlet Monastery shows this warrior's pickups and the first unfinished prerequisite", function(ns, env)
    assert(ns.HasDungeonPrep(796) and not ns.HasDungeonPrep(721))
    assert(#ns.DungeonPrepRows(796) == 2)
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
    assert(not fresh.NextSmartReminder())
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

print(string.format("%d passed, %d failed", passed, failed))
if failed > 0 then os.exit(1) end
