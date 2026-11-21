-- Questynator
-- Copyright (C) 2026 Ashot. Licensed under the GNU GPL v3 or later (see LICENSE).
-- Adds an "LFG" button to each quest in the objective tracker. Clicking it
-- broadcasts "I'm on quest X" over a hidden addon channel, listens for other
-- Questynator users on the same quest, then invites / accepts invites to form a party.
--
-- Matching rules (no server needed, every client reaches the same decision):
--   * Beacons: "S|questID|level|state"   state 0 = solo, 1 = in group, 2 = group leader
--   * If a group leader is seeking the same quest, they invite solo seekers.
--   * Otherwise the solo seeker with the lowest Name-Realm hosts and invites the rest.
--   * Invites from a peer we matched with are auto-accepted (toggle: /qn auto).

local ADDON_NAME, ns = ...

---------------------------------------------------------------------------
-- localization: English text is the key; missing translations fall back to English
---------------------------------------------------------------------------
local L = setmetatable({}, { __index = function(_, k) return k end })
ns.L = L
function ns.ApplyLocale(code)
    for k in pairs(L) do L[k] = nil end
    local t = ns.LOCALES and (ns.LOCALES[code] or (code == "esMX" and ns.LOCALES.esES))
    if t then for k, v in pairs(t) do L[k] = v end end
end

---------------------------------------------------------------------------
-- translations (deDE, frFR, esES/esMX, ruRU). Native speakers: corrections welcome!
---------------------------------------------------------------------------
ns.LOCALES = {
deDE = {
    ["%d dungeon quest pickups are available."] = "%d Dungeonquests können angenommen werden.",
    ["%d in log · %d ready to pick up"] = "%d im Questlog · %d annehmbar",
    ["%d of %d quests complete"] = "%d von %d Quests erledigt",
    ["%d pending"] = "%d ausstehend",
    ["%d yd"] = "%d m",
    ["%d yd away"] = "%d m entfernt",
    ["%s can share %s."] = "%s kann %s teilen.",
    ["%s can share this quest."] = "%s kann diese Quest teilen.",
    ["%s is recruiting for %s (%d/5)."] = "%s sucht Mitspieler für %s (%d/5).",
    ["All weapon types"] = "Alle Waffentypen",
    ["Area %d"] = "Gebiet %d",
    ["Armor (%s)"] = "Rüstung (%s)",
    ["Choice of reward"] = "Belohnung nach Wahl",
    ["Choose All weapon types to see the other matching weapons."] = "Wähle „Alle Waffentypen“, um die übrigen passenden Waffen zu sehen.",
    ["Choose a quest to host"] = "Quest für deine Gruppe wählen",
    ["Choose an unfinished quest in your log."] = "Wähle eine unerledigte Quest aus deinem Questlog.",
    ["Closest to earning"] = "Am nächsten dran",
    ["Could you share %s?"] = "Kannst du %s teilen?",
    ["Current zone unavailable"] = "Aktuelles Gebiet nicht verfügbar",
    ["Dungeon Prep"] = "Dungeon-Vorbereitung",
    ["Dungeon pickups snoozed"] = "Dungeonquests ausgelassen",
    ["From your quest log"] = "Aus deinem Questlog",
    ["Guaranteed reward"] = "Feste Belohnung",
    ["Host LFG"] = "Gruppe leiten",
    ["Host a group for %s."] = "Eine Gruppe für %s leiten.",
    ["Hosting requires a free party slot and group leadership."] = "Zum Leiten brauchst du einen freien Gruppenplatz und die Gruppenführung.",
    ["Hosting stopped"] = "Gruppenleitung beendet",
    ["Hosting: %s"] = "Du leitest: %s",
    ["Later"] = "Später",
    ["Later (30 min)"] = "Später (30 Min.)",
    ["Less"] = "Weniger",
    ["Loading reward items…"] = "Belohnungen werden geladen…",
    ["Location unknown"] = "Ort unbekannt",
    ["Mark on map"] = "Auf Karte markieren",
    ["More"] = "Mehr",
    ["Next"] = "Weiter",
    ["No eligible pickups or known quest stops in this zone."] = "Keine annehmbaren Quests oder bekannten Queststopps in diesem Gebiet.",
    ["No matching rewards"] = "Keine passenden Belohnungen",
    ["No matching rewards in this zone"] = "Keine passenden Belohnungen in diesem Gebiet",
    ["No matching weapons of this type"] = "Keine passenden Waffen dieses Typs",
    ["No other stops found. Undo snooze to restore a stop."] = "Keine weiteren Stopps gefunden. Nimm das Auslassen zurück, um einen Stopp wiederherzustellen.",
    ["No quest stops found in this zone"] = "Keine Queststopps in diesem Gebiet",
    ["No remaining prep quests for your character."] = "Keine offenen Vorbereitungsquests für deinen Charakter.",
    ["Pause"] = "Pause",
    ["Pending"] = "Ausstehend",
    ["Pick up"] = "Annehmen",
    ["Pick up %s from %s"] = "%s bei %s annehmen",
    ["Pickup location unknown"] = "Annahmeort unbekannt",
    ["Plan My Route"] = "Route planen",
    ["Prep"] = "Vorb.",
    ["Prerequisite required"] = "Vorquest erforderlich",
    ["Prerequisites left: %d. Next: %s"] = "Offene Vorquests: %d. Nächste: %s",
    ["Previous"] = "Zurück",
    ["Pursue Reward"] = "Belohnung verfolgen",
    ["Pursuing"] = "Wird verfolgt",
    ["Quest follow-up"] = "Folgequest",
    ["Quest group"] = "Questgruppe",
    ["Quest log full"] = "Questlog voll",
    ["Quest reward"] = "Questbelohnung",
    ["Ready to claim"] = "Abholbereit",
    ["Ready to turn in"] = "Bereit zur Abgabe",
    ["Replan"] = "Neu planen",
    ["Request invite"] = "Einladung anfragen",
    ["Request share"] = "Teilen anfragen",
    ["Requires leadership and a free slot"] = "Erfordert Gruppenführung und einen freien Platz",
    ["Requires level %d"] = "Benötigt Stufe %d",
    ["Resume"] = "Fortsetzen",
    ["Reward Hunting"] = "Belohnungsjagd",
    ["Rewards"] = "Belohnungen",
    ["Route ended"] = "Route beendet",
    ["Route paused"] = "Route pausiert",
    ["Route stop %d"] = "Routenstopp %d",
    ["Route to missing pickups"] = "Route zu fehlenden Quests",
    ["Route to pickups"] = "Route zu den Quests",
    ["Search item, slot or quest"] = "Gegenstand, Platz oder Quest suchen",
    ["Show or hide Dungeon Prep"] = "Dungeon-Vorbereitung ein- oder ausblenden",
    ["Showing unfinished reward quests for your level and equipment proficiencies."] = "Angezeigt werden unerledigte Belohnungsquests für deine Stufe und deine Ausrüstungskenntnisse.",
    ["Speak to %s"] = "Sprich mit %s",
    ["Still to pick up: %s"] = "Noch anzunehmen: %s",
    ["Stop %d of %d"] = "Stopp %d von %d",
    ["Stop hosting"] = "Leitung beenden",
    ["Stop hosting %s."] = "Gruppenleitung für %s beenden.",
    ["Stop prep route"] = "Vorbereitungsroute beenden",
    ["Stop pursuit"] = "Verfolgung beenden",
    ["Turn in"] = "Abgeben",
    ["Turn in %s"] = "%s abgeben",
    ["Turn in %s to %s."] = "Gib %s bei %s ab.",
    ["Turn in at %s"] = "Abgabe bei %s",
    ["Undo"] = "Zurück",
    ["Up next: %s"] = "Danach: %s",
    ["Waiting for invited players."] = "Warte auf eingeladene Spieler.",
    ["Waiting for item details from the game."] = "Warte auf Gegenstandsdaten vom Spiel.",
    ["Waiting for quest and map data"] = "Warte auf Quest- und Kartendaten",
    ["stop all quest searches"] = "alle Questsuchen stoppen",
    ["Cloth"] = "Stoff",
    ["Leather"] = "Leder",
    ["Mail"] = "Kette",
    ["Plate"] = "Platte",
    ["Pin pickup"] = "Annahme markieren",
    ["Pin objective"] = "Ziel markieren",
    ["Pin turn-in"] = "Abgabe markieren",
    ["Pin stop"] = "Stopp markieren",
    ["Snooze stop"] = "Stopp auslassen",
    ["Undo snooze"] = "Zurücknehmen",
    ["Hide this stop until you leave the zone."] = "Diesen Stopp bis zum Verlassen des Gebiets ausblenden.",
    ["Quests remaining: %d"] = "Verbleibende Quests: %d",
    ["Selected quest"] = "Ausgewählte Quest",
    ["Up next when you resume"] = "Danach auf deiner Route",
    ["Resume route"] = "Route fortsetzen",
    ["No matching weapons in this zone"] = "Keine passenden Waffen in diesem Gebiet",
    ["Search all zones"] = "Alle Gebiete durchsuchen",
    ["Search all zones (%d)"] = "Alle Gebiete durchsuchen (%d)",
    ["Show 1 weapon in other zones"] = "1 Waffe in anderen Gebieten anzeigen",
    ["Show %d weapons in other zones"] = "%d Waffen in anderen Gebieten anzeigen",
    ["Show 1 reward in other zones"] = "1 Belohnung in anderen Gebieten anzeigen",
    ["Show %d rewards in other zones"] = "%d Belohnungen in anderen Gebieten anzeigen",
    ["Show Route Planner"] = "Routenplaner anzeigen",
    ["Treasures"] = "Schätze",
    ["%d-slot bag"] = "Tasche mit %d Plätzen",
    ["%d / %d collected"] = "%d / %d gesammelt",
    ["choice of reward"] = "Belohnung zur Wahl",
    ["+3% XP while you rest"] = "+3 % EP nach dem Ausruhen",
    ["Step %d of %d: %s"] = "Schritt %d von %d: %s",
    ["Waypoint"] = "Wegpunkt",
    ["In your log"] = "Im Questlog",
    ["Not yet"] = "Noch nicht",
    ["Collected"] = "Erhalten",
    ["Stats, top helpers, about and settings"] = "Statistik, Top-Helfer, Info und Einstellungen",
    ["Zones"] = "Gebiete",
    ["Nothing new to pick up"] = "Nichts Neues anzunehmen",
    ["You've done every quest for your level that we know of. Check your quest log, or try a dungeon."] = "Du hast alle uns bekannten Quests für deine Stufe erledigt. Schau in dein Questlog oder probier einen Dungeon.",
    ["Click to set a waypoint"] = "Klicken für einen Wegpunkt",
    ["Level %d  ·  %d quests to pick up in %d zones"] = "Stufe %d  ·  %d Quests in %d Gebieten anzunehmen",
    ["%d to pick up"] = "%d anzunehmen",
    ["Chain · %d quests"] = "Kette · %d Quests",
    ["No guide for this quest yet."] = "Noch keine Anleitung für diese Quest.",
    ["Quest arrow is off because you use %s. Turn it on with /qn arrow or in Interface > AddOns > Questynator."] = "Der Questpfeil ist aus, weil du %s nutzt. Einschalten mit /qn arrow oder unter Interface > AddOns > Questynator.",
    ["Quest arrow turned off. Turn it back on with /qn arrow or in Interface > AddOns > Questynator."] = "Questpfeil ausgeschaltet. Wieder einschalten mit /qn arrow oder unter Interface > AddOns > Questynator.",
    ["Hide until next quest"] = "Bis zur nächsten Quest ausblenden",
    ["Turn off the arrow"] = "Pfeil ausschalten",
    ["What's new in Questynator"] = "Neu in Questynator",
    ["Don't show until next update"] = "Bis zum nächsten Update nicht anzeigen",
    ["Got it"] = "Verstanden",
    ["Features"] = "Funktionen",
    ["Interface"] = "Oberfläche",
    ["Shortcuts"] = "Schnellzugriff",
    ["Open Questynator"] = "Questynator öffnen",
    ["Thank your party"] = "Gruppe danken",
    ["What's new"] = "Neuigkeiten",
    ["Directions arrow (quest compass)"] = "Richtungspfeil (Questkompass)",
    ["Party chat messages (objectives done, quest completed)"] = "Gruppenchat-Meldungen (Ziele erledigt, Quest abgeschlossen)",
    ["Auto-accept invites from matched players"] = "Einladungen von passenden Spielern automatisch annehmen",
    ["Chat scanner (find players looking for groups in chat)"] = "Chat-Scanner (Spieler im Chat finden, die Gruppen suchen)",
    ["Minimap button"] = "Minimap-Knopf",
    ["Sound alerts"] = "Tonsignale",
    ["Quest arrow"] = "Questpfeil",
    ["Points to your next turn-in, or to the next objective of the quest you select in the tracker."] = "Zeigt auf deine nächste Abgabe oder auf das nächste Ziel der Quest, die du im Tracker auswählst.",
    ["Drag to move"] = "Ziehen zum Verschieben",
    ["Right-click to hide it or turn it off"] = "Rechtsklick zum Ausblenden oder Ausschalten",
    ["Settings"] = "Einstellungen",
    ["Party messages"] = "Gruppenmeldungen",
    ["Sound"] = "Ton",
    ["All options"] = "Alle Optionen",
    ["On your quests"] = "Auf deinen Quests",
    ["Not in log"] = "Nicht im Log",
    ["Find group"] = "Gruppe suchen",
    ["Lvl %d"] = "Stufe %d",
    ["Lvl %d-%d"] = "Stufe %d-%d",
    ["You"] = "Du",
    ["Full"] = "Voll",
    ["Too low"] = "Zu niedrig",
    ["Too high"] = "Zu hoch",
    ["In a group"] = "In Gruppe",
    ["Open groups"] = "Offene Gruppen",
    ["Your roles"] = "Deine Rollen",
    ["Hosting"] = "Leitest",
    ["Looking"] = "Suchst",
    ["Click to whisper"] = "Klicken zum Flüstern",
    ["Users online"] = "Nutzer online",
    ["Quests together"] = "Quests zusammen",
    ["Groups formed"] = "Gruppen gebildet",
    ["Your kudos %d"] = "Dein Kudos %d",
    ["Made by %s"] = "Von %s",
    ["Bugs & ideas: CurseForge"] = "Bugs & Ideen: CurseForge",
    ["No one nearby yet"] = "Noch niemand in der Nähe",
    ["Questynator pings you when players near you are on your quests."] = "Questynator meldet sich, wenn Spieler in deiner Nähe deine Quests machen.",
    ["Find group for a quest"] = "Gruppe für eine Quest suchen",
    ["No open groups right now"] = "Gerade keine offenen Gruppen",
    ["Groups created with Questynator show up here."] = "Mit Questynator erstellte Gruppen erscheinen hier.",
    ["%d search"] = "%d Suche",
    ["%d searches"] = "%d Suchen",
    ["Search quests"] = "Quests suchen",
    ["%d users online"] = "%d Nutzer online",
    ["Level up!"] = "Stufenaufstieg!",
    ["Max level"] = "Höchststufe",
    ["Enough to level up!"] = "Genug für den Stufenaufstieg!",
    ["quests +%s XP"] = "Quests +%s EP",
    ["XP to next level:"] = "EP bis zur nächsten Stufe:",
    ["XP from your quests:"] = "EP aus deinen Quests:",
    ["Turning in all your quests levels you up."] = "Wenn du alle Quests abgibst, steigst du eine Stufe auf.",
    ["Still needed after quests:"] = "Danach noch benötigt:",
    ["Objective:"] = "Ziel:",
    ["How to do it"] = "So geht's",
    ["Kill %s"] = "Töte %s",
    ["Loot %s from %s"] = "Erbeute %s von %s",
    ["Collect %s"] = "Sammle %s",
    ["Use %s"] = "Benutze %s",
    ["Turn in to %s"] = "Abgeben bei %s",
    ["(Elite)"] = "(Elite)",
    ["Tip:"] = "Tipp:",
    ["You're here"] = "Du bist da",
    ["Not available here"] = "Hier nicht verfügbar",
    ["Turn-in arrow"] = "Abgabe-Pfeil",
    ["Turn-in arrow: %s"] = "Abgabe-Pfeil: %s",
    ["Drag to move. Right-click to hide until the next quest is ready."] = "Ziehen zum Verschieben. Rechtsklick blendet ihn bis zur nächsten fertigen Quest aus.",
    ["Questynator: %s - all objectives done!"] = "Questynator: %s - alle Ziele erledigt!",
    ["Questynator: %s - quest completed!"] = "Questynator: %s - Quest abgeschlossen!",
    ["Party chat messages: %s"] = "Gruppenchat-Meldungen: %s",
    ["%s: now need %s. Click Post to General to update chat."] = "%s: jetzt gesucht: %s. Klicke auf In Allgemein posten, um den Chat zu aktualisieren.",
    ["%d groups"] = "%d Gruppen",
    ["%d kudos"] = "%d Kudos",
    ["%d looking"] = "%d suchen",
    ["%d players"] = "%d Spieler",
    ["%s thanked you! Kudos: %d"] = "%s hat sich bedankt! Kudos: %d",
    ["Click to change which roles your group still needs."] = "Klicken, um festzulegen, welche Rollen deiner Gruppe noch fehlen.",
    ["Click to set a waypoint"] = "Klicken für einen Wegpunkt",
    ["DPS"] = "DPS",
    ["Dungeon search stopped."] = "Dungeon-Suche beendet.",
    ["Dungeons"] = "Dungeons",
    ["Dungeons (%d)"] = "Dungeons (%d)",
    ["Form groups and finish quests together to get on the board."] = "Bilde Gruppen und schließe Quests gemeinsam ab, um auf die Liste zu kommen.",
    ["Group listed for %s. Players can whisper you + to join."] = "Gruppe für %s gelistet. Spieler können dir + flüstern, um beizutreten.",
    ["Healer"] = "Heiler",
    ["Host"] = "Anführen",
    ["Hosting %s"] = "Du leitest %s",
    ["List your group: players whisper you + and get invited."] = "Liste deine Gruppe: Spieler flüstern dir + und werden eingeladen.",
    ["Look"] = "Suchen",
    ["Look for a group for this dungeon with your roles."] = "Suche eine Gruppe für diesen Dungeon mit deinen Rollen.",
    ["Looking for %s"] = "Suche %s",
    ["Looking for a %s group as %s."] = "Suche eine Gruppe für %s als %s.",
    ["Map pin set: %s"] = "Kartenmarkierung gesetzt: %s",
    ["Need:"] = "Gesucht:",
    ["Next:"] = "Danach:",
    ["No dungeons for your level yet."] = "Noch keine Dungeons für deine Stufe.",
    ["Only the group leader can invite."] = "Nur der Gruppenleiter kann einladen.",
    ["Party:"] = "Gruppe:",
    ["Pick your roles, then Look for a group or Host one."] = "Wähle deine Rollen, dann suche eine Gruppe oder leite eine.",
    ["Popular near you"] = "Beliebt in deiner Nähe",
    ["Post to General"] = "In Allgemein posten",
    ["Quest done together! Thank your party? (+1 kudos each)"] = "Quest gemeinsam erledigt! Deiner Gruppe danken? (+1 Kudos für jeden)",
    ["Searching"] = "Suche läuft",
    ["Share quest"] = "Quest teilen",
    ["Shared with your party: %s"] = "Mit der Gruppe geteilt: %s",
    ["Tank"] = "Tank",
    ["This quest can't be shared."] = "Diese Quest kann nicht geteilt werden.",
    ["This quest isn't in your quest log."] = "Diese Quest ist nicht in deinem Questlog.",
    ["Time to level:"] = "Zeit bis Stufenaufstieg:",
    ["Top helpers this week"] = "Top-Helfer dieser Woche",
    ["Waypoint set: %s"] = "Wegpunkt gesetzt: %s",
    ["Waypoint to the entrance"] = "Wegpunkt zum Eingang",
    ["XP per hour:"] = "EP pro Stunde:",
    ["XP per hour: play a few minutes to measure it."] = "EP pro Stunde: spiele ein paar Minuten, um sie zu messen.",
    ["You thanked your party."] = "Du hast deiner Gruppe gedankt.",
    ["You're not in a party."] = "Du bist in keiner Gruppe.",
    ["Your kudos: %d"] = "Deine Kudos: %d",
    ["Your roles:"] = "Deine Rollen:",
    ["doesn't have it"] = "hat sie nicht",
    ["done"] = "fertig",
    ["has it"] = "hat sie",
    ["need"] = "gesucht:",
    ["you"] = "du",
    ["About"] = "Über",
    ["Made by %s"] = "Von %s",
    ["BattleTag: %s"] = "BattleTag: %s",
    ["Whisper %s"] = "%s anflüstern",
    ["Copy BattleTag"] = "BattleTag kopieren",
    ["Questynator author"] = "Questynator-Autor",
    ["Press Ctrl+C to copy it, then add it as a Battle.net friend."] = "Mit Strg+C kopieren und dann als Battle.net-Freund hinzufügen.",
    ["Bugs and ideas: comments on the Questynator page on CurseForge."] = "Fehler und Ideen: Kommentare auf der Questynator-Seite bei CurseForge.",
    ["Announcement"] = "Ankündigung",
    ["A newer Questynator (%s) is out. Update on CurseForge."] = "Ein neueres Questynator (%s) ist da. Aktualisiere es auf CurseForge.",
    ["Questynator admin %s asks for your debug info (version, settings, recent errors). Send it?"] = "Questynator-Admin %s bittet um deine Debug-Infos (Version, Einstellungen, letzte Fehler). Senden?",
    ["Elite enemies - bring a group."] = "Elitegegner – nimm eine Gruppe mit.",
    ["Group quest - %d players suggested."] = "Gruppenquest – %d Spieler empfohlen.",
    ["Enemies are up to level %d - harder than you."] = "Gegner bis Stufe %d – stärker als du.",
    ["Objectives done - go turn it in."] = "Ziele erledigt – jetzt abgeben.",
    ["Progress:"] = "Fortschritt:",
    ["Click to see how to complete this quest."] = "Klicken, um zu sehen, wie du diese Quest abschließt.",
    ["All quests:"] = "Alle Quests:",
    ["XP"] = "EP",
    ["rep"] = "Ruf",
    ["Rewards for completing all your quests"] = "Belohnungen für alle deine Quests",
    ["Experience"] = "Erfahrung",
    ["Money"] = "Geld",
    ["Reputation"] = "Ruf",
    ["Currencies"] = "Währungen",
    ["Groups"] = "Gruppen",
    ["Groups (%d)"] = "Gruppen (%d)",
    ["Join"] = "Beitreten",
    ["Your group"] = "Deine Gruppe",
    ["You have this quest"] = "Du hast diese Quest",
    ["%d/5 players"] = "%d/5 Spieler",
    ["This group is full."] = "Diese Gruppe ist voll.",
    ["Your level isn't in this group's level range."] = "Deine Stufe liegt nicht im Stufenbereich dieser Gruppe.",
    ["Leave your current group first."] = "Verlasse zuerst deine aktuelle Gruppe.",
    ["No groups right now. Groups created with Questynator show up here."] = "Gerade keine Gruppen. Mit Questynator erstellte Gruppen erscheinen hier.",
    ["Asked %s for an invite."] = "%s um eine Einladung gebeten.",
    ["their group"] = "ihre Gruppe",
    ["Quests"] = "Quests",
    ["Nearby"] = "In der Nähe",
    ["Nearby (%d)"] = "In der Nähe (%d)",
    ["Stats"] = "Statistik",
    ["No one nearby yet. Questynator will ping you."] = "Noch niemand in der Nähe. Questynator meldet sich.",
    ["via Questynator"] = "über Questynator",
    ["in chat"] = "im Chat",
    ["Level %d"] = "Stufe %d",
    ["Questynator users online"] = "Questynator-Nutzer online",
    ["Active searches"] = "Aktive Suchen",
    ["%d found"] = "%d gefunden",
    ["%s (%d min ago)"] = "%s (vor %d Min.)",
    ["%s is looking for:"] = "%s sucht:",
    ["(your realm and faction)"] = "(dein Realm und deine Fraktion)",
    ["Auto-accept invites from matched players: %s"] = "Einladungen passender Spieler automatisch annehmen: %s",
    ["Auto-invite players who whisper '+'"] = "Spieler, die '+' flüstern, automatisch einladen",
    ["Cancel"] = "Abbrechen",
    ["Chat (%d)"] = "Chat (%d)",
    ["Chat scanner: %s"] = "Chat-Scanner: %s",
    ["Click to find other Questynator players on this quest and open Questynator."] = "Klicken, um andere Questynator-Spieler für diese Quest zu finden und Questynator zu öffnen.",
    ["Complete - ready to turn in"] = "Abgeschlossen - bereit zur Abgabe",
    ["Couldn't hook the objective tracker; use /qn list and /qn find <questID>."] = "Zielverfolgung nicht gefunden; nutze /qn list und /qn find <questID>.",
    ["Create Group"] = "Gruppe erstellen",
    ["Dungeon"] = "Dungeon",
    ["Elite"] = "Elite",
    ["Find Group"] = "Gruppe suchen",
    ["Find other players on the same quest. Hover a quest for its objectives."] = "Finde Spieler mit derselben Quest. Fahre über eine Quest für ihre Ziele.",
    ["Group"] = "Gruppe",
    ["Group %d+"] = "Gruppe %d+",
    ["Group created for %s (levels %d-%d)."] = "Gruppe erstellt für %s (Stufe %d-%d).",
    ["Group listed"] = "Gruppe gelistet",
    ["Group quest: %s"] = "Gruppenquest: %s",
    ["Groups formed:"] = "Gebildete Gruppen:",
    ["Host a group: pick objectives and a level range, and post it to General chat."] = "Gruppe leiten: Ziele und Stufenbereich wählen und im Allgemein-Chat posten.",
    ["In chat: %d"] = "Im Chat: %d",
    ["Invite"] = "Einladen",
    ["Invited %s (whispered +) for: %s"] = "%s eingeladen (+ geflüstert) für: %s",
    ["Joined %s for: %s"] = "Gruppe von %s beigetreten für: %s",
    ["Keep Searching"] = "Weiter suchen",
    ["Keep looking for another %d seconds before asking again."] = "Noch %d Sekunden weitersuchen, bevor erneut gefragt wird.",
    ["Left-click:"] = "Linksklick:",
    ["Left-click: open Questynator"] = "Linksklick: Questynator öffnen",
    ["Look for other Questynator players on this quest."] = "Nach anderen Questynator-Spielern für diese Quest suchen.",
    ["Looking for players on: %s"] = "Suche Spieler für: %s",
    ["Looking in chat:"] = "Suchen im Chat:",
    ["Looking in chat: %d"] = "Suchen im Chat: %d",
    ["Minimap button hidden (/qn minimap to show)"] = "Minikarten-Button ausgeblendet (/qn minimap zum Anzeigen)",
    ["Minimap button shown"] = "Minikarten-Button angezeigt",
    ["No one found yet"] = "Noch niemand gefunden",
    ["Not searching"] = "Keine Suche",
    ["Objective %d"] = "Ziel %d",
    ["Objectives to do together:"] = "Gemeinsame Ziele:",
    ["Party formed."] = "Gruppe gebildet.",
    ["Player levels:"] = "Spielerstufen:",
    ["Players found:"] = "Gefundene Spieler:",
    ["Players found: %d"] = "Gefundene Spieler: %d",
    ["Players in chat are looking for this quest. Click to whisper or invite the latest one."] = "Spieler im Chat suchen diese Quest. Klicken, um den neuesten anzuflüstern oder einzuladen.",
    ["Post to General chat"] = "Im Allgemein-Chat posten",
    ["Post to General chat - you're not in it"] = "Im Allgemein-Chat posten - du bist nicht drin",
    ["Post your group to General chat again."] = "Gruppe erneut im Allgemein-Chat posten.",
    ["Posted to General chat (/%d)."] = "Im Allgemein-Chat gepostet (/%d).",
    ["Quests done with Questynator groups:"] = "Quests mit Questynator-Gruppen erledigt:",
    ["Questynator - player found in chat"] = "Questynator - Spieler im Chat gefunden",
    ["Questynator user"] = "Questynator-Nutzer",
    ["Questynator users online: %d"] = "Questynator-Nutzer online: %d",
    ["Raid"] = "Schlachtzug",
    ["Repost"] = "Erneut posten",
    ["Right-click:"] = "Rechtsklick:",
    ["Right-click: stop searching"] = "Rechtsklick: Suche beenden",
    ["Searching now"] = "Aktive Suchen",
    ["Searching quests: %d"] = "Gesuchte Quests: %d",
    ["Searching..."] = "Suche läuft...",
    ["Searching... players found: %d"] = "Suche läuft... gefundene Spieler: %d",
    ["Sound alerts: %s"] = "Tonsignale: %s",
    ["Still searching for: %s"] = "Suche weiter nach: %s",
    ["Stop"] = "Stopp",
    ["Stop all"] = "Alle stoppen",
    ["Stop searching for this quest."] = "Suche für diese Quest beenden.",
    ["That quest isn't in your log."] = "Diese Quest ist nicht in deinem Questlog.",
    ["Whisper"] = "Flüstern",
    ["You're not in General chat. Your message: %s"] = "Du bist nicht im Allgemein-Chat. Deine Nachricht: %s",
    ["Your quest log is empty."] = "Dein Questlog ist leer.",
    ["hover a quest for details"] = "über eine Quest fahren für Details",
    ["listed"] = "gelistet",
    ["off"] = "aus",
    ["on"] = "an",
    ["open Questynator"] = "Questynator öffnen",
    ["open Questynator from chat"] = "Questynator aus dem Chat öffnen",
    ["party is full"] = "Gruppe ist voll",
    ["quest is complete"] = "Quest ist abgeschlossen",
    ["quest left your log"] = "Quest nicht mehr im Log",
    ["search cancelled"] = "Suche abgebrochen",
    ["search timed out"] = "Suche abgelaufen",
    ["searching"] = "sucht",
    ["stop all searches"] = "alle Suchen beenden",
    ["to"] = "bis",
},
frFR = {
    ["%d dungeon quest pickups are available."] = "%d quêtes de donjon sont disponibles.",
    ["%d in log · %d ready to pick up"] = "%d dans le journal · %d à prendre",
    ["%d of %d quests complete"] = "%d quêtes terminées sur %d",
    ["%d pending"] = "%d en attente",
    ["%d yd"] = "%d m",
    ["%d yd away"] = "à %d m",
    ["%s can share %s."] = "%s peut partager %s.",
    ["%s can share this quest."] = "%s peut partager cette quête.",
    ["%s is recruiting for %s (%d/5)."] = "%s recrute pour %s (%d/5).",
    ["All weapon types"] = "Tous les types d’armes",
    ["Area %d"] = "Zone %d",
    ["Armor (%s)"] = "Armure (%s)",
    ["Choice of reward"] = "Récompense au choix",
    ["Choose All weapon types to see the other matching weapons."] = "Choisis Tous les types d’armes pour voir les autres armes correspondantes.",
    ["Choose a quest to host"] = "Choisis une quête à organiser",
    ["Choose an unfinished quest in your log."] = "Choisis une quête inachevée de ton journal.",
    ["Closest to earning"] = "Les plus proches",
    ["Could you share %s?"] = "Peux-tu partager %s ?",
    ["Current zone unavailable"] = "Zone actuelle indisponible",
    ["Dungeon Prep"] = "Préparation du donjon",
    ["Dungeon pickups snoozed"] = "Quêtes de donjon reportées",
    ["From your quest log"] = "Depuis ton journal",
    ["Guaranteed reward"] = "Récompense garantie",
    ["Host LFG"] = "Organiser",
    ["Host a group for %s."] = "Organiser un groupe pour %s.",
    ["Hosting requires a free party slot and group leadership."] = "Pour organiser, il faut une place libre et être chef de groupe.",
    ["Hosting stopped"] = "Organisation arrêtée",
    ["Hosting: %s"] = "Organisation : %s",
    ["Later"] = "Plus tard",
    ["Later (30 min)"] = "Plus tard (30 min)",
    ["Less"] = "Moins",
    ["Loading reward items…"] = "Chargement des récompenses…",
    ["Location unknown"] = "Lieu inconnu",
    ["Mark on map"] = "Marquer sur la carte",
    ["More"] = "Plus",
    ["Next"] = "Suivant",
    ["No eligible pickups or known quest stops in this zone."] = "Aucune quête à prendre ni étape connue dans cette zone.",
    ["No matching rewards"] = "Aucune récompense correspondante",
    ["No matching rewards in this zone"] = "Aucune récompense correspondante dans cette zone",
    ["No matching weapons of this type"] = "Aucune arme correspondante de ce type",
    ["No other stops found. Undo snooze to restore a stop."] = "Aucune autre étape. Annule le report pour en rétablir une.",
    ["No quest stops found in this zone"] = "Aucune étape de quête dans cette zone",
    ["No remaining prep quests for your character."] = "Plus aucune quête de préparation pour ton personnage.",
    ["Pause"] = "Pause",
    ["Pending"] = "En attente",
    ["Pick up"] = "Prendre",
    ["Pick up %s from %s"] = "Prendre %s auprès de %s",
    ["Pickup location unknown"] = "Lieu de départ inconnu",
    ["Plan My Route"] = "Planifier",
    ["Prep"] = "Prépa",
    ["Prerequisite required"] = "Prérequis nécessaire",
    ["Prerequisites left: %d. Next: %s"] = "Prérequis restants : %d. Suivant : %s",
    ["Previous"] = "Précédent",
    ["Pursue Reward"] = "Viser la récompense",
    ["Pursuing"] = "Visée",
    ["Quest follow-up"] = "Quête suivante",
    ["Quest group"] = "Groupe de quête",
    ["Quest log full"] = "Journal plein",
    ["Quest reward"] = "Récompense de quête",
    ["Ready to claim"] = "Prête à récupérer",
    ["Ready to turn in"] = "Prête à rendre",
    ["Replan"] = "Replanifier",
    ["Request invite"] = "Demander une invitation",
    ["Request share"] = "Demander partage",
    ["Requires leadership and a free slot"] = "Nécessite d’être chef et une place libre",
    ["Requires level %d"] = "Niveau %d requis",
    ["Resume"] = "Reprendre",
    ["Reward Hunting"] = "Chasse aux récompenses",
    ["Rewards"] = "Récompenses",
    ["Route ended"] = "Parcours terminé",
    ["Route paused"] = "Parcours en pause",
    ["Route stop %d"] = "Étape %d",
    ["Route to missing pickups"] = "Itinéraire des quêtes à prendre",
    ["Route to pickups"] = "Itinéraire des quêtes",
    ["Search item, slot or quest"] = "Chercher objet, emplacement ou quête",
    ["Show or hide Dungeon Prep"] = "Afficher ou masquer la préparation",
    ["Showing unfinished reward quests for your level and equipment proficiencies."] = "Quêtes à récompense inachevées pour ton niveau et tes compétences d’équipement.",
    ["Speak to %s"] = "Parler à %s",
    ["Still to pick up: %s"] = "Encore à prendre : %s",
    ["Stop %d of %d"] = "Étape %d sur %d",
    ["Stop hosting"] = "Arrêter",
    ["Stop hosting %s."] = "Arrêter d’organiser %s.",
    ["Stop prep route"] = "Arrêter l’itinéraire",
    ["Stop pursuit"] = "Arrêter la visée",
    ["Turn in"] = "Rendre",
    ["Turn in %s"] = "Rendre %s",
    ["Turn in %s to %s."] = "Rends %s à %s.",
    ["Turn in at %s"] = "À rendre auprès de %s",
    ["Undo"] = "Annuler",
    ["Up next: %s"] = "Ensuite : %s",
    ["Waiting for invited players."] = "En attente des joueurs invités.",
    ["Waiting for item details from the game."] = "En attente des détails des objets.",
    ["Waiting for quest and map data"] = "En attente des données de quêtes et de carte",
    ["stop all quest searches"] = "arrêter toutes les recherches de quêtes",
    ["Cloth"] = "Tissu",
    ["Leather"] = "Cuir",
    ["Mail"] = "Mailles",
    ["Plate"] = "Plaques",
    ["Pin pickup"] = "Épingler le départ",
    ["Pin objective"] = "Épingler l’objectif",
    ["Pin turn-in"] = "Épingler le rendu",
    ["Pin stop"] = "Épingler l’étape",
    ["Snooze stop"] = "Reporter l’étape",
    ["Undo snooze"] = "Annuler le report",
    ["Hide this stop until you leave the zone."] = "Masque cette étape jusqu’à la sortie de la zone.",
    ["Quests remaining: %d"] = "Quêtes restantes : %d",
    ["Selected quest"] = "Quête sélectionnée",
    ["Up next when you resume"] = "À la reprise du parcours",
    ["Resume route"] = "Reprendre",
    ["No matching weapons in this zone"] = "Aucune arme correspondante dans cette zone",
    ["Search all zones"] = "Chercher dans toutes les zones",
    ["Search all zones (%d)"] = "Chercher dans toutes les zones (%d)",
    ["Show 1 weapon in other zones"] = "Voir 1 arme dans les autres zones",
    ["Show %d weapons in other zones"] = "Voir %d armes dans les autres zones",
    ["Show 1 reward in other zones"] = "Voir 1 récompense dans les autres zones",
    ["Show %d rewards in other zones"] = "Voir %d récompenses dans les autres zones",
    ["Show Route Planner"] = "Afficher le planificateur d’itinéraire",
    ["Treasures"] = "Trésors",
    ["%d-slot bag"] = "Sac de %d places",
    ["%d / %d collected"] = "%d / %d obtenus",
    ["choice of reward"] = "récompense au choix",
    ["+3% XP while you rest"] = "+3 % d'XP après le repos",
    ["Step %d of %d: %s"] = "Étape %d sur %d : %s",
    ["Waypoint"] = "Point de passage",
    ["In your log"] = "Dans ton journal",
    ["Not yet"] = "Pas encore",
    ["Collected"] = "Obtenu",
    ["Stats, top helpers, about and settings"] = "Stats, meilleurs aides, infos et réglages",
    ["Zones"] = "Zones",
    ["Nothing new to pick up"] = "Rien de nouveau à prendre",
    ["You've done every quest for your level that we know of. Check your quest log, or try a dungeon."] = "Tu as fait toutes les quêtes connues pour ton niveau. Regarde ton journal ou essaie un donjon.",
    ["Click to set a waypoint"] = "Clique pour placer un point de passage",
    ["Level %d  ·  %d quests to pick up in %d zones"] = "Niveau %d  ·  %d quêtes à prendre dans %d zones",
    ["%d to pick up"] = "%d à prendre",
    ["Chain · %d quests"] = "Suite · %d quêtes",
    ["No guide for this quest yet."] = "Pas encore de guide pour cette quête.",
    ["Quest arrow is off because you use %s. Turn it on with /qn arrow or in Interface > AddOns > Questynator."] = "La flèche de quête est désactivée car tu utilises %s. Active-la avec /qn arrow ou dans Interface > AddOns > Questynator.",
    ["Quest arrow turned off. Turn it back on with /qn arrow or in Interface > AddOns > Questynator."] = "Flèche de quête désactivée. Réactive-la avec /qn arrow ou dans Interface > AddOns > Questynator.",
    ["Hide until next quest"] = "Masquer jusqu'à la prochaine quête",
    ["Turn off the arrow"] = "Désactiver la flèche",
    ["What's new in Questynator"] = "Nouveautés de Questynator",
    ["Don't show until next update"] = "Ne plus afficher avant la prochaine mise à jour",
    ["Got it"] = "Compris",
    ["Features"] = "Fonctions",
    ["Interface"] = "Interface",
    ["Shortcuts"] = "Raccourcis",
    ["Open Questynator"] = "Ouvrir Questynator",
    ["Thank your party"] = "Remercier le groupe",
    ["What's new"] = "Nouveautés",
    ["Directions arrow (quest compass)"] = "Flèche de direction (boussole de quête)",
    ["Party chat messages (objectives done, quest completed)"] = "Messages de groupe (objectifs terminés, quête terminée)",
    ["Auto-accept invites from matched players"] = "Accepter automatiquement les invitations des joueurs trouvés",
    ["Chat scanner (find players looking for groups in chat)"] = "Analyse du chat (trouver les joueurs qui cherchent un groupe)",
    ["Minimap button"] = "Bouton de la minicarte",
    ["Sound alerts"] = "Alertes sonores",
    ["Quest arrow"] = "Flèche de quête",
    ["Points to your next turn-in, or to the next objective of the quest you select in the tracker."] = "Indique ton prochain rendu, ou le prochain objectif de la quête choisie dans le suivi.",
    ["Drag to move"] = "Glisser pour déplacer",
    ["Right-click to hide it or turn it off"] = "Clic droit pour la masquer ou la désactiver",
    ["Settings"] = "Réglages",
    ["Party messages"] = "Groupe",
    ["Sound"] = "Son",
    ["All options"] = "Options",
    ["On your quests"] = "Sur tes quêtes",
    ["Not in log"] = "Pas dans le journal",
    ["Find group"] = "Chercher un groupe",
    ["Lvl %d"] = "Niv %d",
    ["Lvl %d-%d"] = "Niv %d-%d",
    ["You"] = "Toi",
    ["Full"] = "Complet",
    ["Too low"] = "Trop bas",
    ["Too high"] = "Trop haut",
    ["In a group"] = "En groupe",
    ["Open groups"] = "Groupes ouverts",
    ["Your roles"] = "Tes rôles",
    ["Hosting"] = "Tu organises",
    ["Looking"] = "Tu cherches",
    ["Click to whisper"] = "Clique pour chuchoter",
    ["Users online"] = "Utilisateurs en ligne",
    ["Quests together"] = "Quêtes ensemble",
    ["Groups formed"] = "Groupes formés",
    ["Your kudos %d"] = "Tes kudos %d",
    ["Made by %s"] = "Créé par %s",
    ["Bugs & ideas: CurseForge"] = "Bugs et idées : CurseForge",
    ["No one nearby yet"] = "Personne à proximité",
    ["Questynator pings you when players near you are on your quests."] = "Questynator te prévient quand des joueurs proches font tes quêtes.",
    ["Find group for a quest"] = "Chercher un groupe pour une quête",
    ["No open groups right now"] = "Aucun groupe ouvert pour l'instant",
    ["Groups created with Questynator show up here."] = "Les groupes créés avec Questynator apparaissent ici.",
    ["%d search"] = "%d recherche",
    ["%d searches"] = "%d recherches",
    ["Search quests"] = "Chercher une quête",
    ["%d users online"] = "%d utilisateurs en ligne",
    ["Level up!"] = "Niveau supérieur !",
    ["Max level"] = "Niveau maximum",
    ["Enough to level up!"] = "Assez pour monter de niveau !",
    ["quests +%s XP"] = "quêtes +%s XP",
    ["XP to next level:"] = "XP jusqu'au prochain niveau :",
    ["XP from your quests:"] = "XP de vos quêtes :",
    ["Turning in all your quests levels you up."] = "Rendre toutes vos quêtes vous fait monter de niveau.",
    ["Still needed after quests:"] = "Encore nécessaire après les quêtes :",
    ["Objective:"] = "Objectif :",
    ["How to do it"] = "Comment faire",
    ["Kill %s"] = "Tuez %s",
    ["Loot %s from %s"] = "Récupérez %s sur %s",
    ["Collect %s"] = "Ramassez %s",
    ["Use %s"] = "Utilisez %s",
    ["Turn in to %s"] = "Rendez la quête à %s",
    ["(Elite)"] = "(Élite)",
    ["Tip:"] = "Astuce :",
    ["You're here"] = "Vous y êtes",
    ["Not available here"] = "Indisponible ici",
    ["Turn-in arrow"] = "Flèche de rendu",
    ["Turn-in arrow: %s"] = "Flèche de rendu : %s",
    ["Drag to move. Right-click to hide until the next quest is ready."] = "Glissez pour déplacer. Clic droit pour masquer jusqu'à la prochaine quête terminée.",
    ["Questynator: %s - all objectives done!"] = "Questynator : %s - tous les objectifs sont faits !",
    ["Questynator: %s - quest completed!"] = "Questynator : %s - quête terminée !",
    ["Party chat messages: %s"] = "Messages dans le chat de groupe : %s",
    ["%s: now need %s. Click Post to General to update chat."] = "%s : il manque maintenant %s. Cliquez sur Publier dans Général pour mettre le chat à jour.",
    ["%d groups"] = "%d groupes",
    ["%d kudos"] = "%d kudos",
    ["%d looking"] = "%d cherchent",
    ["%d players"] = "%d joueurs",
    ["%s thanked you! Kudos: %d"] = "%s vous remercie ! Kudos : %d",
    ["Click to change which roles your group still needs."] = "Cliquez pour choisir les rôles qui manquent encore à votre groupe.",
    ["Click to set a waypoint"] = "Cliquez pour placer un point de passage",
    ["DPS"] = "DPS",
    ["Dungeon search stopped."] = "Recherche de donjon arrêtée.",
    ["Dungeons"] = "Donjons",
    ["Dungeons (%d)"] = "Donjons (%d)",
    ["Form groups and finish quests together to get on the board."] = "Formez des groupes et terminez des quêtes ensemble pour apparaître ici.",
    ["Group listed for %s. Players can whisper you + to join."] = "Groupe affiché pour %s. Les joueurs peuvent vous chuchoter + pour rejoindre.",
    ["Healer"] = "Soigneur",
    ["Host"] = "Organiser",
    ["Hosting %s"] = "Vous organisez %s",
    ["List your group: players whisper you + and get invited."] = "Affichez votre groupe : les joueurs vous chuchotent + et sont invités.",
    ["Look"] = "Chercher",
    ["Look for a group for this dungeon with your roles."] = "Cherchez un groupe pour ce donjon avec vos rôles.",
    ["Looking for %s"] = "Recherche : %s",
    ["Looking for a %s group as %s."] = "Recherche d'un groupe pour %s en tant que %s.",
    ["Map pin set: %s"] = "Repère placé sur la carte : %s",
    ["Need:"] = "Besoin :",
    ["Next:"] = "Ensuite :",
    ["No dungeons for your level yet."] = "Pas encore de donjon pour votre niveau.",
    ["Only the group leader can invite."] = "Seul le chef de groupe peut inviter.",
    ["Party:"] = "Groupe :",
    ["Pick your roles, then Look for a group or Host one."] = "Choisissez vos rôles, puis cherchez ou organisez un groupe.",
    ["Popular near you"] = "Populaire près de vous",
    ["Post to General"] = "Publier dans Général",
    ["Quest done together! Thank your party? (+1 kudos each)"] = "Quête terminée ensemble ! Remercier votre groupe ? (+1 kudos chacun)",
    ["Searching"] = "Recherche…",
    ["Share quest"] = "Partager la quête",
    ["Shared with your party: %s"] = "Partagée avec le groupe : %s",
    ["Tank"] = "Tank",
    ["This quest can't be shared."] = "Cette quête ne peut pas être partagée.",
    ["This quest isn't in your quest log."] = "Cette quête n'est pas dans votre journal.",
    ["Time to level:"] = "Temps avant le niveau :",
    ["Top helpers this week"] = "Meilleurs entraideurs de la semaine",
    ["Waypoint set: %s"] = "Point de passage placé : %s",
    ["Waypoint to the entrance"] = "Point de passage vers l'entrée",
    ["XP per hour:"] = "XP par heure :",
    ["XP per hour: play a few minutes to measure it."] = "XP par heure : jouez quelques minutes pour la mesurer.",
    ["You thanked your party."] = "Vous avez remercié votre groupe.",
    ["You're not in a party."] = "Vous n'êtes pas dans un groupe.",
    ["Your kudos: %d"] = "Vos kudos : %d",
    ["Your roles:"] = "Vos rôles :",
    ["doesn't have it"] = "ne l'a pas",
    ["done"] = "terminé",
    ["has it"] = "l'a",
    ["need"] = "besoin :",
    ["you"] = "vous",
    ["About"] = "À propos",
    ["Made by %s"] = "Créé par %s",
    ["BattleTag: %s"] = "BattleTag : %s",
    ["Whisper %s"] = "Chuchoter à %s",
    ["Copy BattleTag"] = "Copier le BattleTag",
    ["Questynator author"] = "Auteur de Questynator",
    ["Press Ctrl+C to copy it, then add it as a Battle.net friend."] = "Appuyez sur Ctrl+C pour le copier, puis ajoutez-le en ami Battle.net.",
    ["Bugs and ideas: comments on the Questynator page on CurseForge."] = "Bugs et idées : commentaires sur la page Questynator de CurseForge.",
    ["Announcement"] = "Annonce",
    ["A newer Questynator (%s) is out. Update on CurseForge."] = "Une nouvelle version de Questynator (%s) est disponible. Mettez-la à jour sur CurseForge.",
    ["Questynator admin %s asks for your debug info (version, settings, recent errors). Send it?"] = "L'admin de Questynator %s demande vos infos de débogage (version, réglages, erreurs récentes). Les envoyer ?",
    ["Elite enemies - bring a group."] = "Ennemis élites – venez en groupe.",
    ["Group quest - %d players suggested."] = "Quête de groupe – %d joueurs conseillés.",
    ["Enemies are up to level %d - harder than you."] = "Ennemis jusqu'au niveau %d – plus forts que vous.",
    ["Objectives done - go turn it in."] = "Objectifs terminés – allez rendre la quête.",
    ["Progress:"] = "Progression :",
    ["Click to see how to complete this quest."] = "Cliquez pour voir comment terminer cette quête.",
    ["All quests:"] = "Toutes les quêtes :",
    ["XP"] = "XP",
    ["rep"] = "réput.",
    ["Rewards for completing all your quests"] = "Récompenses de toutes vos quêtes",
    ["Experience"] = "Expérience",
    ["Money"] = "Argent",
    ["Reputation"] = "Réputation",
    ["Currencies"] = "Monnaies",
    ["Groups"] = "Groupes",
    ["Groups (%d)"] = "Groupes (%d)",
    ["Join"] = "Rejoindre",
    ["Your group"] = "Votre groupe",
    ["You have this quest"] = "Vous avez cette quête",
    ["%d/5 players"] = "%d/5 joueurs",
    ["This group is full."] = "Ce groupe est complet.",
    ["Your level isn't in this group's level range."] = "Votre niveau n'est pas dans la tranche de ce groupe.",
    ["Leave your current group first."] = "Quittez d'abord votre groupe actuel.",
    ["No groups right now. Groups created with Questynator show up here."] = "Aucun groupe pour l'instant. Les groupes créés avec Questynator apparaissent ici.",
    ["Asked %s for an invite."] = "Invitation demandée à %s.",
    ["their group"] = "son groupe",
    ["Quests"] = "Quêtes",
    ["Nearby"] = "À proximité",
    ["Nearby (%d)"] = "À proximité (%d)",
    ["Stats"] = "Stats",
    ["No one nearby yet. Questynator will ping you."] = "Personne à proximité pour l'instant. Questynator vous préviendra.",
    ["via Questynator"] = "via Questynator",
    ["in chat"] = "dans la discussion",
    ["Level %d"] = "Niveau %d",
    ["Questynator users online"] = "Utilisateurs Questynator en ligne",
    ["Active searches"] = "Recherches actives",
    ["%d found"] = "%d trouvé(s)",
    ["%s (%d min ago)"] = "%s (il y a %d min)",
    ["%s is looking for:"] = "%s cherche :",
    ["(your realm and faction)"] = "(votre royaume et faction)",
    ["Auto-accept invites from matched players: %s"] = "Accepter auto. les invitations des joueurs trouvés : %s",
    ["Auto-invite players who whisper '+'"] = "Inviter auto. les joueurs qui chuchotent '+'",
    ["Cancel"] = "Annuler",
    ["Chat (%d)"] = "Discussion (%d)",
    ["Chat scanner: %s"] = "Analyse de la discussion : %s",
    ["Click to find other Questynator players on this quest and open Questynator."] = "Cliquez pour trouver d'autres joueurs Questynator sur cette quête et ouvrir Questynator.",
    ["Complete - ready to turn in"] = "Terminée - prête à rendre",
    ["Couldn't hook the objective tracker; use /qn list and /qn find <questID>."] = "Suivi des objectifs introuvable ; utilisez /qn list et /qn find <questID>.",
    ["Create Group"] = "Créer un groupe",
    ["Dungeon"] = "Donjon",
    ["Elite"] = "Élite",
    ["Find Group"] = "Chercher groupe",
    ["Find other players on the same quest. Hover a quest for its objectives."] = "Trouvez des joueurs sur la même quête. Survolez une quête pour ses objectifs.",
    ["Group"] = "Groupe",
    ["Group %d+"] = "Groupe %d+",
    ["Group created for %s (levels %d-%d)."] = "Groupe créé pour %s (niveaux %d-%d).",
    ["Group listed"] = "Groupe publié",
    ["Group quest: %s"] = "Quête de groupe : %s",
    ["Groups formed:"] = "Groupes formés :",
    ["Host a group: pick objectives and a level range, and post it to General chat."] = "Créer un groupe : choisissez objectifs et niveaux, et publiez-le dans Général.",
    ["In chat: %d"] = "Dans la discussion : %d",
    ["Invite"] = "Inviter",
    ["Invited %s (whispered +) for: %s"] = "%s invité (a chuchoté +) pour : %s",
    ["Joined %s for: %s"] = "Groupe de %s rejoint pour : %s",
    ["Keep Searching"] = "Continuer",
    ["Keep looking for another %d seconds before asking again."] = "Continuer à chercher %d secondes avant de redemander.",
    ["Left-click:"] = "Clic gauche :",
    ["Left-click: open Questynator"] = "Clic gauche : ouvrir Questynator",
    ["Look for other Questynator players on this quest."] = "Chercher d'autres joueurs Questynator sur cette quête.",
    ["Looking for players on: %s"] = "Recherche de joueurs pour : %s",
    ["Looking in chat:"] = "Cherchent dans la discussion :",
    ["Looking in chat: %d"] = "Cherchent dans la discussion : %d",
    ["Minimap button hidden (/qn minimap to show)"] = "Bouton de minicarte masqué (/qn minimap pour l'afficher)",
    ["Minimap button shown"] = "Bouton de minicarte affiché",
    ["No one found yet"] = "Personne trouvé pour l'instant",
    ["Not searching"] = "Aucune recherche",
    ["Objective %d"] = "Objectif %d",
    ["Objectives to do together:"] = "Objectifs à faire ensemble :",
    ["Party formed."] = "Groupe formé.",
    ["Player levels:"] = "Niveaux des joueurs :",
    ["Players found:"] = "Joueurs trouvés :",
    ["Players found: %d"] = "Joueurs trouvés : %d",
    ["Players in chat are looking for this quest. Click to whisper or invite the latest one."] = "Des joueurs cherchent cette quête dans la discussion. Cliquez pour chuchoter ou inviter le dernier.",
    ["Post to General chat"] = "Publier dans Général",
    ["Post to General chat - you're not in it"] = "Publier dans Général - vous n'y êtes pas",
    ["Post your group to General chat again."] = "Republier votre groupe dans Général.",
    ["Posted to General chat (/%d)."] = "Publié dans Général (/%d).",
    ["Quests done with Questynator groups:"] = "Quêtes faites avec des groupes Questynator :",
    ["Questynator - player found in chat"] = "Questynator - joueur trouvé dans la discussion",
    ["Questynator user"] = "Utilisateur de Questynator",
    ["Questynator users online: %d"] = "Utilisateurs Questynator en ligne : %d",
    ["Raid"] = "Raid",
    ["Repost"] = "Republier",
    ["Right-click:"] = "Clic droit :",
    ["Right-click: stop searching"] = "Clic droit : arrêter la recherche",
    ["Searching now"] = "Recherches en cours",
    ["Searching quests: %d"] = "Quêtes recherchées : %d",
    ["Searching..."] = "Recherche...",
    ["Searching... players found: %d"] = "Recherche... joueurs trouvés : %d",
    ["Sound alerts: %s"] = "Alertes sonores : %s",
    ["Still searching for: %s"] = "Toujours en recherche pour : %s",
    ["Stop"] = "Arrêter",
    ["Stop all"] = "Tout arrêter",
    ["Stop searching for this quest."] = "Arrêter la recherche pour cette quête.",
    ["That quest isn't in your log."] = "Cette quête n'est pas dans votre journal.",
    ["Whisper"] = "Chuchoter",
    ["You're not in General chat. Your message: %s"] = "Vous n'êtes pas dans Général. Votre message : %s",
    ["Your quest log is empty."] = "Votre journal de quêtes est vide.",
    ["hover a quest for details"] = "survolez une quête pour les détails",
    ["listed"] = "publié",
    ["off"] = "désactivé",
    ["on"] = "activé",
    ["open Questynator"] = "ouvrir Questynator",
    ["open Questynator from chat"] = "ouvrir Questynator depuis la discussion",
    ["party is full"] = "le groupe est complet",
    ["quest is complete"] = "la quête est terminée",
    ["quest left your log"] = "la quête a quitté votre journal",
    ["search cancelled"] = "recherche annulée",
    ["search timed out"] = "recherche expirée",
    ["searching"] = "recherche",
    ["stop all searches"] = "arrêter toutes les recherches",
    ["to"] = "à",
},
esES = {
    ["%d dungeon quest pickups are available."] = "Hay %d misiones de mazmorra disponibles.",
    ["%d in log · %d ready to pick up"] = "%d en el registro · %d por recoger",
    ["%d of %d quests complete"] = "%d de %d misiones completadas",
    ["%d pending"] = "%d pendientes",
    ["%d yd"] = "%d m",
    ["%d yd away"] = "a %d m",
    ["%s can share %s."] = "%s puede compartir %s.",
    ["%s can share this quest."] = "%s puede compartir esta misión.",
    ["%s is recruiting for %s (%d/5)."] = "%s busca jugadores para %s (%d/5).",
    ["All weapon types"] = "Todos los tipos de arma",
    ["Area %d"] = "Zona %d",
    ["Armor (%s)"] = "Armadura (%s)",
    ["Choice of reward"] = "Recompensa a elegir",
    ["Choose All weapon types to see the other matching weapons."] = "Elige Todos los tipos de arma para ver las demás armas que coinciden.",
    ["Choose a quest to host"] = "Elige una misión para organizar",
    ["Choose an unfinished quest in your log."] = "Elige una misión sin terminar de tu registro.",
    ["Closest to earning"] = "Más cerca de conseguir",
    ["Could you share %s?"] = "¿Puedes compartir %s?",
    ["Current zone unavailable"] = "Zona actual no disponible",
    ["Dungeon Prep"] = "Preparación de mazmorra",
    ["Dungeon pickups snoozed"] = "Misiones de mazmorra pospuestas",
    ["From your quest log"] = "De tu registro de misiones",
    ["Guaranteed reward"] = "Recompensa garantizada",
    ["Host LFG"] = "Organizar grupo",
    ["Host a group for %s."] = "Organizar un grupo para %s.",
    ["Hosting requires a free party slot and group leadership."] = "Para organizar necesitas un hueco libre y ser líder del grupo.",
    ["Hosting stopped"] = "Organización detenida",
    ["Hosting: %s"] = "Organizando: %s",
    ["Later"] = "Después",
    ["Later (30 min)"] = "Después (30 min)",
    ["Less"] = "Menos",
    ["Loading reward items…"] = "Cargando recompensas…",
    ["Location unknown"] = "Ubicación desconocida",
    ["Mark on map"] = "Marcar en el mapa",
    ["More"] = "Más",
    ["Next"] = "Siguiente",
    ["No eligible pickups or known quest stops in this zone."] = "No hay misiones disponibles ni paradas conocidas en esta zona.",
    ["No matching rewards"] = "No hay recompensas que coincidan",
    ["No matching rewards in this zone"] = "No hay recompensas que coincidan en esta zona",
    ["No matching weapons of this type"] = "No hay armas de este tipo que coincidan",
    ["No other stops found. Undo snooze to restore a stop."] = "No hay más paradas. Deshaz el aplazamiento para recuperar una.",
    ["No quest stops found in this zone"] = "No hay paradas de misión en esta zona",
    ["No remaining prep quests for your character."] = "No quedan misiones de preparación para tu personaje.",
    ["Pause"] = "Pausa",
    ["Pending"] = "Pendiente",
    ["Pick up"] = "Recoger",
    ["Pick up %s from %s"] = "Recoger %s de %s",
    ["Pickup location unknown"] = "Lugar de inicio desconocido",
    ["Plan My Route"] = "Planificar ruta",
    ["Prep"] = "Prep.",
    ["Prerequisite required"] = "Requiere misión previa",
    ["Prerequisites left: %d. Next: %s"] = "Misiones previas restantes: %d. Siguiente: %s",
    ["Previous"] = "Anterior",
    ["Pursue Reward"] = "Perseguir recompensa",
    ["Pursuing"] = "En curso",
    ["Quest follow-up"] = "Misión siguiente",
    ["Quest group"] = "Grupo de misión",
    ["Quest log full"] = "Registro lleno",
    ["Quest reward"] = "Recompensa de misión",
    ["Ready to claim"] = "Lista para reclamar",
    ["Ready to turn in"] = "Lista para entregar",
    ["Replan"] = "Replanificar",
    ["Request invite"] = "Pedir invitación",
    ["Request share"] = "Pedir compartir",
    ["Requires leadership and a free slot"] = "Requiere ser líder y un hueco libre",
    ["Requires level %d"] = "Requiere nivel %d",
    ["Resume"] = "Reanudar",
    ["Reward Hunting"] = "Caza de recompensas",
    ["Rewards"] = "Recompensas",
    ["Route ended"] = "Ruta terminada",
    ["Route paused"] = "Ruta en pausa",
    ["Route stop %d"] = "Parada %d",
    ["Route to missing pickups"] = "Ruta a misiones pendientes",
    ["Route to pickups"] = "Ruta a las misiones",
    ["Search item, slot or quest"] = "Buscar objeto, ranura o misión",
    ["Show or hide Dungeon Prep"] = "Mostrar u ocultar la preparación",
    ["Showing unfinished reward quests for your level and equipment proficiencies."] = "Se muestran misiones con recompensa sin terminar para tu nivel y competencias de equipo.",
    ["Speak to %s"] = "Habla con %s",
    ["Still to pick up: %s"] = "Por recoger: %s",
    ["Stop %d of %d"] = "Parada %d de %d",
    ["Stop hosting"] = "Detener grupo",
    ["Stop hosting %s."] = "Dejar de organizar %s.",
    ["Stop prep route"] = "Detener ruta de preparación",
    ["Stop pursuit"] = "Dejar de perseguir",
    ["Turn in"] = "Entregar",
    ["Turn in %s"] = "Entregar %s",
    ["Turn in %s to %s."] = "Entrega %s a %s.",
    ["Turn in at %s"] = "Entregar a %s",
    ["Undo"] = "Deshacer",
    ["Up next: %s"] = "Después: %s",
    ["Waiting for invited players."] = "Esperando a los jugadores invitados.",
    ["Waiting for item details from the game."] = "Esperando los datos de los objetos.",
    ["Waiting for quest and map data"] = "Esperando datos de misiones y mapa",
    ["stop all quest searches"] = "detener todas las búsquedas de misiones",
    ["Cloth"] = "Tela",
    ["Leather"] = "Cuero",
    ["Mail"] = "Malla",
    ["Plate"] = "Placas",
    ["Pin pickup"] = "Marcar inicio",
    ["Pin objective"] = "Marcar objetivo",
    ["Pin turn-in"] = "Marcar entrega",
    ["Pin stop"] = "Marcar parada",
    ["Snooze stop"] = "Posponer parada",
    ["Undo snooze"] = "Deshacer",
    ["Hide this stop until you leave the zone."] = "Oculta esta parada hasta que salgas de la zona.",
    ["Quests remaining: %d"] = "Misiones restantes: %d",
    ["Selected quest"] = "Misión seleccionada",
    ["Up next when you resume"] = "Al reanudar la ruta",
    ["Resume route"] = "Reanudar ruta",
    ["No matching weapons in this zone"] = "No hay armas que coincidan en esta zona",
    ["Search all zones"] = "Buscar en todas las zonas",
    ["Search all zones (%d)"] = "Buscar en todas las zonas (%d)",
    ["Show 1 weapon in other zones"] = "Ver 1 arma en otras zonas",
    ["Show %d weapons in other zones"] = "Ver %d armas en otras zonas",
    ["Show 1 reward in other zones"] = "Ver 1 recompensa en otras zonas",
    ["Show %d rewards in other zones"] = "Ver %d recompensas en otras zonas",
    ["Show Route Planner"] = "Mostrar el planificador de rutas",
    ["Treasures"] = "Tesoros",
    ["%d-slot bag"] = "Bolsa de %d casillas",
    ["%d / %d collected"] = "%d / %d conseguidos",
    ["choice of reward"] = "recompensa a elegir",
    ["+3% XP while you rest"] = "+3 % de XP tras descansar",
    ["Step %d of %d: %s"] = "Paso %d de %d: %s",
    ["Waypoint"] = "Punto de ruta",
    ["In your log"] = "En tu registro",
    ["Not yet"] = "Aún no",
    ["Collected"] = "Conseguido",
    ["Stats, top helpers, about and settings"] = "Estadísticas, mejores ayudantes, info y ajustes",
    ["Zones"] = "Zonas",
    ["Nothing new to pick up"] = "Nada nuevo que recoger",
    ["You've done every quest for your level that we know of. Check your quest log, or try a dungeon."] = "Has hecho todas las misiones que conocemos para tu nivel. Revisa tu registro o prueba una mazmorra.",
    ["Click to set a waypoint"] = "Clic para poner un punto de ruta",
    ["Level %d  ·  %d quests to pick up in %d zones"] = "Nivel %d  ·  %d misiones por recoger en %d zonas",
    ["%d to pick up"] = "%d por recoger",
    ["Chain · %d quests"] = "Cadena · %d misiones",
    ["No guide for this quest yet."] = "Aún no hay guía para esta misión.",
    ["Quest arrow is off because you use %s. Turn it on with /qn arrow or in Interface > AddOns > Questynator."] = "La flecha de misión está apagada porque usas %s. Actívala con /qn arrow o en Interfaz > AddOns > Questynator.",
    ["Quest arrow turned off. Turn it back on with /qn arrow or in Interface > AddOns > Questynator."] = "Flecha de misión apagada. Vuelve a activarla con /qn arrow o en Interfaz > AddOns > Questynator.",
    ["Hide until next quest"] = "Ocultar hasta la próxima misión",
    ["Turn off the arrow"] = "Apagar la flecha",
    ["What's new in Questynator"] = "Novedades de Questynator",
    ["Don't show until next update"] = "No mostrar hasta la próxima actualización",
    ["Got it"] = "Entendido",
    ["Features"] = "Funciones",
    ["Interface"] = "Interfaz",
    ["Shortcuts"] = "Accesos rápidos",
    ["Open Questynator"] = "Abrir Questynator",
    ["Thank your party"] = "Agradecer al grupo",
    ["What's new"] = "Novedades",
    ["Directions arrow (quest compass)"] = "Flecha de dirección (brújula de misión)",
    ["Party chat messages (objectives done, quest completed)"] = "Mensajes de grupo (objetivos hechos, misión completada)",
    ["Auto-accept invites from matched players"] = "Aceptar invitaciones de jugadores encontrados",
    ["Chat scanner (find players looking for groups in chat)"] = "Escáner de chat (jugadores que buscan grupo en el chat)",
    ["Minimap button"] = "Botón del minimapa",
    ["Sound alerts"] = "Alertas de sonido",
    ["Quest arrow"] = "Flecha de misión",
    ["Points to your next turn-in, or to the next objective of the quest you select in the tracker."] = "Apunta a tu próxima entrega, o al siguiente objetivo de la misión que elijas en el seguimiento.",
    ["Drag to move"] = "Arrastra para mover",
    ["Right-click to hide it or turn it off"] = "Clic derecho para ocultarla o apagarla",
    ["Settings"] = "Ajustes",
    ["Party messages"] = "Grupo",
    ["Sound"] = "Sonido",
    ["All options"] = "Opciones",
    ["On your quests"] = "En tus misiones",
    ["Not in log"] = "No en el registro",
    ["Find group"] = "Buscar grupo",
    ["Lvl %d"] = "Nv %d",
    ["Lvl %d-%d"] = "Nv %d-%d",
    ["You"] = "Tú",
    ["Full"] = "Lleno",
    ["Too low"] = "Muy bajo",
    ["Too high"] = "Muy alto",
    ["In a group"] = "En grupo",
    ["Open groups"] = "Grupos abiertos",
    ["Your roles"] = "Tus roles",
    ["Hosting"] = "Organizas",
    ["Looking"] = "Buscas",
    ["Click to whisper"] = "Clic para susurrar",
    ["Users online"] = "Usuarios conectados",
    ["Quests together"] = "Misiones juntos",
    ["Groups formed"] = "Grupos formados",
    ["Your kudos %d"] = "Tus kudos %d",
    ["Made by %s"] = "Hecho por %s",
    ["Bugs & ideas: CurseForge"] = "Errores e ideas: CurseForge",
    ["No one nearby yet"] = "Nadie cerca todavía",
    ["Questynator pings you when players near you are on your quests."] = "Questynator te avisa cuando jugadores cercanos hacen tus misiones.",
    ["Find group for a quest"] = "Buscar grupo para una misión",
    ["No open groups right now"] = "No hay grupos abiertos ahora",
    ["Groups created with Questynator show up here."] = "Los grupos creados con Questynator aparecen aquí.",
    ["%d search"] = "%d búsqueda",
    ["%d searches"] = "%d búsquedas",
    ["Search quests"] = "Buscar misiones",
    ["%d users online"] = "%d usuarios conectados",
    ["Level up!"] = "¡Subes de nivel!",
    ["Max level"] = "Nivel máximo",
    ["Enough to level up!"] = "¡Suficiente para subir de nivel!",
    ["quests +%s XP"] = "misiones +%s PX",
    ["XP to next level:"] = "PX para el siguiente nivel:",
    ["XP from your quests:"] = "PX de tus misiones:",
    ["Turning in all your quests levels you up."] = "Entregar todas tus misiones te sube de nivel.",
    ["Still needed after quests:"] = "Aún necesario tras las misiones:",
    ["Objective:"] = "Objetivo:",
    ["How to do it"] = "Cómo hacerla",
    ["Kill %s"] = "Mata a %s",
    ["Loot %s from %s"] = "Despoja %s de %s",
    ["Collect %s"] = "Recoge %s",
    ["Use %s"] = "Usa %s",
    ["Turn in to %s"] = "Entrega a %s",
    ["(Elite)"] = "(Élite)",
    ["Tip:"] = "Consejo:",
    ["You're here"] = "Ya has llegado",
    ["Not available here"] = "No disponible aquí",
    ["Turn-in arrow"] = "Flecha de entrega",
    ["Turn-in arrow: %s"] = "Flecha de entrega: %s",
    ["Drag to move. Right-click to hide until the next quest is ready."] = "Arrastra para mover. Clic derecho para ocultarla hasta la próxima misión lista.",
    ["Questynator: %s - all objectives done!"] = "Questynator: %s - ¡todos los objetivos completados!",
    ["Questynator: %s - quest completed!"] = "Questynator: %s - ¡misión completada!",
    ["Party chat messages: %s"] = "Mensajes en el chat de grupo: %s",
    ["%s: now need %s. Click Post to General to update chat."] = "%s: ahora faltan %s. Pulsa Publicar en General para actualizar el chat.",
    ["%d groups"] = "%d grupos",
    ["%d kudos"] = "%d kudos",
    ["%d looking"] = "%d buscan",
    ["%d players"] = "%d jugadores",
    ["%s thanked you! Kudos: %d"] = "¡%s te ha dado las gracias! Kudos: %d",
    ["Click to change which roles your group still needs."] = "Haz clic para cambiar qué roles le faltan a tu grupo.",
    ["Click to set a waypoint"] = "Haz clic para poner un punto de ruta",
    ["DPS"] = "DPS",
    ["Dungeon search stopped."] = "Búsqueda de mazmorra detenida.",
    ["Dungeons"] = "Mazmorras",
    ["Dungeons (%d)"] = "Mazmorras (%d)",
    ["Form groups and finish quests together to get on the board."] = "Forma grupos y completa misiones juntos para aparecer aquí.",
    ["Group listed for %s. Players can whisper you + to join."] = "Grupo publicado para %s. Los jugadores pueden susurrarte + para unirse.",
    ["Healer"] = "Sanador",
    ["Host"] = "Organizar",
    ["Hosting %s"] = "Organizas %s",
    ["List your group: players whisper you + and get invited."] = "Publica tu grupo: los jugadores te susurran + y reciben invitación.",
    ["Look"] = "Buscar",
    ["Look for a group for this dungeon with your roles."] = "Busca grupo para esta mazmorra con tus roles.",
    ["Looking for %s"] = "Buscando %s",
    ["Looking for a %s group as %s."] = "Buscando grupo para %s como %s.",
    ["Map pin set: %s"] = "Marcador puesto en el mapa: %s",
    ["Need:"] = "Faltan:",
    ["Next:"] = "Siguiente:",
    ["No dungeons for your level yet."] = "Aún no hay mazmorras para tu nivel.",
    ["Only the group leader can invite."] = "Solo el líder del grupo puede invitar.",
    ["Party:"] = "Grupo:",
    ["Pick your roles, then Look for a group or Host one."] = "Elige tus roles y luego busca u organiza un grupo.",
    ["Popular near you"] = "Popular cerca de ti",
    ["Post to General"] = "Publicar en General",
    ["Quest done together! Thank your party? (+1 kudos each)"] = "¡Misión completada juntos! ¿Agradecer a tu grupo? (+1 kudos cada uno)",
    ["Searching"] = "Buscando",
    ["Share quest"] = "Compartir misión",
    ["Shared with your party: %s"] = "Compartida con el grupo: %s",
    ["Tank"] = "Tanque",
    ["This quest can't be shared."] = "Esta misión no se puede compartir.",
    ["This quest isn't in your quest log."] = "Esta misión no está en tu registro.",
    ["Time to level:"] = "Tiempo para subir:",
    ["Top helpers this week"] = "Mejores ayudantes de la semana",
    ["Waypoint set: %s"] = "Punto de ruta puesto: %s",
    ["Waypoint to the entrance"] = "Punto de ruta a la entrada",
    ["XP per hour:"] = "PX por hora:",
    ["XP per hour: play a few minutes to measure it."] = "PX por hora: juega unos minutos para medirla.",
    ["You thanked your party."] = "Has dado las gracias a tu grupo.",
    ["You're not in a party."] = "No estás en un grupo.",
    ["Your kudos: %d"] = "Tus kudos: %d",
    ["Your roles:"] = "Tus roles:",
    ["doesn't have it"] = "no la tiene",
    ["done"] = "hecho",
    ["has it"] = "la tiene",
    ["need"] = "faltan:",
    ["you"] = "tú",
    ["About"] = "Acerca de",
    ["Made by %s"] = "Creado por %s",
    ["BattleTag: %s"] = "BattleTag: %s",
    ["Whisper %s"] = "Susurrar a %s",
    ["Copy BattleTag"] = "Copiar BattleTag",
    ["Questynator author"] = "Autor de Questynator",
    ["Press Ctrl+C to copy it, then add it as a Battle.net friend."] = "Pulsa Ctrl+C para copiarlo y añádelo como amigo de Battle.net.",
    ["Bugs and ideas: comments on the Questynator page on CurseForge."] = "Errores e ideas: comentarios en la página de Questynator en CurseForge.",
    ["Announcement"] = "Anuncio",
    ["A newer Questynator (%s) is out. Update on CurseForge."] = "Hay una versión nueva de Questynator (%s). Actualízala en CurseForge.",
    ["Questynator admin %s asks for your debug info (version, settings, recent errors). Send it?"] = "El admin de Questynator %s pide tu información de depuración (versión, ajustes, errores recientes). ¿Enviarla?",
    ["Elite enemies - bring a group."] = "Enemigos élite: ve en grupo.",
    ["Group quest - %d players suggested."] = "Misión de grupo: se recomiendan %d jugadores.",
    ["Enemies are up to level %d - harder than you."] = "Enemigos hasta nivel %d: más fuertes que tú.",
    ["Objectives done - go turn it in."] = "Objetivos completos: ve a entregarla.",
    ["Progress:"] = "Progreso:",
    ["Click to see how to complete this quest."] = "Haz clic para ver cómo completar esta misión.",
    ["All quests:"] = "Todas las misiones:",
    ["XP"] = "PX",
    ["rep"] = "rep.",
    ["Rewards for completing all your quests"] = "Recompensas por completar todas tus misiones",
    ["Experience"] = "Experiencia",
    ["Money"] = "Dinero",
    ["Reputation"] = "Reputación",
    ["Currencies"] = "Monedas",
    ["Groups"] = "Grupos",
    ["Groups (%d)"] = "Grupos (%d)",
    ["Join"] = "Unirse",
    ["Your group"] = "Tu grupo",
    ["You have this quest"] = "Tienes esta misión",
    ["%d/5 players"] = "%d/5 jugadores",
    ["This group is full."] = "Este grupo está lleno.",
    ["Your level isn't in this group's level range."] = "Tu nivel no está en el rango de este grupo.",
    ["Leave your current group first."] = "Primero sal de tu grupo actual.",
    ["No groups right now. Groups created with Questynator show up here."] = "No hay grupos ahora. Los grupos creados con Questynator aparecen aquí.",
    ["Asked %s for an invite."] = "Has pedido una invitación a %s.",
    ["their group"] = "su grupo",
    ["Quests"] = "Misiones",
    ["Nearby"] = "Cerca",
    ["Nearby (%d)"] = "Cerca (%d)",
    ["Stats"] = "Estadísticas",
    ["No one nearby yet. Questynator will ping you."] = "Aún no hay nadie cerca. Questynator te avisará.",
    ["via Questynator"] = "vía Questynator",
    ["in chat"] = "en el chat",
    ["Level %d"] = "Nivel %d",
    ["Questynator users online"] = "Usuarios de Questynator conectados",
    ["Active searches"] = "Búsquedas activas",
    ["%d found"] = "%d encontrados",
    ["%s (%d min ago)"] = "%s (hace %d min)",
    ["%s is looking for:"] = "%s busca:",
    ["(your realm and faction)"] = "(tu reino y facción)",
    ["Auto-accept invites from matched players: %s"] = "Aceptar automáticamente invitaciones de jugadores encontrados: %s",
    ["Auto-invite players who whisper '+'"] = "Invitar automáticamente a quien susurre '+'",
    ["Cancel"] = "Cancelar",
    ["Chat (%d)"] = "Chat (%d)",
    ["Chat scanner: %s"] = "Escáner de chat: %s",
    ["Click to find other Questynator players on this quest and open Questynator."] = "Haz clic para encontrar otros jugadores de Questynator en esta misión y abrir Questynator.",
    ["Complete - ready to turn in"] = "Completada - lista para entregar",
    ["Couldn't hook the objective tracker; use /qn list and /qn find <questID>."] = "No se encontró el rastreador de objetivos; usa /qn list y /qn find <questID>.",
    ["Create Group"] = "Crear grupo",
    ["Dungeon"] = "Mazmorra",
    ["Elite"] = "Élite",
    ["Find Group"] = "Buscar grupo",
    ["Find other players on the same quest. Hover a quest for its objectives."] = "Encuentra jugadores en la misma misión. Pasa el ratón por una misión para ver sus objetivos.",
    ["Group"] = "Grupo",
    ["Group %d+"] = "Grupo %d+",
    ["Group created for %s (levels %d-%d)."] = "Grupo creado para %s (niveles %d-%d).",
    ["Group listed"] = "Grupo publicado",
    ["Group quest: %s"] = "Misión de grupo: %s",
    ["Groups formed:"] = "Grupos formados:",
    ["Host a group: pick objectives and a level range, and post it to General chat."] = "Crea un grupo: elige objetivos y niveles, y publícalo en el chat General.",
    ["In chat: %d"] = "En el chat: %d",
    ["Invite"] = "Invitar",
    ["Invited %s (whispered +) for: %s"] = "%s invitado (susurró +) para: %s",
    ["Joined %s for: %s"] = "Te uniste a %s para: %s",
    ["Keep Searching"] = "Seguir buscando",
    ["Keep looking for another %d seconds before asking again."] = "Seguir buscando %d segundos más antes de volver a preguntar.",
    ["Left-click:"] = "Clic izquierdo:",
    ["Left-click: open Questynator"] = "Clic izquierdo: abrir Questynator",
    ["Look for other Questynator players on this quest."] = "Buscar otros jugadores de Questynator en esta misión.",
    ["Looking for players on: %s"] = "Buscando jugadores para: %s",
    ["Looking in chat:"] = "Buscando en el chat:",
    ["Looking in chat: %d"] = "Buscando en el chat: %d",
    ["Minimap button hidden (/qn minimap to show)"] = "Botón del minimapa oculto (/qn minimap para mostrarlo)",
    ["Minimap button shown"] = "Botón del minimapa visible",
    ["No one found yet"] = "Aún no se ha encontrado a nadie",
    ["Not searching"] = "Sin búsqueda",
    ["Objective %d"] = "Objetivo %d",
    ["Objectives to do together:"] = "Objetivos para hacer juntos:",
    ["Party formed."] = "Grupo formado.",
    ["Player levels:"] = "Niveles de jugador:",
    ["Players found:"] = "Jugadores encontrados:",
    ["Players found: %d"] = "Jugadores encontrados: %d",
    ["Players in chat are looking for this quest. Click to whisper or invite the latest one."] = "Hay jugadores en el chat buscando esta misión. Haz clic para susurrar o invitar al último.",
    ["Post to General chat"] = "Publicar en el chat General",
    ["Post to General chat - you're not in it"] = "Publicar en el chat General - no estás en él",
    ["Post your group to General chat again."] = "Volver a publicar tu grupo en el chat General.",
    ["Posted to General chat (/%d)."] = "Publicado en el chat General (/%d).",
    ["Quests done with Questynator groups:"] = "Misiones hechas con grupos de Questynator:",
    ["Questynator - player found in chat"] = "Questynator - jugador encontrado en el chat",
    ["Questynator user"] = "Usuario de Questynator",
    ["Questynator users online: %d"] = "Usuarios de Questynator conectados: %d",
    ["Raid"] = "Banda",
    ["Repost"] = "Republicar",
    ["Right-click:"] = "Clic derecho:",
    ["Right-click: stop searching"] = "Clic derecho: detener la búsqueda",
    ["Searching now"] = "Buscando ahora",
    ["Searching quests: %d"] = "Misiones en búsqueda: %d",
    ["Searching..."] = "Buscando...",
    ["Searching... players found: %d"] = "Buscando... jugadores encontrados: %d",
    ["Sound alerts: %s"] = "Alertas de sonido: %s",
    ["Still searching for: %s"] = "Sigue buscando para: %s",
    ["Stop"] = "Detener",
    ["Stop all"] = "Detener todo",
    ["Stop searching for this quest."] = "Dejar de buscar para esta misión.",
    ["That quest isn't in your log."] = "Esa misión no está en tu registro.",
    ["Whisper"] = "Susurrar",
    ["You're not in General chat. Your message: %s"] = "No estás en el chat General. Tu mensaje: %s",
    ["Your quest log is empty."] = "Tu registro de misiones está vacío.",
    ["hover a quest for details"] = "pasa el ratón por una misión para ver detalles",
    ["listed"] = "publicado",
    ["off"] = "desactivado",
    ["on"] = "activado",
    ["open Questynator"] = "abrir Questynator",
    ["open Questynator from chat"] = "abrir Questynator desde el chat",
    ["party is full"] = "el grupo está lleno",
    ["quest is complete"] = "la misión está completada",
    ["quest left your log"] = "la misión salió de tu registro",
    ["search cancelled"] = "búsqueda cancelada",
    ["search timed out"] = "la búsqueda caducó",
    ["searching"] = "buscando",
    ["stop all searches"] = "detener todas las búsquedas",
    ["to"] = "a",
},
ruRU = {
    ["%d dungeon quest pickups are available."] = "Доступно заданий подземелья: %d.",
    ["%d in log · %d ready to pick up"] = "В журнале: %d · можно взять: %d",
    ["%d of %d quests complete"] = "Выполнено заданий: %d из %d",
    ["%d pending"] = "ожидают: %d",
    ["%d yd"] = "%d м",
    ["%d yd away"] = "%d м отсюда",
    ["%s can share %s."] = "%s может поделиться заданием %s.",
    ["%s can share this quest."] = "%s может поделиться этим заданием.",
    ["%s is recruiting for %s (%d/5)."] = "%s собирает группу: %s (%d/5).",
    ["All weapon types"] = "Все типы оружия",
    ["Area %d"] = "Зона %d",
    ["Armor (%s)"] = "Броня (%s)",
    ["Choice of reward"] = "Награда на выбор",
    ["Choose All weapon types to see the other matching weapons."] = "Выберите «Все типы оружия», чтобы увидеть остальное подходящее оружие.",
    ["Choose a quest to host"] = "Выберите задание для сбора группы",
    ["Choose an unfinished quest in your log."] = "Выберите незавершённое задание из журнала.",
    ["Closest to earning"] = "Ближе всего к получению",
    ["Could you share %s?"] = "Можешь поделиться заданием %s?",
    ["Current zone unavailable"] = "Текущая зона недоступна",
    ["Dungeon Prep"] = "Подготовка к подземелью",
    ["Dungeon pickups snoozed"] = "Задания подземелья отложены",
    ["From your quest log"] = "Из журнала заданий",
    ["Guaranteed reward"] = "Гарантированная награда",
    ["Host LFG"] = "Собрать группу",
    ["Host a group for %s."] = "Собрать группу для: %s.",
    ["Hosting requires a free party slot and group leadership."] = "Чтобы собрать группу, нужно свободное место и роль лидера.",
    ["Hosting stopped"] = "Сбор группы остановлен",
    ["Hosting: %s"] = "Сбор группы: %s",
    ["Later"] = "Позже",
    ["Later (30 min)"] = "Позже (30 мин)",
    ["Less"] = "Меньше",
    ["Loading reward items…"] = "Загрузка наград…",
    ["Location unknown"] = "Место неизвестно",
    ["Mark on map"] = "Отметить на карте",
    ["More"] = "Больше",
    ["Next"] = "Далее",
    ["No eligible pickups or known quest stops in this zone."] = "В этой зоне нет доступных заданий или известных точек.",
    ["No matching rewards"] = "Нет подходящих наград",
    ["No matching rewards in this zone"] = "В этой зоне нет подходящих наград",
    ["No matching weapons of this type"] = "Нет подходящего оружия этого типа",
    ["No other stops found. Undo snooze to restore a stop."] = "Других точек нет. Верните отложенную точку, чтобы продолжить.",
    ["No quest stops found in this zone"] = "В этой зоне нет точек заданий",
    ["No remaining prep quests for your character."] = "Для вашего персонажа не осталось заданий подготовки.",
    ["Pause"] = "Пауза",
    ["Pending"] = "Ожидание",
    ["Pick up"] = "Взять",
    ["Pick up %s from %s"] = "Взять «%s» у %s",
    ["Pickup location unknown"] = "Где взять — неизвестно",
    ["Plan My Route"] = "Построить маршрут",
    ["Prep"] = "Подг.",
    ["Prerequisite required"] = "Нужно предыдущее задание",
    ["Prerequisites left: %d. Next: %s"] = "Осталось предыдущих заданий: %d. Следующее: %s",
    ["Previous"] = "Назад",
    ["Pursue Reward"] = "Добыть награду",
    ["Pursuing"] = "Цель",
    ["Quest follow-up"] = "Следующее задание",
    ["Quest group"] = "Группа для задания",
    ["Quest log full"] = "Журнал заполнен",
    ["Quest reward"] = "Награда за задание",
    ["Ready to claim"] = "Можно получить",
    ["Ready to turn in"] = "Можно сдать",
    ["Replan"] = "Перестроить",
    ["Request invite"] = "Попросить приглашение",
    ["Request share"] = "Попросить",
    ["Requires leadership and a free slot"] = "Нужны роль лидера и свободное место",
    ["Requires level %d"] = "Требуется уровень %d",
    ["Resume"] = "Продолжить",
    ["Reward Hunting"] = "Охота за наградами",
    ["Rewards"] = "Награды",
    ["Route ended"] = "Маршрут завершён",
    ["Route paused"] = "Маршрут на паузе",
    ["Route stop %d"] = "Точка %d",
    ["Route to missing pickups"] = "Маршрут к заданиям",
    ["Route to pickups"] = "Маршрут к заданиям",
    ["Search item, slot or quest"] = "Поиск предмета, ячейки или задания",
    ["Show or hide Dungeon Prep"] = "Показать или скрыть подготовку",
    ["Showing unfinished reward quests for your level and equipment proficiencies."] = "Показаны незавершённые задания с наградами для вашего уровня и навыков владения снаряжением.",
    ["Speak to %s"] = "Поговорить: %s",
    ["Still to pick up: %s"] = "Осталось взять: %s",
    ["Stop %d of %d"] = "Точка %d из %d",
    ["Stop hosting"] = "Остановить сбор",
    ["Stop hosting %s."] = "Прекратить сбор группы: %s.",
    ["Stop prep route"] = "Остановить маршрут",
    ["Stop pursuit"] = "Отменить цель",
    ["Turn in"] = "Сдать",
    ["Turn in %s"] = "Сдать «%s»",
    ["Turn in %s to %s."] = "Сдайте «%s» персонажу %s.",
    ["Turn in at %s"] = "Сдать: %s",
    ["Undo"] = "Вернуть",
    ["Up next: %s"] = "Далее: %s",
    ["Waiting for invited players."] = "Ожидание приглашённых игроков.",
    ["Waiting for item details from the game."] = "Ожидание данных о предметах.",
    ["Waiting for quest and map data"] = "Ожидание данных заданий и карты",
    ["stop all quest searches"] = "остановить все поиски заданий",
    ["Cloth"] = "Ткань",
    ["Leather"] = "Кожа",
    ["Mail"] = "Кольчуга",
    ["Plate"] = "Латы",
    ["Pin pickup"] = "Где взять",
    ["Pin objective"] = "Где выполнить",
    ["Pin turn-in"] = "Где сдать",
    ["Pin stop"] = "Отметить точку",
    ["Snooze stop"] = "Отложить точку",
    ["Undo snooze"] = "Вернуть точку",
    ["Hide this stop until you leave the zone."] = "Скрыть эту точку до выхода из зоны.",
    ["Quests remaining: %d"] = "Осталось заданий: %d",
    ["Selected quest"] = "Выбранное задание",
    ["Up next when you resume"] = "После возврата к маршруту",
    ["Resume route"] = "К маршруту",
    ["No matching weapons in this zone"] = "В этой зоне нет подходящего оружия",
    ["Search all zones"] = "Искать во всех зонах",
    ["Search all zones (%d)"] = "Искать во всех зонах (%d)",
    ["Show 1 weapon in other zones"] = "Показать оружие в других зонах (1)",
    ["Show %d weapons in other zones"] = "Показать оружие в других зонах (%d)",
    ["Show 1 reward in other zones"] = "Показать награду в других зонах (1)",
    ["Show %d rewards in other zones"] = "Показать награды в других зонах (%d)",
    ["Show Route Planner"] = "Показывать планировщик маршрута",
    ["Treasures"] = "Сокровища",
    ["%d-slot bag"] = "Сумка на %d ячеек",
    ["%d / %d collected"] = "%d / %d получено",
    ["choice of reward"] = "награда на выбор",
    ["+3% XP while you rest"] = "+3% опыта после отдыха",
    ["Step %d of %d: %s"] = "Шаг %d из %d: %s",
    ["Waypoint"] = "Метка",
    ["In your log"] = "В журнале",
    ["Not yet"] = "Пока нет",
    ["Collected"] = "Получено",
    ["Stats, top helpers, about and settings"] = "Статистика, лучшие помощники, об аддоне и настройки",
    ["Zones"] = "Зоны",
    ["Nothing new to pick up"] = "Новых заданий нет",
    ["You've done every quest for your level that we know of. Check your quest log, or try a dungeon."] = "Вы выполнили все известные нам задания для вашего уровня. Загляните в журнал или в подземелье.",
    ["Click to set a waypoint"] = "Нажмите, чтобы поставить метку",
    ["Level %d  ·  %d quests to pick up in %d zones"] = "Уровень %d  ·  %d заданий в %d зонах",
    ["%d to pick up"] = "%d можно взять",
    ["Chain · %d quests"] = "Цепочка · %d заданий",
    ["No guide for this quest yet."] = "Для этого задания пока нет описания.",
    ["Quest arrow is off because you use %s. Turn it on with /qn arrow or in Interface > AddOns > Questynator."] = "Стрелка заданий выключена, так как у вас %s. Включить: /qn arrow или Интерфейс > Модификации > Questynator.",
    ["Quest arrow turned off. Turn it back on with /qn arrow or in Interface > AddOns > Questynator."] = "Стрелка заданий выключена. Включить снова: /qn arrow или Интерфейс > Модификации > Questynator.",
    ["Hide until next quest"] = "Скрыть до следующего задания",
    ["Turn off the arrow"] = "Выключить стрелку",
    ["What's new in Questynator"] = "Что нового в Questynator",
    ["Don't show until next update"] = "Не показывать до следующего обновления",
    ["Got it"] = "Понятно",
    ["Features"] = "Функции",
    ["Interface"] = "Интерфейс",
    ["Shortcuts"] = "Быстрые действия",
    ["Open Questynator"] = "Открыть Questynator",
    ["Thank your party"] = "Поблагодарить группу",
    ["What's new"] = "Что нового",
    ["Directions arrow (quest compass)"] = "Стрелка направления (компас заданий)",
    ["Party chat messages (objectives done, quest completed)"] = "Сообщения в группу (цели выполнены, задание сдано)",
    ["Auto-accept invites from matched players"] = "Автоматически принимать приглашения найденных игроков",
    ["Chat scanner (find players looking for groups in chat)"] = "Сканер чата (игроки, ищущие группу в чате)",
    ["Minimap button"] = "Кнопка у миникарты",
    ["Sound alerts"] = "Звуковые сигналы",
    ["Quest arrow"] = "Стрелка заданий",
    ["Points to your next turn-in, or to the next objective of the quest you select in the tracker."] = "Указывает на ближайшую сдачу задания или на следующую цель выбранного в списке задания.",
    ["Drag to move"] = "Перетащите, чтобы переместить",
    ["Right-click to hide it or turn it off"] = "Правый клик: скрыть или выключить",
    ["Settings"] = "Настройки",
    ["Party messages"] = "Группа",
    ["Sound"] = "Звук",
    ["All options"] = "Настройки",
    ["On your quests"] = "На ваших заданиях",
    ["Not in log"] = "Нет в журнале",
    ["Find group"] = "Найти группу",
    ["Lvl %d"] = "Ур. %d",
    ["Lvl %d-%d"] = "Ур. %d-%d",
    ["You"] = "Вы",
    ["Full"] = "Полная",
    ["Too low"] = "Слишком низкий",
    ["Too high"] = "Слишком высокий",
    ["In a group"] = "В группе",
    ["Open groups"] = "Открытые группы",
    ["Your roles"] = "Ваши роли",
    ["Hosting"] = "Собираете",
    ["Looking"] = "Ищете",
    ["Click to whisper"] = "Нажмите, чтобы шепнуть",
    ["Users online"] = "В сети",
    ["Quests together"] = "Заданий вместе",
    ["Groups formed"] = "Групп собрано",
    ["Your kudos %d"] = "Ваши кудос %d",
    ["Made by %s"] = "Автор: %s",
    ["Bugs & ideas: CurseForge"] = "Ошибки и идеи: CurseForge",
    ["No one nearby yet"] = "Рядом пока никого",
    ["Questynator pings you when players near you are on your quests."] = "Questynator сообщит, когда игроки рядом будут на ваших заданиях.",
    ["Find group for a quest"] = "Найти группу для задания",
    ["No open groups right now"] = "Сейчас нет открытых групп",
    ["Groups created with Questynator show up here."] = "Здесь появляются группы, созданные в Questynator.",
    ["%d search"] = "%d поиск",
    ["%d searches"] = "%d поисков",
    ["Search quests"] = "Поиск заданий",
    ["%d users online"] = "%d в сети",
    ["Level up!"] = "Новый уровень!",
    ["Max level"] = "Максимальный уровень",
    ["Enough to level up!"] = "Хватит для нового уровня!",
    ["quests +%s XP"] = "задания +%s опыта",
    ["XP to next level:"] = "Опыта до следующего уровня:",
    ["XP from your quests:"] = "Опыт за ваши задания:",
    ["Turning in all your quests levels you up."] = "Сдав все задания, вы получите новый уровень.",
    ["Still needed after quests:"] = "Останется после заданий:",
    ["Objective:"] = "Цель:",
    ["How to do it"] = "Как выполнить",
    ["Kill %s"] = "Убейте: %s",
    ["Loot %s from %s"] = "Добудьте %s с %s",
    ["Collect %s"] = "Соберите %s",
    ["Use %s"] = "Используйте %s",
    ["Turn in to %s"] = "Сдайте: %s",
    ["(Elite)"] = "(Элита)",
    ["Tip:"] = "Совет:",
    ["You're here"] = "Вы на месте",
    ["Not available here"] = "Здесь недоступно",
    ["Turn-in arrow"] = "Стрелка сдачи",
    ["Turn-in arrow: %s"] = "Стрелка сдачи: %s",
    ["Drag to move. Right-click to hide until the next quest is ready."] = "Перетащите, чтобы переместить. ПКМ скрывает до следующего готового задания.",
    ["Questynator: %s - all objectives done!"] = "Questynator: %s - все цели выполнены!",
    ["Questynator: %s - quest completed!"] = "Questynator: %s - задание сдано!",
    ["Party chat messages: %s"] = "Сообщения в чат группы: %s",
    ["%s: now need %s. Click Post to General to update chat."] = "%s: теперь нужны %s. Нажмите «Написать в Общий», чтобы обновить сообщение в чате.",
    ["%d groups"] = "групп: %d",
    ["%d kudos"] = "кудосов: %d",
    ["%d looking"] = "ищут: %d",
    ["%d players"] = "игроков: %d",
    ["%s thanked you! Kudos: %d"] = "%s благодарит вас! Кудосы: %d",
    ["Click to change which roles your group still needs."] = "Нажмите, чтобы выбрать, каких ролей ещё не хватает группе.",
    ["Click to set a waypoint"] = "Нажмите, чтобы поставить метку",
    ["DPS"] = "ДД",
    ["Dungeon search stopped."] = "Поиск подземелья остановлен.",
    ["Dungeons"] = "Подземелья",
    ["Dungeons (%d)"] = "Подземелья (%d)",
    ["Form groups and finish quests together to get on the board."] = "Собирайте группы и выполняйте задания вместе, чтобы попасть в список.",
    ["Group listed for %s. Players can whisper you + to join."] = "Группа в %s создана. Игроки могут шепнуть вам +, чтобы вступить.",
    ["Healer"] = "Лекарь",
    ["Host"] = "Собрать",
    ["Hosting %s"] = "Вы собираете %s",
    ["List your group: players whisper you + and get invited."] = "Создайте группу: игроки шепчут вам + и получают приглашение.",
    ["Look"] = "Искать",
    ["Look for a group for this dungeon with your roles."] = "Искать группу в это подземелье с вашими ролями.",
    ["Looking for %s"] = "Ищу: %s",
    ["Looking for a %s group as %s."] = "Ищу группу в %s как %s.",
    ["Map pin set: %s"] = "Метка на карте: %s",
    ["Need:"] = "Нужны:",
    ["Next:"] = "Далее:",
    ["No dungeons for your level yet."] = "Пока нет подземелий для вашего уровня.",
    ["Only the group leader can invite."] = "Приглашать может только лидер группы.",
    ["Party:"] = "Группа:",
    ["Pick your roles, then Look for a group or Host one."] = "Выберите роли, затем ищите группу или соберите свою.",
    ["Popular near you"] = "Популярно рядом",
    ["Post to General"] = "Написать в Общий",
    ["Quest done together! Thank your party? (+1 kudos each)"] = "Задание выполнено вместе! Поблагодарить группу? (+1 кудос каждому)",
    ["Searching"] = "Поиск",
    ["Share quest"] = "Поделиться заданием",
    ["Shared with your party: %s"] = "Поделились с группой: %s",
    ["Tank"] = "Танк",
    ["This quest can't be shared."] = "Этим заданием нельзя поделиться.",
    ["This quest isn't in your quest log."] = "Этого задания нет в вашем журнале.",
    ["Time to level:"] = "До уровня:",
    ["Top helpers this week"] = "Лучшие помощники недели",
    ["Waypoint set: %s"] = "Метка поставлена: %s",
    ["Waypoint to the entrance"] = "Метка ко входу",
    ["XP per hour:"] = "Опыт в час:",
    ["XP per hour: play a few minutes to measure it."] = "Опыт в час: поиграйте несколько минут, чтобы измерить.",
    ["You thanked your party."] = "Вы поблагодарили группу.",
    ["You're not in a party."] = "Вы не в группе.",
    ["Your kudos: %d"] = "Ваши кудосы: %d",
    ["Your roles:"] = "Ваши роли:",
    ["doesn't have it"] = "нет задания",
    ["done"] = "готово",
    ["has it"] = "есть",
    ["need"] = "нужны:",
    ["you"] = "вы",
    ["About"] = "Об аддоне",
    ["Made by %s"] = "Автор: %s",
    ["BattleTag: %s"] = "BattleTag: %s",
    ["Whisper %s"] = "Шепнуть: %s",
    ["Copy BattleTag"] = "Копировать BattleTag",
    ["Questynator author"] = "Автор Questynator",
    ["Press Ctrl+C to copy it, then add it as a Battle.net friend."] = "Нажмите Ctrl+C, чтобы скопировать, и добавьте в друзья Battle.net.",
    ["Bugs and ideas: comments on the Questynator page on CurseForge."] = "Ошибки и идеи: комментарии на странице Questynator в CurseForge.",
    ["Announcement"] = "Объявление",
    ["A newer Questynator (%s) is out. Update on CurseForge."] = "Вышла новая версия Questynator (%s). Обновите на CurseForge.",
    ["Questynator admin %s asks for your debug info (version, settings, recent errors). Send it?"] = "Админ Questynator %s запрашивает вашу отладочную информацию (версия, настройки, последние ошибки). Отправить?",
    ["Elite enemies - bring a group."] = "Элитные враги – берите группу.",
    ["Group quest - %d players suggested."] = "Групповое задание – рекомендуется игроков: %d.",
    ["Enemies are up to level %d - harder than you."] = "Враги до %d уровня – сильнее вас.",
    ["Objectives done - go turn it in."] = "Цели выполнены – идите сдавать.",
    ["Progress:"] = "Прогресс:",
    ["Click to see how to complete this quest."] = "Нажмите, чтобы узнать, как выполнить задание.",
    ["All quests:"] = "Все задания:",
    ["XP"] = "опыта",
    ["rep"] = "репутации",
    ["Rewards for completing all your quests"] = "Награды за все ваши задания",
    ["Experience"] = "Опыт",
    ["Money"] = "Деньги",
    ["Reputation"] = "Репутация",
    ["Currencies"] = "Валюты",
    ["Groups"] = "Группы",
    ["Groups (%d)"] = "Группы (%d)",
    ["Join"] = "Вступить",
    ["Your group"] = "Ваша группа",
    ["You have this quest"] = "У вас есть это задание",
    ["%d/5 players"] = "%d/5 игроков",
    ["This group is full."] = "Группа заполнена.",
    ["Your level isn't in this group's level range."] = "Ваш уровень не входит в диапазон этой группы.",
    ["Leave your current group first."] = "Сначала покиньте текущую группу.",
    ["No groups right now. Groups created with Questynator show up here."] = "Сейчас групп нет. Группы, созданные в Questynator, появятся здесь.",
    ["Asked %s for an invite."] = "Запрошено приглашение у %s.",
    ["their group"] = "его группу",
    ["Quests"] = "Задания",
    ["Nearby"] = "Рядом",
    ["Nearby (%d)"] = "Рядом (%d)",
    ["Stats"] = "Статистика",
    ["No one nearby yet. Questynator will ping you."] = "Рядом пока никого. Questynator сообщит.",
    ["via Questynator"] = "через Questynator",
    ["in chat"] = "в чате",
    ["Level %d"] = "Уровень %d",
    ["Questynator users online"] = "Пользователей Questynator в сети",
    ["Active searches"] = "Активные поиски",
    ["%d found"] = "найдено: %d",
    ["%s (%d min ago)"] = "%s (%d мин назад)",
    ["%s is looking for:"] = "%s ищет:",
    ["(your realm and faction)"] = "(ваш мир и фракция)",
    ["Auto-accept invites from matched players: %s"] = "Автопринятие приглашений от найденных игроков: %s",
    ["Auto-invite players who whisper '+'"] = "Автоприглашение тех, кто шепнёт '+'",
    ["Cancel"] = "Отмена",
    ["Chat (%d)"] = "Чат (%d)",
    ["Chat scanner: %s"] = "Сканер чата: %s",
    ["Click to find other Questynator players on this quest and open Questynator."] = "Нажмите, чтобы найти других игроков Questynator на этом задании и открыть Questynator.",
    ["Complete - ready to turn in"] = "Выполнено - можно сдать",
    ["Couldn't hook the objective tracker; use /qn list and /qn find <questID>."] = "Не удалось подключиться к списку целей; используйте /qn list и /qn find <questID>.",
    ["Create Group"] = "Создать группу",
    ["Dungeon"] = "Подземелье",
    ["Elite"] = "Элитное",
    ["Find Group"] = "Найти группу",
    ["Find other players on the same quest. Hover a quest for its objectives."] = "Найдите игроков на том же задании. Наведите на задание, чтобы увидеть цели.",
    ["Group"] = "Группа",
    ["Group %d+"] = "Группа %d+",
    ["Group created for %s (levels %d-%d)."] = "Группа создана для %s (уровни %d-%d).",
    ["Group listed"] = "Группа объявлена",
    ["Group quest: %s"] = "Групповое задание: %s",
    ["Groups formed:"] = "Собрано групп:",
    ["Host a group: pick objectives and a level range, and post it to General chat."] = "Соберите группу: выберите цели и уровни и объявите в общем чате.",
    ["In chat: %d"] = "В чате: %d",
    ["Invite"] = "Пригласить",
    ["Invited %s (whispered +) for: %s"] = "%s приглашён (шепнул +) на: %s",
    ["Joined %s for: %s"] = "Вы вступили в группу %s на: %s",
    ["Keep Searching"] = "Искать дальше",
    ["Keep looking for another %d seconds before asking again."] = "Искать ещё %d секунд, прежде чем спросить снова.",
    ["Left-click:"] = "ЛКМ:",
    ["Left-click: open Questynator"] = "ЛКМ: открыть Questynator",
    ["Look for other Questynator players on this quest."] = "Искать других игроков Questynator на этом задании.",
    ["Looking for players on: %s"] = "Поиск игроков на: %s",
    ["Looking in chat:"] = "Ищут в чате:",
    ["Looking in chat: %d"] = "Ищут в чате: %d",
    ["Minimap button hidden (/qn minimap to show)"] = "Кнопка у миникарты скрыта (/qn minimap, чтобы показать)",
    ["Minimap button shown"] = "Кнопка у миникарты показана",
    ["No one found yet"] = "Пока никого не найдено",
    ["Not searching"] = "Поиск не идёт",
    ["Objective %d"] = "Цель %d",
    ["Objectives to do together:"] = "Цели для совместного выполнения:",
    ["Party formed."] = "Группа собрана.",
    ["Player levels:"] = "Уровни игроков:",
    ["Players found:"] = "Найдены игроки:",
    ["Players found: %d"] = "Найдено игроков: %d",
    ["Players in chat are looking for this quest. Click to whisper or invite the latest one."] = "Игроки в чате ищут это задание. Нажмите, чтобы шепнуть или пригласить последнего.",
    ["Post to General chat"] = "Написать в общий чат",
    ["Post to General chat - you're not in it"] = "Написать в общий чат - вы не в нём",
    ["Post your group to General chat again."] = "Снова объявить группу в общем чате.",
    ["Posted to General chat (/%d)."] = "Объявлено в общем чате (/%d).",
    ["Quests done with Questynator groups:"] = "Заданий выполнено с группами Questynator:",
    ["Questynator - player found in chat"] = "Questynator - игрок найден в чате",
    ["Questynator user"] = "Пользователь Questynator",
    ["Questynator users online: %d"] = "Пользователей Questynator в сети: %d",
    ["Raid"] = "Рейд",
    ["Repost"] = "Повторить",
    ["Right-click:"] = "ПКМ:",
    ["Right-click: stop searching"] = "ПКМ: остановить поиск",
    ["Searching now"] = "Идёт поиск",
    ["Searching quests: %d"] = "Заданий в поиске: %d",
    ["Searching..."] = "Поиск...",
    ["Searching... players found: %d"] = "Поиск... найдено игроков: %d",
    ["Sound alerts: %s"] = "Звуковые оповещения: %s",
    ["Still searching for: %s"] = "Поиск продолжается: %s",
    ["Stop"] = "Стоп",
    ["Stop all"] = "Остановить всё",
    ["Stop searching for this quest."] = "Остановить поиск для этого задания.",
    ["That quest isn't in your log."] = "Этого задания нет в вашем журнале.",
    ["Whisper"] = "Шепнуть",
    ["You're not in General chat. Your message: %s"] = "Вы не в общем чате. Ваше сообщение: %s",
    ["Your quest log is empty."] = "Ваш журнал заданий пуст.",
    ["hover a quest for details"] = "наведите на задание для подробностей",
    ["listed"] = "объявлено",
    ["off"] = "выкл.",
    ["on"] = "вкл.",
    ["open Questynator"] = "открыть Questynator",
    ["open Questynator from chat"] = "открыть Questynator из чата",
    ["party is full"] = "группа заполнена",
    ["quest is complete"] = "задание выполнено",
    ["quest left your log"] = "задание исчезло из журнала",
    ["search cancelled"] = "поиск отменён",
    ["search timed out"] = "время поиска истекло",
    ["searching"] = "поиск",
    ["stop all searches"] = "остановить все поиски",
    ["to"] = "до",
},
}
ns.ApplyLocale(GetLocale and GetLocale() or "enUS")

ns.BUILD = nil
local PREFIX       = "QSTYN1"
local CHANNEL      = "QuestynatorLFG"
local BEACON_EVERY = 20   -- seconds between beacons while searching
local PEER_TTL     = 60   -- forget a peer if no beacon for this long
local TICK         = 5
local MAX_PARTY    = 5
local MAX_INVITES  = 3    -- invites per peer per search (don't spam decliners)
local CREATE_AFTER = 10   -- seconds with nobody found before offering Keep Searching / Create Group
local MAX_OBJ      = 6    -- objectives tracked per quest (bitmask)

local band = (bit and bit.band) or (bit32 and bit32.band)

-- random per-session id carried in every beacon, so we can recognise (and ignore) our own
-- messages echoed back by the channel without relying on how the sender name is formatted
local SID = string.format("%08x", math.random(0, 0x7fffffff))

local DEFAULTS = { autoAccept = true, levelRange = 6, timeout = 600, minimap = { hide = false }, collapsed = {},
                   sound = true, chatScan = true, partyChat = true, arrow = true, stats = { quests = 0, groups = 0 } }

local DB
local seeking = {}        -- [questID] = { started, peers = {[name] = {t, level, state}}, inviteCount = {} }
local invitedAt = {}      -- [name] = last invite time
local ticker, lastJoin, pendingRefresh, wasGrouped
local buttons = {}        -- [block] = button

---------------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------------
local function Print(...)
    print("|cff33ccffQuestynator|r:", ...)
end

local function MyFullName()
    local name = UnitName("player")
    local realm = GetNormalizedRealmName and GetNormalizedRealmName() or ""
    if realm and realm ~= "" then return name .. "-" .. realm end
    return name
end

local function Same(a, b)
    return Ambiguate(a, "none") == Ambiguate(b, "none")
end

-- An absent quest can have a nil or zero index depending on the client.
function ns.QuestLogIndex(questID)
    local index = C_QuestLog.GetLogIndexForQuestID and C_QuestLog.GetLogIndexForQuestID(questID)
    return index and index > 0 and index or nil
end

local function QuestTitle(questID)
    local t = C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(questID)
    if not t then                                   -- not in your log yet: the name from the bundled data
        local D = ns.QDATA
        local raw = D and ((D.a and D.a[questID]) or (D.t and D.t[questID]))
        t = raw and raw:match(";([^;]*)$")
        if t == "" then t = nil end
    end
    return t or ("quest " .. questID)
end

local function MyState()
    if not IsInGroup() then return 0 end
    if UnitIsGroupLeader("player") then return 2 end
    return 1
end

local function CountPeers(s)
    local n = 0
    for _ in pairs(s.peers) do n = n + 1 end
    return n
end

---------------------------------------------------------------------------
-- hidden channel + sending
---------------------------------------------------------------------------
local function ChannelID()
    local id = GetChannelName(CHANNEL)
    if id and id > 0 then return id end
end

local function HideChannelFromChat()
    for i = 1, (NUM_CHAT_WINDOWS or 10) do
        local f = _G["ChatFrame" .. i]
        if f and ChatFrame_RemoveChannel then pcall(ChatFrame_RemoveChannel, f, CHANNEL) end
    end
end

local function EnsureChannel()
    if ChannelID() then return end
    local now = GetTime()
    if lastJoin and now - lastJoin < 10 then return end
    lastJoin = now
    JoinTemporaryChannel(CHANNEL)
    C_Timer.After(1, HideChannelFromChat)
end

local function Send(msg)
    local id = ChannelID()
    if not id then return false end
    local send = (C_ChatInfo and C_ChatInfo.SendAddonMessage) or SendAddonMessage
    send(PREFIX, msg, "CHANNEL", id)
    return true
end

---------------------------------------------------------------------------
-- alerts: sound + flash the taskbar icon (throttled)
---------------------------------------------------------------------------
local lastAlert = 0
function ns.Alert()
    if not DB or not DB.sound then return end
    local now = GetTime()
    if now - lastAlert < 4 then return end
    lastAlert = now
    if PlaySound and SOUNDKIT then
        PlaySound(SOUNDKIT.READY_CHECK or SOUNDKIT.TELL_MESSAGE or 3081, "Master")
    end
    if FlashClientIcon then FlashClientIcon() end
end

---------------------------------------------------------------------------
-- online presence: every client says hello on login and every few minutes
---------------------------------------------------------------------------
local ONLINE_TTL, HEARTBEAT = 330, 240
local online, lastHello, replyPending = {}, 0, false

function ns.Version()
    local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local v = getMeta and getMeta(ADDON_NAME, "Version")
    if type(v) ~= "string" or v == "" then v = "1.6.3" end
    return v
end

local REGIONS = { [1] = "US", [2] = "KR", [3] = "EU", [4] = "TW", [5] = "CN" }
function ns.Region()
    local id = GetCurrentRegion and GetCurrentRegion()
    return REGIONS[id] or (id and tostring(id)) or ""
end

-- "H|sessionId|version|language|level|class|region|race|kudos|week|weekScore" (older clients read only the session id)
function ns.SendHello(query, tries)
    local _, class = UnitClass("player")
    local _, race = UnitRace("player")
    local msg = string.format("%s|%s|%s|%s|%d|%s|%s|%s|%d|%s|%d", query and "HQ" or "H", SID, ns.Version(),
        (GetLocale and GetLocale()) or "", UnitLevel("player") or 0, class or "", ns.Region(), race or "",
        tonumber(DB.kudos) or 0, ns.WeekKey(), ns.WeekScore())
    if Send(msg) then
        lastHello = GetTime()
    elseif (tries or 0) < 5 then
        C_Timer.After(5, function() ns.SendHello(query, (tries or 0) + 1) end)
    end
end

-- players known to run Questynator (by name), for the tooltip tag
local users = {}
function ns.SeenUser(sender)
    if type(sender) == "string" and sender ~= "" then users[Ambiguate(sender, "none")] = GetTime() end
end
function ns.IsUser(name)
    local t = name and users[name]
    return t ~= nil and GetTime() - t < ONLINE_TTL
end

local function UnitKey(unit)
    local name, realm = UnitName(unit)
    if not name then return nil end
    if realm and realm ~= "" then return name .. "-" .. realm end
    return name
end

-- the author: shown on the Stats tab, in /qn about and the minimap tooltip
local AUTHOR = { name = "Bethrayer", realm = "Forever", battletag = "Valacas#21304" }
ns.AUTHOR = AUTHOR

function ns.IsAuthorUnit(unit)
    local name, realm = UnitName(unit)
    if name ~= AUTHOR.name then return false end
    if realm and realm ~= "" then return realm:find(AUTHOR.realm, 1, true) ~= nil end
    return true
end

function ns.AuthorLine()
    local faction = FACTION_HORDE or "Horde"
    return string.format(L["Made by %s"], "|cffffd100" .. AUTHOR.name .. " " .. AUTHOR.realm .. "|r") .. " |cff9d9d9d(" .. faction .. ", PvE, EU)|r"
end

function ns.WhisperAuthor()
    if UnitName("player") == AUTHOR.name then return end
    if ChatFrameUtil and ChatFrameUtil.SendTell then ChatFrameUtil.SendTell(AUTHOR.name)
    elseif ChatFrame_SendTell then ChatFrame_SendTell(AUTHOR.name) end
end

-- WoW can't write to the clipboard: show the BattleTag selected in a box, ready for Ctrl+C
function ns.ShowCopyBattleTag()
    if not (StaticPopupDialogs and StaticPopup_Show) then
        Print("BattleTag: " .. AUTHOR.battletag)
        return
    end
    StaticPopupDialogs["QUESTYNATOR_COPY"] = StaticPopupDialogs["QUESTYNATOR_COPY"] or {
        button1 = OKAY or "OK", hasEditBox = true, editBoxWidth = 220, timeout = 0, whileDead = true, hideOnEscape = true,
        OnShow = function(self, data)
            local box = self.editBox or self.EditBox
            if box then
                box:SetText(data or "")
                box:HighlightText()
                box:SetFocus()
            end
        end,
        EditBoxOnEnterPressed = function(self) self:GetParent():Hide() end,
        EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
    }
    StaticPopupDialogs["QUESTYNATOR_COPY"].text = L["Press Ctrl+C to copy it, then add it as a Battle.net friend."]
    StaticPopup_Show("QUESTYNATOR_COPY", nil, nil, AUTHOR.battletag)
end

function ns.PrintAbout()
    Print(ns.AuthorLine())
    Print(string.format(L["BattleTag: %s"], "|cff00ccff" .. AUTHOR.battletag .. "|r"))
    Print(L["Bugs and ideas: comments on the Questynator page on CurseForge."])
end

function ns.TooltipTag(tooltip)
    if not tooltip or not tooltip.GetUnit then return end
    local _, unit = tooltip:GetUnit()
    if not unit or (issecretvalue and issecretvalue(unit)) then return end
    if not UnitIsPlayer(unit) then return end
    local key = UnitKey(unit)
    if not key or (issecretvalue and issecretvalue(key)) then return end
    if ns.IsAuthorUnit(unit) then
        tooltip:AddLine(ns.L["Questynator author"], 1, 0.6, 0.2)
    elseif UnitIsUnit(unit, "player") or ns.IsUser(key) then
        local kudos = UnitIsUnit(unit, "player") and (tonumber(DB.kudos) or 0) or (ns.UserKudos and ns.UserKudos(key))
        local extra = (kudos and kudos > 0) and ("  |cffffd100" .. string.format(ns.L["%d kudos"], kudos) .. "|r") or ""
        tooltip:AddLine(ns.L["Questynator user"] .. extra, 0.2, 1, 0.2)
    end
end

function ns.SetupTooltipTag()
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tt) pcall(ns.TooltipTag, tt) end)
    elseif GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnTooltipSetUnit", function(tt) pcall(ns.TooltipTag, tt) end)
    end
end

-- stats: groups formed through Questynator and quests turned in while in one
local lastQInvite, lastMembers = -1000, 0
ns.inQGroup = false
function ns.MarkQInvite() lastQInvite = GetTime() end
function ns.CountGroup()
    if not ns.inQGroup then
        ns.inQGroup = true
        DB.stats.groups = DB.stats.groups + 1
        ns.AddWeekly("groups")
    end
end
function ns.OnRosterForStats()
    local members = IsInGroup() and GetNumGroupMembers() or 0
    if members == 0 then
        ns.inQGroup = false
    elseif members > lastMembers and GetTime() - lastQInvite < 120 then
        ns.CountGroup()                          -- someone we invited through Questynator joined
    end
    lastMembers = members
end
function ns.OnQuestTurnedIn()
    if ns.inQGroup and IsInGroup() then
        DB.stats.quests = DB.stats.quests + 1
        ns.AddWeekly("quests")
    end
    if IsInGroup() then pcall(ns.MaybeAskThanks) end
end

function ns.SeenOnline(sid)
    if type(sid) == "string" and sid ~= "" and sid ~= SID then online[sid] = GetTime() end
end

function ns.OnPresence(kind, sid)
    ns.SeenOnline(sid)
    -- a newcomer asked who's here: answer after a random delay so replies don't all land at once
    if kind == "HQ" and not replyPending then
        replyPending = true
        C_Timer.After(1 + math.random() * 9, function()
            replyPending = false
            if GetTime() - lastHello > 15 then ns.SendHello(false) end
        end)
    end
    ns.RequestRefresh()
end

function ns.OnlineCount()
    local n, now = 1, GetTime()              -- 1 = you
    for sid, t in pairs(online) do
        if now - t > ONLINE_TTL then online[sid] = nil else n = n + 1 end
    end
    return n
end

function ns.StartPresence()
    EnsureChannel()
    C_Timer.After(3, function() ns.SendHello(true) end)
    C_Timer.NewTicker(HEARTBEAT, function() EnsureChannel(); ns.SendHello(false) end)
end

---------------------------------------------------------------------------
-- group quests (Blizzard tags and suggested group size)
---------------------------------------------------------------------------
local TAG_LABEL = { [1] = "Group", [81] = "Dungeon", [62] = "Raid", [88] = "Raid", [89] = "Raid" }

function ns.GroupInfo(questID, suggested)
    local size = tonumber(suggested) or 0
    if size == 0 then
        local idx = ns.QuestLogIndex(questID)
        local info = idx and C_QuestLog.GetInfo(idx)
        size = info and tonumber(info.suggestedGroup) or 0
    end
    local tag = C_QuestLog.GetQuestTagInfo and C_QuestLog.GetQuestTagInfo(questID)
    local kind = type(tag) == "table" and TAG_LABEL[tag.tagID] or nil
    if kind == "Dungeon" or kind == "Raid" then return L[kind] end
    if size > 1 then return string.format(L["Group %d+"], size) end
    if kind then return L[kind] end
    if type(tag) == "table" and tag.isElite then return L["Elite"] end
    return nil
end

-- bitmask of this quest's objectives that are still unfinished (bit i-1 = objective i); 0 = unknown
function ns.NeedMask(questID)
    local objs = C_QuestLog.GetQuestObjectives and C_QuestLog.GetQuestObjectives(questID)
    local mask = 0
    if type(objs) == "table" then
        for i, o in ipairs(objs) do
            if i > MAX_OBJ then break end
            if not o.finished then mask = mask + math.floor(2 ^ (i - 1)) end
        end
    end
    return mask
end

-- objective masks overlap (0 = unknown, matches anything)
local function Overlap(a, b)
    if not band or a == 0 or b == 0 then return true end
    return band(a, b) ~= 0
end

-- isReply beacons answer someone else's beacon; receivers never answer a reply,
-- so two clients can't ping-pong each other.
local function Beacon(questID, force, isReply)
    local s = seeking[questID]
    if not s then return end
    local now = GetTime()
    if not force and s.lastBeacon and now - s.lastBeacon < 3 then return end
    local previous = s.lastBeacon
    s.lastBeacon = now
    local LST = s.listing
    -- S|quest|myLevel|state|isReply|isHost|hostMinLvl|hostMaxLvl|objectivesINeed|objectivesHostWants|sessionId|class
    local msg = string.format("S|%d|%d|%d|%d|%d|%d|%d|%d|%d|%s|%s", questID, UnitLevel("player"), MyState(),
        isReply and 1 or 0, LST and 1 or 0, LST and LST.min or 0, LST and LST.max or 0, ns.NeedMask(questID), LST and LST.want or 0, SID,
        (UnitClass and select(2, UnitClass("player"))) or "")
    if LST then
        local function clean(v, n) return (tostring(v or ""):gsub("|", "")):sub(1, n) end
        msg = msg .. "|" .. clean(QuestTitle(questID), 60) .. "|" .. clean(GetRealZoneText and GetRealZoneText(), 40)
            .. "|" .. (IsInGroup() and GetNumGroupMembers() or 1) .. "|" .. ns.PendingHostInvites()
    end
    if not Send(msg) then
        s.lastBeacon = previous
    end
end

---------------------------------------------------------------------------
-- matching
---------------------------------------------------------------------------
-- chat text without colors/link codes, lowercased (server may rewrite quest links)
function ns.PlainText(t)
    if type(t) ~= "string" then return "" end
    t = t:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h(.-)|h", "%1")
    return (t:gsub("%s+", " "):gsub("^ ", ""):gsub(" $", ""):lower())
end

-- is this chat sender me? GUID first (reliable), then the bare character name
local function IsMe(sender, guid)
    if guid and UnitGUID and not (issecretvalue and issecretvalue(guid)) and guid == UnitGUID("player") then
        return true
    end
    if type(sender) ~= "string" or (issecretvalue and issecretvalue(sender)) then return false end
    if Same(sender, MyFullName()) then return true end
    -- character names never contain spaces or hyphens, so the first word is always the name,
    -- whatever follows it ("Name-Realm", "Name Forever", "Name")
    local bare = sender:match("^%s*([^%-%s]+)")
    return bare ~= nil and bare == UnitName("player")
end
ns.IsMe = IsMe

-- admin test mode: fake players exist only on this screen, so nothing real is sent to them
ns.testMode = false
local function TestBlocked(what)
    if not ns.testMode then return false end
    Print("|cff888888[test] " .. what .. "|r")
    return true
end
ns.TestBlocked = TestBlocked

local Invite
do
    local pending = {}
    local function Key(name)
        local realm = GetNormalizedRealmName and GetNormalizedRealmName()
        if realm and realm ~= "" and not name:find("-", 1, true) then name = name .. "-" .. realm end
        return name:lower()
    end

    function ns.PendingHostInvites(target)
        local now, count, inParty = GetTime(), 0, false
        local targetKey = target and Key(target)
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) then
                local name = (GetUnitName and GetUnitName(unit, true)) or UnitName(unit)
                if name and not (issecretvalue and issecretvalue(name)) then
                    local key = Key(name)
                    pending[key] = nil
                    if targetKey == key then inParty = true end
                end
            end
        end
        for key, expires in pairs(pending) do
            if now >= expires then pending[key] = nil else count = count + 1 end
        end
        return count, inParty or pending[targetKey] ~= nil
    end

    Invite = function(name, automatic)
        if IsMe(name) or TestBlocked("would invite " .. tostring(name)) then return false end
        if automatic then
            if MyState() == 1 or (IsInRaid and IsInRaid()) then return false end
            if ns.trustInviter and GetTime() - ns.trustInviter.t < 90 then return false end
            local count, duplicate = ns.PendingHostInvites(name)
            local members = IsInGroup() and GetNumGroupMembers() or 1
            if duplicate or members + count >= MAX_PARTY then return false end
        end
        local inv = (C_PartyInfo and C_PartyInfo.InviteUnit) or InviteUnit
        if not inv then return false end
        local ok, sent = pcall(inv, name)
        if not ok or sent == false then return false end
        pending[Key(name)] = GetTime() + 60
        if ns.MarkQInvite then ns.MarkQInvite() end
        return true
    end
end

-- matching helpers (one table, not separate locals: the main chunk is close to Lua 5.1's 200-local limit)
local Match = { MERGE_WAIT = 45, PENDING_INVITE_TTL = 10 }

-- "Name-Realm" for any sender, so both clients compare the same strings when ranking hosts
-- (a sender without a realm is on ours)
function Match.RankName(name)
    name = tostring(name or "")
    if name:find("-", 1, true) then return name end
    local realm = GetNormalizedRealmName and GetNormalizedRealmName() or ""
    return (realm ~= "") and (name .. "-" .. realm) or name
end

function Match.InRange(level, lo, hi)
    return type(level) == "number" and type(lo) == "number" and type(hi) == "number" and level >= lo and level <= hi
end

-- two solo hosts on the same quest merge into one group when each fits the other's listing
-- (level range and objectives). The rule is symmetric, so both clients reach the same answer;
-- the lower name then invites the other. Hosts that already lead a party are never merged.
-- Match.MERGE_WAIT: seconds a higher-name host waits for the merge invite before going on alone
function Match.HostsMerge(LST, myLevel, myNeed, p)
    return LST ~= nil and p.host and p.state == 0 and MyState() == 0
        and Match.InRange(myLevel, p.min, p.max) and Match.InRange(p.level, LST.min, LST.max)
        and Overlap(myNeed, p.want) and Overlap(p.need, LST.want or 0)
end

-- would `name` (a peer on this quest) invite me under the rules in Evaluate? Mirrors the inviter's side,
-- so auto-accept only takes invites the matcher could have sent.
function Match.InviterFits(questID, s, name, p, now)
    if not p or now - p.t > PEER_TTL then return false end
    local myLevel, myNeed, LST = UnitLevel("player"), ns.NeedMask(questID), s.listing
    if LST then
        -- I host this quest: only a compatible solo host that outranks me merges me in
        return Match.HostsMerge(LST, myLevel, myNeed, p) and Match.RankName(name) < Match.RankName(MyFullName())
    end
    if p.host then return Match.InRange(myLevel, p.min, p.max) and Overlap(myNeed, p.want) end
    if math.abs((p.level or 0) - myLevel) > DB.levelRange then return false end
    if p.state == 2 then return true end                  -- a party leader on my quest
    return p.state == 0 and Overlap(p.need, myNeed)       -- a solo seeker hosting by name order
end

local function Evaluate(questID)
    local s = seeking[questID]
    if not s then return end

    local state = MyState()
    if state == 1 then return end                 -- member, not leader: leader handles invites

    local now, myLevel, me = GetTime(), UnitLevel("player"), MyFullName()
    local LST = s.listing                            -- set when I created a group (I'm the host)
    local lo, hi = myLevel - DB.levelRange, myLevel + DB.levelRange
    if LST then lo, hi = LST.min, LST.max end
    local myNeed = ns.NeedMask(questID)
    local myRank = Match.RankName(me)
    s.mergeWait = s.mergeWait or {}

    local candidates, hostPeer, lowerHost = {}, false, false
    for name, p in pairs(s.peers) do
        if now - p.t > PEER_TTL then
            s.peers[name] = nil
            s.mergeWait[name] = nil
        elseif LST then
            -- I'm hosting: invite solo searchers in my level range who need one of my objectives
            if p.host then
                -- another host: merge only when both of us are solo and compatible; otherwise
                -- each host carries on with its own group
                if state == 0 and Match.HostsMerge(LST, myLevel, myNeed, p) then
                    if Match.RankName(name) < myRank then
                        -- they invite me; wait a while, but don't stall forever if no invite comes
                        s.mergeWait[name] = s.mergeWait[name] or now
                        if now - s.mergeWait[name] < Match.MERGE_WAIT then lowerHost = true end
                    else
                        candidates[#candidates + 1] = name     -- I'm the lower name: I invite them
                    end
                end
            elseif p.state == 0 and p.level >= lo and p.level <= hi and Overlap(p.need, LST.want) then
                candidates[#candidates + 1] = name
            end
        elseif p.host then
            -- someone else is hosting: they invite me if I fit their range and objectives
            if myLevel >= p.min and myLevel <= p.max and Overlap(myNeed, p.want) then hostPeer = true end
        elseif p.state == 2 then
            if math.abs(p.level - myLevel) <= DB.levelRange then hostPeer = true end
        elseif p.state == 0 and p.level >= lo and p.level <= hi and Overlap(p.need, myNeed) then
            candidates[#candidates + 1] = name
        end
    end

    if state == 0 then
        if LST then
            if lowerHost then return end
        else
            if hostPeer then return end           -- a leader/host will invite us
            if #candidates == 0 then return end
            table.sort(candidates)
            if me > candidates[1] then return end -- someone with a lower name hosts
        end
    end

    local slots = MAX_PARTY - (IsInGroup() and GetNumGroupMembers() or 1)
    if slots <= 0 then return end
    table.sort(candidates)
    for _, name in ipairs(candidates) do
        if slots <= 0 then break end
        local count = s.inviteCount[name] or 0
        if count < MAX_INVITES and (not invitedAt[name] or now - invitedAt[name] > 30) and Invite(name, true) then
            invitedAt[name] = now
            s.inviteCount[name] = count + 1
            slots = slots - 1
        end
    end
end

---------------------------------------------------------------------------
-- search lifecycle
---------------------------------------------------------------------------
local function Tick()
    EnsureChannel()
    local now = GetTime()
    for questID, s in pairs(seeking) do
        if now - s.started > DB.timeout then
            ns.Stop(questID, "search timed out")
        elseif C_QuestLog.IsComplete and C_QuestLog.IsComplete(questID) then
            ns.Stop(questID, "quest is complete")
        else
            if not s.lastBeacon or now - s.lastBeacon >= BEACON_EVERY then
                Beacon(questID, true)
            end
            Evaluate(questID)
        end
    end
    ns.RequestRefresh()
end

function ns.IsSearching(questID) return seeking[questID] ~= nil end

function ns.Start(questID)
    -- quests from the Zones tab can be searched before you pick them up
    if not ns.QuestLogIndex(questID) and not (ns.ZoneQuest and ns.ZoneQuest(questID)) then
        Print(L["That quest isn't in your log."])
        return
    end
    EnsureChannel()
    local now = GetTime()
    seeking[questID] = { started = now, promptAt = now + CREATE_AFTER, peers = {}, inviteCount = {}, repliedAt = {} }
    -- offer Keep Searching / Create Group once the search has been empty for a while
    C_Timer.After(CREATE_AFTER + 0.2, function() ns.RequestRefresh() end)
    Print(string.format(L["Looking for players on: %s"], QuestTitle(questID)))
    Beacon(questID, true)
    if not ticker then ticker = C_Timer.NewTicker(TICK, Tick) end
    ns.RequestRefresh()
end

function ns.Stop(questID, why)
    if not seeking[questID] then return end
    Send(string.format("C|%d", questID))
    seeking[questID] = nil
    if why then Print(QuestTitle(questID) .. ": " .. L[why]) end
    if not next(seeking) and ticker then
        ticker:Cancel()
        ticker = nil
    end
    ns.RequestRefresh()
end

function ns.Toggle(questID)
    if seeking[questID] then ns.Stop(questID, "search cancelled") else ns.Start(questID) end
end

---------------------------------------------------------------------------
-- incoming
---------------------------------------------------------------------------
local pendingInvite   -- { who, t }: the current invite, if it arrived before we'd heard the inviter's beacon

-- the quest an invite from `inviter` can be auto-accepted for, or nil: auto-accept on, solo,
-- an active search with fresh beacon data from the inviter, and their level/objective rules fit
function Match.AutoAcceptQuest(inviter, now)
    if not DB.autoAccept or IsInGroup() then return nil end
    for questID, s in pairs(seeking) do
        for name, p in pairs(s.peers) do
            if Same(name, inviter) and Match.InviterFits(questID, s, name, p, now) then return questID end
        end
    end
end

function ns.ClearPendingInvite() pendingInvite = nil end

local function AcceptInvite(inviter, questID)
    pendingInvite = nil
    -- a host merged into another host's group: their listing now stands for the party
    local s = seeking[questID]
    if s and s.listing then
        s.listing = nil
        Beacon(questID, true)
    end
    ns.CountGroup()
    AcceptGroup()
    C_Timer.After(0.1, function() StaticPopup_Hide("PARTY_INVITE") end)
    Print(string.format(L["Joined %s for: %s"], Ambiguate(inviter, "none"), QuestTitle(questID)))
end

---------------------------------------------------------------------------
-- Groups board: every group created with Questynator on your realm/faction
---------------------------------------------------------------------------
local GROUP_TTL = 75
local groups = {}          -- ["Host-Realm#questID"] = entry

function ns.RecordGroup(sender, questID, g)
    local key = sender .. "#" .. questID
    local e = groups[key] or {}
    e.host, e.questID, e.t = sender, questID, GetTime()
    e.level, e.class, e.min, e.max = g.level, g.class, g.min, g.max
    e.want = g.want or 0
    if g.title and g.title ~= "" then e.title = g.title end
    if g.zone and g.zone ~= "" then e.zone = g.zone end
    e.members = g.members or e.members or 1
    e.pending = g.pending or 0
    groups[key] = e
end

function ns.RemoveGroup(sender, questID)
    groups[sender .. "#" .. tostring(questID)] = nil
end

function ns.GroupNeedsMatch(entry)
    return not entry.wantedObjectives or entry.wantedObjectives == 0
        or Overlap(ns.NeedMask(entry.questID), entry.wantedObjectives)
end

function ns.GroupEntries()
    local list, now, myLevel = {}, GetTime(), UnitLevel("player")
    for key, e in pairs(groups) do
        if now - e.t > GROUP_TTL then
            groups[key] = nil
        else
            list[#list + 1] = {
                host = e.host, questID = e.questID, level = e.level, class = e.class,
                min = e.min, max = e.max, zone = e.zone, members = e.members, pending = e.pending, t = e.t,
                title = e.title or QuestTitle(e.questID),
                haveQuest = ns.QuestLogIndex(e.questID) ~= nil,
                fits = myLevel >= (e.min or 0) and myLevel <= ((e.max and e.max > 0) and e.max or 999),
                wantedObjectives = e.want,
            }
        end
    end
    -- your own listed groups (your beacons don't come back to you)
    for questID, s in pairs(seeking) do
        local LST = s.listing
        if LST then
            list[#list + 1] = {
                host = MyFullName(), questID = questID, level = myLevel,
                class = UnitClass and select(2, UnitClass("player")) or nil,
                min = LST.min, max = LST.max, zone = GetRealZoneText and GetRealZoneText() or nil,
                members = IsInGroup() and GetNumGroupMembers() or 1, pending = ns.PendingHostInvites(), t = now, mine = true,
                title = QuestTitle(questID), haveQuest = true, fits = true,
            }
        end
    end
    table.sort(list, function(a, b)
        if (a.mine or false) ~= (b.mine or false) then return a.mine == true end
        if a.haveQuest ~= b.haveQuest then return a.haveQuest end
        if a.fits ~= b.fits then return a.fits end
        return a.t > b.t
    end)
    return list
end

-- Join = whisper "+" to the host (their Questynator auto-invites, on any version),
-- and trust their invite so it's auto-accepted
function ns.JoinGroup(e)
    if not e or e.mine or not e.host then return end
    if TestBlocked("would whisper + to " .. tostring(e.host)) then return end
    ns.trustInviter = { who = e.host, t = GetTime() }    -- before the whisper, so a fast invite is already trusted
    SendChatMessage("+", "WHISPER", nil, e.host)
    Print(string.format(L["Asked %s for an invite."], Ambiguate(e.host, "none")))
end

local function OnAddonMessage(prefix, text, channel, sender)
    if prefix ~= PREFIX then return end
    if issecretvalue and (issecretvalue(text) or issecretvalue(sender)) then return end
    if channel == "WHISPER" then
        if text and sender then
            local roles = text:match("^DJ|%d+|([THD]*)$")
            if roles then ns.OnDungeonJoinInfo(sender, roles) else ns.OnAdminWhisper(text, sender) end
        end
        return
    end
    if channel == "PARTY" or channel == "RAID" then
        if text and sender then ns.OnGroupMessage(text, sender) end
        return
    end
    if channel ~= "CHANNEL" then return end
    if not text or not sender or Same(sender, MyFullName()) then return end

    local kind, qid, lvl, st, reply, host, minL, maxL, need, want, sid, cls = strsplit("|", text)
    ns.SeenUser(sender)
    if kind == "H" or kind == "HQ" then      -- presence: "H|sessionId|version|..."
        if qid ~= SID then
            ns.OnPresence(kind, qid)
            ns.CheckNewer(lvl)                 -- 3rd field = their version
            ns.OnHelloInfo(sender, host, need, want, sid)   -- class, kudos, week, weekly score
        end
        return
    end
    if kind == "A" then ns.OnAnnounce(sender, text); return end
    if kind == "D" then ns.OnDungeonBeacon(sender, qid, lvl, st, reply, host, minL, maxL, need); return end
    if kind == "DC" then ns.OnDungeonCancel(sender, qid); return end
    if sid == SID then return end            -- our own beacon echoed back
    ns.SeenOnline(sid)
    qid = tonumber(qid)
    if qid and kind == "S" then ns.NotePopular(qid, sender, lvl, (select(13, strsplit("|", text)))) end
    if qid and kind == "S" and host == "1" then
        local gTitle, gZone, gMembers, gPending = select(13, strsplit("|", text))
        ns.RecordGroup(sender, qid, {
            level = tonumber(lvl), class = (type(cls) == "string" and cls ~= "") and cls or nil,
            min = tonumber(minL) or 0, max = tonumber(maxL) or 0,
            title = gTitle, zone = gZone, members = tonumber(gMembers), want = tonumber(want),
            pending = math.max(0, math.min(MAX_PARTY - 1, tonumber(gPending) or 0)),
        })
        ns.RequestRefresh()
    elseif qid and (kind == "C" or (kind == "S" and host ~= "1")) then
        ns.RemoveGroup(sender, qid)
    end
    local s = qid and seeking[qid]
    if not s then return end

    if kind == "C" then
        s.peers[sender] = nil
    elseif kind == "S" then
        local now = GetTime()
        if not s.peers[sender] then ns.Alert() end   -- someone new on this quest
        s.peers[sender] = {
            t = now, level = tonumber(lvl) or 1, state = tonumber(st) or 0,
            host = (host == "1"), min = tonumber(minL) or 0, max = tonumber(maxL) or 0,
            need = tonumber(need) or 0, want = tonumber(want) or 0,
            class = (type(cls) == "string" and cls ~= "") and cls or nil,
        }

        -- answer a newcomer's beacon (once per peer every few seconds; never answer a reply)
        if reply ~= "1" and (not s.repliedAt[sender] or now - s.repliedAt[sender] > 3) then
            s.repliedAt[sender] = now
            Beacon(qid, true, true)
        end

        -- an invite from this peer got here before their beacon did: same checks as an immediate accept
        if pendingInvite and now - pendingInvite.t >= Match.PENDING_INVITE_TTL then
            pendingInvite = nil
        elseif pendingInvite and Same(pendingInvite.who, sender) then
            local acceptFor = Match.AutoAcceptQuest(pendingInvite.who, now)
            if acceptFor then AcceptInvite(pendingInvite.who, acceptFor) end
        end
        Evaluate(qid)
    end
    ns.RequestRefresh()
end

local function OnPartyInvite(inviter)
    pendingInvite = nil              -- a new invite replaces any earlier one we were holding
    if not DB.autoAccept or IsInGroup() then return end
    if issecretvalue and issecretvalue(inviter) then return end
    if type(inviter) ~= "string" then return end
    local now = GetTime()
    local trust = ns.trustInviter
    if trust and now - trust.t < 90 and Same(trust.who, inviter) then
        ns.trustInviter = nil
        AcceptGroup()
        C_Timer.After(0.1, function() StaticPopup_Hide("PARTY_INVITE") end)
        ns.CountGroup()
        Print(string.format(L["Joined %s for: %s"], Ambiguate(inviter, "none"), L["their group"]))
        return
    end
    local questID = Match.AutoAcceptQuest(inviter, now)
    if questID then
        AcceptInvite(inviter, questID)
        return
    end
    -- Not a matching peer (yet). The invite and the inviter's beacon travel separately,
    -- so hold on to it briefly; OnAddonMessage accepts it if a fitting beacon shows up.
    if next(seeking) then pendingInvite = { who = inviter, t = now } end
end

-- hosting: someone whispers "inv" (they saw our General chat post) -> invite them
local function OnWhisper(text, sender)
    if issecretvalue and (issecretvalue(text) or issecretvalue(sender)) then return end
    if type(text) ~= "string" or type(sender) ~= "string" then return end
    local word = text:lower():match("^%s*(%S+)")
    if word ~= "inv" and word ~= "invite" and word ~= "+" then return end
    if ns.OnDungeonWhisper(sender, text) then return end
    for questID, s in pairs(seeking) do
        local LST = s.listing
        if LST and LST.autoInvite then
            local count = s.inviteCount[sender] or 0
            if count < MAX_INVITES and Invite(sender, true) then
                s.inviteCount[sender] = count + 1
                ns.Alert()
                Print(string.format(L["Invited %s (whispered +) for: %s"], Ambiguate(sender, "none"), QuestTitle(questID)))
            end
            return
        end
    end
end

local function OnGroupUpdate()
    ns.PendingHostInvites()
    ns.OnRosterForStats()
    pcall(ns.OnPartyRoster)
    pcall(ns.CheckDungeonLeader)
    local grouped = IsInGroup()
    if grouped then pendingInvite = nil end
    if grouped and not wasGrouped then Print(L["Party formed."]) end
    wasGrouped = grouped
    if grouped and GetNumGroupMembers() >= MAX_PARTY then
        for questID in pairs(seeking) do ns.Stop(questID, "party is full") end
    else
        local member = grouped and not UnitIsGroupLeader("player")
        for questID, search in pairs(seeking) do
            local withdraw = member and search.listing ~= nil
            if withdraw then search.listing = nil end
            Beacon(questID, withdraw)
        end
    end
    ns.RequestRefresh()
end

---------------------------------------------------------------------------
-- chat scanner: spot players in public chat who are looking for one of your quests
---------------------------------------------------------------------------
local CHAT_TTL = 600
local chatHits = {}        -- [questID] = { [sender] = { t, text } }
local LFG_WORDS = {}
for w in ("lfg lfm lf lf1m lf2m lf3m lf4m group grp help need needs anyone any1 inv invite party join "
        .. "duo trio + quest "
        .. "gruppe grp suche suchen hilfe brauche jemand "                 -- German
        .. "groupe cherche aide besoin qqn "                               -- French
        .. "grupo busco buscando ayuda necesito alguien "                  -- Spanish
        .. "группа группу группы ищу помощь помогите нужна нужен кто пати гр"  -- Russian
        ):gmatch("%S+") do LFG_WORDS[w] = true end

local function HasLFGWord(lower)
    for w in lower:gmatch("[%w%+\128-\255]+") do       -- \128-\255 keeps UTF-8 letters (Cyrillic, accents)
        if LFG_WORDS[w] then return true end
    end
    return false
end

local function QuestOpen(questID)
    if not ns.QuestLogIndex(questID) then return false end
    return not (C_QuestLog.IsComplete and C_QuestLog.IsComplete(questID))
end

function ns.ChatHits(questID)
    local list, now = {}, GetTime()
    local hits = chatHits[questID]
    if not hits then return list end
    for name, h in pairs(hits) do
        if now - h.t > CHAT_TTL then hits[name] = nil
        else list[#list + 1] = { name = name, t = h.t, text = h.text, class = h.class, level = h.level } end
    end
    table.sort(list, function(a, b) return a.t > b.t end)
    return list
end

-- quest IDs from your log that this chat line is about
function ns.MatchChat(text)
    local hits = {}
    for idText in text:gmatch("|Hquest:(%d+)") do
        local id = tonumber(idText)
        if id and QuestOpen(id) then hits[id] = true end
    end
    if next(hits) then return hits end
    local lower = text:lower()
    if not HasLFGWord(lower) then return hits end
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and info.questID and type(info.title) == "string" and #info.title >= 6
            and QuestOpen(info.questID) and lower:find(info.title:lower(), 1, true) then
            hits[info.questID] = true
        end
    end
    return hits
end

function ns.OnPublicChat(text, sender, channelBase, guid)
    if not DB.chatScan then return end
    if issecretvalue and (issecretvalue(text) or issecretvalue(sender)) then return end
    if type(text) ~= "string" or type(sender) ~= "string" or sender == "" then return end
    if channelBase == CHANNEL or IsMe(sender, guid) then return end
    if ns.lastPost and GetTime() - ns.lastPost.t < 120 and ns.PlainText(text) == ns.lastPost.plain then return end   -- our own LFG post
    if IsInGroup() and GetNumGroupMembers() >= MAX_PARTY then return end
    if UnitInParty and UnitInParty(Ambiguate(sender, "none")) then return end
    local hits = ns.MatchChat(text)
    local now, any = GetTime(), false
    local hitClass, hitLevel
    if next(hits) and guid and GetPlayerInfoByGUID and not (issecretvalue and issecretvalue(guid)) then
        local ok, _, englishClass, _, _, _, _, _, level = pcall(GetPlayerInfoByGUID, guid)
        if ok then
            hitClass = type(englishClass) == "string" and englishClass ~= "" and englishClass or nil
            hitLevel = type(level) == "number" and level > 0 and level or nil
        end
    end
    for questID in pairs(hits) do
        any = true
        if ns.debug then
            Print(string.format("chat hit: sender=%s guid=%s myGUID=%s myName=%s", tostring(sender), tostring(guid),
                tostring(UnitGUID and UnitGUID("player")), tostring(UnitName("player"))))
        end
        chatHits[questID] = chatHits[questID] or {}
        local prev = chatHits[questID][sender]
        chatHits[questID][sender] = { t = now, text = text, class = hitClass, level = hitLevel }
        if not prev or now - prev.t > 120 then
            ns.ShowChatToast(questID, sender, text)
            ns.Alert()
        end
    end
    if any then ns.RequestRefresh() end
end

local function PlainChat(text)
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h(.-)|h", "%1")
    if #text > 90 then text = text:sub(1, 87) .. "..." end
    return text
end

local function Whisper(name)
    if TestBlocked("would whisper " .. tostring(name)) then return end
    local short = Ambiguate(name, "none")
    if ChatFrameUtil and ChatFrameUtil.SendTell then ChatFrameUtil.SendTell(short)
    elseif ChatFrame_SendTell then ChatFrame_SendTell(short) end
end

---------------------------------------------------------------------------
-- Midnight theme: flat dark panels, one teal accent, Arial Narrow
---------------------------------------------------------------------------
do
    local UI = {}
    ns.UI = UI
    UI.FONT = "Fonts\\ARIALN.TTF"
    local FONT_DIR = "Interface\\AddOns\\Questynator\\Media\\Fonts\\"
    UI.FONTS = { regular = FONT_DIR .. "Poppins-Regular.ttf", medium = FONT_DIR .. "Poppins-Medium.ttf", bold = FONT_DIR .. "Poppins-Bold.ttf" }
    -- Poppins has Latin only: Russian (and Asian) clients keep the game's own font
    local LATIN = { enUS = true, enGB = true, deDE = true, frFR = true, esES = true, esMX = true, itIT = true, ptBR = true }
    function UI.Face(weight)
        local loc = GetLocale and GetLocale() or "enUS"
        if LATIN[loc] then return UI.FONTS[weight or "regular"] or UI.FONTS.regular end
        return STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    end
    UI.C = {
        accent = { 0.31, 0.82, 0.77 },   -- #4fd1c5
        bg     = { 0.06, 0.07, 0.08, 0.95 },
        panel  = { 0.094, 0.106, 0.133, 1 },
        panel2 = { 0.12, 0.135, 0.165, 1 },
        line   = { 0.15, 0.165, 0.2, 1 },
        text   = { 0.91, 0.90, 0.89 },
        muted  = { 0.545, 0.56, 0.6 },
        dim    = { 0.36, 0.38, 0.42 },
        dark   = { 0.043, 0.05, 0.063 },
        red    = { 0.94, 0.42, 0.42 },
        gold   = { 1, 0.82, 0.3 },
    }
    UI.HEX = { accent = "4fd1c5", text = "e8e6e3", muted = "8b8f98", dim = "5b606b", red = "f06b6b", gold = "ffd14d", green = "5fd38a" }
    local C = UI.C

    function UI.Font(fs, size, flags, weight)
        if not (fs and fs.SetFont) then return fs end
        local ok, set = pcall(fs.SetFont, fs, UI.Face(weight), size or 12, flags or "")
        if not ok or set == false then pcall(fs.SetFont, fs, UI.FONT, size or 12, flags or "") end
        -- flat look: no drop shadow (WoW's font templates add a 1px shadow down-right)
        if fs.SetShadowOffset then fs:SetShadowOffset(0, 0) end
        if fs.SetShadowColor then fs:SetShadowColor(0, 0, 0, 0) end
        return fs
    end

    function UI.Text(parent, size, color, layer, weight)
        local fs = parent:CreateFontString(nil, layer or "OVERLAY", "GameFontHighlight")
        UI.Font(fs, size or 12, nil, weight)
        local c = C[color or "text"] or C.text
        fs:SetTextColor(c[1], c[2], c[3])
        return fs
    end

    -- rounded box built from 9 pieces of a 32x32 rounded-rect texture (6px corners)
    local MEDIA = "Interface\\AddOns\\Questynator\\Media\\"
    -- the 64px texture is cut at 24 texels, past the end of the 15-texel curve, so seams sit on
    -- straight edges and pixel rounding can't show a step; 8 units on screen = ~5 unit radius
    local CORNER, SLICE, TEX = 8, 24, 64
    local function NineSlice(f, file, layer, sub)
        local parts = {}
        local c = SLICE / TEX
        local cols = { { 0, c }, { c, 1 - c }, { 1 - c, 1 } }
        for row = 1, 3 do
            for col = 1, 3 do
                local t = f:CreateTexture(nil, layer, nil, sub)
                t:SetTexture(MEDIA .. file)
                t:SetTexCoord(cols[col][1], cols[col][2], cols[row][1], cols[row][2])
                parts[#parts + 1] = t
            end
        end
        local tl, tm, tr, ml, mm, mr, bl, bm, br = (unpack or table.unpack)(parts)
        tl:SetSize(CORNER, CORNER); tl:SetPoint("TOPLEFT")
        tr:SetSize(CORNER, CORNER); tr:SetPoint("TOPRIGHT")
        bl:SetSize(CORNER, CORNER); bl:SetPoint("BOTTOMLEFT")
        br:SetSize(CORNER, CORNER); br:SetPoint("BOTTOMRIGHT")
        tm:SetPoint("TOPLEFT", tl, "TOPRIGHT"); tm:SetPoint("BOTTOMRIGHT", tr, "BOTTOMLEFT")
        bm:SetPoint("TOPLEFT", bl, "TOPRIGHT"); bm:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT")
        ml:SetPoint("TOPLEFT", tl, "BOTTOMLEFT"); ml:SetPoint("BOTTOMRIGHT", bl, "TOPRIGHT")
        mr:SetPoint("TOPLEFT", tr, "BOTTOMLEFT"); mr:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT")
        mm:SetPoint("TOPLEFT", tl, "BOTTOMRIGHT"); mm:SetPoint("BOTTOMRIGHT", br, "TOPLEFT")
        local box = { parts = parts }
        function box:SetColorTexture(r, g, b, a)
            for _, t in ipairs(self.parts) do t:SetVertexColor(r, g, b, a or 1) end
        end
        function box:Show() for _, t in ipairs(self.parts) do t:Show() end end
        function box:Hide() for _, t in ipairs(self.parts) do t:Hide() end end
        function box:SetShown(on) if on then self:Show() else self:Hide() end end
        return box
    end
    UI.NineSlice = NineSlice

    -- rounded fill + 1px rounded border
    function UI.Flat(f, fill, border)
        fill = fill or C.panel
        if not rawget(f, "flatBg") then
            f.flatBg = NineSlice(f, "Round", "BACKGROUND", -8)
            f.flatEdge = NineSlice(f, "RoundEdge", "BORDER", -8)
        end
        f.flatBg:SetColorTexture(fill[1], fill[2], fill[3], fill[4] or 1)
        UI.SetEdge(f, border == false and nil or (border or C.line))
        return f
    end

    function UI.SetEdge(f, c, a)
        local e = rawget(f, "flatEdge")
        if type(e) ~= "table" or type(rawget(e, "parts")) ~= "table" then return end
        if c then e:SetColorTexture(c[1], c[2], c[3], a or c[4] or 1); e:Show() else e:Hide() end
    end

    -- a rounded card (panel fill, line border)
    function UI.Card(parent, w, h)
        local f = CreateFrame("Frame", nil, parent)
        if w then f:SetWidth(w) end
        if h then f:SetHeight(h) end
        UI.Flat(f, C.panel, C.line)
        return f
    end

    -- class badge: tinted rounded square with the class initial (like the mockups)
    function UI.ClassBadge(parent, size)
        local b = CreateFrame("Frame", nil, parent)
        b:SetSize(size or 20, size or 20)
        UI.Flat(b, C.panel2, false)
        b.letter = UI.Text(b, math.floor((size or 20) * 0.5), "text", nil, "bold")
        b.letter:SetPoint("CENTER", 0, 0)
        function b:SetClass(cls, label)
            local c = cls and ((C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(cls))
                or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[cls]))
            local r, g, bl = 0.55, 0.56, 0.6
            if type(c) == "table" and c.r then r, g, bl = c.r, c.g, c.b end
            self.flatBg:SetColorTexture(r, g, bl, 0.22)
            self.letter:SetTextColor(r, g, bl)
            local name = label or (cls and ((LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[cls]) or cls)) or "?"
            self.letter:SetText((tostring(name):match("^[%z\1-\127\194-\244][\128-\191]*") or "?"):upper())
        end
        b:SetClass(nil)
        return b
    end

    -- small caps section header with an optional right-hand note
    function UI.Section(parent)
        local s = CreateFrame("Frame", nil, parent)
        s:SetHeight(20)
        s.label = UI.Text(s, 9, "muted", nil, "bold")
        s.label:SetPoint("LEFT", 2, 0)
        s.note = UI.Text(s, 9, "dim", nil, "medium")
        s.note:SetPoint("RIGHT", -2, 0)
        function s:Set(label, note)
            local up = label or ""
            if not up:find("[\128-\255]") then up = up:upper() end
            self.label:SetText(up)
            self.note:SetText(note or "")
        end
        return s
    end

    -- empty state: "?" circle, title, line, button
    function UI.Empty(parent, onClick)
        local e = CreateFrame("Frame", nil, parent)
        e:SetSize(380, 180)
        e.circle = e:CreateTexture(nil, "ARTWORK")
        e.circle:SetSize(48, 48)
        e.circle:SetPoint("TOP", 0, 0)
        e.circle:SetTexture(MEDIA .. "Circle")
        e.circle:SetVertexColor(C.accent[1] * 0.3, C.accent[2] * 0.3, C.accent[3] * 0.3, 1)
        e.mark = UI.Text(e, 20, "accent", nil, "bold")
        e.mark:SetPoint("CENTER", e.circle, "CENTER", 0, 0)
        e.mark:SetText("?")
        e.title = UI.Text(e, 12, "text", nil, "medium")
        e.title:SetPoint("TOP", e.circle, "BOTTOM", 0, -14)
        e.sub = UI.Text(e, 10, "muted")
        e.sub:SetPoint("TOP", e.title, "BOTTOM", 0, -6)
        e.sub:SetWidth(360)
        e.btn = UI.Button(e, 140, 22, "primary")
        e.btn:SetPoint("TOP", e.sub, "BOTTOM", 0, -12)
        e.btn:SetScript("OnClick", function() if onClick then onClick() end end)
        function e:Set(title, sub, button)
            self.title:SetText(title or "")
            self.sub:SetText(sub or "")
            if button then
                self.btn:SetText(button)
                self.btn:SetWidth((tonumber(self.btn.label:GetStringWidth()) or 100) + 28)
                self.btn:Show()
            else self.btn:Hide() end
        end
        return e
    end

    -- difficulty colour for level badges (Blizzard's own table when present)
    function UI.LevelColor(qlvl, plvl)
        qlvl = tonumber(qlvl) or 0
        plvl = tonumber(plvl) or (UnitLevel and UnitLevel("player")) or 1
        local d = qlvl - plvl
        if d >= 5 then return "ff5c5c"
        elseif d >= 3 then return "ff9c40"
        elseif d >= -2 then return "f2d45c"
        end
        local gray = (GetQuestGreenRange and GetQuestGreenRange()) or (plvl <= 5 and 5 or math.floor(plvl / 10) + 5)
        if -d <= gray then return "5fd38a" end
        return "8b8f98"
    end

    local KINDS = {
        primary = { fill = C.accent, hover = { 0.42, 0.9, 0.85 }, text = C.dark },
        ghost   = { fill = C.panel2, hover = { 0.17, 0.19, 0.23 }, text = C.text, edge = C.line },
        outline = { fill = { 0.31, 0.82, 0.77, 0.08 }, hover = { 0.31, 0.82, 0.77, 0.18 }, text = C.accent, edge = C.accent },
        soft    = { fill = { 0.31, 0.82, 0.77, 0.2 }, hover = { 0.31, 0.82, 0.77, 0.28 }, text = C.accent },
        danger  = { fill = { 0.94, 0.42, 0.42, 0.12 }, hover = { 0.94, 0.42, 0.42, 0.25 }, text = C.red, edge = C.red },
    }

    -- disabled buttons keep their shape: ghost-style with muted text (like "Too high", "Not in log")
    local function Paint(b)
        local k = KINDS[b.kind] or KINDS.ghost
        local enabled = not b.IsEnabled or b:IsEnabled()
        if enabled == false and b.kind ~= "outline" and b.kind ~= "soft" then k = KINDS.ghost end
        local fill = (b.hovered and enabled) and k.hover or k.fill
        b.flatBg:SetColorTexture(fill[1], fill[2], fill[3], fill[4] or 1)
        if k.edge then UI.SetEdge(b, k.edge, b.kind == "outline" and 0.8 or 1) else UI.SetEdge(b, nil) end
        local tc = (enabled == false and k == KINDS.ghost) and C.muted or k.text
        if b.label then b.label:SetTextColor(tc[1], tc[2], tc[3]) end
    end
    UI.PaintButton = Paint

    -- flat button: kind = primary | ghost | outline | danger
    function UI.Button(parent, w, h, kind)
        local b = CreateFrame("Button", nil, parent)
        b:SetSize(w or 90, h or 22)
        b.kind = kind or "ghost"
        UI.Flat(b, C.panel2)
        b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        UI.Font(b.label, 11, nil, "medium")
        b.label:SetPoint("CENTER", 0, 0)
        if b.SetFontString then b:SetFontString(b.label) end
        -- callers set their own OnEnter/OnLeave; keep the hover paint underneath them
        local rawSet = b.SetScript
        function b:SetScript(kind, fn)
            if kind == "OnEnter" or kind == "OnLeave" then
                local hover = (kind == "OnEnter")
                return rawSet(self, kind, function(btn, ...)
                    btn.hovered = hover; Paint(btn)
                    if fn then return fn(btn, ...) end
                end)
            end
            return rawSet(self, kind, fn)
        end
        b:SetScript("OnEnter", nil)
        b:SetScript("OnLeave", nil)
        rawSet(b, "OnEnable", Paint)
        rawSet(b, "OnDisable", Paint)
        function b:SetKind(k) self.kind = k; Paint(self) end
        Paint(b)
        return b
    end

    -- top text tab with an underline
    function UI.Tab(parent, text)
        local t = CreateFrame("Button", nil, parent)
        t:SetHeight(28)
        t.label = t:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        UI.Font(t.label, 12, nil, "medium")
        t.label:SetPoint("LEFT", 2, 1)
        t.badgeBg = CreateFrame("Frame", nil, t)
        t.badgeBg:SetFrameLevel(math.max(0, (tonumber(t:GetFrameLevel()) or 1) - 1))
        UI.Flat(t.badgeBg, { C.accent[1], C.accent[2], C.accent[3], 0.9 }, false)
        t.badge = t:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        UI.Font(t.badge, 9, nil, "bold")
        t.badge:SetPoint("LEFT", t.label, "RIGHT", 9, 0)
        t.badgeBg:SetPoint("TOPLEFT", t.badge, "TOPLEFT", -4, 2)
        t.badgeBg:SetPoint("BOTTOMRIGHT", t.badge, "BOTTOMRIGHT", 4, -2)
        t.line = t:CreateTexture(nil, "OVERLAY")
        t.line:SetHeight(2)
        t.line:SetPoint("BOTTOMLEFT"); t.line:SetPoint("BOTTOMRIGHT")
        t.line:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
        function t:SetLabel(s, badge)
            self.label:SetText(s)
            self.badge:SetText(badge or "")
            if badge and badge ~= "" then self.badgeBg:Show() else self.badgeBg:Hide() end
            local w = (tonumber(self.label:GetStringWidth()) or 50) + ((badge and badge ~= "") and ((tonumber(self.badge:GetStringWidth()) or 12) + 14) or 0)
            self:SetWidth(w + 6)
        end
        function t:SetActive(on)
            self.active = on and true or false
            local c = on and C.text or C.muted
            self.label:SetTextColor(c[1], c[2], c[3])
            self.badge:SetTextColor(C.dark[1], C.dark[2], C.dark[3])
            if on then self.line:Show() else self.line:Hide() end
        end
        t:SetScript("OnEnter", function(self) if not self.active then self.label:SetTextColor(C.text[1], C.text[2], C.text[3]) end end)
        t:SetScript("OnLeave", function(self) self:SetActive(self.active) end)
        t:SetLabel(text)
        t:SetActive(false)
        return t
    end

    -- dark search box with a placeholder
    function UI.SearchBox(parent, w, placeholder, onChange)
        local e = CreateFrame("EditBox", nil, parent)
        e:SetSize(w, 24)
        e:SetAutoFocus(false)
        UI.Flat(e, C.panel)
        UI.SetEdge(e, nil)
        if not pcall(e.SetFont, e, UI.Face(), 11, "") then e:SetFont(UI.FONT, 12, "") end
        if e.SetShadowOffset then e:SetShadowOffset(0, 0) end
        e:SetTextInsets(24, 8, 0, 0)
        e:SetTextColor(C.text[1], C.text[2], C.text[3])
        local icon = e:CreateTexture(nil, "OVERLAY")
        icon:SetSize(12, 12)
        icon:SetPoint("LEFT", 7, 0)
        icon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
        icon:SetVertexColor(C.muted[1], C.muted[2], C.muted[3])
        e.ph = UI.Text(e, 12, "dim")
        e.ph:SetPoint("LEFT", 24, 0)
        e.ph:SetText(placeholder or "")
        e:SetScript("OnEscapePressed", function(self) self:SetText(""); self:ClearFocus() end)
        e:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
        e:SetScript("OnEditFocusGained", function(self) UI.SetEdge(self, C.accent, 0.8) end)
        e:SetScript("OnEditFocusLost", function(self) UI.SetEdge(self, nil) end)
        e:SetScript("OnTextChanged", function(self)
            local s = self:GetText() or ""
            if s == "" then self.ph:Show() else self.ph:Hide() end
            if onChange then onChange(s) end
        end)
        return e
    end

    -- small flat window with a title and an x (toast, create-group dialog)
    function UI.Window(name, w, h)
        local f = CreateFrame("Frame", name, UIParent)
        f:SetSize(w, h)
        UI.Flat(f, C.bg, C.line)
        f.TitleText = UI.Text(f, 13, "text")
        f.TitleText:SetPoint("TOPLEFT", 12, -10)
        local x = CreateFrame("Button", nil, f)
        x:SetSize(20, 20)
        x:SetPoint("TOPRIGHT", -6, -6)
        x.t = UI.Text(x, 14, "muted")
        x.t:SetPoint("CENTER")
        x.t:SetText("x")
        x:SetScript("OnEnter", function(self) self.t:SetTextColor(C.red[1], C.red[2], C.red[3]) end)
        x:SetScript("OnLeave", function(self) self.t:SetTextColor(C.muted[1], C.muted[2], C.muted[3]) end)
        x:SetScript("OnClick", function() f:Hide() end)
        f.CloseButton = x
        return f
    end

    -- flat scrollbar skin for UIPanelScrollFrameTemplate
    function UI.SkinScroll(scroll)
        local bar = scroll and (scroll.ScrollBar or (scroll.GetName and scroll:GetName() and _G[scroll:GetName() .. "ScrollBar"]))
        if type(bar) ~= "table" then return end
        for _, k in ipairs({ "ScrollUpButton", "ScrollDownButton" }) do
            local b = bar[k]
            if type(b) == "table" and b.SetAlpha then b:SetAlpha(0); if b.EnableMouse then b:EnableMouse(false) end end
        end
        local thumb = bar.ThumbTexture or (bar.GetThumbTexture and bar:GetThumbTexture())
        if type(thumb) == "table" and thumb.SetColorTexture then
            thumb:SetColorTexture(C.line[1] + 0.12, C.line[2] + 0.12, C.line[3] + 0.12, 1)
            thumb:SetWidth(4)
        end
    end
end

local toast
local function CreateToast()
    local t = ns.UI.Window("QuestynatorToast", 340, 124)
    t:SetFrameStrata("FULLSCREEN_DIALOG")
    t:SetToplevel(true)
    t:SetClampedToScreen(true)
    t:SetMovable(true)
    t:EnableMouse(true)
    t:RegisterForDrag("LeftButton")
    t:SetScript("OnDragStart", t.StartMoving)
    t:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        DB.toastPos = { point, relPoint, x, y }
    end)
    local pos = DB.toastPos
    if pos then t:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) else t:SetPoint("TOP", 0, -140) end
    if t.TitleText then t.TitleText:SetText(L["Questynator - player found in chat"]) end

    t.who = t:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    t.who:SetPoint("TOPLEFT", 14, -32)
    t.who:SetPoint("RIGHT", -14, 0)
    t.who:SetJustifyH("LEFT")
    t.quest = t:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    t.quest:SetPoint("TOPLEFT", t.who, "BOTTOMLEFT", 0, -4)
    t.quest:SetPoint("RIGHT", -14, 0)
    t.quest:SetJustifyH("LEFT")
    t.quest:SetWordWrap(false)
    t.msg = t:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    t.msg:SetPoint("TOPLEFT", t.quest, "BOTTOMLEFT", 0, -4)
    t.msg:SetPoint("RIGHT", -14, 0)
    t.msg:SetJustifyH("LEFT")
    t.msg:SetWordWrap(false)

    t.invite = ns.UI.Button(t, 90, 22, "primary")
    t.invite:SetSize(90, 22)
    t.invite:SetPoint("BOTTOMRIGHT", -10, 10)
    t.invite:SetText(L["Invite"])
    t.invite:SetScript("OnClick", function()
        if t.sender then Invite(t.sender) end
        t:Hide()
    end)
    t.whisper = ns.UI.Button(t, 90, 22, "ghost")
    t.whisper:SetSize(90, 22)
    t.whisper:SetPoint("RIGHT", t.invite, "LEFT", -6, 0)
    t.whisper:SetText(L["Whisper"])
    t.whisper:SetScript("OnClick", function()
        if t.sender then Whisper(t.sender) end
        t:Hide()
    end)
    t:SetScript("OnUpdate", function(self)
        if self.hideAt and GetTime() > self.hideAt and not self:IsMouseOver() then self:Hide() end
    end)
    if UISpecialFrames then tinsert(UISpecialFrames, "QuestynatorToast") end
    t:Hide()
    return t
end

function ns.ShowChatToast(questID, sender, text)
    if IsMe(sender) then return end
    if not toast then toast = CreateToast() end
    toast.sender, toast.questID = sender, questID
    local h = chatHits[questID] and chatHits[questID][sender]
    local coloured = (ns.ClassColorName and h and h.class) and ns.ClassColorName(sender, h.class)
        or ("|cff33ccff" .. Ambiguate(sender, "none") .. "|r")
    toast.who:SetText(string.format(L["%s is looking for:"], coloured))
    toast.quest:SetText(QuestTitle(questID))
    toast.msg:SetText('"' .. PlainChat(text) .. '"')
    toast.hideAt = GetTime() + 30
    toast:Show()
    toast:Raise()
end

-- reopen the toast for the newest chat hit on a quest (panel "Chat" button)
function ns.ShowLatestChat(questID)
    local h = ns.ChatHits(questID)[1]
    if h then ns.ShowChatToast(questID, h.name, h.text) end
end

---------------------------------------------------------------------------
-- tracker buttons
---------------------------------------------------------------------------
-- same art as Blizzard's quest POI button on the left of each tracked quest
-- (POIButtonTemplate / Blizzard_POIButton\POIButton.lua, normal quest style)
local ICON        = 20
local POI_NORMAL  = "UI-QuestPoi-QuestNumber"
local POI_PRESSED = "UI-QuestPoi-QuestNumber-Pressed"
local POI_ACTIVE  = "UI-QuestPoi-QuestNumber-SuperTracked"          -- used while searching
local POI_ACTIVE_PRESSED = "UI-QuestPoi-QuestNumber-Pressed-SuperTracked"
local POI_HOVER   = "UI-QuestPoi-InnerGlow"
local POI_GLOW    = "UI-QuestPoi-OuterGlow"
local GOLD        = { 1, 0.82, 0 }
local GREEN       = { 0.2, 1, 0.2 }
local ORANGE      = { 1, 0.6, 0.2 }

local function UpdateButton(btn)
    local s = btn.questID and seeking[btn.questID]
    btn.normal:SetAtlas(s and POI_ACTIVE or POI_NORMAL, true)
    btn.pushed:SetAtlas(s and POI_ACTIVE_PRESSED or POI_PRESSED, true)
    btn.glow:SetShown(s and true or false)
    local c = s and GREEN or (btn.group and ORANGE or GOLD)   -- orange = group/elite quest
    btn.text:SetTextColor(c[1], c[2], c[3])
    local n = s and CountPeers(s) or 0
    btn.badge:SetText(n > 0 and tostring(n) or "")
end

local function ShowTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Questynator")
    if self.group then GameTooltip:AddLine(string.format(L["Group quest: %s"], self.group), 1, 0.6, 0.2) end
    local nChat = self.questID and #ns.ChatHits(self.questID) or 0
    if nChat > 0 then GameTooltip:AddLine(string.format(L["Looking in chat: %d"], nChat), 0.2, 0.8, 1) end
    local s = self.questID and seeking[self.questID]
    if s then
        GameTooltip:AddLine(string.format(L["Searching... players found: %d"], CountPeers(s)), 0.2, 1, 0.2)
        GameTooltip:AddLine(L["Left-click: open Questynator"], 1, 1, 1)
        GameTooltip:AddLine(L["Right-click: stop searching"], 1, 1, 1)
    else
        GameTooltip:AddLine(L["Click to find other Questynator players on this quest and open Questynator."], 1, 1, 1, true)
    end
    GameTooltip:Show()
end

local function CreateButton(block)
    local btn = CreateFrame("Button", nil, block)
    btn:SetSize(ICON, ICON)
    btn:SetFrameLevel(block:GetFrameLevel() + 5)

    btn.glow = btn:CreateTexture(nil, "BACKGROUND")
    btn.glow:SetAtlas(POI_GLOW, true)
    btn.glow:SetBlendMode("ADD")
    btn.glow:SetPoint("CENTER")
    btn.glow:Hide()

    btn:SetNormalAtlas(POI_NORMAL)
    btn:SetPushedAtlas(POI_PRESSED)
    btn.normal, btn.pushed = btn:GetNormalTexture(), btn:GetPushedTexture()
    for _, t in ipairs({ btn.normal, btn.pushed }) do
        if type(t) == "table" and t.ClearAllPoints then
            t:SetAtlas(t == btn.normal and POI_NORMAL or POI_PRESSED, true)   -- native atlas size, like Blizzard
            t:ClearAllPoints()
            t:SetPoint("CENTER")
        end
    end

    btn.hoverTex = btn:CreateTexture(nil, "OVERLAY")
    btn.hoverTex:SetAtlas(POI_HOVER, true)
    btn.hoverTex:SetBlendMode("ADD")
    btn.hoverTex:SetPoint("CENTER")
    btn.hoverTex:Hide()

    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.text:SetPoint("CENTER", 0, 0)
    btn.text:SetText("LFG")
    local face, _, flags = btn.text:GetFont()
    if face then btn.text:SetFont(face, 8, flags) end
    btn:SetScript("OnMouseDown", function(self) self.text:SetPoint("CENTER", 1, -1) end)
    btn:SetScript("OnMouseUp", function(self) self.text:SetPoint("CENTER", 0, 0) end)

    btn.badge = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")   -- players found
    btn.badge:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 4, -3)

    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:SetScript("OnClick", function(self, button)
        local questID = self.questID
        if not questID then return end
        if button == "RightButton" then
            ns.Stop(questID, "search cancelled")
            return
        end
        if not seeking[questID] then ns.Start(questID) end
        ns.ShowPanel()
    end)
    btn:SetScript("OnEnter", function(self) self.hoverTex:Show(); ShowTooltip(self) end)
    btn:SetScript("OnLeave", function(self) self.hoverTex:Hide(); GameTooltip:Hide() end)
    return btn
end

local function IsFrame(v)
    return type(v) == "table" and type(v.IsShown) == "function"
end

local function RefreshTracker()
    pendingRefresh = false
    local seen = {}

    local function Consider(block, key)
        if not IsFrame(block) then return end
        local questID = block.id or key
        if type(questID) ~= "number" then return end
        if not ns.QuestLogIndex(questID) then return end
        if not block:IsShown() then return end
        local btn = buttons[block]
        if not btn then
            btn = CreateButton(block)
            buttons[block] = btn
        end
        btn.questID = questID
        btn.group = ns.GroupInfo(questID) or false
        -- sit just left of Blizzard's quest icon (block.poiButton); it's recycled, so re-anchor every time
        btn:ClearAllPoints()
        local poi = block.poiButton
        if IsFrame(poi) and poi:IsShown() then
            btn:SetPoint("RIGHT", poi, "LEFT", -2, 0)
        elseif IsFrame(block.HeaderText) then
            btn:SetPoint("TOPRIGHT", block.HeaderText, "TOPLEFT", -31, 4)   -- where icon + gap would be
        else
            btn:SetPoint("TOPRIGHT", block, "TOPLEFT", -2, 0)
        end
        btn:Show()
        UpdateButton(btn)
        seen[btn] = true
    end

    local m = QuestObjectiveTracker
    if m and type(m.usedBlocks) == "table" then
        for key, v in pairs(m.usedBlocks) do
            if IsFrame(v) then
                Consider(v, key)                       -- flat: usedBlocks[id] = block
            elseif type(v) == "table" then
                for id, block in pairs(v) do Consider(block, id) end   -- usedBlocks[template][id]
            end
        end
    end

    for _, btn in pairs(buttons) do
        if not seen[btn] then btn:Hide() end
    end
end

---------------------------------------------------------------------------
-- quest panel: our own window listing the quest log
---------------------------------------------------------------------------
local panel, content, footer, stopAll, emptyText
local panelRows = {}
local ROW_W, QUEST_H, HEADER_H = 508, 48, 30
local KEEP_SEARCHING_FOR = 30   -- "Keep Searching" hides the prompt for this long

-- Active searches first, then the quest log grouped by zone (zones can be collapsed)
local questFilter = ""
function ns.SetQuestFilter(text)
    questFilter = ((text or ""):lower()):gsub("^%s+", ""):gsub("%s+$", "")
end
function ns.QuestFilter() return questFilter end

local function BuildEntries()
    local zones, order, active = {}, {}, {}
    local filter = questFilter
    local cur = nil
    local function zone(name)
        name = name or "Other"
        if not zones[name] then zones[name] = {}; order[#order + 1] = name end
        return name
    end
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        if info then
            if info.isHeader then
                cur = zone(info.title)
            elseif not info.isHidden and info.questID
                and not (C_QuestLog.IsComplete and C_QuestLog.IsComplete(info.questID))   -- hide completed quests
                and (filter == "" or (info.title or ""):lower():find(filter, 1, true)) then
                local e = {
                    questID  = info.questID,
                    title    = info.title or ("quest " .. info.questID),
                    level    = info.level,
                    group    = ns.GroupInfo(info.questID, info.suggestedGroup),
                    order    = i,
                    complete = C_QuestLog.IsComplete and C_QuestLog.IsComplete(info.questID) or false,
                }
                if seeking[info.questID] then
                    active[#active + 1] = e
                else
                    local z = cur or zone(nil)
                    table.insert(zones[z], e)
                end
            end
        end
    end
    local out = {}
    if #active > 0 then
        out[#out + 1] = { header = L["Searching now"], active = true, count = #active }
        for _, e in ipairs(active) do out[#out + 1] = e end
    end
    for _, z in ipairs(order) do
        local list = zones[z]
        table.sort(list, function(a, b)          -- group/elite quests first, otherwise quest log order
            if (a.group ~= nil) ~= (b.group ~= nil) then return a.group ~= nil end
            return a.order < b.order
        end)
        if #list > 0 then
            local collapsed = DB.collapsed[z] and true or false
            out[#out + 1] = { header = z, zone = z, count = #list, collapsed = collapsed }
            if not collapsed then
                for _, e in ipairs(list) do out[#out + 1] = e end
            end
        end
    end
    return out
end
ns.BuildEntries = BuildEntries

function ns.ToggleZone(z)
    if not z then return end
    DB.collapsed[z] = (not DB.collapsed[z]) or nil
    ns.RequestRefresh()
end

-- what a quest row should show right now
local function RowState(questID, complete)
    local s = seeking[questID]
    if not s then return complete and "complete" or "idle" end
    if s.listing then return "listed" end
    if CountPeers(s) > 0 then return "found" end
    if GetTime() >= (s.promptAt or math.huge) then return "prompt" end
    return "searching"
end

local function Elapsed(s)
    local t = math.floor(GetTime() - s.started)
    return string.format("%d:%02d", math.floor(t / 60), t % 60)
end

function ns.UnmatchedQuestSearch()
    local first, started
    for id, s in pairs(seeking) do
        if RowState(id) == "prompt" and not ns.IsReadyToTurnIn(id)
            and (not started or s.started < started or (s.started == started and id < first)) then
            first, started = id, s.started
        end
    end
    return first
end

local function OnRowAction(r, action)
    local questID = r.questID
    if not questID then return end
    local s = seeking[questID]
    if action == "find" then
        ns.Start(questID)
    elseif action == "stop" then
        ns.Stop(questID, "search cancelled")
    elseif action == "keep" and s then
        s.promptAt = GetTime() + KEEP_SEARCHING_FOR
        C_Timer.After(KEEP_SEARCHING_FOR + 0.2, function() ns.RequestRefresh() end)
        Print(string.format(L["Still searching for: %s"], QuestTitle(questID)))
    elseif action == "create" and s then
        ns.OpenCreateDialog(questID)
    elseif action == "repost" and s then
        ns.PostListing(questID)
    elseif action == "chat" then
        ns.ShowLatestChat(questID)
    end
    ns.RequestRefresh()
end

local ACTION_TIPS = {
    find   = L["Look for other Questynator players on this quest."],
    stop   = L["Stop searching for this quest."],
    keep   = string.format(L["Keep looking for another %d seconds before asking again."], KEEP_SEARCHING_FOR),
    create = L["Host a group: pick objectives and a level range, and post it to General chat."],
    repost = L["Post your group to General chat again."],
    chat   = L["Players in chat are looking for this quest. Click to whisper or invite the latest one."],
}

local function MakeRowButton(r, width)
    local b = ns.UI.Button(r, width, 22, "primary")
    b:SetScript("OnClick", function(self) OnRowAction(r, self.action) end)
    b:SetScript("OnEnter", function(self)
        r.hl:Show()
        local tip = ACTION_TIPS[self.action]
        if tip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(self:GetText() or "", 1, 0.82, 0)
            GameTooltip:AddLine(tip, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", function() r.hl:Hide(); GameTooltip:Hide() end)
    return b
end

local BUTTON_KIND = { find = "primary", create = "primary", stop = "outline" }
local function SetButton(b, text, action, enabled)
    if not text then b:Hide() return end
    b:SetText(text)
    b.action = action
    if b.SetKind then b:SetKind(BUTTON_KIND[action] or "ghost") end
    b:Show()
    if enabled == false then b:Disable() else b:Enable() end
end

local function ShowQuestTooltip(r)
    if not r.questID then return end
    GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
    GameTooltip:AddLine(QuestTitle(r.questID), 1, 0.82, 0)
    GameTooltip:AddLine(L["Click to see how to complete this quest."], 0.6, 0.8, 1, true)
    local objs = (C_QuestLog.GetQuestObjectives and C_QuestLog.GetQuestObjectives(r.questID)) or {}
    for _, o in ipairs(objs) do
        if o.finished then GameTooltip:AddLine("  " .. (o.text or ""), 0.5, 0.5, 0.5, true)
        else GameTooltip:AddLine("  " .. (o.text or ""), 1, 1, 1, true) end
    end
    local grp = ns.GroupInfo(r.questID)
    if grp then GameTooltip:AddLine(string.format(L["Group quest: %s"], grp), 1, 0.6, 0.2) end
    local chat = ns.ChatHits(r.questID)
    if #chat > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Looking in chat:"], 0.2, 0.8, 1)
        for i = 1, math.min(#chat, 5) do
            GameTooltip:AddLine("  " .. string.format(L["%s (%d min ago)"], Ambiguate(chat[i].name, "none"),
                math.floor((GetTime() - chat[i].t) / 60)), 1, 1, 1)
        end
    end
    local s = seeking[r.questID]
    if s and next(s.peers) then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Players found:"], 0.2, 1, 0.2)
        for name, pr in pairs(s.peers) do
            GameTooltip:AddLine(string.format("  %s (%d)", Ambiguate(name, "none"), pr.level), 1, 1, 1)
        end
    end
    GameTooltip:Show()
end

local PANEL_ICON = "Interface\\AddOns\\Questynator\\Media\\Icon"

-- class helpers (Blizzard art: classicon-<class> atlas, class colors)
local function ClassColorName(name, cls)
    local short = Ambiguate(name, "none")
    local c = cls and ((C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(cls))
        or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[cls]))
    if c and c.WrapTextInColorCode then return c:WrapTextInColorCode(short) end
    if c and c.r then return string.format("|cff%02x%02x%02x%s|r", c.r * 255, c.g * 255, c.b * 255, short) end
    return "|cffffffff" .. short .. "|r"
end

ns.ClassColorName = ClassColorName

local function SetClassIcon(tex, cls)
    if cls and cls ~= "" then
        local atlas = GetClassAtlas and GetClassAtlas(cls:lower()) or ("classicon-" .. cls:lower())
        tex:SetAtlas(atlas)
        tex:Show()
    else
        tex:SetTexture("Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon")
        tex:Show()
    end
end

-- objective progress (done, total) for the card progress bar
local function ObjectiveProgress(questID)
    local objs = C_QuestLog.GetQuestObjectives and C_QuestLog.GetQuestObjectives(questID)
    if type(objs) ~= "table" or #objs == 0 then return 0, 0 end
    local done = 0
    for _, o in ipairs(objs) do if o.finished then done = done + 1 end end
    return done, #objs
end

-- everyone we know about: Questynator matches + players looking in chat
function ns.NearbyEntries()
    local list, seen = {}, {}
    for questID, s in pairs(seeking) do
        for name, p in pairs(s.peers) do
            local key = name .. "#" .. questID
            if not seen[key] then
                seen[key] = true
                list[#list + 1] = { name = name, questID = questID, level = p.level, class = p.class,
                                    src = "addon", t = p.t, state = p.state }
            end
        end
    end
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and info.questID then
            for _, h in ipairs(ns.ChatHits(info.questID)) do
                local key = h.name .. "#" .. info.questID
                if not seen[key] then
                    seen[key] = true
                    list[#list + 1] = { name = h.name, questID = info.questID, level = h.level, class = h.class,
                                        src = "chat", t = h.t }
                end
            end
        end
    end
    table.sort(list, function(a, b) return a.t > b.t end)
    return list
end

---------------------------------------------------------------------------
-- quest details: "how to complete" (Blizzard quest text + bundled QuestieDB locations)
---------------------------------------------------------------------------
local expanded = {}          -- [questID] = true while a card is opened

local function ZoneName(areaId)
    if not areaId then return nil end
    if C_Map and C_Map.GetAreaInfo then
        local ok, name = pcall(C_Map.GetAreaInfo, areaId)
        if ok and type(name) == "string" and name ~= "" then return name end
    end
    if QuestieLoader and C_Map and C_Map.GetMapInfo then
        local ok, ZoneDB = pcall(QuestieLoader.ImportModule, QuestieLoader, "ZoneDB")
        if ok and ZoneDB and ZoneDB.GetUiMapIdByAreaId then
            local ok2, uiMap = pcall(ZoneDB.GetUiMapIdByAreaId, ZoneDB, areaId)
            local info = ok2 and uiMap and C_Map.GetMapInfo(uiMap)
            if info and info.name then return info.name end
        end
    end
    return nil
end
ns.AreaName = ZoneName

-- coordinates as " (x, y)"
local function Coords(x, y)
    x, y = tonumber(x), tonumber(y)
    if x and y and x >= 0 and y >= 0 then
        return string.format(" (%d, %d)", math.floor(x + 0.5), math.floor(y + 0.5))
    end
    return ""
end

-- bundled data (Data\QuestData.lua, derived from QuestieDB, GPLv3) ------------
-- q[id] = "start/finish/mobs/objects/items/rep"   e.g. "n197/n197/6///72:100"
-- n[id], o[id] = "zone,x,y,rank,level,Name"       i[id] = "n69,n299;Item name"
local function Split(str, sep)
    local out, from = {}, 1
    while true do
        local a, b = string.find(str, sep, from, true)
        if not a then out[#out + 1] = string.sub(str, from); return out end
        out[#out + 1] = string.sub(str, from, a - 1)
        from = b + 1
    end
end

-- map waypoints ---------------------------------------------------------------
-- a location in the guide is a link: click it to get a TomTom arrow or a map pin
function ns.UiMapForArea(area)
    local m = ns.QDATA and ns.QDATA.m
    local id = m and area and m[area]
    return id and tonumber(id) or nil
end

function ns.WayLink(area, x, y, title, text)
    if not (area and x and y and x >= 0 and y >= 0) or text == "" then return text end
    title = tostring(title or ""):gsub("[|:]", " ")
    return string.format("|cff66ddff|Hquestynator:way:%d:%.1f:%.1f:%s|h%s|h|r", area, x, y, title, text)
end

function ns.Waypoint(area, x, y, title, keepQuestSelection)
    local uiMap = ns.UiMapForArea(area)
    local where = (ZoneName(area) or "?") .. string.format(" (%d, %d)", math.floor(x + 0.5), math.floor(y + 0.5))
    if uiMap and TomTom and TomTom.AddWaypoint then
        local ok = pcall(TomTom.AddWaypoint, TomTom, uiMap, x / 100, y / 100,
            { title = title, persistent = false, minimap = true, world = true, from = "Questynator" })
        if ok then Print(string.format(L["Waypoint set: %s"], title .. " - " .. where)); return "tomtom" end
    end
    if uiMap and C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates then
        local can = not C_Map.CanSetUserWaypointOnMap or C_Map.CanSetUserWaypointOnMap(uiMap)
        if can then
            local ok = pcall(C_Map.SetUserWaypoint, UiMapPoint.CreateFromCoordinates(uiMap, x / 100, y / 100))
            if ok then
                if not keepQuestSelection and C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
                    pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
                end
                Print(string.format(L["Map pin set: %s"], title .. " - " .. where))
                return "pin"
            end
        end
    end
    -- no pins on this client: open the map there and print the coordinates
    if uiMap and WorldMapFrame and WorldMapFrame.SetMapID then
        if not WorldMapFrame:IsShown() and ToggleWorldMap then pcall(ToggleWorldMap) end
        pcall(WorldMapFrame.SetMapID, WorldMapFrame, uiMap)
    end
    Print(title .. " - " .. where)
    return "map"
end

function ns.OnHyperlink(link)
    local shareID = tostring(link):match("^questynator:share:(%d+)$")
    if shareID then
        ns.linkClickedAt = GetTime()
        ns.ShareQuest(tonumber(shareID))
        return true
    end
    local area, x, y, title = tostring(link):match("^questynator:way:(%d+):([%d%.]+):([%d%.]+):(.*)$")
    if area then
        ns.linkClickedAt = GetTime()
        ns.Waypoint(tonumber(area), tonumber(x), tonumber(y), title)
        return true
    end
    return false
end

-- quest chains: what this quest unlocks (filtered by your race and class)
local function HasBit(mask, bitIndex)
    mask = tonumber(mask) or 0
    if mask == 0 or not bitIndex then return true end
    return math.floor(mask / 2 ^ (bitIndex - 1)) % 2 == 1
end

-- Forever stores Skyborne race IDs 95 and 96 in mask positions 33 and 34.
function ns.RaceBit(raceID)
    if raceID == 95 then return 33 end
    if raceID == 96 then return 34 end
    return raceID
end

function ns.NextQuests(questID, limit)
    local D = ns.QDATA
    local raw = D and D.q and D.q[questID]
    if not raw or not D.t then return {} end
    local f = Split(raw, "/")
    local _, _, raceID = UnitRace("player")
    local _, _, classID = UnitClass("player")
    local out = {}
    for id in (f[7] or ""):gmatch("%d+") do
        local t = D.t[tonumber(id)]
        if t then
            local lvl, races, classes, name = t:match("^([^;]*);([^;]*);([^;]*);(.*)$")
            if name and HasBit(races, ns.RaceBit(raceID)) and HasBit(classes, classID) then
                out[#out + 1] = { id = tonumber(id), name = name, level = tonumber(lvl) }
            end
        end
        if #out >= (limit or 2) then break end
    end
    return out
end

-- { name, where = " - Zone (x, y)", rank, level = "10-12", maxLevel }
local function DataInfo(ref)
    local D = ns.QDATA
    if not D or type(ref) ~= "string" then return nil end
    local kind, id = ref:match("^([no])(%d+)$")
    local raw = kind and D[kind] and D[kind][tonumber(id)]
    if not raw then return nil end
    local zone, x, y, rank, level, name = raw:match("^([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),(.*)$")
    if not name or name == "" then return nil end
    local where = ""
    local zoneName = ZoneName(tonumber(zone))
    if zoneName then where = " - " .. zoneName end
    where = where .. Coords(x, y)
    where = ns.WayLink(tonumber(zone), tonumber(x), tonumber(y), name, where)
    return { name = name, where = where, rank = tonumber(rank) or 0, zone = tonumber(zone), x = tonumber(x), y = tonumber(y),
             level = level ~= "" and level or nil, maxLevel = tonumber(level:match("(%d+)$")) }
end

function ns.BundledQuest(questID)
    local D = ns.QDATA
    local raw = D and D.q and D.q[questID]
    if not raw then return nil end
    local f = Split(raw, "/")
    local q = { start = f[1] ~= "" and f[1] or nil, finish = f[2] ~= "" and f[2] or nil,
                mobs = {}, objects = {}, items = {}, rep = {} }
    for id in (f[3] or ""):gmatch("%d+") do q.mobs[#q.mobs + 1] = "n" .. id end
    for ref in (f[4] or ""):gmatch("o%d+") do q.objects[#q.objects + 1] = ref end
    for id in (f[5] or ""):gmatch("%d+") do q.items[#q.items + 1] = tonumber(id) end
    for fid, v in (f[6] or ""):gmatch("(%d+):(%-?%d+)") do q.rep[#q.rep + 1] = { tonumber(fid), tonumber(v) } end
    return q
end

local GOLD, BLUE, ORANGE, GREY = "|cffffd100", "|cff33ccff", "|cffff9933", "|cff9d9d9d"

local function Mob(info, tips)
    local text = ORANGE .. info.name .. "|r"
    if info.level then text = text .. GREY .. " [" .. info.level .. "]|r" end
    if info.rank == 1 or info.rank == 2 or info.rank == 3 then
        text = text .. " |cffff3333" .. L["(Elite)"] .. "|r"
        tips.elite = true
    end
    if info.maxLevel and (not tips.maxLevel or info.maxLevel > tips.maxLevel) then tips.maxLevel = info.maxLevel end
    return text .. info.where
end

-- short "how to do it": steps + tips, from the bundled data
local function BundledGuide(questID)
    local q = ns.BundledQuest(questID)
    if not q then return nil end
    local steps, tips = {}, {}
    for _, ref in ipairs(q.mobs) do
        local info = DataInfo(ref)
        if info then steps[#steps + 1] = string.format(L["Kill %s"], Mob(info, tips)) end
    end
    local items = ns.QDATA.i or {}
    for _, id in ipairs(q.items) do
        local raw = items[id]
        if raw then
            local srcs, name = raw:match("^([^;]*);(.*)$")
            local src
            for ref in (srcs or ""):gmatch("[no]%d+") do
                src = DataInfo(ref)
                if src then
                    src = ref:sub(1, 1) == "n" and Mob(src, tips) or (ORANGE .. src.name .. "|r" .. src.where)
                    break
                end
            end
            local item = BLUE .. name .. "|r"
            steps[#steps + 1] = src and string.format(L["Loot %s from %s"], item, src) or string.format(L["Collect %s"], item)
        end
    end
    for _, ref in ipairs(q.objects) do
        local info = DataInfo(ref)
        if info then steps[#steps + 1] = string.format(L["Use %s"], ORANGE .. info.name .. "|r" .. info.where) end
    end
    local fin = DataInfo(q.finish)
    if fin then steps[#steps + 1] = string.format(L["Turn in to %s"], BLUE .. fin.name .. "|r" .. fin.where) end
    if not steps[1] then return nil end
    return steps, tips
end

-- "Name - Zone (x, y)" for a live Questie NPC id (used only when the bundled data lacks a quest)
local function NpcWhere(DB, npcId)
    if not npcId then return nil end
    local ok, npc = pcall(DB.GetNPC, DB, npcId)
    if not ok or type(npc) ~= "table" or not npc.name then return nil end
    local text = npc.name
    local zoneId, coords = npc.zoneID, nil
    if type(npc.spawns) == "table" then
        if zoneId and type(npc.spawns[zoneId]) == "table" then coords = npc.spawns[zoneId][1] end
        if not coords then
            for z, list in pairs(npc.spawns) do
                if type(list) == "table" and list[1] then zoneId, coords = z, list[1]; break end
            end
        end
    end
    local zone = ZoneName(zoneId)
    if zone then text = text .. " - " .. zone end
    if type(coords) == "table" then text = text .. Coords(coords[1], coords[2]) end
    return text
end

local function LiveQuestieGuide(questID)
    if not (QuestieLoader and QuestieLoader.ImportModule) then return nil end
    local ok, DB = pcall(QuestieLoader.ImportModule, QuestieLoader, "QuestieDB")
    if not ok or type(DB) ~= "table" or not DB.GetQuest then return nil end
    local ok2, q = pcall(DB.GetQuest, questID)
    if not ok2 or type(q) ~= "table" then return nil end
    local steps = {}
    if type(q.ObjectiveData) == "table" then
        for _, o in ipairs(q.ObjectiveData) do
            if o.Type == "monster" and o.Id then
                local where = NpcWhere(DB, o.Id)
                if where then steps[#steps + 1] = string.format(L["Kill %s"], ORANGE .. where .. "|r") end
            end
        end
    end
    local finish = q.Finisher and q.Finisher.NPC
    if type(finish) == "table" and finish[1] then
        local where = NpcWhere(DB, finish[1])
        if where then steps[#steps + 1] = string.format(L["Turn in to %s"], BLUE .. where .. "|r") end
    end
    if not steps[1] then return nil end
    return steps, {}
end

-- steps + tips for a quest: bundled data first, a live Questie install for anything it doesn't know
function ns.QuestGuide(questID)
    local steps, tips = BundledGuide(questID)
    if not steps then steps, tips = LiveQuestieGuide(questID) end
    return steps, tips or {}
end

-- full "how to complete" text for a quest card
function ns.QuestDetails(questID)
    local lines = {}
    local idx = ns.QuestLogIndex(questID)
    local objectiveText
    if idx and GetQuestLogQuestText then
        local ok, _, o = pcall(GetQuestLogQuestText, idx)
        if ok then objectiveText = o end
    end
    if type(objectiveText) == "string" and objectiveText ~= "" then
        lines[#lines + 1] = GOLD .. L["Objective:"] .. "|r " .. objectiveText
    end
    local objs = (C_QuestLog.GetQuestObjectives and C_QuestLog.GetQuestObjectives(questID)) or {}
    if #objs > 0 then
        lines[#lines + 1] = GOLD .. L["Progress:"] .. "|r"
        for _, o in ipairs(objs) do
            local color = o.finished and "|cff33ff33" or "|cffffffff"
            lines[#lines + 1] = "   " .. color .. "- " .. (o.text or "") .. "|r"
        end
    end
    local party = ns.PartyLine and ns.PartyLine(questID)
    if party then lines[#lines + 1] = party end
    local complete = C_QuestLog.IsComplete and C_QuestLog.IsComplete(questID)
    local steps, tips = ns.QuestGuide(questID)
    if steps then
        lines[#lines + 1] = GOLD .. L["How to do it"] .. "|r"
        local first = complete and #steps or 1      -- done: only the turn-in step matters
        for i = first, #steps do
            lines[#lines + 1] = "   " .. (i - first + 1) .. ". " .. steps[i]
        end
    end
    -- what this quest unlocks
    local nexts = ns.NextQuests(questID)
    if #nexts > 0 then
        local names = {}
        for _, n in ipairs(nexts) do
            names[#names + 1] = "|cffffffff" .. n.name .. "|r" .. (n.level and n.level > 0 and (GREY .. " [" .. n.level .. "]|r") or "")
        end
        lines[#lines + 1] = GOLD .. L["Next:"] .. "|r " .. table.concat(names, ", ")
    end
    -- tips
    local tipLines = {}
    if complete then
        tipLines[#tipLines + 1] = L["Objectives done - go turn it in."]
    else
        if tips.elite then tipLines[#tipLines + 1] = L["Elite enemies - bring a group."] end
        local suggested = 0
        if idx and C_QuestLog.GetInfo then
            local info = C_QuestLog.GetInfo(idx)
            suggested = info and tonumber(info.suggestedGroup) or 0
        end
        if suggested > 1 then tipLines[#tipLines + 1] = string.format(L["Group quest - %d players suggested."], suggested) end
        local myLevel = UnitLevel and UnitLevel("player") or 0
        if tips.maxLevel and myLevel > 0 and tips.maxLevel >= myLevel + 2 then
            tipLines[#tipLines + 1] = string.format(L["Enemies are up to level %d - harder than you."], tips.maxLevel)
        end
    end
    for _, t in ipairs(tipLines) do
        lines[#lines + 1] = GOLD .. L["Tip:"] .. "|r |cffbbbbbb" .. t .. "|r"
    end
    return table.concat(lines, "\n")
end

---------------------------------------------------------------------------
-- rewards for completing everything in your quest log (header)
---------------------------------------------------------------------------
local repCache = {}            -- [questID] = { {factionName, value}, ... } (static, bundled data / Questie)

local function FactionName(id)
    if C_Reputation and C_Reputation.GetFactionDataByID then
        local ok, d = pcall(C_Reputation.GetFactionDataByID, id)
        if ok and type(d) == "table" and d.name and d.name ~= "" then return d.name end
    end
    if GetFactionInfoByID then
        local ok, name = pcall(GetFactionInfoByID, id)
        if ok and type(name) == "string" and name ~= "" then return name end
    end
    if QuestieLoader and QuestieLoader.ImportModule then
        local ok, QR = pcall(QuestieLoader.ImportModule, QuestieLoader, "QuestieReputation")
        if ok and type(QR) == "table" and QR.GetFactionName then
            local ok2, n = pcall(QR.GetFactionName, id)
            if ok2 and type(n) == "string" and n ~= "" then return n end
        end
    end
    return nil
end

local function QuestRep(questID)
    if repCache[questID] then return repCache[questID] end
    local rewards
    local q = ns.BundledQuest(questID)
    if q and q.rep[1] then rewards = q.rep end
    if not rewards and QuestieLoader and QuestieLoader.ImportModule then
        local ok, QR = pcall(QuestieLoader.ImportModule, QuestieLoader, "QuestieReputation")
        if ok and type(QR) == "table" and QR.GetReputationReward then
            local ok2, r = pcall(QR.GetReputationReward, questID)
            if ok2 and type(r) == "table" then rewards = r end
        end
    end
    local list = {}
    for _, entry in pairs(rewards or {}) do
        local id, value = tonumber(entry[1]), tonumber(entry[2])
        if id and value and value ~= 0 then
            list[#list + 1] = { name = FactionName(id) or ("#" .. id), value = value }
        end
    end
    repCache[questID] = list
    return list
end

function ns.LogRewards()
    local r = { xp = 0, money = 0, rep = {}, repTotal = 0, currencies = {}, quests = 0, hasQuestie = false }
    r.hasQuestie = (QuestieLoader ~= nil) or (ns.QDATA ~= nil)
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and info.questID and not info.isHidden then
            local id = info.questID
            r.quests = r.quests + 1
            local xp, money = 0, 0
            if GetQuestLogRewardXP then
                local ok, v = pcall(GetQuestLogRewardXP, id)
                if ok and tonumber(v) then xp = tonumber(v) end
            end
            if GetQuestLogRewardMoney then
                local ok, v = pcall(GetQuestLogRewardMoney, id)
                if ok and tonumber(v) then money = tonumber(v) end
            end
            -- Blizzard can return 0 for quests it hasn't loaded; Questie's own numbers fill the gap
            if (xp == 0 or money == 0) and QuestieLoader and QuestieLoader.ImportModule then
                local ok, QX = pcall(QuestieLoader.ImportModule, QuestieLoader, "QuestXP")
                if ok and type(QX) == "table" then
                    if xp == 0 and QX.GetQuestLogRewardXP then
                        local ok2, v = pcall(QX.GetQuestLogRewardXP, QX, id, false)
                        if ok2 and tonumber(v) then xp = tonumber(v) end
                    end
                    if money == 0 and QX.GetQuestRewardMoney then
                        local ok2, v = pcall(QX.GetQuestRewardMoney, id)
                        if ok2 and tonumber(v) then money = tonumber(v) end
                    end
                end
            end
            r.xp, r.money = r.xp + xp, r.money + money
            for _, f in ipairs(QuestRep(id)) do
                r.rep[f.name] = (r.rep[f.name] or 0) + f.value
                if f.value > 0 then r.repTotal = r.repTotal + f.value end
            end
            if C_QuestLog.GetQuestRewardCurrencies then
                local ok, list = pcall(C_QuestLog.GetQuestRewardCurrencies, id)
                if ok and type(list) == "table" then
                    for _, c in ipairs(list) do
                        local name = c.name or ("#" .. tostring(c.currencyID))
                        r.currencies[name] = (r.currencies[name] or 0) + (tonumber(c.totalRewardAmount or c.baseRewardAmount) or 0)
                    end
                end
            end
        end
    end
    return r
end

local function Num(n)
    if FormatLargeNumber then return FormatLargeNumber(n) end
    return tostring(n)
end
ns.FormatNumber = Num

function ns.MoneyText(copper)
    if GetCoinTextureString then return GetCoinTextureString(copper) end
    local g, sv, c = math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100
    return string.format("%dg %ds %dc", g, sv, c)
end

-- one line for the header
-- the header chips: XP, money, rep (no "All quests:" label)
function ns.RewardParts()
    local r = ns.LogRewards()
    local parts = { "|cffb48ef9" .. Num(r.xp) .. " " .. L["XP"] .. "|r", ns.MoneyText(r.money) }
    if r.repTotal > 0 then parts[#parts + 1] = "|cff4fc3f7+" .. Num(r.repTotal) .. " " .. L["rep"] .. "|r" end
    return parts
end

function ns.RewardsLine()
    local r = ns.LogRewards()
    local parts = { "|cffffd100" .. L["All quests:"] .. "|r" }
    parts[#parts + 1] = "|cffb48ef9" .. Num(r.xp) .. " " .. L["XP"] .. "|r"
    parts[#parts + 1] = ns.MoneyText(r.money)
    if r.repTotal > 0 then parts[#parts + 1] = "|cff33ccff+" .. Num(r.repTotal) .. " " .. L["rep"] .. "|r" end
    return table.concat(parts, "   "), r
end

function ns.ShowRewardsTooltip(owner)
    local r = ns.LogRewards()
    GameTooltip:SetOwner(owner, "ANCHOR_BOTTOM")
    GameTooltip:AddLine(L["Rewards for completing all your quests"], 1, 0.82, 0)
    GameTooltip:AddDoubleLine(L["Experience"], Num(r.xp) .. " " .. L["XP"], 1, 1, 1, 0.7, 0.55, 0.98)
    GameTooltip:AddDoubleLine(L["Money"], ns.MoneyText(r.money), 1, 1, 1, 1, 1, 1)
    local names = {}
    for name in pairs(r.rep) do names[#names + 1] = name end
    table.sort(names, function(a, b) return r.rep[a] > r.rep[b] end)
    if #names > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Reputation"], 1, 0.82, 0)
        for _, name in ipairs(names) do
            local v = r.rep[name]
            GameTooltip:AddDoubleLine("  " .. name, (v > 0 and "+" or "") .. Num(v), 1, 1, 1, v > 0 and 0.2 or 1, v > 0 and 0.8 or 0.3, v > 0 and 1 or 0.3)
        end
    end
    local cur = {}
    for name in pairs(r.currencies) do cur[#cur + 1] = name end
    if #cur > 0 then
        table.sort(cur)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Currencies"], 1, 0.82, 0)
        for _, name in ipairs(cur) do GameTooltip:AddDoubleLine("  " .. name, Num(r.currencies[name]), 1, 1, 1, 1, 1, 1) end
    end
    GameTooltip:Show()
end

-- XP progress: now, and after turning in every quest in your log
function ns.XPInfo()
    local cur, max = tonumber(UnitXP and UnitXP("player")) or 0, tonumber(UnitXPMax and UnitXPMax("player")) or 0
    local maxed = (IsPlayerAtEffectiveMaxLevel and IsPlayerAtEffectiveMaxLevel()) or max <= 0
    local quest = ns.LogRewards().xp
    local after = cur + quest
    return {
        level = UnitLevel("player"), cur = cur, max = max, quest = quest, maxed = maxed,
        pct = max > 0 and cur / max or 0,
        afterPct = max > 0 and math.min(after / max, 1) or 0,
        levelsUp = max > 0 and after >= max,
        remaining = math.max(max - cur, 0),
    }
end

function ns.UpdateXPBar(bar)
    if not bar then return end
    local x = ns.XPInfo()
    local w = tonumber(bar:GetWidth()) or 0
    if x.maxed then
        bar.fill:Hide(); bar.quest:Hide()
        bar.text:SetText("|cffffd100" .. L["Max level"] .. "|r")
        return
    end
    local function width(frac) return math.max(w * frac, 0.001) end
    bar.fill:SetWidth(width(x.pct)); bar.fill:Show()
    if x.quest > 0 then
        bar.quest:SetWidth(width(math.max(x.afterPct - x.pct, 0))); bar.quest:Show()
    else
        bar.quest:Hide()
    end
    local text = string.format("%d%%", math.floor(x.pct * 100))
    if x.quest > 0 then
        if x.levelsUp then
            text = text .. "  |cff5b606b·|r  " .. L["Level up!"]
        else
            text = text .. string.format(" > |cff66bbff%d%%|r", math.floor(x.afterPct * 100))
        end
    end
    bar.text:SetText(text)
end

function ns.ShowXPTooltip(owner)
    local x = ns.XPInfo()
    GameTooltip:SetOwner(owner, "ANCHOR_BOTTOM")
    GameTooltip:AddLine(string.format(L["Level %d"], x.level), 1, 0.82, 0)
    if x.maxed then
        GameTooltip:AddLine(L["Max level"], 1, 1, 1)
    else
        GameTooltip:AddDoubleLine(L["Experience"], string.format("%s / %s (%d%%)", Num(x.cur), Num(x.max), math.floor(x.pct * 100)), 1, 1, 1, 1, 1, 1)
        GameTooltip:AddDoubleLine(L["XP to next level:"], Num(x.remaining), 1, 1, 1, 1, 1, 1)
        GameTooltip:AddDoubleLine(L["XP from your quests:"], "+" .. Num(x.quest), 1, 1, 1, 0.4, 0.8, 1)
        if x.levelsUp then
            GameTooltip:AddLine(L["Turning in all your quests levels you up."], 0.2, 1, 0.2, true)
        else
            GameTooltip:AddDoubleLine(L["Still needed after quests:"], Num(x.remaining - x.quest), 1, 1, 1, 1, 0.82, 0)
        end
        local rate = ns.XPRate()
        GameTooltip:AddLine(" ")
        if rate and rate > 0 then
            GameTooltip:AddDoubleLine(L["XP per hour:"], Num(math.floor(rate)), 1, 1, 1, 1, 1, 1)
            GameTooltip:AddDoubleLine(L["Time to level:"], "~" .. ns.FormatDuration(x.remaining / rate * 3600), 1, 1, 1, 0.2, 1, 0.2)
        else
            GameTooltip:AddLine(L["XP per hour: play a few minutes to measure it."], 0.6, 0.6, 0.6, true)
        end
    end
    GameTooltip:Show()
end

function ns.ToggleDetails(questID)
    expanded[questID] = not expanded[questID] or nil
    ns.RequestRefresh()
end

local function GetPanelRow(i)
    local r = panelRows[i]
    if r then return r end
    r = CreateFrame("Frame", nil, content)
    r:SetWidth(ROW_W)
    r:EnableMouse(true)

    -- card background, hover highlight, left accent bar
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetPoint("TOPLEFT", 0, -2)
    r.bg:SetPoint("BOTTOMRIGHT", 0, 2)
    r.glow = r:CreateTexture(nil, "BACKGROUND", nil, 1)
    r.glow:SetAllPoints(r.bg)
    r.glow:SetColorTexture(0.31, 0.82, 0.77, 0.12)
    r.glow:Hide()
    r.hl = r:CreateTexture(nil, "BORDER")
    r.hl:SetAllPoints(r.bg)
    r.hl:SetColorTexture(1, 1, 1, 0.035)
    -- 1px card outline (teal while searching)
    -- rounded card drawn on a frame just below the row, so the row's text stays on top
    r.edge = CreateFrame("Frame", nil, r)
    r.edge:SetAllPoints(r.bg)
    r.edge:SetFrameLevel(math.max(0, (tonumber(r:GetFrameLevel()) or 1) - 1))
    ns.UI.Flat(r.edge, ns.UI.C.panel, ns.UI.C.line)
    r.bg:SetAlpha(0)
    r.glow:SetAlpha(0)
    r.hl:SetAlpha(0)
    r.hl:Hide()
    r.accent = r:CreateTexture(nil, "BORDER", nil, 1)
    r.accent:SetWidth(3)
    r.accent:SetPoint("TOPLEFT", r.bg, "TOPLEFT")
    r.accent:SetPoint("BOTTOMLEFT", r.bg, "BOTTOMLEFT")
    r.line = r:CreateTexture(nil, "BORDER")
    r.line:SetHeight(1)
    r.line:SetPoint("BOTTOMLEFT", 4, 2)
    r.line:SetPoint("BOTTOMRIGHT", -4, 2)
    r.line:SetColorTexture(0.15, 0.165, 0.2, 1)

    -- level badge
    r.lvlBg = r:CreateTexture(nil, "ARTWORK")
    r.lvlBg:SetSize(28, 20)
    r.lvlBg:SetPoint("TOPLEFT", r.bg, "TOPLEFT", 10, -11)
    r.lvlBg:SetColorTexture(0.043, 0.05, 0.063, 1)
    r.lvl = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ns.UI.Font(r.lvl, 11, "", "bold")
    r.count = ns.UI.Text(r, 10, "dim", nil, "medium")
    r.count:SetPoint("BOTTOMRIGHT", r, "BOTTOMRIGHT", -8, 8)
    r.count:Hide()
    r.lvl:SetPoint("CENTER", r.lvlBg, "CENTER", 0, 0)

    r.label = ns.UI.Text(r, 13, "text")
    r.label:SetJustifyH("LEFT")
    r.label:SetWordWrap(false)
    r.status = ns.UI.Text(r, 12, "muted")
    ns.UI.Font(r.status, 11, "")
    r.status:SetJustifyH("LEFT")
    r.status:SetWordWrap(false)

    -- group pill (Group 3+, Elite, Dungeon)
    r.pillBg = r:CreateTexture(nil, "ARTWORK")
    r.pillBg:SetColorTexture(1, 1, 1, 0.08)
    r.pill = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ns.UI.Font(r.pill, 9, "", "medium")
    r.pill:SetTextColor(0.62, 0.64, 0.68)
    r.pillBg:SetPoint("TOPLEFT", r.pill, "TOPLEFT", -4, 2)
    r.pillBg:SetPoint("BOTTOMRIGHT", r.pill, "BOTTOMRIGHT", 4, -2)

    -- objective progress bar along the bottom of the card
    r.bar = CreateFrame("StatusBar", nil, r)
    r.bar:SetHeight(3)
    r.bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    r.bar:SetMinMaxValues(0, 1)
    r.barBg = r.bar:CreateTexture(nil, "BACKGROUND")
    r.barBg:SetAllPoints()
    r.barBg:SetColorTexture(0.043, 0.05, 0.063, 1)

    r.btnA = MakeRowButton(r, 88)                       -- right-most button
    r.btnA:SetPoint("TOPRIGHT", r, "TOPRIGHT", -10, -13)
    r.btnB = MakeRowButton(r, 100)                      -- second button, left of A
    r.btnB:SetPoint("RIGHT", r.btnA, "LEFT", -6, 0)

    -- +/- for collapsible zone headers (Blizzard's quest log buttons)
    r.toggle = r:CreateTexture(nil, "ARTWORK")
    r.toggle:SetSize(14, 14)
    r.toggle:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", 6, 6)
    r.toggle:Hide()

    r:SetScript("OnEnter", function(self)
        if self.questID then self.hl:Show(); ShowQuestTooltip(self)
        elseif self.zone then self.hl:Show() end
    end)
    r:SetScript("OnMouseUp", function(self)
        if self.zone then ns.ToggleZone(self.zone)
        elseif self.questID then
            -- wait a moment: a click on a map link inside the card must not close it
            local qid = self.questID
            C_Timer.After(0.05, function()
                if ns.linkClickedAt and GetTime() - ns.linkClickedAt < 0.3 then return end
                ns.ToggleDetails(qid)                                     -- open/close "how to complete"
            end)
        end
    end)
    if r.SetHyperlinksEnabled then r:SetHyperlinksEnabled(true) end
    r:SetScript("OnHyperlinkClick", function(_, link) ns.OnHyperlink(link) end)
    r:SetScript("OnHyperlinkEnter", function(self, link)
        if tostring(link):find("^questynator:way:") then
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:AddLine(L["Click to set a waypoint"], 1, 1, 1)
            GameTooltip:Show()
        end
    end)
    r:SetScript("OnHyperlinkLeave", function() GameTooltip:Hide() end)
    r:SetScript("OnLeave", function(self) self.hl:Hide(); GameTooltip:Hide() end)

    -- "how to complete" text, shown when the card is opened
    r.details = ns.UI.Text(r, 12, "muted")
    ns.UI.Font(r.details, 11, "")
    r.details:SetTextColor(0.8, 0.8, 0.8)
    r.details:SetPoint("TOPLEFT", r, "TOPLEFT", 14, -48)
    r.details:SetWidth(ROW_W - 28)
    r.details:SetJustifyH("LEFT")
    r.details:SetJustifyV("TOP")
    r.details:SetWordWrap(true)
    if r.details.SetSpacing then r.details:SetSpacing(2) end
    r.details:Hide()
    r.chev = r:CreateTexture(nil, "ARTWORK")
    r.chev:SetSize(12, 12)
    r.chev:SetPoint("BOTTOMRIGHT", r.lvlBg, "TOPLEFT", 4, -4)
    r.chev:Hide()

    panelRows[i] = r
    return r
end

local function HideCardParts(r)
    r.edge:Hide(); r.bg:Hide(); r.glow:Hide(); r.accent:Hide(); r.lvlBg:Hide(); r.lvl:Hide()
    r.pill:Hide(); r.pillBg:Hide(); r.bar:Hide(); r.details:Hide(); r.chev:Hide(); r.toggle:Hide(); r.line:Hide()
end

local function LayoutHeader(r, e)
    r.questID = nil
    r.zone = e.zone
    r:SetHeight(HEADER_H)
    HideCardParts(r)
    r.btnA:Hide()
    r.btnB:Hide()
    r.status:Hide()
    r.label:ClearAllPoints()
    r.label:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", 4, 8)
    r.label:SetPoint("RIGHT", r.count, "LEFT", -8, 0)
    ns.UI.Font(r.label, 10, "", "bold")
    local upper = e.header or ""
    if not upper:find("[\128-\255]") then upper = upper:upper() end   -- small caps only for plain ASCII names
    if e.active then r.label:SetTextColor(0.31, 0.82, 0.77)
    elseif e.collapsed then r.label:SetTextColor(0.36, 0.38, 0.42)
    else r.label:SetTextColor(0.545, 0.56, 0.6) end
    r.label:SetText(upper)
    r.count:SetText(tostring(e.count or ""))
    r.count:Show()
end

local function LayoutQuest(r, e, stripe)
    r.questID = e.questID
    r.zone = nil
    r.toggle:Hide()
    r.line:Hide()
    r.count:Hide()
    r:SetHeight(QUEST_H)
    r.bg:Show()
    r.bg:SetColorTexture(0.094, 0.106, 0.133, 1)
    r.edge:Show()
    r.status:Show()

    local state = RowState(e.questID, e.complete)
    local statusText = ""
    local s = seeking[e.questID]
    local n = s and CountPeers(s) or 0

    if state == "idle" then
        SetButton(r.btnA, L["Find group"], "find")
        SetButton(r.btnB, nil)
        statusText = ("|cff808080" .. L["Not searching"] .. "|r")
    elseif state == "complete" then
        SetButton(r.btnA, L["Find group"], "find", false)
        SetButton(r.btnB, nil)
        statusText = ("|cff808080" .. L["Complete - ready to turn in"] .. "|r")
    elseif state == "searching" then
        SetButton(r.btnA, L["Stop"], "stop")
        SetButton(r.btnB, nil)
        statusText = ("|cff4fd1c5" .. L["Searching..."] .. "|r  |cff5b606b" .. Elapsed(s) .. "|r")
    elseif state == "found" then
        SetButton(r.btnA, L["Stop"], "stop")
        SetButton(r.btnB, nil)
        statusText = ("|cff5fd38a" .. string.format(L["Players found: %d"], n) .. "|r  |cff5b606b" .. Elapsed(s) .. "|r")
    elseif state == "prompt" then
        SetButton(r.btnA, L["Create Group"], "create")
        SetButton(r.btnB, L["Keep Searching"], "keep")
        statusText = ("|cffff9933" .. L["No one found yet"] .. "|r  |cff808080" .. Elapsed(s) .. "|r")
    elseif state == "listed" then
        SetButton(r.btnA, L["Stop"], "stop")
        SetButton(r.btnB, L["Repost"], "repost")
        local LST = s.listing
        statusText = (string.format("|cff33ccff%s|r  |cff808080Lv%d-%d|r%s", L["Group listed"], LST.min, LST.max,
            n > 0 and ("  |cff5fd38a" .. string.format(L["Players found: %d"], n) .. "|r") or ""))
    end

    -- players spotted in chat for this quest: count on the status line + a Chat button when there's room
    local nChat = #ns.ChatHits(e.questID)
    if nChat > 0 then
        statusText = statusText .. "  |cff33ccff" .. string.format(L["In chat: %d"], nChat) .. "|r"
        if not r.btnB:IsShown() then SetButton(r.btnB, string.format(L["Chat (%d)"], nChat), "chat") end
    end
    r.status:SetText(statusText)

    -- difficulty color drives the level badge and the accent bar (green while searching)
    local lvl = e.level or 0
    local hex = ns.UI.LevelColor(lvl)
    local cr, cg, cb = tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
    if e.complete then cr, cg, cb = 0.5, 0.5, 0.5 end
    r.lvlBg:Show()
    r.lvl:Show()
    r.lvl:SetText(lvl > 0 and tostring(lvl) or "?")
    r.lvl:SetTextColor(cr, cg, cb)
    r.lvlBg:SetColorTexture(cr, cg, cb, 0.16)
    r.accent:Hide()
    if s then ns.UI.Flat(r.edge, { 0.11, 0.2, 0.21, 1 }, ns.UI.C.accent)
    else ns.UI.Flat(r.edge, ns.UI.C.panel, ns.UI.C.line) end

    local rightOf = r.btnB:IsShown() and r.btnB or r.btnA
    local btnW = (r.btnA:IsShown() and 88 or 0) + (r.btnB:IsShown() and 106 or 0)
    r.label:ClearAllPoints()
    r.label:SetPoint("TOPLEFT", r.lvlBg, "TOPRIGHT", 10, 3)
    ns.UI.Font(r.label, 12, "", "medium")
    r.label:SetText(e.title)
    r.label:SetTextColor(e.complete and 0.6 or 0.91, e.complete and 0.6 or 0.9, e.complete and 0.6 or 0.89)

    -- title gets the room left of the buttons, minus the group pill
    local pillW = 0
    if e.group then
        r.pill:SetText(e.group)
        pillW = (tonumber(r.pill:GetStringWidth()) or 30) + 16
    end
    local room = ROW_W - 48 - btnW - 18 - pillW
    local tw = tonumber(r.label:GetStringWidth()) or room
    r.label:SetWidth(math.max(40, math.min(tw + 2, room)))
    if e.group then
        r.pill:ClearAllPoints()
        r.pill:SetPoint("LEFT", r.label, "RIGHT", 10, 0)
        r.pill:Show(); r.pillBg:Show()
    else
        r.pill:Hide(); r.pillBg:Hide()
    end

    r.status:ClearAllPoints()
    r.status:SetPoint("TOPLEFT", r.label, "BOTTOMLEFT", 0, -2)
    r.status:SetPoint("RIGHT", rightOf, "LEFT", -8, 0)

    local done, total = ObjectiveProgress(e.questID)
    if total > 0 then
        r.bar:ClearAllPoints()
        r.bar:SetHeight(2)
        r.bar:SetPoint("BOTTOMLEFT", r.bg, "BOTTOMLEFT", 1, 1)
        r.bar:SetPoint("RIGHT", r.bg, "RIGHT", -1, 0)
        r.bar:SetValue(done / total)
        if done == total then r.bar:SetStatusBarColor(0.37, 0.83, 0.54) else r.bar:SetStatusBarColor(0.31, 0.82, 0.77) end
        r.bar:Show()
    else
        r.bar:Hide()
    end

    -- opened card: show "how to complete" and grow to fit it
    local height = QUEST_H
    r.chev:Hide()
    if expanded[e.questID] then
        r.details:SetText(ns.QuestDetails(e.questID))
        r.details:Show()
        local h = tonumber(r.details:GetStringHeight()) or 0
        height = QUEST_H + math.max(h, 14) + 10
    else
        r.details:Hide()
    end
    r:SetHeight(height)
    return height
end

---------------------------------------------------------------------------
-- Nearby tab: player chips (Questynator matches + players looking in chat)
---------------------------------------------------------------------------
local nearbyContent, nearbyEmpty
local VS = { nearbySections = {}, helperRows = {}, chips = {}, popRows = {}, CARD_GAP = 6 }
VS.CHIP_H, VS.POP_H = 46 + VS.CARD_GAP, 34 + VS.CARD_GAP

function ns.UI.ShowTip(self)
    local tip = self.tip or self.reason
    if tip then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(tip, 1, 1, 1, true)
        GameTooltip:Show()
    end
end

local function GetChip(i)
    local c = VS.chips[i]
    if c then return c end
    c = ns.UI.Card(nearbyContent, ROW_W, VS.CHIP_H - VS.CARD_GAP)
    c.badge = ns.UI.ClassBadge(c, 22)
    c.badge:SetPoint("LEFT", 10, 0)
    c.invite = ns.UI.Button(c, 62, 22, "primary")
    c.invite:SetPoint("RIGHT", c, "RIGHT", -10, 0)
    c.invite:SetText(L["Invite"])
    c.invite:SetScript("OnClick", function() if c.who then Invite(c.who) end end)
    c.whisper = ns.UI.Button(c, 66, 22, "ghost")
    c.whisper:SetPoint("RIGHT", c.invite, "LEFT", -6, 0)
    c.whisper:SetText(L["Whisper"])
    c.whisper:SetScript("OnClick", function() if c.who then Whisper(c.who) end end)
    c.name = ns.UI.Text(c, 12, "text", nil, "medium")
    c.name:SetPoint("TOPLEFT", c.badge, "TOPRIGHT", 10, 4)
    c.name:SetJustifyH("LEFT")
    c.name:SetWordWrap(false)
    c.lvl = ns.UI.Text(c, 9, "dim")
    c.lvl:SetPoint("LEFT", c.name, "RIGHT", 6, 0)
    c.info = ns.UI.Text(c, 10, "muted")
    c.info:SetPoint("TOPLEFT", c.name, "BOTTOMLEFT", 0, -3)
    c.info:SetPoint("RIGHT", c.whisper, "LEFT", -8, 0)
    c.info:SetJustifyH("LEFT")
    c.info:SetWordWrap(false)
    VS.chips[i] = c
    return c
end

local function GetPopRow(i)
    local r = VS.popRows[i]
    if r then return r end
    r = ns.UI.Card(nearbyContent, ROW_W, VS.POP_H - VS.CARD_GAP)
    r.title = ns.UI.Text(r, 12, "text", nil, "medium")
    r.title:SetPoint("LEFT", 12, 0)
    r.title:SetJustifyH("LEFT")
    r.title:SetWordWrap(false)
    r.count = ns.UI.Text(r, 9, "accent", nil, "medium")
    r.count:SetPoint("LEFT", r.title, "RIGHT", 8, 0)
    r.btn = ns.UI.Button(r, 86, 22, "primary")
    r.btn:SetPoint("RIGHT", -8, 0)
    r.btn:SetMotionScriptsWhileDisabled(true)
    r.btn:SetScript("OnClick", function()
        if r.questID and not r.seeking then ns.Start(r.questID) end
    end)
    r.btn:SetScript("OnEnter", ns.UI.ShowTip)
    r.btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    VS.popRows[i] = r
    return r
end

function VS.NearbySection(i)
    local s = VS.nearbySections[i]
    if not s then
        s = ns.UI.Section(nearbyContent)
        s:SetWidth(ROW_W)
        VS.nearbySections[i] = s
    end
    return s
end

function ns.UI.FitTitle(fs, room)
    local w = tonumber(fs:GetStringWidth()) or room
    fs:SetWidth(math.max(40, math.min(w + 2, room)))
end

local function RefreshNearby()
    local list = ns.NearbyEntries()
    local y = 0
    local pop = ns.PopularNearYou and ns.PopularNearYou(5) or {}
    local s1, s2 = VS.NearbySection(1), VS.NearbySection(2)
    if #pop > 0 then
        s1:Set(L["Popular near you"], (GetZoneText and GetZoneText()) or "")
        s1:ClearAllPoints(); s1:SetPoint("TOPLEFT", nearbyContent, "TOPLEFT", 0, -y); s1:Show()
        y = y + 24
        for i, e in ipairs(pop) do
            local r = GetPopRow(i)
            r.questID, r.seeking = e.questID, e.seeking
            r:ClearAllPoints()
            r:SetPoint("TOPLEFT", nearbyContent, "TOPLEFT", 0, -y)
            r:Show()
            r.title:SetText(tostring(e.title))
            r.count:SetText(string.format(L["%d players"], e.count))
            r.btn.tip = nil
            if e.seeking then
                r.btn:SetText(L["Searching"]); r.btn:SetKind("outline"); r.btn:Enable()
            elseif e.inLog then
                r.btn:SetText(L["Find group"]); r.btn:SetKind("primary"); r.btn:Enable()
            else
                r.btn:SetText(L["Not in log"]); r.btn:SetKind("ghost"); r.btn:Disable()
                r.btn.tip = L["This quest isn't in your quest log."]
            end
            ns.UI.FitTitle(r.title, ROW_W - 12 - 86 - 24 - ((tonumber(r.count:GetStringWidth()) or 50) + 8))
            y = y + VS.POP_H
        end
        y = y + 8
    else
        s1:Hide()
    end
    for i = #pop + 1, #VS.popRows do VS.popRows[i]:Hide() end
    if #list > 0 then
        s2:Set(L["On your quests"], tostring(#list))
        s2:ClearAllPoints(); s2:SetPoint("TOPLEFT", nearbyContent, "TOPLEFT", 0, -y); s2:Show()
        y = y + 24
    else
        s2:Hide()
    end
    for i, e in ipairs(list) do
        local c = GetChip(i)
        c.who = e.name
        c:ClearAllPoints()
        c:SetPoint("TOPLEFT", nearbyContent, "TOPLEFT", 0, -y)
        c:Show()
        c.badge:SetClass(e.class)
        c.name:SetText(ClassColorName(e.name, e.class))
        ns.UI.FitTitle(c.name, 200)
        c.lvl:SetText(e.level and string.format(L["Lvl %d"], e.level) or "")
        local src = e.src == "chat" and L["in chat"] or L["via Questynator"]
        c.info:SetText(QuestTitle(e.questID) .. "  |cff5b606b·|r  " .. src)
        y = y + VS.CHIP_H
    end
    for i = #list + 1, #VS.chips do VS.chips[i]:Hide() end
    nearbyContent:SetHeight(math.max(y, 1))
    if #list == 0 and #pop == 0 then nearbyEmpty:Show() else nearbyEmpty:Hide() end
    return #list
end

---------------------------------------------------------------------------
-- Groups tab: every group created with Questynator
---------------------------------------------------------------------------
local groupsContent, groupsEmpty
local groupRows = {}
local GROUP_H = 46 + VS.CARD_GAP

local function GetGroupRow(i)
    local g = groupRows[i]
    if g then return g end
    g = ns.UI.Card(groupsContent, ROW_W, GROUP_H - VS.CARD_GAP)
    g:EnableMouse(true)
    g.badge = ns.UI.ClassBadge(g, 22)
    g.badge:SetPoint("LEFT", 10, 0)
    g.join = ns.UI.Button(g, 80, 22, "primary")
    g.join:SetPoint("RIGHT", g, "RIGHT", -10, 0)
    g.join:SetText(L["Join"])
    g.join:SetScript("OnClick", function()
        if g.entry and not g.entry.mine then ns.JoinGroup(g.entry) end
    end)
    g.join:SetMotionScriptsWhileDisabled(true)
    g.join:SetScript("OnEnter", ns.UI.ShowTip)
    g.join:SetScript("OnLeave", function() GameTooltip:Hide() end)
    g.quest = ns.UI.Text(g, 12, "text", nil, "medium")
    g.quest:SetPoint("TOPLEFT", g.badge, "TOPRIGHT", 10, 4)
    g.quest:SetPoint("RIGHT", g.join, "LEFT", -10, 0)
    g.quest:SetJustifyH("LEFT")
    g.quest:SetWordWrap(false)
    g.info = ns.UI.Text(g, 10, "muted")
    g.info:SetPoint("TOPLEFT", g.quest, "BOTTOMLEFT", 0, -3)
    g.info:SetPoint("RIGHT", g.join, "LEFT", -10, 0)
    g.info:SetJustifyH("LEFT")
    g.info:SetWordWrap(false)
    groupRows[i] = g
    return g
end

local function RefreshGroups()
    local list = ns.GroupEntries()
    local y = 0
    if not VS.groupsSection then
        VS.groupsSection = ns.UI.Section(groupsContent)
        VS.groupsSection:SetWidth(ROW_W)
        VS.groupsSection:SetPoint("TOPLEFT", groupsContent, "TOPLEFT", 0, 0)
    end
    VS.groupsSection:SetShown(#list > 0)
    if #list > 0 then
        VS.groupsSection:Set(L["Open groups"], tostring(#list))
        y = 24
    end
    local C = ns.UI.C
    local myLevel = UnitLevel("player") or 0
    for i, e in ipairs(list) do
        local g = GetGroupRow(i)
        g.entry = e
        g:ClearAllPoints()
        g:SetPoint("TOPLEFT", groupsContent, "TOPLEFT", 0, -y)
        g:Show()
        g.badge:SetClass(e.class)
        g.quest:SetText(e.title or QuestTitle(e.questID))
        local parts = { e.mine and L["You"] or Ambiguate(e.host or "?", "none") }
        if e.min and e.max and e.max > 0 then parts[#parts + 1] = string.format(L["Lvl %d-%d"], e.min, e.max) end
        if e.zone and e.zone ~= "" then parts[#parts + 1] = e.zone end
        parts[#parts + 1] = string.format(L["%d/5 players"], e.members or 1)
        if (e.pending or 0) > 0 then parts[#parts + 1] = string.format(L["%d pending"], e.pending) end
        g.info:SetText(table.concat(parts, "  |cff5b606b·|r  "))

        g.join.reason = nil
        if e.mine then
            ns.UI.Flat(g, { 0.11, 0.2, 0.21, 1 }, C.accent)
            g.join:SetText(L["Your group"]); g.join:SetKind("soft"); g.join:Enable()
        else
            ns.UI.Flat(g, C.panel, C.line)
            local label = L["Join"]
            if (e.members or 1) >= MAX_PARTY then
                g.join.reason = L["This group is full."]; label = L["Full"]
            elseif (e.members or 1) + (e.pending or 0) >= MAX_PARTY then
                g.join.reason = L["Waiting for invited players."]; label = L["Pending"]
            elseif not e.fits then
                g.join.reason = L["Your level isn't in this group's level range."]
                label = (e.min and myLevel < e.min) and L["Too low"] or L["Too high"]
            elseif IsInGroup() and not UnitIsGroupLeader("player") then
                g.join.reason = L["Leave your current group first."]; label = L["In a group"]
            end
            g.join:SetText(label)
            if g.join.reason then g.join:SetKind("ghost"); g.join:Disable()
            else g.join:SetKind("primary"); g.join:Enable() end
        end
        y = y + GROUP_H
    end
    for i = #list + 1, #groupRows do groupRows[i]:Hide() end
    groupsContent:SetHeight(math.max(y, 1))
    if #list == 0 then groupsEmpty:Show() else groupsEmpty:Hide() end
    return #list
end

do -- Dungeons tab UI
---------------------------------------------------------------------------
-- Dungeons tab
---------------------------------------------------------------------------
local dview = {}
local D_HEAD_H, D_ENTRY_H = 30 + VS.CARD_GAP, 28 + 4

local function SmallButton(parent, w, text, fn, kind)
    local b = ns.UI.Button(parent, w, 20, kind or "ghost")
    b:SetText(text)
    b:SetScript("OnClick", fn)
    b:SetMotionScriptsWhileDisabled(true)
    b:SetScript("OnEnter", ns.UI.ShowTip)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return b
end

function ns.BuildDungeonsView(p, inset)
    local UI = ns.UI
    local v = CreateFrame("Frame", nil, inset)
    v:SetAllPoints(inset)
    p.dungeonsView = v

    -- roles card: your roles on the left, what you're doing on the right
    local top = UI.Card(v, ROW_W, 64)
    top:SetPoint("TOPLEFT", v, "TOPLEFT", 6, -6)
    top.label = UI.Text(top, 9, "muted", nil, "bold")
    top.label:SetPoint("TOPLEFT", 12, -10)
    local rl = L["Your roles"]
    top.label:SetText(rl:find("[\128-\255]") and rl or rl:upper())
    dview.roleButtons = {}
    local prev
    for _, r in ipairs({ "T", "H", "D" }) do
        -- the game's own role icons; the name shows on hover
        local b = UI.Button(top, 34, 26, "ghost")
        b:SetText("")
        b.icon = b:CreateTexture(nil, "OVERLAY")
        b.icon:SetSize(20, 20)
        b.icon:SetPoint("CENTER")
        b.icon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
        b.icon:SetTexCoord((unpack or table.unpack)(ns.RoleIconCoords(r)))
        b:SetScript("OnClick", function() ns.ToggleMyRole(r) end)
        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(ns.RoleName(r), 1, 1, 1)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        if prev then b:SetPoint("LEFT", prev, "RIGHT", 6, 0) else b:SetPoint("TOPLEFT", top, "TOPLEFT", 10, -30) end
        b.role = r
        dview.roleButtons[#dview.roleButtons + 1] = b
        prev = b
    end
    top.mode = UI.Text(top, 9, "dim", nil, "medium")
    top.mode:SetPoint("TOPRIGHT", -12, -10)
    top.name = UI.Text(top, 11, "accent", nil, "medium")
    top.name:SetPoint("TOPRIGHT", -12, -24)
    top.need = UI.Text(top, 9, "muted")
    top.need:SetPoint("TOPRIGHT", -12, -40)
    top.need:SetJustifyH("RIGHT")
    dview.top = top

    top.post = UI.Button(v, 120, 22, "primary")
    top.post:SetText(L["Post to General"])
    top.post:SetScript("OnClick", function() ns.PostDungeon() end)
    top.post:SetPoint("TOPLEFT", top, "BOTTOMLEFT", 0, -8)
    top.stop = UI.Button(v, 60, 22, "ghost")
    top.stop:SetText(L["Stop"])
    top.stop:SetScript("OnClick", function() ns.StopDungeon(false) end)

    local scroll = CreateFrame("ScrollFrame", nil, v, "UIPanelScrollFrameTemplate")
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(ROW_W, 1)
    scroll:SetScrollChild(child)
    UI.SkinScroll(scroll)
    dview.scroll = scroll
    dview.content = child
    dview.heads, dview.entries = {}, {}
    dview.empty = UI.Text(v, 12, "dim")
    dview.empty:SetPoint("CENTER", v, "CENTER", 0, -30)
    dview.empty:SetText(L["No dungeons for your level yet."])
    dview.empty:Hide()
end

local function DungeonHead(i)
    local h = dview.heads[i]
    if h then return h end
    h = ns.UI.Card(dview.content, ROW_W, D_HEAD_H - VS.CARD_GAP)
    h:EnableMouse(true)
    h.name = ns.UI.Text(h, 12, "text", nil, "medium")
    h.name:SetPoint("LEFT", 12, 0)
    h.name:SetJustifyH("LEFT")
    h.name:SetWordWrap(false)
    h.range = ns.UI.Text(h, 9, "dim")
    h.range:SetPoint("LEFT", h.name, "RIGHT", 6, 0)
    h.count = ns.UI.Text(h, 9, "accent", nil, "medium")
    h.count:SetPoint("LEFT", h, "LEFT", 236, 0)
    h.host = SmallButton(h, 44, L["Host"], function() ns.StartDungeon(h.id, "host") end)
    h.host:SetPoint("RIGHT", -8, 0)
    h.host.tip = L["List your group: players whisper you + and get invited."]
    h.look = SmallButton(h, 44, L["Look"], function() ns.StartDungeon(h.id, "seek") end)
    h.look:SetPoint("RIGHT", h.host, "LEFT", -4, 0)
    h.look.tip = L["Look for a group for this dungeon with your roles."]
    h.prep = SmallButton(h, 48, L["Prep"], function()
        dview.selectedPrep = dview.selectedPrep ~= h.id and h.id or nil
        ns.RefreshDungeons()
    end)
    h.prep:SetPoint("RIGHT", h.look, "LEFT", -4, 0)
    h.prep.tip = L["Show or hide Dungeon Prep"]
    -- click the dungeon name for a waypoint to the entrance
    h:SetScript("OnMouseUp", function() if h.id then ns.DungeonWaypoint(h.id) end end)
    h:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L["Waypoint to the entrance"], 1, 1, 1)
        GameTooltip:Show()
    end)
    h:SetScript("OnLeave", function() GameTooltip:Hide() end)
    dview.heads[i] = h
    return h
end

local function DungeonEntry(i)
    local e = dview.entries[i]
    if e then return e end
    e = ns.UI.Card(dview.content, ROW_W - 12, D_ENTRY_H - 4)
    e:EnableMouse(true)
    e.badge = ns.UI.ClassBadge(e, 18)
    e.badge:SetPoint("LEFT", 8, 0)
    e.text = ns.UI.Text(e, 11, "muted")
    e.text:SetPoint("LEFT", e.badge, "RIGHT", 8, 0)
    e.text:SetJustifyH("LEFT")
    e.text:SetWordWrap(false)
    e.btn = SmallButton(e, 56, "", function()
        if e.action == "join" then ns.JoinDungeon(e.who, e.id)
        elseif e.action == "invite" then Invite(e.who) end
    end, "primary")
    e.btn:SetPoint("RIGHT", -8, 0)
    e.text:SetPoint("RIGHT", e.btn, "LEFT", -8, 0)
    -- click the player to whisper them
    e:SetScript("OnMouseUp", function() if e.who then Whisper(e.who) end end)
    e:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L["Click to whisper"], 1, 1, 1)
        GameTooltip:Show()
    end)
    e:SetScript("OnLeave", function() GameTooltip:Hide() end)
    dview.entries[i] = e
    return e
end

function ns.RefreshDungeons()
    if not dview.content then return 0 end
    local C = ns.UI.C
    local roles, mine = ns.MyRoles(), ns.MyDungeon()
    for _, b in ipairs(dview.roleButtons) do b:SetKind(roles[b.role] and "primary" or "ghost") end
    local top = dview.top
    local hosting = mine and mine.mode == "host"
    if mine then
        top.mode:SetText(hosting and L["Hosting"] or L["Looking"])
        top.name:SetText(ns.DungeonName(mine.id))
        local need = hosting and ns.NeedText() or ns.RolesText(roles)
        top.need:SetText(need ~= "" and ((hosting and (L["need"] .. " ") or "") .. need) or "")
        top.stop:Show()
        top.stop:ClearAllPoints()
        if hosting then
            top.post:Show()
            top.stop:SetPoint("LEFT", top.post, "RIGHT", 6, 0)
        else
            top.post:Hide()
            top.stop:SetPoint("TOPLEFT", top, "BOTTOMLEFT", 0, -8)
        end
    else
        top.mode:SetText("")
        top.name:SetText("")
        top.need:SetText(L["Pick your roles, then Look for a group or Host one."])
        top.need:SetWidth(200)
        top.stop:Hide()
        top.post:Hide()
    end
    local listTop = mine and 108 or 78
    dview.scroll:ClearAllPoints()
    dview.scroll:SetPoint("TOPLEFT", dview.scroll:GetParent(), "TOPLEFT", 6, -listTop)
    dview.scroll:SetPoint("BOTTOMRIGHT", dview.scroll:GetParent(), "BOTTOMRIGHT", -28, 6)

    local list = ns.DungeonList()
    local y, nh, ne, total = 0, 0, 0, 0
    local grouped = IsInGroup()
    local canInvite = not grouped or UnitIsGroupLeader("player")
    if dview.prepCard then dview.prepCard:Hide() end
    for _, d in ipairs(list) do
        nh = nh + 1
        local h = DungeonHead(nh)
        h.id = d.id
        h:ClearAllPoints()
        h:SetPoint("TOPLEFT", dview.content, "TOPLEFT", 0, -y)
        h:Show()
        if d.mine then ns.UI.SetEdge(h, C.accent, 0.9) else ns.UI.SetEdge(h, C.line) end
        h.name:SetText(d.name)
        ns.UI.FitTitle(h.name, 160)
        h.range:SetText(d.min .. "-" .. d.max)
        local counts = {}
        if #d.hosts > 0 then counts[#counts + 1] = string.format(L["%d groups"], #d.hosts) end
        if #d.seekers > 0 then counts[#counts + 1] = string.format(L["%d looking"], #d.seekers) end
        h.count:SetText(table.concat(counts, "  "))
        local hasPrep = ns.HasDungeonPrep(d.id)
        h.prep:SetShown(hasPrep)
        h.count:SetWidth(hasPrep and 112 or 160)
        h.count:SetJustifyH("LEFT")
        h.count:SetWordWrap(false)
        h.look:SetShown(not d.mine)
        h.host:SetShown(not d.mine)
        if canInvite then
            h.host.tip = L["List your group: players whisper you + and get invited."]
            h.host:Enable()
        else
            h.host.tip = L["Only the group leader can invite."]
            h.host:Disable()
        end
        y = y + D_HEAD_H
        total = total + #d.hosts + #d.seekers
        local had = false
        for _, kind in ipairs({ "hosts", "seekers" }) do
            for _, who in ipairs(d[kind]) do
                had = true
                ne = ne + 1
                local e = DungeonEntry(ne)
                e.who, e.id = who.name, d.id
                e:ClearAllPoints()
                e:SetPoint("TOPLEFT", dview.content, "TOPLEFT", 12, -(y - VS.CARD_GAP + 4))
                e:Show()
                e.badge:SetClass(who.class)
                local lvl = who.level and ("  |cff5b606b" .. string.format(L["Lvl %d"], who.level) .. "|r") or ""
                local name = ClassColorName(who.name, who.class)
                if kind == "hosts" then
                    local need = ns.RolesText(who.roles)
                    e.text:SetText(name .. lvl .. "  |cff5b606b·|r  " .. string.format(L["%d/5 players"], who.members or 1)
                        .. (need ~= "" and ("  |cff5b606b·|r  " .. L["need"] .. " " .. need) or ""))
                    e.action = "join"
                    e.btn:SetText(L["Join"])
                    e.btn.tip = nil
                    if grouped then
                        e.btn.tip = L["Leave your current group first."]
                        e.btn:Disable()
                    elseif (who.members or 1) + who.pending >= MAX_PARTY then
                        e.btn:SetText(who.pending > 0 and L["Pending"] or L["Full"])
                        e.btn.tip = who.pending > 0 and L["Waiting for invited players."] or L["This group is full."]
                        e.btn:Disable()
                    else
                        e.btn:Enable()
                    end
                else
                    e.text:SetText(name .. lvl .. "  |cff5b606b·|r  " .. ns.RolesText(who.roles))
                    e.action = "invite"
                    e.btn:SetText(L["Invite"])
                    e.btn.tip = nil
                    if canInvite then e.btn:Enable() else e.btn.tip = L["Only the group leader can invite."]; e.btn:Disable() end
                end
                y = y + D_ENTRY_H
            end
        end
        if had then y = y + VS.CARD_GAP end
        if hasPrep and dview.selectedPrep == d.id then
            y = ns.DrawDungeonPrep(dview, d.id, ROW_W, y) + VS.CARD_GAP
        end
    end
    for i = nh + 1, #dview.heads do dview.heads[i]:Hide() end
    for i = ne + 1, #dview.entries do dview.entries[i]:Hide() end
    dview.content:SetHeight(math.max(y, 1))
    dview.empty:SetShown(#list == 0)
    return total
end
end

---------------------------------------------------------------------------
-- Stats tab
---------------------------------------------------------------------------
local statTiles = {}

function ns.UI.Caps(s)
    s = tostring(s or ""):gsub(":$", "")
    if s:find("[\128-\255]") then return s end
    return s:upper()
end

function ns.BuildStatsView(p, inset)
    local UI, C = ns.UI, ns.UI.C
    local v = CreateFrame("Frame", nil, inset)
    v:SetAllPoints(inset)
    p.statsView = v
    local W = 536          -- the Stats view has no scrollbar, so it uses the full inset (548 - 2 x 6)
    local tileW = math.floor((W - 8) / 2)
    local labels = { L["Users online"], L["Quests together"], L["Groups formed"], L["Active searches"] }
    for i, text in ipairs(labels) do
        local t = UI.Card(v, tileW, 60)
        local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
        t:SetPoint("TOPLEFT", v, "TOPLEFT", 6 + col * (tileW + 8), -6 - row * 68)
        t.value = UI.Text(t, 20, i == 1 and "accent" or "text", nil, "bold")
        t.value:SetPoint("TOPLEFT", 12, -9)
        t.label = UI.Text(t, 8, "muted", nil, "bold")
        t.label:SetPoint("TOPLEFT", 12, -40)
        t.label:SetText(ns.UI.Caps(text))
        statTiles[i] = t
    end

    -- top helpers this week
    local helpers = UI.Card(v, W, 128)
    helpers:SetPoint("TOPLEFT", v, "TOPLEFT", 6, -146)
    helpers.title = UI.Text(helpers, 9, "muted", nil, "bold")
    helpers.title:SetPoint("TOPLEFT", 12, -11)
    helpers.title:SetText(ns.UI.Caps(L["Top helpers this week"]))
    helpers.kudos = UI.Text(helpers, 9, "accent", nil, "medium")
    helpers.kudos:SetPoint("TOPRIGHT", -12, -11)
    for i = 1, 5 do
        local y = -32 - (i - 1) * 18
        local r = {}
        r.rank = UI.Text(helpers, 10, "dim")
        r.rank:SetPoint("TOPLEFT", 12, y)
        r.badge = UI.ClassBadge(helpers, 14)
        r.badge:SetPoint("TOPLEFT", 26, y + 1)
        r.name = UI.Text(helpers, 11, "text", nil, "medium")
        r.name:SetPoint("TOPLEFT", 46, y)
        r.you = UI.Text(helpers, 9, "accent", nil, "medium")
        r.you:SetPoint("LEFT", r.name, "RIGHT", 6, 0)
        r.bar = helpers:CreateTexture(nil, "ARTWORK")
        r.bar:SetHeight(4)
        r.bar:SetPoint("TOPLEFT", helpers, "TOPLEFT", W - 276, y - 5)
        r.bar:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
        r.score = UI.Text(helpers, 11, "text", nil, "bold")
        r.score:SetPoint("TOPRIGHT", -12, y)
        VS.helperRows[i] = r
    end
    helpers.empty = UI.Text(helpers, 10, "muted")
    helpers.empty:SetPoint("TOPLEFT", 12, -34)
    helpers.empty:SetWidth(W - 24)
    helpers.empty:SetJustifyH("LEFT")
    helpers.empty:SetText(L["Form groups and finish quests together to get on the board."])
    p.helpers = helpers

    -- about the author
    local about = UI.Card(v, W, 100)
    about:SetPoint("TOPLEFT", v, "TOPLEFT", 6, -282)
    about.title = UI.Text(about, 9, "muted", nil, "bold")
    about.title:SetPoint("TOPLEFT", 12, -11)
    about.title:SetText(ns.UI.Caps(L["About"]))
    about.who = UI.Text(about, 11, "muted")
    about.who:SetPoint("TOPLEFT", 12, -29)
    about.who:SetText(string.format(L["Made by %s"], "|cffe8e6e3" .. AUTHOR.name .. " " .. AUTHOR.realm .. "|r")
        .. "  |cff5b606bHorde · PvE · EU|r")
    about.tag = UI.Text(about, 11, "accent", nil, "medium")
    about.tag:SetPoint("TOPLEFT", 12, -47)
    about.tag:SetText("BattleTag  " .. AUTHOR.battletag)
    about.whisper = UI.Button(about, 128, 22, "ghost")
    about.whisper:SetPoint("BOTTOMLEFT", 10, 10)
    about.whisper:SetText(string.format(L["Whisper %s"], AUTHOR.name))
    about.whisper:SetScript("OnClick", ns.WhisperAuthor)
    about.copy = UI.Button(about, 110, 22, "ghost")
    about.copy:SetPoint("LEFT", about.whisper, "RIGHT", 6, 0)
    about.copy:SetText(L["Copy BattleTag"])
    about.copy:SetScript("OnClick", ns.ShowCopyBattleTag)
    about.note = UI.Text(about, 8, "dim")
    about.note:SetPoint("BOTTOMRIGHT", -12, 17)
    about.note:SetText(L["Bugs & ideas: CurseForge"])
    p.about = about

    -- quick settings: the toggles people look for most, plus the full options page
    local qs = UI.Card(v, W, 44)
    qs:SetPoint("TOPLEFT", v, "TOPLEFT", 6, -390)
    -- no section label: four buttons and the labels of other languages need the whole width
    qs.toggles = {}
    local prev
    for _, t in ipairs({ { "arrow", L["Quest arrow"] }, { "partyChat", L["Party messages"] }, { "sound", L["Sound"] } }) do
        local b = UI.Button(qs, 10, 22, "ghost")
        b:SetText(t[2])
        b:SetWidth((tonumber(b.label:GetStringWidth()) or 60) + 20)
        if prev then b:SetPoint("LEFT", prev, "RIGHT", 6, 0) else b:SetPoint("LEFT", qs, "LEFT", 10, 0) end
        b.key = t[1]
        b:SetScript("OnClick", function(self) ns.SetOption(self.key, not ns.GetOption(self.key)) end)
        qs.toggles[#qs.toggles + 1] = b
        prev = b
    end
    local all = UI.Button(qs, 86, 22, "ghost")
    all:SetPoint("RIGHT", -10, 0)
    all:SetText(L["All options"])
    all:SetWidth(math.max(70, (tonumber(all.label:GetStringWidth()) or 66) + 20))
    all:SetScript("OnClick", function() ns.OpenOptions() end)
    p.quickSettings = qs
    function ns.RefreshQuickSettings()
        for _, b in ipairs(qs.toggles) do b:SetKind(ns.GetOption(b.key) and "soft" or "ghost") end
    end
    ns.RefreshQuickSettings()
end

local function RefreshStats()
    local active = 0
    for _ in pairs(seeking) do active = active + 1 end
    local values = { ns.OnlineCount(), DB.stats.quests, DB.stats.groups, active }
    for i, t in ipairs(statTiles) do t.value:SetText(tostring(values[i] or 0)) end
    local h = panel and panel.helpers
    if h then
        h.kudos:SetText(string.format(L["Your kudos %d"], tonumber(DB.kudos) or 0))
        local top = ns.TopHelpers(5)
        local max = 1
        for _, e in ipairs(top) do if (e.score or 0) > max then max = e.score end end
        for i, r in ipairs(VS.helperRows) do
            local e = top[i]
            local on = e ~= nil
            for _, k in ipairs({ "rank", "name", "you", "bar", "score" }) do r[k]:SetShown(on) end
            r.badge:SetShown(on)
            if on then
                r.rank:SetText(tostring(i))
                r.badge:SetClass(e.class)
                r.name:SetText(ClassColorName(e.name, e.class))
                r.you:SetText(e.me and L["you"] or "")
                r.bar:SetWidth(math.max(2, 150 * (e.score or 0) / max))
                r.score:SetText(tostring(e.score or 0))
            end
        end
        h.empty:SetShown(#top == 0)
    end
end


---------------------------------------------------------------------------
-- Zones tab: quests you can pick up now, grouped by the zone you get them in
---------------------------------------------------------------------------
do
local CLASS_ID = { WARRIOR = 1, PALADIN = 2, HUNTER = 3, ROGUE = 4, PRIEST = 5, DEATHKNIGHT = 6, SHAMAN = 7,
                   MAGE = 8, WARLOCK = 9, MONK = 10, DRUID = 11, DEMONHUNTER = 12 }
local HORDE_RACE = { [2] = true, [5] = true, [6] = true, [8] = true, [9] = true, [10] = true, [96] = true }
function ns.PlayerFaction(raceID)
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    if faction == "Horde" then return "H" end
    if faction == "Alliance" then return "A" end
    raceID = raceID or select(3, UnitRace("player"))
    return raceID and (HORDE_RACE[raceID] and "H" or "A") or nil
end
-- capitals and home zones: a "friendly to both" giver standing here is only reachable by that faction
-- (e.g. the Argent Dawn in Darnassus). Contested and neutral zones are left out on purpose.
local FACTION_ZONE = {
    [1519] = "A", [1537] = "A", [1657] = "A", [12] = "A", [1] = "A", [141] = "A", [40] = "A", [38] = "A",
    [148] = "A", [44] = "A", [10] = "A",
    [1637] = "H", [1638] = "H", [1497] = "H", [14] = "H", [215] = "H", [85] = "H", [130] = "H",
}

local function HasBit(mask, bit)                 -- plain arithmetic: works on every client
    return math.floor(mask / 2 ^ (bit - 1)) % 2 == 1
end

local function List(s)
    local out = {}
    for n in tostring(s or ""):gmatch("%d+") do out[#out + 1] = tonumber(n) end
    return out
end

-- a["id"] = "req;lvl;races;classes;preAll;preAny;exclusive;chain;elite;faction;name"
local parsed = {}
function ns.ZoneQuest(qid)
    local p = parsed[qid]
    if p ~= nil then return p or nil end
    local D = ns.QDATA
    local raw = D and D.a and D.a[qid]
    if not raw then parsed[qid] = false; return nil end
    local req, lvl, races, classes, pre, preAny, excl, chain, elite, fac, name =
        raw:match("^([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);(.*)$")
    if not name then parsed[qid] = false; return nil end
    p = { req = tonumber(req) or 0, level = tonumber(lvl) or 0, races = tonumber(races) or 0, classes = tonumber(classes) or 0,
          pre = List(pre), preAny = List(preAny), excl = List(excl), chain = tonumber(chain), elite = elite == "1",
          faction = fac ~= "" and fac or nil, name = name }
    parsed[qid] = p
    return p
end

-- quest XP: base value from the bundled QuestieDB XP table (x), scaled to your level the Classic way:
-- full up to quest level + 5, then 80/60/40/20%, then 10%; rounded like the game rounds it
local XP_FACTOR = { [6] = 0.8, [7] = 0.6, [8] = 0.4, [9] = 0.2 }
function ns.QuestXP(qid, playerLevel)
    local D = ns.QDATA
    local base = D and D.x and tonumber(D.x[qid])
    if not base then return nil end
    local p = ns.ZoneQuest(qid)
    playerLevel = playerLevel or UnitLevel("player") or 1
    local qlvl = p and p.level or playerLevel
    local maxLevel = GetMaxPlayerLevel and GetMaxPlayerLevel()
    if maxLevel and playerLevel >= maxLevel then return 0 end
    local diff = playerLevel - qlvl
    local xp = base * (diff <= 5 and 1 or XP_FACTOR[diff] or 0.1)
    local step = xp <= 100 and 5 or xp <= 500 and 10 or xp <= 1000 and 25 or 50
    return math.floor(xp / step + 0.5) * step
end

local completed = {}
function ns.RecordQuestTurnIn(qid)
    if type(qid) == "number" and qid > 0 then completed[qid] = true end
    completed.loaded = nil
end

local function Completed(qid)
    if completed[qid] then return true end
    if not completed.loaded and C_QuestLog.GetAllCompletedQuestIDs then
        local ids = C_QuestLog.GetAllCompletedQuestIDs()
        if ids then
            for _, id in ipairs(ids) do completed[id] = true end
            completed.loaded = true
        end
    end
    if not completed[qid] then
        local flagged = C_QuestLog.IsQuestFlaggedCompleted or IsQuestFlaggedCompleted
        if flagged and flagged(qid) then completed[qid] = true end
    end
    return completed[qid] == true
end

-- the giver: name, zone and coordinates from the bundled data
local function Giver(qid)
    local D = ns.QDATA
    local q = D and D.q and D.q[qid]
    local kind, id
    if q then kind, id = q:match("^([no])(%d+)") end
    local raw = kind and D[kind] and D[kind][tonumber(id)]
    if not raw then return nil end
    local zone, x, y, _, _, name = raw:match("^([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),(.*)$")
    zone, x, y = tonumber(zone), tonumber(x), tonumber(y)
    if not (zone and x and y) then return nil end
    return { area = zone, x = x, y = y, name = name }
end

function ns.QuestGreenRange(level)
    return (GetQuestGreenRange and GetQuestGreenRange()) or (level <= 5 and 5 or math.floor(level / 10) + 5)
end

function ns.QuestFitsLevel(quest, level, green)
    return quest and quest.req <= level and quest.level >= level - green and quest.level <= level + 5
end

local function Me()
    local level = UnitLevel("player") or 1
    local _, _, raceID = UnitRace("player")
    local _, classToken, classID = UnitClass("player")
    classID = classID or CLASS_ID[classToken or ""]
    local f = ns.PlayerFaction(raceID)
    local green = ns.QuestGreenRange(level)
    return level, ns.RaceBit(raceID), classID, f, green
end

-- every quest you could walk up to and take right now
function ns.AvailableQuests()
    local D = ns.QDATA
    if not (D and D.a) then return {} end
    local level, raceBit, classID, faction, green = Me()
    local inLog = {}
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        if info and info.questID and not info.isHeader then inLog[info.questID] = true end
    end
    local out = {}
    for qid in pairs(D.a) do
        if not completed[qid] and not inLog[qid] then
            local p = ns.ZoneQuest(qid)
            local ok = ns.QuestFitsLevel(p, level, green)
            if ok and p.races > 0 and raceBit then ok = HasBit(p.races, raceBit) end
            if ok and p.classes > 0 and classID then ok = HasBit(p.classes, classID) end
            if ok and p.faction and faction then ok = p.faction == faction end
            if ok then for _, id in ipairs(p.pre) do if not Completed(id) then ok = false; break end end end
            if ok and #p.preAny > 0 then
                local any = false
                for _, id in ipairs(p.preAny) do if Completed(id) then any = true; break end end
                ok = any
            end
            if ok then for _, id in ipairs(p.excl) do if Completed(id) or inLog[id] then ok = false; break end end end
            local g = ok and Giver(qid)
            if g and not p.faction and faction and FACTION_ZONE[g.area] and FACTION_ZONE[g.area] ~= faction then g = nil end
            if g and not Completed(qid) then
                local elite = p.elite
                if not elite and C_QuestLog.GetQuestTagInfo then
                    local tag = C_QuestLog.GetQuestTagInfo(qid)
                    elite = type(tag) == "table" and (tag.isElite or tag.tagID == 1) and true or false
                end
                out[#out + 1] = { questID = qid, level = p.level, name = p.name, chain = p.chain, elite = elite,
                                  giver = g.name, area = g.area, x = g.x, y = g.y, xp = ns.QuestXP(qid, level) }
            end
        end
    end
    return out
end

-- one quest's state for you: done / inlog / available / locked (+ the level it needs) / hidden (not for you)
-- grey quests still count as available here (Treasures want them even when they give little XP)
function ns.QuestState(qid)
    local level, raceBit, classID, faction = Me()
    if Completed(qid) then return "done" end
    if ns.QuestLogIndex(qid) then return "inlog" end
    local p = ns.ZoneQuest(qid)
    if not p then return "unknown" end
    if p.races > 0 and raceBit and not HasBit(p.races, raceBit) then return "hidden" end
    if p.classes > 0 and classID and not HasBit(p.classes, classID) then return "hidden" end
    if p.faction and faction and p.faction ~= faction then return "hidden" end
    local g = Giver(qid)
    if g and not p.faction and faction and FACTION_ZONE[g.area] and FACTION_ZONE[g.area] ~= faction then return "hidden" end
    for _, id in ipairs(p.excl) do
        if Completed(id) or ns.QuestLogIndex(id) then return "hidden" end
    end
    if p.req > level then return "locked", p.req end
    for _, id in ipairs(p.pre) do if not Completed(id) then return "locked", p.req end end
    if #p.preAny > 0 then
        local any = false
        for _, id in ipairs(p.preAny) do if Completed(id) then any = true; break end end
        if not any then return "locked", p.req end
    end
    return "available"
end

function ns.QuestGiver(qid) return Giver(qid) end

-- zones that have quests for you; your current zone first, then the closest level ranges
function ns.ZoneGroups(maxZones)
    local D = ns.QDATA
    local level = UnitLevel("player") or 1
    local byArea, order = {}, {}
    for _, e in ipairs(ns.AvailableQuests()) do
        local z = byArea[e.area]
        if not z then
            local lo, hi = tostring(D.z and D.z[e.area] or ""):match("^(%d+),(%d+)$")
            z = { area = e.area, min = tonumber(lo), max = tonumber(hi), quests = {} }
            z.name = (C_Map and C_Map.GetAreaInfo and C_Map.GetAreaInfo(e.area))
            if type(z.name) ~= "string" or z.name == "" then
                local m = ns.UiMapForArea(e.area)
                local info = m and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(m)
                z.name = (info and info.name) or ("#" .. e.area)
            end
            byArea[e.area] = z
            order[#order + 1] = z
        end
        z.quests[#z.quests + 1] = e
        z.xp = (z.xp or 0) + (e.xp or 0)
        -- the label shows the levels of the quests you can pick up here, not the zone's whole range
        z.lo = math.min(z.lo or e.level, e.level)
        z.hi = math.max(z.hi or e.level, e.level)
    end
    local hereMap = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local function score(z)
        if hereMap and ns.UiMapForArea(z.area) == hereMap then return -1000 end
        local mid = (z.lo and z.hi) and (z.lo + z.hi) / 2 or level
        return math.abs(mid - level) - #z.quests * 0.05
    end
    table.sort(order, function(a, b)
        local sa, sb = score(a), score(b)
        if sa ~= sb then return sa < sb end
        return a.area < b.area
    end)
    for _, z in ipairs(order) do
        table.sort(z.quests, function(a, b)
            if a.level ~= b.level then return a.level < b.level end
            return a.name < b.name
        end)
    end
    if maxZones and #order > maxZones then
        for i = #order, maxZones + 1, -1 do table.remove(order, i) end
    end
    return order
end

---------------------------------------------------------------------------
-- the tab
---------------------------------------------------------------------------
local zv = { heads = {}, rows = {}, open = {} }
local Z_HEAD_H, Z_ROW_H, GAP = 34, 46, 6

function ns.BuildZonesView(p, inset)
    local UI = ns.UI
    local v = CreateFrame("Frame", nil, inset)
    v:SetAllPoints(inset)
    p.zonesView = v
    zv.top = UI.Text(v, 11, "muted")
    zv.top:SetPoint("TOPLEFT", v, "TOPLEFT", 8, -8)
    zv.top:SetWidth(ROW_W)
    zv.top:SetJustifyH("LEFT")
    local scroll = CreateFrame("ScrollFrame", nil, v, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", v, "TOPLEFT", 6, -30)
    scroll:SetPoint("BOTTOMRIGHT", v, "BOTTOMRIGHT", -28, 6)
    UI.SkinScroll(scroll)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(ROW_W, 1)
    scroll:SetScrollChild(child)
    zv.content = child
    zv.empty = UI.Empty(v, function() ns.SelectTab(1) end)
    zv.empty:SetPoint("CENTER", v, "CENTER", 0, 10)
    zv.empty:Set(L["Nothing new to pick up"], L["You've done every quest for your level that we know of. Check your quest log, or try a dungeon."], L["Quests"])
end

local function Head(i)
    local h = zv.heads[i]
    if h then return h end
    local UI = ns.UI
    h = UI.Card(zv.content, ROW_W, Z_HEAD_H - GAP)
    h:EnableMouse(true)
    h.name = UI.Text(h, 12, "text", nil, "medium")
    h.name:SetPoint("LEFT", 12, 0)
    h.range = UI.Text(h, 9, "dim")
    h.range:SetPoint("LEFT", h.name, "RIGHT", 6, 0)
    h.count = UI.Text(h, 9, "accent", nil, "medium")
    h.count:SetPoint("RIGHT", -12, 0)
    h:SetScript("OnMouseUp", function(self)
        zv.open[self.area] = not zv.open[self.area]
        ns.RefreshZones()
    end)
    zv.heads[i] = h
    return h
end

local function Row(i)
    local r = zv.rows[i]
    if r then return r end
    local UI = ns.UI
    r = UI.Card(zv.content, ROW_W - 12, Z_ROW_H - GAP)
    r:EnableMouse(true)
    r.lvlBg = CreateFrame("Frame", nil, r)
    r.lvlBg:SetSize(28, 20)
    r.lvlBg:SetPoint("TOPLEFT", 10, -10)
    UI.Flat(r.lvlBg, UI.C.panel2, false)
    r.lvl = UI.Text(r.lvlBg, 11, "text", nil, "bold")
    r.lvl:SetPoint("CENTER")
    r.btn = UI.Button(r, 88, 22, "primary")
    r.btn:SetPoint("TOPRIGHT", -10, -9)
    r.btn:SetScript("OnClick", function(self)
        if not r.questID then return end
        ns.Toggle(r.questID)
    end)
    r.name = UI.Text(r, 12, "text", nil, "medium")
    r.name:SetPoint("TOPLEFT", r.lvlBg, "TOPRIGHT", 10, 3)
    r.name:SetJustifyH("LEFT")
    r.name:SetWordWrap(false)
    r.pills = UI.Text(r, 9, "accent", nil, "medium")
    r.pills:SetPoint("LEFT", r.name, "RIGHT", 8, 0)
    r.where = CreateFrame("Button", nil, r)
    r.where:SetHeight(14)
    r.where:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -3)
    r.where.text = UI.Text(r.where, 10, "muted")
    r.where.text:SetPoint("LEFT")
    r.where.text:SetJustifyH("LEFT")
    r.where.text:SetWordWrap(false)
    r.where:EnableMouse(false)
    -- right side, centred on the card: [Find group] [waypoint] [!]
    local function Tip(b, line)
        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(line, 1, 1, 1)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    r.info = UI.Button(r, 26, 22, "soft")
    r.info:SetPoint("TOPRIGHT", -10, -9)
    r.info.mark = UI.Text(r.info, 13, "gold", "OVERLAY", "bold")
    r.info.mark:SetPoint("CENTER", 0, 0)
    r.info.mark:SetText("!")
    r.info:SetScript("OnClick", function()
        if r.questID then zv.open["q" .. r.questID] = not zv.open["q" .. r.questID] or nil; ns.RefreshZones() end
    end)
    Tip(r.info, L["How to do it"])
    r.nav = UI.Button(r, 26, 22, "soft")
    r.nav:SetPoint("RIGHT", r.info, "LEFT", -6, 0)
    r.nav.icon = r.nav:CreateTexture(nil, "OVERLAY")
    r.nav.icon:SetSize(14, 14)
    r.nav.icon:SetPoint("CENTER", 0, 0)
    r.nav.icon:SetTexture("Interface\\AddOns\\Questynator\\Media\\NavArrow")
    r.nav.icon:SetVertexColor(UI.C.accent[1], UI.C.accent[2], UI.C.accent[3])
    r.nav:SetScript("OnClick", function()
        if r.e then ns.Waypoint(r.e.area, r.e.x, r.e.y, r.e.giver .. " - " .. r.e.name) end
    end)
    Tip(r.nav, L["Click to set a waypoint"])
    r.btn:ClearAllPoints()
    r.btn:SetPoint("RIGHT", r.nav, "LEFT", -6, 0)
    r.details = UI.Text(r, 11, "text")
    r.details:SetPoint("TOPLEFT", r, "TOPLEFT", 14, -46)
    r.details:SetWidth(ROW_W - 40)
    r.details:SetJustifyH("LEFT")
    r.details:SetJustifyV("TOP")
    zv.rows[i] = r
    return r
end

local function LevelRGB(lvl)
    local hex = ns.UI.LevelColor(lvl)
    return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end

function ns.ZonesState() return zv end

function ns.RefreshZones()
    if not zv.content then return 0 end
    local zones = ns.ZoneGroups(6)
    local level = UnitLevel("player") or 1
    local total = 0
    for _, z in ipairs(zones) do total = total + #z.quests end
    zv.top:SetText(string.format(L["Level %d  ·  %d quests to pick up in %d zones"], level, total, #zones))
    zv.empty:SetShown(#zones == 0)
    zv.top:SetShown(#zones > 0)
    if zv.firstOpen == nil and zones[1] then zv.open[zones[1].area] = true; zv.firstOpen = true end
    local y, nh, nr = 0, 0, 0
    for _, z in ipairs(zones) do
        nh = nh + 1
        local h = Head(nh)
        h.area = z.area
        h:ClearAllPoints()
        h:SetPoint("TOPLEFT", zv.content, "TOPLEFT", 0, -y)
        h:Show()
        h.name:SetText(z.name)
        h.range:SetText((z.lo and z.hi) and (z.lo == z.hi and tostring(z.lo) or (z.lo .. "-" .. z.hi)) or "")
        local zxp = (z.xp or 0) > 0 and ("  |cff5b606b·|r  |cffb48ef9" .. ns.FormatNumber(z.xp) .. " " .. L["XP"] .. "|r") or ""
        h.count:SetText(string.format(L["%d to pick up"], #z.quests) .. zxp .. (zv.open[z.area] and "" or "  +"))
        y = y + Z_HEAD_H
        if zv.open[z.area] then
            for _, e in ipairs(z.quests) do
                nr = nr + 1
                local r = Row(nr)
                r.questID, r.e = e.questID, e
                local cr, cg, cb = LevelRGB(e.level)
                r.lvl:SetText(e.level)
                r.lvl:SetTextColor(cr, cg, cb)
                r.lvlBg.flatBg:SetColorTexture(cr, cg, cb, 0.16)
                r.name:SetText(e.name)
                local pills = {}
                if e.xp and e.xp > 0 then pills[#pills + 1] = "|cffb48ef9" .. ns.FormatNumber(e.xp) .. " " .. L["XP"] .. "|r" end
                if e.chain and e.chain > 1 then pills[#pills + 1] = string.format(L["Chain · %d quests"], e.chain) end
                if e.elite then pills[#pills + 1] = "|cffff9c40" .. L["Elite"] .. "|r" end
                local tre = ns.TreasureFor and ns.TreasureFor(e.questID)
                if tre then pills[#pills + 1] = "|cffffd14d" .. ns.TreasureLabel(tre) .. "|r" end
                r.pills:SetText(table.concat(pills, "   "))
                r.where.text:SetText(e.giver .. "  |cff5b606b·|r  |cff7fe3d8" .. z.name
                    .. string.format(" (%d, %d)", math.floor(e.x + 0.5), math.floor(e.y + 0.5)) .. "|r")
                r.where:SetWidth(math.min(300, (tonumber(r.where.text:GetStringWidth()) or 200) + 4))
                local btnW = e.elite and 98 or 0
                local room = ROW_W - 12 - 48 - btnW - 64 - 20 - ((tonumber(r.pills:GetStringWidth()) or 0) + 8)
                r.name:SetWidth(math.max(60, math.min((tonumber(r.name:GetStringWidth()) or room) + 2, room)))
                if e.elite then
                    local on = ns.IsSearching and ns.IsSearching(e.questID)
                    r.btn:SetText(on and L["Stop"] or L["Find group"])
                    r.btn:SetKind(on and "outline" or "primary")
                    r.btn:Show()
                else
                    r.btn:Hide()
                end
                local h2 = Z_ROW_H - GAP
                r.info:SetKind(zv.open["q" .. e.questID] and "outline" or "soft")
                if zv.open["q" .. e.questID] then
                    local steps = ns.QuestGuide(e.questID)
                    local lines = {}
                    if steps then
                        lines[#lines + 1] = "|cff4fd1c5" .. L["How to do it"] .. "|r"
                        for k, st in ipairs(steps) do lines[#lines + 1] = "   " .. k .. ". " .. st end
                    else
                        lines[#lines + 1] = "|cff5b606b" .. L["No guide for this quest yet."] .. "|r"
                    end
                    r.details:SetText(table.concat(lines, "\n"))
                    r.details:Show()
                    h2 = h2 + (tonumber(r.details:GetStringHeight()) or 40) + 8
                else
                    r.details:Hide()
                end
                r:SetHeight(h2)
                r:ClearAllPoints()
                r:SetPoint("TOPLEFT", zv.content, "TOPLEFT", 12, -y)
                r:Show()
                y = y + h2 + GAP
            end
            y = y + 4
        end
    end
    for i = nh + 1, #zv.heads do zv.heads[i]:Hide() end
    for i = nr + 1, #zv.rows do zv.rows[i]:Hide() end
    zv.content:SetHeight(math.max(1, y))
    return total
end
end


---------------------------------------------------------------------------
-- Treasures: bag quests and the Cozy Sleeping Bag, as a checklist
---------------------------------------------------------------------------
do
-- steps: quest ids in order; a step can be { horde id, alliance id } (whichever is yours).
-- Sources: WoW Forever bag guides (leprestore, method.gg, Icy Veins) and the Cozy Sleeping Bag guides;
-- quest ids and order from the bundled QuestieDB data.
ns.TREASURES_DEFAULT = {
    { steps = { 91775 }, reward = "Book Bag", item = 279936, slots = 6, races = { "Human" } },
    { steps = { 97277 }, reward = "Canvas Latchbag", item = 277977, slots = 6, races = { "Dwarf", "Gnome" } },
    { steps = { 87288 }, reward = "Soft Saber Sack", item = 280088, slots = 6, races = { "NightElf" } },
    { steps = { 86784 }, reward = "Collecting Basket", item = 279939, slots = 6, races = { "Scourge", "Undead" } },
    { steps = { 791 }, reward = "Handmade Leather Bag", item = 11845, slots = 6, races = { "Orc", "Troll" } },
    { steps = { 95805 }, reward = "Scorched Leather Pouch", item = 277200, slots = 6, races = { "Tauren" } },
    { steps = { 92515 }, reward = "Simple Leather Satchel", item = 256935, slots = 6, races = { "Skyborne" } },
    { steps = { 97253 }, reward = "Scuffed Shipping Crate", item = 277332, slots = 8 },
    { steps = { 151 }, reward = "Old Blanchy's Feed Pouch", item = 1537, slots = 8 },
    { steps = { 1003 }, reward = "Wizbang's Gunnysack", item = 2082, slots = 8 },
    { steps = { 271, 531 }, reward = "Hunting Satchel", item = 270017, slots = 10, choice = true },
    { steps = { 1486 }, reward = "Deviate Hide Pack", item = 918, slots = 10, choice = true },
    { steps = { { 79007, 79008 }, 79192 }, reward = "Old Toolbox or Sturdy Lunchbox", item = 221498, slots = 12, choice = true },
    { steps = { 96260 }, reward = "Spidersilk Pouch", item = 276891, slots = 12, choice = true },
    { steps = { 56, 57, 58 }, item = 1729, slots = 10 },
    { steps = { 470 }, item = 3352, slots = 10 },
    { steps = { { 2440, 2439 } }, item = 9587, slots = 14 },
    { steps = { { 79007, 79008 }, 79192, 79980, 79974, 79975, 79976 }, reward = "Cozy Sleeping Bag", item = 211527,
      note = "+3% XP while you rest" },
}
-- races = the starter bags: each race's own (another race could walk there, but it isn't worth it)
ns.TREASURES = ns.TREASURES or ns.TREASURES_DEFAULT

-- texture coordinates of the tank / healer / damage icons in UI-LFG-ICON-PORTRAITROLES
local ROLE_COORDS = { T = { 0, 19 / 64, 22 / 64, 41 / 64 }, H = { 20 / 64, 39 / 64, 1 / 64, 20 / 64 }, D = { 20 / 64, 39 / 64, 22 / 64, 41 / 64 } }
function ns.RoleIconCoords(r) return ROLE_COORDS[r] or ROLE_COORDS.D end

function ns.TreasureIcon(t)
    if not t.item then return end
    local getIcon = C_Item and C_Item.GetItemIconByID or GetItemIcon
    local icon = getIcon and getIcon(t.item)
    if icon and icon ~= 0 then return icon end
    local instant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
    if instant then
        local _, _, _, _, texture = instant(t.item)
        if texture and texture ~= 0 then return texture end
    end
end

function ns.TreasureLabel(t)
    if t.reward then return L[t.reward] end
    return string.format(L["%d-slot bag"], t.slots or 0)
end

-- which treasure a quest belongs to (the Zones tab shows it as a gold pill)
local indexFor, index
function ns.TreasureFor(qid)
    if indexFor ~= ns.TREASURES then
        indexFor, index = ns.TREASURES, {}
        for _, t in ipairs(ns.TREASURES) do
            for _, s in ipairs(t.steps) do
                if type(s) == "table" then for _, id in ipairs(s) do index[id] = index[id] or t end
                else index[s] = index[s] or t end
            end
        end
    end
    return index[qid]
end

local ORDER = { available = 1, inlog = 2, locked = 3, done = 4 }

-- every treasure for your character, with where you stand in it
function ns.TreasureList()
    local list, done = {}, 0
    local _, myRace = UnitRace("player")
    for _, t in ipairs(ns.TREASURES) do
        local steps, hidden = {}, false
        if t.races and myRace then
            hidden = true
            for _, r in ipairs(t.races) do if r == myRace then hidden = false end end
        end
        for _, s in ipairs(hidden and {} or t.steps) do
            if type(s) == "table" then
                local pick
                for _, id in ipairs(s) do
                    if ns.QuestState(id) ~= "hidden" then pick = id; break end
                end
                if not pick then hidden = true; break end
                steps[#steps + 1] = pick
            else
                steps[#steps + 1] = s
            end
        end
        if not hidden and steps[1] and ns.QuestState(steps[1]) == "hidden" then hidden = true end
        if not hidden then
            local e = { treasure = t, reward = ns.TreasureLabel(t), slots = t.slots, choice = t.choice, note = t.note,
                        icon = ns.TreasureIcon(t), steps = #steps }
            if ns.QuestState(steps[#steps]) == "done" then
                e.status, e.step, e.stepIndex = "done", steps[#steps], #steps
                done = done + 1
            else
                for i, id in ipairs(steps) do
                    local st, lvl = ns.QuestState(id)
                    if st ~= "done" then
                        e.step, e.stepIndex = id, i
                        e.status = (st == "available" or st == "inlog") and st or "locked"
                        e.level = lvl
                        if st == "hidden" then e = nil end
                        break
                    end
                end
            end
            if e and e.step then
                local p = ns.ZoneQuest(e.step)
                e.questName = p and p.name or nil
                local g = ns.QuestGiver(e.step)
                if g then e.giver, e.area, e.x, e.y = g.name, g.area, g.x, g.y end
                list[#list + 1] = e
            end
        end
    end
    table.sort(list, function(a, b)
        local oa, ob = ORDER[a.status] or 9, ORDER[b.status] or 9
        if oa ~= ob then return oa < ob end
        if (a.level or 0) ~= (b.level or 0) then return (a.level or 0) < (b.level or 0) end
        return (a.slots or 99) > (b.slots or 99)
    end)
    return list, done, #list
end

---------------------------------------------------------------------------
-- the tab
---------------------------------------------------------------------------
local tv = { rows = {} }
local ROW_H, GAP = 62, 6

function ns.BuildTreasuresView(p, inset)
    local UI = ns.UI
    local C = UI.C
    local v = CreateFrame("Frame", nil, inset)
    v:SetAllPoints(inset)
    p.treasuresView = v
    tv.title = UI.Text(v, 9, "muted", nil, "bold")
    tv.title:SetPoint("TOPLEFT", v, "TOPLEFT", 8, -10)
    tv.title:SetText(ns.UI.Caps(L["Treasures"]))
    tv.count = UI.Text(v, 10, "accent", nil, "medium")
    tv.count:SetPoint("TOPRIGHT", v, "TOPRIGHT", -12, -9)
    tv.barBg = v:CreateTexture(nil, "ARTWORK")
    tv.barBg:SetHeight(4)
    tv.barBg:SetPoint("TOPLEFT", v, "TOPLEFT", 8, -28)
    tv.barBg:SetPoint("TOPRIGHT", v, "TOPRIGHT", -12, -28)
    tv.barBg:SetColorTexture(C.panel2[1], C.panel2[2], C.panel2[3], 1)
    tv.bar = v:CreateTexture(nil, "OVERLAY")
    tv.bar:SetHeight(4)
    tv.bar:SetPoint("TOPLEFT", tv.barBg, "TOPLEFT")
    tv.bar:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
    local scroll = CreateFrame("ScrollFrame", nil, v, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", v, "TOPLEFT", 6, -40)
    scroll:SetPoint("BOTTOMRIGHT", v, "BOTTOMRIGHT", -28, 6)
    UI.SkinScroll(scroll)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(ROW_W, 1)
    scroll:SetScrollChild(child)
    tv.content = child
end

local function Row(i)
    local r = tv.rows[i]
    if r then return r end
    local UI = ns.UI
    r = UI.Card(tv.content, ROW_W, ROW_H - GAP)
    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetSize(36, 36)
    r.icon:SetPoint("LEFT", 10, 0)
    r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    r.slotsBg = r:CreateTexture(nil, "OVERLAY", nil, 1)
    r.slotsBg:SetSize(18, 13)
    r.slotsBg:SetPoint("BOTTOMRIGHT", r.icon, "BOTTOMRIGHT", 2, -2)
    r.slotsBg:SetColorTexture(0.043, 0.05, 0.063, 0.9)
    r.slots = UI.Text(r, 9, "text", "OVERLAY", "bold")
    r.slots:SetPoint("CENTER", r.slotsBg, "CENTER", 0, 0)
    r.check = r:CreateTexture(nil, "OVERLAY", nil, 2)
    r.check:SetSize(22, 22)
    r.check:SetPoint("CENTER", r.icon, "CENTER", 0, 0)
    r.check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    r.check:Hide()
    r.btn = UI.Button(r, 96, 22, "soft")
    r.btn:SetPoint("RIGHT", -10, 0)
    r.btn:SetMotionScriptsWhileDisabled(true)
    r.btn:SetScript("OnClick", function()
        local e = r.e
        if e and e.area then ns.Waypoint(e.area, e.x, e.y, (e.giver or "") .. " - " .. (e.questName or "")) end
    end)
    r.name = UI.Text(r, 12, "gold", nil, "medium")
    r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 12, 1)
    r.name:SetPoint("RIGHT", r.btn, "LEFT", -10, 0)
    r.name:SetJustifyH("LEFT")
    r.name:SetWordWrap(false)
    r.sub = UI.Text(r, 10, "muted")
    r.sub:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -2)
    r.sub:SetPoint("RIGHT", r.btn, "LEFT", -10, 0)
    r.sub:SetJustifyH("LEFT")
    r.sub:SetWordWrap(false)
    r.where = UI.Text(r, 10, "dim")
    r.where:SetPoint("TOPLEFT", r.sub, "BOTTOMLEFT", 0, -2)
    r.where:SetPoint("RIGHT", r.btn, "LEFT", -10, 0)
    r.where:SetJustifyH("LEFT")
    r.where:SetWordWrap(false)
    tv.rows[i] = r
    return r
end

-- the tab's badge (treasures you can go get now) without building the rows
function ns.TreasureCount()
    local n = 0
    for _, e in ipairs((ns.TreasureList())) do
        if e.status == "available" then n = n + 1 end
    end
    return n
end

function ns.RefreshTreasures()
    if not tv.content then return 0 end
    local list, done, total = ns.TreasureList()
    tv.count:SetText(string.format(L["%d / %d collected"], done, total))
    local w = (tonumber(tv.barBg:GetWidth()) or ROW_W)
    tv.bar:SetWidth(math.max(1, w * (total > 0 and done / total or 0)))
    local y, avail = 0, 0
    for i, e in ipairs(list) do
        local r = Row(i)
        r.e = e
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", tv.content, "TOPLEFT", 0, -y)
        r:Show()
        r.icon:SetTexture(e.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        local itemID = e.treasure.item
        if not e.icon and itemID and r.requestedItem ~= itemID and Item and Item.CreateFromItemID then
            r.requestedItem = itemID
            Item:CreateFromItemID(itemID):ContinueOnItemLoad(function()
                if r.e and r.e.treasure.item == itemID then
                    local icon = ns.TreasureIcon(r.e.treasure)
                    if icon then r.icon:SetTexture(icon) end
                end
            end)
        end
        r.slots:SetText(e.slots and tostring(e.slots) or "")
        r.slotsBg:SetShown(e.slots ~= nil)
        r.name:SetText(e.reward)
        local sub = {}
        if e.slots then sub[#sub + 1] = string.format(L["%d-slot bag"], e.slots) end
        if e.choice then sub[#sub + 1] = L["choice of reward"] end
        if e.note then sub[#sub + 1] = L[e.note] end
        r.sub:SetText(table.concat(sub, "  |cff5b606b·|r  "))
        local stepText = e.questName or ("#" .. tostring(e.step))
        if e.steps > 1 then stepText = string.format(L["Step %d of %d: %s"], e.stepIndex, e.steps, stepText) end
        local where = e.giver and ("  |cff5b606b·|r  " .. e.giver) or ""
        r.where:SetText("|cffe8e6e3" .. stepText .. "|r" .. where)
        local done = e.status == "done"
        r:SetAlpha(done and 0.55 or 1)
        r.icon:SetDesaturated(done)
        r.check:SetShown(done)
        if e.status == "available" then
            avail = avail + 1
            r.btn:SetText(L["Waypoint"]); r.btn:SetKind("primary"); r.btn:Enable()
        elseif e.status == "inlog" then
            r.btn:SetText(L["In your log"]); r.btn:SetKind("outline"); r.btn:Enable()
        elseif e.status == "locked" then
            r.btn:SetText(e.level and string.format(L["Level %d"], e.level) or L["Not yet"]); r.btn:SetKind("ghost"); r.btn:Disable()
        else
            r.btn:SetText(L["Collected"]); r.btn:SetKind("ghost"); r.btn:Disable()
        end
        y = y + ROW_H
    end
    for i = #list + 1, #tv.rows do tv.rows[i]:Hide() end
    tv.content:SetHeight(math.max(1, y))
    return avail
end
end

---------------------------------------------------------------------------
-- refresh + window
---------------------------------------------------------------------------
local function RefreshQuests()
    local y = ns.RefreshRouteView(panel)
    local list = BuildEntries()
    local stripe = false
    for i, e in ipairs(list) do
        local r = GetPanelRow(i)
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
        r:Show()
        if e.header then
            LayoutHeader(r, e)
            stripe = false
            y = y + HEADER_H
        else
            stripe = not stripe
            y = y + (LayoutQuest(r, e, stripe) or QUEST_H)
        end
    end
    for i = #list + 1, #panelRows do panelRows[i]:Hide() end
    content:SetHeight(math.max(y, 1))
    if #list == 0 then emptyText:Show() else emptyText:Hide() end
end

-- Tab contents are only built for the tab you're looking at. Every other tab is marked dirty and
-- rebuilt when it's selected. Badges, rewards, the XP bar and the footer are cheap and always updated.
-- (one table, not separate locals: the main chunk is close to Lua 5.1's 200-local limit)
-- tick = tabs that show times or expiring entries, rebuilt by the once-a-second tick while visible
local Tabs = { n = 8, dirty = {}, counts = {}, tick = { [1] = true, [2] = true, [3] = true, [7] = true } }
for i = 1, Tabs.n do Tabs.dirty[i] = true end

function Tabs.Render(tab)
    Tabs.dirty[tab] = false
    if tab == 1 then RefreshQuests()
    elseif tab == 2 then Tabs.counts[2] = RefreshNearby()
    elseif tab == 3 then Tabs.counts[3] = RefreshGroups()
    elseif tab == 4 then Tabs.counts[4] = ns.RefreshDungeons()
    elseif tab == 5 then ns.RefreshZones()
    elseif tab == 6 then Tabs.counts[6] = ns.RefreshTreasures()
    elseif tab == 7 then RefreshStats()
    elseif tab == 8 then ns.RefreshRewardHunting() end
end

-- tick = true: the panel's 1-second timer (nothing changed but time); otherwise data may have changed
local function RefreshPanel(tick)
    if tick ~= true then
        for i = 1, Tabs.n do Tabs.dirty[i] = true end
    end
    if not panel or not panel:IsShown() then return end
    local tab = panel.selectedTab or 1
    ns.PaintHostButton(panel.host)
    panel.questView:SetShown(tab == 1)
    panel.nearbyView:SetShown(tab == 2)
    panel.groupsView:SetShown(tab == 3)
    if panel.dungeonsView then panel.dungeonsView:SetShown(tab == 4) end
    if panel.zonesView then panel.zonesView:SetShown(tab == 5) end
    if panel.treasuresView then panel.treasuresView:SetShown(tab == 6) end
    panel.statsView:SetShown(tab == 7)
    panel.rewardView:SetShown(tab == 8)
    if panel.statsBtn then panel.statsBtn:SetActive(tab == 7) end

    if tick == true and Tabs.tick[tab] then Tabs.dirty[tab] = true end
    local rendered = Tabs.dirty[tab] and tab or nil
    if rendered then Tabs.Render(tab) end

    -- badge counts without building the hidden tabs
    if rendered ~= 2 then Tabs.counts[2] = #ns.NearbyEntries() end
    if rendered ~= 3 then Tabs.counts[3] = #ns.GroupEntries() end
    if rendered ~= 4 then Tabs.counts[4] = ns.DungeonActivity() end
    if rendered ~= 6 and (tick ~= true or Tabs.counts[6] == nil) then Tabs.counts[6] = ns.TreasureCount() end
    if panel.Tabs then
        for _, tab in ipairs(panel.Tabs) do
            local n = Tabs.counts[tab:GetID()]
            if tab.hasBadge then tab:SetLabel(tab.baseName, (n or 0) > 0 and tostring(n) or nil) end
        end
        panel:LayoutTabs()
    end

    local parts = ns.RewardParts()
    for i, c in ipairs(panel.chips or {}) do
        if parts[i] then
            c.text:SetText(parts[i])
            c:SetWidth((tonumber(c.text:GetStringWidth()) or 40) + 18)
            c:Show()
        else c:Hide() end
    end
    ns.UpdateXPBar(panel.xpBar)

    local active, found = 0, 0
    for _, s in pairs(seeking) do
        active = active + 1
        found = found + CountPeers(s)
    end
    local online = ns.OnlineCount and ns.OnlineCount() or 0
    local status = active == 0 and L["Not searching"]
        or string.format(active == 1 and L["%d search"] or L["%d searches"], active)
    if found > 0 then status = status .. "  |cff5b606b·|r  |cff4fd1c5" .. string.format(L["Players found: %d"], found) .. "|r" end
    if online > 0 then status = status .. "  |cff5b606b·|r  " .. string.format(L["%d users online"], online) end
    footer:SetText(status)
    if active == 0 then stopAll:Disable() else stopAll:Enable() end
end

local function MakeScroll(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, -6)
    scroll:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -28, 6)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(ROW_W, 1)
    scroll:SetScrollChild(child)
    ns.UI.SkinScroll(scroll)
    return scroll, child
end

local function CreatePanel()
    local UI, C = ns.UI, ns.UI.C
    local p = CreateFrame("Frame", "QuestynatorPanel", UIParent)
    p:SetSize(560, 580)
    UI.Flat(p, C.bg, C.line)
    -- highest window layer (only tooltips draw above it)
    p:SetFrameStrata("FULLSCREEN_DIALOG")
    p:SetToplevel(true)
    p:SetClampedToScreen(true)
    p:SetMovable(true)
    p:EnableMouse(true)
    p:RegisterForDrag("LeftButton")
    p:SetScript("OnDragStart", p.StartMoving)
    p:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        DB.panelPos = { point, relPoint, x, y }
    end)
    local pos = DB.panelPos
    if pos then p:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) else p:SetPoint("CENTER") end
    if UISpecialFrames then tinsert(UISpecialFrames, "QuestynatorPanel") end   -- Esc closes it

    -- header: logo, name, version (from the .toc so it stays in sync), close
    local name = UI.Text(p, 15, "text", nil, "bold")
    name:SetPoint("TOPLEFT", p, "TOPLEFT", 16, -16)
    name:SetText("QUESTYNATOR")
    local ver = UI.Text(p, 11, "dim")
    ver:SetPoint("BOTTOMLEFT", name, "BOTTOMRIGHT", 6, 1)
    ver:SetText("v" .. ns.Version())
    p.titleText = name

    local close = CreateFrame("Button", nil, p)
    close:SetSize(24, 24)
    close:SetPoint("TOPRIGHT", -8, -10)
    close.x = UI.Text(close, 16, "muted")
    close.x:SetPoint("CENTER", 0, 0)
    close.x:SetText("x")
    close:SetScript("OnEnter", function(self) self.x:SetTextColor(C.red[1], C.red[2], C.red[3]) end)
    close:SetScript("OnLeave", function(self) self.x:SetTextColor(C.muted[1], C.muted[2], C.muted[3]) end)
    close:SetScript("OnClick", function() p:Hide() end)
    p.CloseButton = close

    -- Stats, About and quick settings live behind a small chart icon (the tab row is full)
    local sb = CreateFrame("Button", nil, p)
    sb:SetSize(24, 24)
    sb:SetPoint("RIGHT", close, "LEFT", -4, 0)
    sb.bars = {}
    for i, h in ipairs({ 6, 11, 8 }) do
        local t = sb:CreateTexture(nil, "ARTWORK")
        t:SetSize(3, h)
        t:SetPoint("BOTTOMLEFT", sb, "BOTTOMLEFT", 6 + (i - 1) * 5, 6)
        sb.bars[i] = t
    end
    function sb:SetActive(on)
        self.active = on and true or false
        local c = on and C.accent or (self.hover and C.text or C.muted)
        for _, t in ipairs(self.bars) do t:SetColorTexture(c[1], c[2], c[3], 1) end
    end
    sb:SetScript("OnEnter", function(self)
        self.hover = true; self:SetActive(self.active)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine(L["Stats"], 1, 1, 1)
        GameTooltip:AddLine(L["Stats, top helpers, about and settings"], 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    sb:SetScript("OnLeave", function(self) self.hover = false; self:SetActive(self.active); GameTooltip:Hide() end)
    sb:SetScript("OnClick", function() ns.SelectTab(7) end)
    sb:SetActive(false)
    p.statsBtn = sb
    p.host = ns.MakeHostButton(p)
    p.host:SetPoint("RIGHT", sb, "LEFT", -10, 0)

    -- rewards line (hover for the full breakdown) + thin XP bar
    -- reward chips: XP, money, rep
    p.chips = {}
    for i = 1, 3 do
        local c = CreateFrame("Frame", nil, p)
        c:SetHeight(20)
        UI.Flat(c, { 0.13, 0.145, 0.18, 1 }, false)
        c.text = UI.Text(c, 10, "text", nil, "medium")
        c.text:SetPoint("CENTER", 0, 0)
        if i == 1 then c:SetPoint("TOPLEFT", p, "TOPLEFT", 14, -42)
        else c:SetPoint("LEFT", p.chips[i - 1], "RIGHT", 6, 0) end
        p.chips[i] = c
    end
    local sub = p.chips[1]
    p.sub = { SetText = function() end }
    local subHover = CreateFrame("Frame", nil, p)
    subHover:SetPoint("TOPLEFT", p.chips[1], "TOPLEFT", 0, 0)
    subHover:SetPoint("BOTTOMRIGHT", p.chips[3], "BOTTOMRIGHT", 0, 0)
    subHover:SetFrameLevel((tonumber(p:GetFrameLevel()) or 1) + 5)
    subHover:EnableMouse(true)
    subHover:SetScript("OnEnter", function(self) ns.ShowRewardsTooltip(self) end)
    subHover:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- XP bar: teal = now, light teal = what your quests add
    local bar = CreateFrame("Frame", nil, p)
    bar:SetSize(150, 8)
    bar:SetPoint("RIGHT", p, "TOPRIGHT", -16, -54)
    bar:EnableMouse(true)
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    bar.bg:SetColorTexture(C.dark[1], C.dark[2], C.dark[3], 1)
    bar.fill = bar:CreateTexture(nil, "BORDER")
    bar.fill:SetPoint("TOPLEFT"); bar.fill:SetPoint("BOTTOMLEFT")
    bar.fill:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
    bar.quest = bar:CreateTexture(nil, "BORDER", nil, 1)
    bar.quest:SetPoint("TOPLEFT", bar.fill, "TOPRIGHT"); bar.quest:SetPoint("BOTTOMLEFT", bar.fill, "BOTTOMRIGHT")
    bar.quest:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.35)
    bar.border = bar:CreateTexture(nil, "OVERLAY")
    bar.border:SetPoint("TOPLEFT", -1, 1); bar.border:SetPoint("BOTTOMRIGHT", 1, -1)
    bar.border:SetColorTexture(C.line[1], C.line[2], C.line[3], 1)
    bar.border:SetDrawLayer("BACKGROUND", -1)
    bar.text = UI.Text(bar, 10, "accent", nil, "medium")
    bar.text:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", 0, 3)
    bar:SetScript("OnEnter", function(self) ns.ShowXPTooltip(self) end)
    bar:SetScript("OnLeave", function() GameTooltip:Hide() end)
    bar:SetScript("OnSizeChanged", function(self) ns.UpdateXPBar(self) end)
    p.xpBar = bar

    -- top tabs with a teal underline and count badges
    p.Tabs = {}
    local tabDefs = {
        { id = 1, name = "Quests" }, { id = 5, name = "Zones" },
        { id = 2, name = "Nearby", groupStart = true, badge = true },
        { id = 3, name = "Groups", badge = true }, { id = 4, name = "Dungeons", badge = true },
        { id = 6, name = "Treasures", groupStart = true, badge = true }, { id = 8, name = "Reward Hunting" },
    }
    for i, def in ipairs(tabDefs) do
        local tab = UI.Tab(p, L[def.name])
        tab:SetID(def.id)
        tab.baseName, tab.hasBadge, tab.groupStart = L[def.name], def.badge, def.groupStart
        tab:SetScript("OnClick", function(self) ns.SelectTab(self:GetID()) end)
        p.Tabs[i] = tab
    end
    local rule = p:CreateTexture(nil, "ARTWORK")
    rule:SetHeight(1)
    rule:SetColorTexture(C.line[1], C.line[2], C.line[3], 1)
    p.selectedTab = 1

    -- content area
    local inset = CreateFrame("Frame", nil, p)
    inset:SetPoint("TOPLEFT", rule, "BOTTOMLEFT", -8, -3)
    inset:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -6, 36)
    p.Inset = inset
    function p:LayoutTabs()
        local x, y = 16, -68
        for i, tab in ipairs(self.Tabs) do
            local width = tab:GetWidth()
            if tab.groupStart then
                local groupWidth = width
                for j = i + 1, #self.Tabs do
                    if self.Tabs[j].groupStart then break end
                    groupWidth = groupWidth + 6 + self.Tabs[j]:GetWidth()
                end
                x = x + 10
                if x + groupWidth > self:GetWidth() - 14 then x, y = 16, y - 28 end
            end
            if x + width > self:GetWidth() - 14 then x, y = 16, y - 28 end
            tab:SetPoint("TOPLEFT", self, "TOPLEFT", x, y)
            x = x + width + 6
        end
        rule:SetPoint("TOPLEFT", self, "TOPLEFT", 14, y - 28)
        rule:SetPoint("TOPRIGHT", self, "TOPRIGHT", -14, y - 28)
    end
    p:LayoutTabs()

    -- Quests tab
    p.questView = CreateFrame("Frame", nil, inset)
    p.questView:SetAllPoints(inset)
    p.search = UI.SearchBox(p.questView, 200, L["Search quests"], function(text)
        ns.SetQuestFilter(text)
        RefreshPanel()
    end)
    p.search:SetPoint("TOPLEFT", p.questView, "TOPLEFT", 10, -6)
    p.search:SetPoint("TOPRIGHT", p.questView, "TOPRIGHT", -10, -6)
    ns.BuildRouteView(p)
    p.questBody = CreateFrame("Frame", nil, p.questView)
    p.questBody:SetPoint("TOPLEFT", p.routeView, "BOTTOMLEFT")
    p.questBody:SetPoint("BOTTOMRIGHT", p.questView, "BOTTOMRIGHT", 0, 0)
    local scroll
    scroll, content = MakeScroll(p.questBody)
    p.questScroll = scroll
    emptyText = ns.UI.Text(p.questView, 13, "dim")
    emptyText:SetPoint("CENTER", scroll, "CENTER")
    emptyText:SetText(L["Your quest log is empty."])
    emptyText:Hide()

    -- Nearby tab
    local toQuests = function() ns.SelectTab(1) end
    p.nearbyView = CreateFrame("Frame", nil, inset)
    p.nearbyView:SetAllPoints(inset)
    local nscroll
    nscroll, nearbyContent = MakeScroll(p.nearbyView)
    nearbyEmpty = UI.Empty(p.nearbyView, toQuests)
    nearbyEmpty:SetPoint("CENTER", p.nearbyView, "CENTER", 0, 10)
    nearbyEmpty:Set(L["No one nearby yet"], L["Questynator pings you when players near you are on your quests."], L["Find group for a quest"])

    -- Groups tab
    p.groupsView = CreateFrame("Frame", nil, inset)
    p.groupsView:SetAllPoints(inset)
    local gscroll
    gscroll, groupsContent = MakeScroll(p.groupsView)
    groupsEmpty = UI.Empty(p.groupsView, toQuests)
    groupsEmpty:SetPoint("CENTER", p.groupsView, "CENTER", 0, 10)
    groupsEmpty:Set(L["No open groups right now"], L["Groups created with Questynator show up here."], L["Find group for a quest"])

    -- Dungeons + Stats tabs
    ns.BuildDungeonsView(p, inset)
    ns.BuildZonesView(p, inset)
    ns.BuildTreasuresView(p, inset)
    ns.BuildRewardHunting(p, inset)
    ns.BuildStatsView(p, inset)

    -- footer: status + Stop all
    local foot = p:CreateTexture(nil, "ARTWORK")
    foot:SetHeight(1)
    foot:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 1, 34)
    foot:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -1, 34)
    foot:SetColorTexture(C.line[1], C.line[2], C.line[3], 1)
    footer = UI.Text(p, 10, "dim")
    footer:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 16, 12)
    stopAll = UI.Button(p, 84, 22, "ghost")
    stopAll:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -10, 6)
    stopAll:SetText(L["Stop all"])
    stopAll:SetScript("OnClick", function()
        for questID in pairs(seeking) do ns.Stop(questID, "search cancelled") end
    end)

    -- tick once a second: while searching (timers, the prompt) or on the Groups tab, refresh the
    -- visible tab and the cheap shared parts; dungeon listings that time out drop off even when idle
    local acc = 0
    p:SetScript("OnUpdate", function(_, elapsed)
        acc = acc + elapsed
        if acc >= 1 then
            acc = 0
            local expired = ns.PruneDungeons and ns.PruneDungeons()
            if expired then Tabs.dirty[4] = true end
            if next(seeking) or (p.selectedTab == 3) or expired then RefreshPanel(true) end
        end
    end)
    p:SetScript("OnShow", function() RefreshPanel() end)
    p:Hide()
    return p
end

function ns.SelectTab(i)
    if not panel then return end
    panel.selectedTab = i
    for _, tab in ipairs(panel.Tabs or {}) do tab:SetActive(tab:GetID() == i) end
    if panel.statsBtn then panel.statsBtn:SetActive(i == 7) end
    Tabs.dirty[i] = true                         -- hidden tabs may be stale: build it now it's shown
    RefreshPanel(true)
end

function ns.TabState()
    local st = { selected = panel and panel.selectedTab or 1, active = {} }
    for _, tab in ipairs(panel and panel.Tabs or {}) do st.active[tab:GetID()] = tab.active end
    if panel and panel.statsBtn then st.active[7] = panel.statsBtn.active end
    return st
end

function ns.ShowPanel()
    if not panel then panel = CreatePanel() end
    panel:Show()
    panel:Raise()
    RefreshPanel()
end

function ns.TogglePanel()
    if not panel then panel = CreatePanel() end
    if panel:IsShown() then panel:Hide() else panel:Show() end
end

---------------------------------------------------------------------------
-- Create Group: host a group for a quest with chosen objectives + level range
---------------------------------------------------------------------------
local dialog

-- General's channel number (usually 1, but don't assume)
local GENERAL_NAMES = { "general", "allgemein", "général", "общий", "generale", "geral" }
function ns.GeneralChannel()
    local list = GetChannelList and { GetChannelList() } or {}
    for i = 1, #list do
        local id, name = list[i], list[i + 1]
        if type(id) == "number" and type(name) == "string" then
            local lower = name:lower()
            for _, g in ipairs(GENERAL_NAMES) do
                if lower:find("^" .. g) then return id end
            end
        end
    end
    local id = GetChannelName(1)
    if id and id > 0 then return 1 end
end

local function ListingMessage(questID, LST)
    local link = (GetQuestLink and GetQuestLink(questID)) or ("[" .. QuestTitle(questID) .. "]")
    return "Questynator: LFG " .. link .. " - /w +"
end

function ns.PostListing(questID)
    local s = seeking[questID]
    local LST = s and s.listing
    if not LST then return end
    local msg = ListingMessage(questID, LST)
    if TestBlocked("would post to General: " .. msg) then return end
    -- must be sent from a click (Blizzard requires a hardware event)
    local id = ns.GeneralChannel()
    if id then
        ns.lastPost = { text = msg, plain = ns.PlainText(msg), t = GetTime() }
        SendChatMessage(msg, "CHANNEL", nil, id)
        Print(string.format(L["Posted to General chat (/%d)."], id))
    else
        Print(string.format(L["You're not in General chat. Your message: %s"], msg))
    end
end

function ns.CreateListing(questID, opts)
    local s = seeking[questID]
    if not s then return end
    s.listing = { min = opts.min, max = opts.max, want = opts.want, texts = opts.texts, autoInvite = opts.autoInvite }
    Print(string.format(L["Group created for %s (levels %d-%d)."], QuestTitle(questID), opts.min, opts.max))
    Beacon(questID, true)
    if opts.post then ns.PostListing(questID) end
    ns.RequestRefresh()
end

-- Stop hosting. A search that Host LFG started ends with its listing; a search the
-- player started earlier keeps looking for a group.
function ns.WithdrawListing(questID)
    local s = seeking[questID]
    if not s or not s.listing then return end
    if s.quickHost then ns.Stop(questID, "Hosting stopped"); return end
    s.listing = nil
    Beacon(questID, true)
    Print(QuestTitle(questID) .. ": " .. L["Hosting stopped"])
    ns.RequestRefresh()
end

local function OnCreateClicked()
    local d = dialog
    local questID = d.questID
    if not questID or not seeking[questID] then d:Hide() return end
    local objs = (C_QuestLog.GetQuestObjectives and C_QuestLog.GetQuestObjectives(questID)) or {}
    local want, texts = 0, {}
    for i = 1, MAX_OBJ do
        local o = objs[i]
        if o and not o.finished and d.objs[i]:GetChecked() then
            want = want + math.floor(2 ^ (i - 1))
            texts[#texts + 1] = o.text
        end
    end
    local me = UnitLevel("player")
    local lo = tonumber(d.min:GetText()) or (me - DB.levelRange)
    local hi = tonumber(d.max:GetText()) or (me + DB.levelRange)
    if lo > hi then lo, hi = hi, lo end
    ns.CreateListing(questID, {
        min = lo, max = hi, want = want, texts = texts,
        autoInvite = d.auto:GetChecked() and true or false,
        post = d.post:GetChecked() and true or false,
    })
    d:Hide()
end

local function Check(d, text, x, y)
    local cb = CreateFrame("CheckButton", nil, d, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb:SetPoint("TOPLEFT", d, "TOPLEFT", x, y)
    cb.label = d:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cb.label:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    cb.label:SetPoint("RIGHT", d, "RIGHT", -16, 0)
    cb.label:SetJustifyH("LEFT")
    cb.label:SetWordWrap(false)
    cb.label:SetText(text or "")
    return cb
end

local function LevelBox(d, x, y)
    local e = CreateFrame("EditBox", nil, d, "InputBoxTemplate")
    e:SetSize(36, 20)
    e:SetPoint("TOPLEFT", d, "TOPLEFT", x, y)
    e:SetAutoFocus(false)
    e:SetNumeric(true)
    e:SetMaxLetters(3)
    return e
end

local function CreateDialog()
    local d = ns.UI.Window("QuestynatorCreate", 360, 340)
    d:SetPoint("CENTER", 0, 60)
    d:SetFrameStrata("FULLSCREEN_DIALOG")   -- same top layer as the panel, raised above it on show
    d:SetToplevel(true)
    d:SetClampedToScreen(true)
    d:SetMovable(true)
    d:EnableMouse(true)
    d:RegisterForDrag("LeftButton")
    d:SetScript("OnDragStart", d.StartMoving)
    d:SetScript("OnDragStop", d.StopMovingOrSizing)
    if d.TitleText then d.TitleText:SetText(L["Create Group"]) end
    if UISpecialFrames then tinsert(UISpecialFrames, "QuestynatorCreate") end

    d.quest = d:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    d.quest:SetPoint("TOPLEFT", d, "TOPLEFT", 16, -34)
    d.quest:SetPoint("RIGHT", d, "RIGHT", -16, 0)
    d.quest:SetJustifyH("LEFT")
    d.quest:SetWordWrap(false)

    local hdr = d:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    hdr:SetPoint("TOPLEFT", d, "TOPLEFT", 16, -58)
    hdr:SetText(L["Objectives to do together:"])

    d.objs = {}
    for i = 1, MAX_OBJ do
        d.objs[i] = Check(d, "", 12, -76 - (i - 1) * 24)
    end

    local lv = d:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lv:SetPoint("TOPLEFT", d, "TOPLEFT", 16, -236)
    lv:SetText(L["Player levels:"])
    d.min = LevelBox(d, 110, -232)
    local to = d:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    to:SetPoint("TOPLEFT", d, "TOPLEFT", 156, -236)
    to:SetText(L["to"])
    d.max = LevelBox(d, 176, -232)

    d.auto = Check(d, L["Auto-invite players who whisper '+'"], 12, -258)
    d.post = Check(d, L["Post to General chat"], 12, -282)

    local ok = ns.UI.Button(d, 90, 22, "primary")
    ok:SetSize(110, 22)
    ok:SetPoint("BOTTOMRIGHT", d, "BOTTOMRIGHT", -12, 10)
    ok:SetText(L["Create Group"])
    ok:SetScript("OnClick", OnCreateClicked)
    local cancel = ns.UI.Button(d, 90, 22, "ghost")
    cancel:SetSize(80, 22)
    cancel:SetPoint("RIGHT", ok, "LEFT", -6, 0)
    cancel:SetText(L["Cancel"])
    cancel:SetScript("OnClick", function() d:Hide() end)

    d:Hide()
    return d
end

function ns.OpenCreateDialog(questID)
    if not dialog then dialog = CreateDialog() end
    local d = dialog
    d.questID = questID
    d.quest:SetText(QuestTitle(questID))
    local objs = (C_QuestLog.GetQuestObjectives and C_QuestLog.GetQuestObjectives(questID)) or {}
    for i = 1, MAX_OBJ do
        local cb, o = d.objs[i], objs[i]
        if o then
            cb:Show()
            cb.label:Show()
            cb.label:SetText(o.text or string.format(L["Objective %d"], i))
            cb:SetChecked(not o.finished)
            if o.finished then cb:Disable() else cb:Enable() end
        else
            cb:Hide()
            cb.label:Hide()
        end
    end
    local lvl = UnitLevel("player")
    d.min:SetText(tostring(math.max(1, lvl - DB.levelRange)))
    d.max:SetText(tostring(lvl + DB.levelRange))
    d.auto:SetChecked(true)
    local hasGeneral = ns.GeneralChannel() ~= nil
    d.post:SetChecked(hasGeneral)
    if hasGeneral then d.post:Enable() else d.post:Disable() end
    d.post.label:SetText(hasGeneral and L["Post to General chat"] or L["Post to General chat - you're not in it"])
    d:Show()
    d:Raise()
    local lvl = panel and panel:GetFrameLevel()
    if type(lvl) == "number" then d:SetFrameLevel(lvl + 20) end
end

-- Give these features their own Lua stack frame. The main addon chunk also builds the UI.
local function InitializeQuestAndPartyFeatures()
---------------------------------------------------------------------------
-- party quest progress, quest sharing and kudos (addon messages inside your party)
---------------------------------------------------------------------------
local partyData = {}       -- [name] = { gen, parts, quests = {[qid] = {have, need, done}}, ready }
local partyGen, partyPending, lastPartyPayload = 0, false, nil

local function GroupChannel()
    if IsInRaid and IsInRaid() then return "RAID" end
    if IsInGroup() then return "PARTY" end
end

local function SendGroup(msg)
    local chan = GroupChannel()
    if not chan then return false end
    local send = (C_ChatInfo and C_ChatInfo.SendAddonMessage) or SendAddonMessage
    send(PREFIX, msg, chan)
    return true
end

local function MyProgress()
    local list = {}
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and info.questID and not info.isHidden then
            local have, need = 0, 0
            for _, o in ipairs((C_QuestLog.GetQuestObjectives and C_QuestLog.GetQuestObjectives(info.questID)) or {}) do
                have = have + (tonumber(o.numFulfilled) or 0)
                need = need + (tonumber(o.numRequired) or 0)
            end
            local done = C_QuestLog.IsComplete and C_QuestLog.IsComplete(info.questID)
            local share = C_QuestLog.IsPushableQuest and C_QuestLog.IsPushableQuest(info.questID)
            list[#list + 1] = string.format("%d:%d:%d:%d%s", info.questID, have, need, done and 1 or 0, share and "s" or "")
        end
    end
    return list
end

function ns.SendPartyProgress()
    if not GroupChannel() then return end
    local entries = MyProgress()
    local payload = table.concat(entries, ",")
    if payload == lastPartyPayload then return end
    lastPartyPayload = payload
    partyGen = partyGen % 99 + 1
    local chunks, cur = {}, ""
    for _, e in ipairs(entries) do
        if cur ~= "" and #cur + #e + 1 > 200 then
            chunks[#chunks + 1] = cur
            cur = e
        else
            cur = (cur == "") and e or (cur .. "," .. e)
        end
    end
    chunks[#chunks + 1] = cur
    for i, c in ipairs(chunks) do SendGroup(string.format("P|%d|%d|%d|%s", partyGen, i, #chunks, c)) end
end

function ns.SchedulePartySync(force)
    if force then lastPartyPayload = nil end
    if partyPending then return end
    partyPending = true
    C_Timer.After(2, function()
        partyPending = false
        pcall(ns.SendPartyProgress)
    end)
end

local function PartyKey(sender) return (Ambiguate(sender, "none")) end

function ns.OnPartyRoster()
    pcall(ns.UpdateDungeonComposition)
    if not IsInGroup() then
        for k in pairs(partyData) do partyData[k] = nil end
        lastPartyPayload = nil
        return
    end
    local present = {}
    for i = 1, 4 do
        local u = "party" .. i
        if UnitExists(u) then
            present[UnitName(u) or ""] = true
            if GetUnitName then present[GetUnitName(u, true) or ""] = true end
        end
    end
    for name in pairs(partyData) do if not present[name] then partyData[name] = nil end end
    ns.SchedulePartySync(true)
end

function ns.OnGroupMessage(text, sender)
    if type(text) ~= "string" or type(sender) ~= "string" or IsMe(sender) then return end
    local kind = text:match("^(%a+)|") or text
    if kind == "P" then
        local gen, i, n, body = text:match("^P|(%d+)|(%d+)|(%d+)|(.*)$")
        if not gen then return end
        gen, i, n = tonumber(gen), tonumber(i), tonumber(n)
        local who = PartyKey(sender)
        local d = partyData[who]
        if not d or d.gen ~= gen then
            d = { gen = gen, parts = {}, quests = d and d.quests or {}, ready = d and d.ready }
            partyData[who] = d
        end
        d.parts[i] = body
        for k = 1, n do if not d.parts[k] then return end end
        local quests = {}
        for k = 1, n do
            for qid, have, need, done, share in d.parts[k]:gmatch("(%d+):(%d+):(%d+):(%d)(s?)") do
                quests[tonumber(qid)] = { have = tonumber(have), need = tonumber(need), done = done == "1", share = share == "s" }
            end
        end
        d.quests, d.ready, d.t = quests, true, GetTime()
        ns.RequestRefresh()
    elseif kind == "PQ" then
        ns.SchedulePartySync(true)
    elseif kind == "K" then
        ns.OnKudos(sender)
    end
end

function ns.PartyHasAddon()
    for _, d in pairs(partyData) do if d.ready then return true end end
    return false
end

function ns.PrepShareSource(id)
    if not IsInGroup() or (IsInRaid and IsInRaid()) then return end
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and (not UnitIsConnected or UnitIsConnected(unit)) then
            local who = (GetUnitName and GetUnitName(unit, true)) or UnitName(unit)
            local data = who and partyData[PartyKey(who)]
            local quest = data and data.ready and data.quests[id]
            if quest and quest.share then return who end
        end
    end
end

-- "Party: Lunaria 9/12, Grimbold done, Korgash doesn't have it [Share quest]"
function ns.PartyLine(questID)
    if not IsInGroup() or (IsInRaid and IsInRaid()) then return nil end
    local parts, missing = {}, false
    for i = 1, 4 do
        local u = "party" .. i
        if UnitExists(u) then
            local name = UnitName(u)
            local full = (GetUnitName and GetUnitName(u, true)) or name
            local _, class = UnitClass(u)
            local d = partyData[full] or partyData[name]
            local label = ClassColorName(name, class)
            if d and d.ready then
                local q = d.quests[questID]
                if not q then
                    label = label .. " |cff9d9d9d" .. L["doesn't have it"] .. "|r"
                    missing = true
                elseif q.done then
                    label = label .. " |cff33ff33" .. L["done"] .. "|r"
                elseif q.need > 0 then
                    label = label .. string.format(" |cffffffff%d/%d|r", q.have, q.need)
                else
                    label = label .. " |cffffffff" .. L["has it"] .. "|r"
                end
            else
                label = label .. " |cff9d9d9d?|r"
            end
            parts[#parts + 1] = label
        end
    end
    if #parts == 0 then return nil end
    local line = "|cffffd100" .. L["Party:"] .. "|r " .. table.concat(parts, ", ")
    if missing then
        line = line .. "  |cff66ddff|Hquestynator:share:" .. questID .. "|h[" .. L["Share quest"] .. "]|h|r"
    end
    return line
end

function ns.ShareQuest(questID)
    local idx = ns.QuestLogIndex(questID)
    if not idx then return false end
    if C_QuestLog.SetSelectedQuest then pcall(C_QuestLog.SetSelectedQuest, questID) end
    if SelectQuestLogEntry then pcall(SelectQuestLogEntry, idx) end
    local pushable
    if C_QuestLog.IsPushableQuest then pushable = C_QuestLog.IsPushableQuest(questID)
    elseif GetQuestLogPushable then pushable = GetQuestLogPushable() end
    if pushable and QuestLogPushQuest then
        QuestLogPushQuest(idx)
        Print(string.format(L["Shared with your party: %s"], QuestTitle(questID)))
        return true
    end
    Print(L["This quest can't be shared."])
    return false
end

-- kudos: thank your party after a quest done together; each person can thank you 3 times a day
function ns.OnKudos(sender)
    local who = PartyKey(sender)
    local today = date("%Y-%m-%d")
    if type(DB.kudosFrom) ~= "table" then DB.kudosFrom = {} end
    for k in pairs(DB.kudosFrom) do
        if not k:find(today, 1, true) then DB.kudosFrom[k] = nil end
    end
    local key = who .. "@" .. today
    local n = DB.kudosFrom[key] or 0
    if n >= 3 then return end
    DB.kudosFrom[key] = n + 1
    DB.kudos = (tonumber(DB.kudos) or 0) + 1
    Print(string.format(L["%s thanked you! Kudos: %d"], who, DB.kudos))
    if PlaySound and SOUNDKIT and SOUNDKIT.UI_70_ARTIFACT_FORGE_TRAIT_FIRST_TRAIT then
        pcall(PlaySound, SOUNDKIT.UI_70_ARTIFACT_FORGE_TRAIT_FIRST_TRAIT, "Master")
    end
end

function ns.ThankParty()
    if SendGroup("K|1") then
        Print(L["You thanked your party."])
        return true
    end
    Print(L["You're not in a party."])
    return false
end

local lastThanksPrompt = -1000
function ns.MaybeAskThanks()
    if not IsInGroup() or not ns.PartyHasAddon() then return end
    if GetTime() - lastThanksPrompt < 600 then return end
    lastThanksPrompt = GetTime()
    if not (StaticPopupDialogs and StaticPopup_Show) then return end
    StaticPopupDialogs["QUESTYNATOR_THANKS"] = StaticPopupDialogs["QUESTYNATOR_THANKS"] or {
        button1 = YES or "Yes", button2 = NO or "No", timeout = 30, whileDead = true, hideOnEscape = true,
        OnAccept = function() ns.ThankParty() end,
    }
    StaticPopupDialogs["QUESTYNATOR_THANKS"].text = L["Quest done together! Thank your party? (+1 kudos each)"]
    StaticPopup_Show("QUESTYNATOR_THANKS")
end

---------------------------------------------------------------------------
-- party chat: "objectives done" and "quest completed" messages
---------------------------------------------------------------------------
local doneState = {}       -- [questID] = true when all objectives are done
local announced = {}       -- ["done:" / "turnin:" .. questID] = time, no repeats
local scanned = false

local function PartyChatTarget()
    if IsInRaid and IsInRaid() then return "RAID" end
    if IsInGroup() then return "PARTY" end
end

local function SayToGroup(key, msg)
    if not DB.partyChat then return false end
    local chan = PartyChatTarget()
    if not chan then return false end
    if announced[key] and GetTime() - announced[key] < 300 then return false end
    announced[key] = GetTime()
    if TestBlocked("would say in party: " .. msg) then return false end
    SendChatMessage(msg, chan)
    return true
end
ns.SayToGroup = SayToGroup

-- Track objective transitions separately from whole-quest party announcements.
local inLog = {}           -- [questID][objective index] = finished on the previous scan
function ns.CheckQuestDone()
    local now, present = {}, {}
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and info.questID and not info.isHidden then
            local previousObjectives = inLog[info.questID]
            local objs = C_QuestLog.GetQuestObjectives and C_QuestLog.GetQuestObjectives(info.questID) or {}
            -- A follow-up can enter the log after the turn-in's replan has already run.
            if scanned and (not previousObjectives or (not next(previousObjectives) and #objs > 0)) then
                ns.QueueRouteReplan()
            end
            local states = previousObjectives or {}
            for index, objective in ipairs(objs) do
                local finished = objective.finished == true
                if states[index] == false and finished then ns.QueueRouteReplan() end
                states[index] = finished
            end
            present[info.questID] = states
            local complete = C_QuestLog.IsComplete and C_QuestLog.IsComplete(info.questID)
            if complete and #objs > 0 then now[info.questID] = info.title or true end
        end
    end
    local previous = inLog
    inLog = present
    if scanned then
        for qid in pairs(previous) do
            if not present[qid] and not ns.QuestLogIndex(qid) then
                ns.QueueRouteReplan()
                break
            end
        end
        for qid, title in pairs(now) do
            if not doneState[qid] and previous[qid] then
                ns.QueueRouteReplan()
                local name = type(title) == "string" and title or QuestTitle(qid)
                SayToGroup("done:" .. qid, string.format(L["Questynator: %s - all objectives done!"], ns.QuestChatLink(qid, name)))
            end
        end
    end
    doneState = now
    scanned = true
end

ns.titleCache, ns.linkCache = {}, {}

-- the game's own clickable quest link (yellow [Quest Name]), like Questie posts; nil if the client has none
local function NativeQuestLink(qid)
    local fn = (C_QuestLog and C_QuestLog.GetQuestLink) or GetQuestLink
    if not fn then return nil end
    local ok, link = pcall(fn, qid)
    if ok and type(link) == "string" and link:find("|Hquest:", 1, true) then return link end
    return nil
end

function ns.QuestChatLink(qid, title)
    local link = NativeQuestLink(qid) or ns.linkCache[qid]
    if link then return link end
    return "[" .. tostring(title or ns.titleCache[qid] or QuestTitle(qid)) .. "]"
end

function ns.CacheTitles()
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and info.questID and info.title then
            ns.titleCache[info.questID] = info.title
            ns.linkCache[info.questID] = NativeQuestLink(info.questID) or ns.linkCache[info.questID]
        end
    end
end

function ns.AnnounceTurnIn(questID, title)
    if not questID then return end
    local name = title or QuestTitle(questID)
    if not name or name == "" or name:find("^#") then
        name = ns.AnyQuestTitle and ns.AnyQuestTitle(questID) or ("#" .. questID)
    end
    SayToGroup("turnin:" .. questID, string.format(L["Questynator: %s - quest completed!"], ns.QuestChatLink(questID, name)))
end

---------------------------------------------------------------------------
-- weekly top helpers (groups formed + quests done in Questynator groups, shared in the hello)
---------------------------------------------------------------------------
function ns.WeekKey() return date("%Y-%W") end

function ns.AddWeekly(kind)
    local wk = ns.WeekKey()
    if type(DB.week) ~= "table" or DB.week.key ~= wk then DB.week = { key = wk, groups = 0, quests = 0 } end
    DB.week[kind] = (DB.week[kind] or 0) + 1
end

function ns.WeekScore()
    if type(DB.week) ~= "table" or DB.week.key ~= ns.WeekKey() then return 0 end
    return (DB.week.groups or 0) + (DB.week.quests or 0)
end

local userInfo = {}        -- [name] = { kudos, class }
function ns.OnHelloInfo(sender, class, kudos, week, score)
    local who = Ambiguate(sender, "none")
    userInfo[who] = { kudos = tonumber(kudos) or 0, class = (class ~= "" and class) or nil }
    score = tonumber(score) or 0
    if type(DB.helpers) ~= "table" then DB.helpers = {} end
    local wk = ns.WeekKey()
    if week == wk and score > 0 then
        DB.helpers[who] = { week = wk, score = score, class = userInfo[who].class }
    end
end

function ns.UserKudos(name)
    local u = name and userInfo[name]
    return u and u.kudos or nil
end

function ns.TopHelpers(n)
    local wk, list = ns.WeekKey(), {}
    if type(DB.helpers) ~= "table" then DB.helpers = {} end
    for name, h in pairs(DB.helpers) do
        if h.week ~= wk then DB.helpers[name] = nil
        elseif not IsMe(name) then list[#list + 1] = { name = name, score = h.score, class = h.class } end
    end
    local mine = ns.WeekScore()
    if mine > 0 then
        local _, c = UnitClass("player")
        list[#list + 1] = { name = UnitName("player"), score = mine, class = c, me = true }
    end
    table.sort(list, function(a, b) return a.score > b.score end)
    while #list > (n or 5) do table.remove(list) end
    return list
end

---------------------------------------------------------------------------
-- XP per hour and time to level
---------------------------------------------------------------------------
local xpLog, lastXP, lastXPMax, lastLevel = {}, nil, nil, nil
function ns.OnXPChange()
    local cur, max, lvl = UnitXP("player") or 0, UnitXPMax("player") or 0, UnitLevel("player") or 0
    if not ns.xpStart then ns.xpStart = GetTime() end
    if lastXP then
        local gain = (lvl > lastLevel) and ((lastXPMax - lastXP) + cur) or (cur - lastXP)
        if gain > 0 then xpLog[#xpLog + 1] = { t = GetTime(), xp = gain } end
    end
    lastXP, lastXPMax, lastLevel = cur, max, lvl
    local cutoff = GetTime() - 3600
    while xpLog[1] and xpLog[1].t < cutoff do table.remove(xpLog, 1) end
end

-- XP per hour over the last hour (or the session so far, after 5 minutes)
function ns.XPRate()
    if not ns.xpStart then return nil end
    local now = GetTime()
    local window = math.min(3600, now - ns.xpStart)
    if window < 300 then return nil end
    local total = 0
    for _, e in ipairs(xpLog) do
        if e.t > now - 3600 then total = total + e.xp end
    end
    return total / window * 3600
end

function ns.FormatDuration(sec)
    sec = math.max(0, math.floor(sec or 0))
    local h, m = math.floor(sec / 3600), math.floor((sec % 3600) / 60)
    if h > 0 then return string.format("%dh %02dm", h, m) end
    return string.format("%dm", math.max(1, m))
end

---------------------------------------------------------------------------
-- popular near you: quests other Questynator players in your zone are searching for
---------------------------------------------------------------------------
local popular = {}         -- [qid] = { [name] = { t, level, title } }
local POPULAR_TTL = 600

function ns.NotePopular(qid, sender, level, title)
    if not qid then return end
    popular[qid] = popular[qid] or {}
    popular[qid][Ambiguate(sender, "none")] = { t = GetTime(), level = tonumber(level), title = (title ~= "" and title) or nil }
end

local function RefZone(ref)
    local D = ns.QDATA
    if not D or type(ref) ~= "string" then return nil end
    local kind, id = ref:match("^([no])(%d+)$")
    local raw = kind and D[kind] and D[kind][tonumber(id)]
    return raw and tonumber(raw:match("^([^,]*),"))
end

function ns.QuestZone(qid)
    local q = ns.BundledQuest(qid)
    if not q then return nil end
    for _, ref in ipairs({ q.mobs[1] or false, q.objects[1] or false, q.start or false, q.finish or false }) do
        local z = ref and RefZone(ref)
        if z then return z end
    end
end

local function PlayerMaps(zoneOnly)
    local set = {}
    local id = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    for _ = 1, 6 do
        if not id or id == 0 then break end
        local info = C_Map.GetMapInfo and C_Map.GetMapInfo(id)
        if zoneOnly and info and info.mapType and info.mapType < 3 then break end
        set[id] = true
        if zoneOnly and info and (info.mapType == 3 or info.mapType == 4) then break end
        id = info and info.parentMapID
    end
    return set
end

function ns.CurrentZoneMaps() return PlayerMaps(true) end

function ns.AnyQuestTitle(qid, fallback)
    if ns.QuestLogIndex(qid) then return QuestTitle(qid) end
    if C_QuestLog.GetTitleForQuestID then
        local t = C_QuestLog.GetTitleForQuestID(qid)
        if type(t) == "string" and t ~= "" then return t end
    end
    local D = ns.QDATA
    local t = D and D.t and D.t[qid]
    if t then return t:match(";([^;]*)$") end
    return fallback or ("#" .. qid)
end

function ns.PopularNearYou(limit)
    local maps, now, me = PlayerMaps(), GetTime(), UnitLevel("player") or 1
    local list = {}
    for qid, who in pairs(popular) do
        local n, title, levels = 0, nil, 0
        for name, p in pairs(who) do
            if now - p.t > POPULAR_TTL then who[name] = nil
            else
                n = n + 1
                title = title or p.title
                levels = levels + (p.level or me)
            end
        end
        if n > 0 then
            local zone = ns.QuestZone(qid)
            local uiMap = zone and ns.UiMapForArea(zone)
            local near = uiMap and maps[uiMap]
            local avg = levels / n
            if near and math.abs(avg - me) <= 8 then
                list[#list + 1] = { questID = qid, count = n, title = ns.AnyQuestTitle(qid, title),
                    inLog = ns.QuestLogIndex(qid) ~= nil, seeking = seeking[qid] ~= nil }
            end
        else
            popular[qid] = nil
        end
    end
    table.sort(list, function(a, b) return a.count > b.count end)
    while #list > (limit or 5) do table.remove(list) end
    return list
end

do -- turn-in arrow
---------------------------------------------------------------------------
-- turn-in arrow: where to hand in quests that are ready (target + geometry)
---------------------------------------------------------------------------
local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end

local function NormAngle(a)
    while a > math.pi do a = a - 2 * math.pi end
    while a <= -math.pi do a = a + 2 * math.pi end
    return a
end
ns.NormAngle = NormAngle

local function RefPlace(ref)
    local D = ns.QDATA
    if not D or type(ref) ~= "string" then return nil end
    local kind, id = ref:match("^([no])(%d+)$")
    local raw = kind and D[kind] and D[kind][tonumber(id)]
    if not raw then return nil end
    local zone, x, y, _, _, name = raw:match("^([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),(.*)$")
    zone, x, y = tonumber(zone), tonumber(x), tonumber(y)
    if not (zone and x and y and x >= 0 and y >= 0) then return nil end
    local uiMap = ns.UiMapForArea(zone)
    if not uiMap then return nil end
    return { area = zone, x = x, y = y, name = name, uiMap = uiMap }
end

local function TargetWorld(t)
    if not (C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then return nil end
    local ok, inst, pos = pcall(C_Map.GetWorldPosFromMapPos, t.uiMap, CreateVector2D(t.x / 100, t.y / 100))
    if not ok or not pos then return nil end
    return inst, pos.x, pos.y
end

-- UnitPosition returns world X (north) first, then world Y (west)
local function PlayerWorld()
    if not UnitPosition then return nil end
    local north, west, _, inst = UnitPosition("player")
    if not north or not west then return nil end
    return inst, north, west
end

-- Objective details can be empty while the client is loading them.
local function IsReady(qid)
    return not not ((C_QuestLog.ReadyForTurnIn and C_QuestLog.ReadyForTurnIn(qid))
        or (C_QuestLog.IsComplete and C_QuestLog.IsComplete(qid)))
end
ns.IsReadyToTurnIn = IsReady

-- the quest selected in the tracker (Blizzard super-tracking), if any
local function TrackedQuest()
    local st = C_SuperTrack
    if not (st and st.GetSuperTrackedQuestID) then return nil end
    local ok, id = pcall(st.GetSuperTrackedQuestID)
    if ok and id and id > 0 then return id, ns.QuestLogIndex(id) end
end

-- distance from you to a place (and remember its world position)
local function PlaceDistance(place, pinst, px, py)
    local tinst, tx, ty = TargetWorld(place)
    place.wInst, place.wx, place.wy = tinst, tx, ty
    if pinst and tinst == pinst then return math.sqrt((tx - px) ^ 2 + (ty - py) ^ 2) end
    if pinst and tinst then return 1e9 end            -- other continent: last resort
    return math.huge
end

-- where to go for a quest that isn't done: spots of the unfinished objectives
-- (mobs, objects, and the mobs/objects that drop the items), matched by name; all spots if nothing matches
function ns.ObjectiveSpots(qid, objectiveIndex)
    local D = ns.QDATA
    local q = ns.BundledQuest(qid)
    if not (D and q) then return {} end
    local entries = {}                          -- { name = lowercased, refs = { "n1", ... } }
    for _, ref in ipairs(q.mobs) do
        local p = RefPlace(ref)
        if p then entries[#entries + 1] = { name = p.name:lower(), refs = { ref } } end
    end
    for _, ref in ipairs(q.objects) do
        local p = RefPlace(ref)
        if p then entries[#entries + 1] = { name = p.name:lower(), refs = { ref } } end
    end
    for _, id in ipairs(q.items) do
        local raw = D.i and D.i[id]
        local srcs, name
        if raw then srcs, name = raw:match("^([^;]*);(.*)$") end
        if srcs then
            local refs = {}
            for ref in srcs:gmatch("[no]%d+") do refs[#refs + 1] = ref end
            entries[#entries + 1] = { name = (name or ""):lower(), refs = refs }
        end
    end
    -- entries an objective text names; a longer name hides one it contains
    -- ("Burly Rockjaw Trogg" over "Rockjaw Trogg")
    local function Named(text)
        local hits, named = {}, {}
        for _, e in ipairs(entries) do
            local first, last
            if e.name ~= "" then first, last = text:find(e.name, 1, true) end
            if first then hits[#hits + 1] = { first = first, last = last, entry = e } end
        end
        for _, hit in ipairs(hits) do
            local contained = false
            for _, other in ipairs(hits) do
                if other.first <= hit.first and other.last >= hit.last
                    and (other.first < hit.first or other.last > hit.last) then
                    contained = true
                    break
                end
            end
            if not contained then named[#named + 1] = hit.entry end
        end
        return named
    end
    local objectives = (C_QuestLog.GetQuestObjectives and C_QuestLog.GetQuestObjectives(qid)) or {}
    local refs, finishedNames, anyNamed, firstOpen, openInScope = {}, {}, false, nil, 0
    for i, o in ipairs(objectives) do
        local named = o.text and Named(o.text:lower()) or {}
        if #named > 0 then anyNamed = true end
        if o.finished then
            for _, e in ipairs(named) do finishedNames[e] = true end
        elseif o.text then
            firstOpen = firstOpen or i
            if not objectiveIndex or i == objectiveIndex then
                openInScope = openInScope + 1
                for _, e in ipairs(named) do for _, r in ipairs(e.refs) do refs[r] = true end end
            end
        end
    end
    -- Translated clients never match the English names in the data. Fall back to every
    -- spot no finished objective names: for the whole quest, for a single-objective quest,
    -- or, when no objective names anything, for the first open objective so routes advance.
    if not next(refs) and openInScope > 0 and (not objectiveIndex or #objectives == 1
        or (not anyNamed and objectiveIndex == firstOpen)) then
        for _, e in ipairs(entries) do
            if not finishedNames[e] then
                for _, r in ipairs(e.refs) do refs[r] = true end
            end
        end
    end
    local out = {}
    for r in pairs(refs) do
        local p = RefPlace(r)
        if p then out[#out + 1] = p end
    end
    return out
end

-- A selection in Blizzard's objective tracker takes precedence over route guidance.
function ns.ArrowTarget()
    local tracked, index = TrackedQuest()
    local pinst, px, py = PlayerWorld()
    if index then
        local best, bestD
        local ready = IsReady(tracked)
        if not ready then
            for _, place in ipairs(ns.ObjectiveSpots(tracked)) do
                local d = PlaceDistance(place, pinst, px, py)
                if not bestD or d < bestD then best, bestD = place, d end
            end
        end
        if not best then
            local q = ns.BundledQuest(tracked)
            -- Delivery quests can show a "speak to" objective with no separate objective spot.
            if q and (ready or (#q.mobs == 0 and #q.objects == 0 and #q.items == 0)) then
                best = RefPlace(q.finish)
                if best then PlaceDistance(best, pinst, px, py) end
            end
        end
        if best then
            local info = C_QuestLog.GetInfo(index)
            best.questID, best.title = tracked, (info and info.title) or QuestTitle(tracked)
            best.objective = not ready
            best.selectedQuest = true
        end
        return best
    end

    local routeTarget = ns.RouteTarget()
    if routeTarget then return routeTarget end
    if ns.RoutePaused() then return end
    local best, bestD
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        local qid = info and not info.isHeader and info.questID
        if qid and not info.isHidden and IsReady(qid) then
            local q = ns.BundledQuest(qid)
            local place = q and RefPlace(q.finish)
            if place and not ns.IsSnoozedPlace(place) then
                place.questID, place.title = qid, info.title or QuestTitle(qid)
                local d = PlaceDistance(place, pinst, px, py)
                if not bestD or d < bestD then best, bestD = place, d end
            end
        end
    end
    return best
end

local function ContinentName(uiMap)
    local id = uiMap
    for _ = 1, 6 do
        local info = id and C_Map.GetMapInfo and C_Map.GetMapInfo(id)
        if not info then return nil end
        if info.mapType == 2 then return info.name end      -- Enum.UIMapType.Continent
        id = info.parentMapID
    end
end

-- where the target is from here: state "ok" (this zone), "far" (other zone), "continent", "unavailable"
function ns.ArrowGeometry(t)
    local g = { zoneName = ZoneName(t.area) }
    local pinst, px, py = PlayerWorld()
    if not pinst then g.state = "unavailable"; return g end
    local tinst, tx, ty = t.wInst, t.wx, t.wy
    if not tinst then tinst, tx, ty = TargetWorld(t) end
    if not tinst or tinst ~= pinst then
        g.state = "continent"
        g.continent = ContinentName(t.uiMap)
        return g
    end
    local dx, dy = tx - px, ty - py                     -- world x = north, y = west
    g.yards = math.sqrt(dx * dx + dy * dy)
    g.bearing = atan2(dy, dx)
    g.angle = NormAngle(g.bearing - (GetPlayerFacing and GetPlayerFacing() or 0))
    g.state = PlayerMaps()[t.uiMap] and "ok" or "far"
    return g
end

-- Route locals belong to their own function; the addon chunk is near Lua's 200-local limit.
local function InitializeRoutes()
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
        local limit = DB.plannerExpanded and 3 or 1
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
        planner.expand:SetText(DB.plannerExpanded and L["Less"] or L["More"])
        planner.expand:SetShown(total > 1 or stop ~= nil)
        planner.expand:SetPoint("TOPLEFT", 12, -top)
        planner.snooze:SetShown(stop ~= nil and DB.plannerExpanded == true)
        planner.undo:SetShown(QuestynatorRouteSnoozes ~= nil)
        planner.snooze:SetPoint("TOPLEFT", 72, -top)
        planner.undo:SetPoint("TOPLEFT", stop and (DB.plannerExpanded and 175 or 72) or 12, -top)
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
        DB.plannerHidden = not shown
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
                DB.plannerPos = { point, relative, x, y }
            end)
            local pos = DB.plannerPos
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
                DB.plannerExpanded = not DB.plannerExpanded
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
end
InitializeRoutes()

end -- arrow geometry
do -- the compass on screen
local NormAngle, IsReady = ns.NormAngle, ns.IsReadyToTurnIn
-- the compass on screen ---------------------------------------------------
local EASE_TAU = 0.06          -- ~0.25 s to settle (4 x tau)
function ns.EaseAngle(cur, target, dt)
    local diff = NormAngle(target - cur)
    local k = 1 - math.exp(-(dt or 0) / EASE_TAU)
    return NormAngle(cur + diff * k)
end

local function Comma(n)
    local s = tostring(math.floor(n + 0.5))
    while true do
        local r, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        s = r
        if k == 0 then return s end
    end
end

function ns.ArrowText(t, g)
    local line1 = tostring(t.name or "?") .. (t.title and (" - " .. t.title) or "")
    local line2
    if g.state == "unavailable" then
        line2 = L["Not available here"]
    elseif g.state == "continent" then
        line2 = string.format("%s (%s)", g.zoneName or "?", g.continent or "?")
    elseif g.state == "far" then
        line2 = string.format("%s · %s yd", g.zoneName or "?", Comma(g.yards or 0))
    elseif (g.yards or 0) <= 10 then
        line2 = L["You're here"]
    else
        line2 = Comma(g.yards or 0) .. " yd"
    end
    return line1, line2
end

local arrow                    -- the frame
local current                  -- current target
local dismissed                -- ready quest ids at the time of the right-click
local needleAngle, alpha, elapsed, sinceRefresh, sinceGeo = 0, 0, 0, 0, 1
local geo                      -- last geometry (refreshed ~10 times a second)

local function ReadySet()
    local set = {}
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        local qid = info and not info.isHeader and info.questID
        if qid and not info.isHidden and IsReady(qid) then set[qid] = true end
    end
    return set
end

local function CreateArrow()
    local f = CreateFrame("Frame", "QuestynatorArrow", UIParent)
    f:SetSize(160, 104)
    f:SetFrameStrata("MEDIUM")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint(1)
        DB.arrowPos = { point = point, relPoint = relPoint, x = x, y = y }
    end)
    f:SetScript("OnMouseUp", function(self, button) if button == "RightButton" then ns.ShowArrowMenu(self) end end)
    local pos = type(DB.arrowPos) == "table" and DB.arrowPos
    if pos then f:SetPoint(pos.point or "TOP", UIParent, pos.relPoint or "TOP", pos.x or 0, pos.y or -120)
    else f:SetPoint("TOP", UIParent, "TOP", 0, -120) end
    f.ring = f:CreateTexture(nil, "ARTWORK")
    f.ring:SetSize(64, 64)
    f.ring:SetPoint("TOP", 0, 0)
    f.ring:SetTexture("Interface\\AddOns\\Questynator\\Media\\CompassRing")
    f.needle = f:CreateTexture(nil, "OVERLAY")
    f.needle:SetSize(64, 64)
    f.needle:SetPoint("CENTER", f.ring, "CENTER")
    f.needle:SetTexture("Interface\\AddOns\\Questynator\\Media\\CompassNeedle")
    f.source = ns.UI.Text(f, 11, "accent", nil, "medium")
    f.source:SetPoint("LEFT", f.ring, "RIGHT", 4, 0)
    f.source:SetText(L["Selected quest"])
    f.source:Hide()
    f.line1 = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.line1:SetPoint("TOP", f.ring, "BOTTOM", 0, -2)
    f.line1:SetWidth(220)
    f.line1:SetWordWrap(false)
    f.line2 = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.line2:SetPoint("TOP", f.line1, "BOTTOM", 0, -2)
    f:SetScript("OnUpdate", function(_, dt) ns.ArrowUpdate(dt) end)
    f:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine(L["Quest arrow"], 1, 0.82, 0)
        GameTooltip:AddLine(L["Points to your next turn-in, or to the next objective of the quest you select in the tracker."], 1, 1, 1, true)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Drag to move"], 0.7, 0.7, 0.7)
        GameTooltip:AddLine(L["Right-click to hide it or turn it off"], 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f:SetAlpha(0)
    f:Hide()
    arrow = f
end

-- pick the target and show / hide the compass
function ns.ArrowRefresh()
    ns.UpdateRoute()
    ns.RefreshPlanner()
    if DB.arrow == false then
        current = nil
        if arrow then arrow:Hide() end
        return
    end
    local ready = ReadySet()
    if dismissed then
        for qid in pairs(ready) do
            if not dismissed[qid] then dismissed = nil; break end   -- a new quest is ready: show again
        end
    end
    local prev = current
    current = (not dismissed) and ns.ArrowTarget() or nil
    if not current or not prev or prev.questID ~= current.questID or prev.routeStop ~= current.routeStop then geo = nil end
    if current then
        if not arrow then CreateArrow() end
        arrow.source:SetShown(current.selectedQuest == true)
        if not arrow:IsShown() then alpha = 0; arrow:SetAlpha(0) end
        arrow:Show()
    elseif arrow then
        arrow:Hide()
    end
end

function ns.ArrowDismiss()
    dismissed = ReadySet()
    if arrow then arrow:Hide() end
    current = nil
end

function ns.ArrowUndismiss() dismissed = nil end

-- /qn arrowdebug: raw numbers to check the compass against the real game
function ns.ArrowDebug()
    local t = current or ns.ArrowTarget()
    if not t then Print("arrow debug: no quest is ready to turn in") return end
    local deg = function(a) return a and string.format("%.0f", math.deg(a)) or "?" end
    local north, west, _, inst = UnitPosition("player")
    local mp = C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(t.uiMap, "player")
    local mx, my
    if mp then mx, my = mp:GetXY() end
    local g = ns.ArrowGeometry(t)
    Print(string.format("arrow debug: %s (quest %d) on map %d at %.1f, %.1f (area %d)", tostring(t.name), t.questID, t.uiMap, t.x, t.y, t.area))
    Print(string.format("  you: map %s, %s   world N=%s W=%s inst=%s   facing=%s deg",
        mx and string.format("%.1f", mx * 100) or "?", my and string.format("%.1f", my * 100) or "?",
        tostring(north and math.floor(north)), tostring(west and math.floor(west)), tostring(inst), deg(GetPlayerFacing())))
    Print(string.format("  target world N=%s W=%s inst=%s   state=%s  yards=%s  bearing=%s deg  needle=%s deg (0 = straight ahead, + = left)",
        tostring(t.wx and math.floor(t.wx)), tostring(t.wy and math.floor(t.wy)), tostring(t.wInst), tostring(g.state),
        g.yards and string.format("%.0f", g.yards) or "-", deg(g.bearing), deg(g.angle)))
end

function ns.ArrowShown() return arrow ~= nil and arrow:IsShown() and true or false end
function ns.ArrowCurrent() return current end

function ns.ArrowUpdate(dt)
    if not arrow or not current or not arrow:IsShown() then return end
    dt = dt or 0
    elapsed, sinceRefresh = elapsed + dt, sinceRefresh + dt
    if sinceRefresh > 2 then
        sinceRefresh = 0
        ns.ArrowRefresh()
        if not current then return end
    end
    if alpha < 1 then alpha = math.min(1, alpha + dt * 4); arrow:SetAlpha(alpha) end      -- fade in
    sinceGeo = sinceGeo + dt
    if not geo or sinceGeo >= 0.1 then
        sinceGeo = 0
        geo = ns.ArrowGeometry(current)
        local l1, l2 = ns.ArrowText(current, geo)
        arrow.line1:SetText(l1)
        arrow.line2:SetText(l2)
    end
    local g = geo
    if g.bearing then
        -- turning is read every frame so the needle stays smooth; position only 10 times a second
        local target = NormAngle(g.bearing - (GetPlayerFacing() or 0))
        needleAngle = ns.EaseAngle(needleAngle, target, dt)
        arrow.needle:SetRotation(needleAngle)
    end
    local here = g.state == "ok" and (g.yards or 99) <= 10
    if g.state == "unavailable" or g.state == "continent" then
        arrow.needle:SetDesaturated(true); arrow.needle:SetVertexColor(0.7, 0.7, 0.7); arrow.needle:SetAlpha(0.5)
        arrow.ring:SetAlpha(0.5)
        arrow.line2:SetTextColor(0.6, 0.6, 0.6)
    elseif here then
        arrow.needle:SetDesaturated(false); arrow.needle:SetVertexColor(0.3, 1, 0.3); arrow.needle:SetAlpha(1)
        arrow.ring:SetAlpha(0.8 + 0.2 * math.sin(elapsed * 2 * math.pi))     -- pulse, ~1 s
        arrow.line2:SetTextColor(0.3, 1, 0.3)
    else
        arrow.needle:SetDesaturated(false); arrow.needle:SetVertexColor(1, 1, 1); arrow.needle:SetAlpha(1)
        arrow.ring:SetAlpha(1)
        arrow.line2:SetTextColor(1, 0.82, 0)
    end
end

end -- turn-in arrow

---------------------------------------------------------------------------
-- dungeon finder with roles
---------------------------------------------------------------------------
-- id = AreaTable id (name comes from the game, in your language); entrance = zone, x, y
local DUNGEONS = {
    { id = 2437, min = 13, max = 18, zone = 1637, x = 52.6, y = 49.0, name = "Ragefire Chasm", faction = "H" },   -- inside Orgrimmar
    { id = 718,  min = 15, max = 25, zone = 17,   x = 46.0, y = 36.5, name = "Wailing Caverns" },
    { id = 1581, min = 18, max = 23, zone = 40,   x = 42.5, y = 71.7, name = "The Deadmines" },
    { id = 209,  min = 22, max = 30, zone = 130,  x = 44.8, y = 67.8, name = "Shadowfang Keep" },
    { id = 717,  min = 22, max = 30, zone = 1519, x = 52.4, y = 70.0, name = "The Stockade", faction = "A" },     -- inside Stormwind
    { id = 719,  min = 24, max = 32, zone = 331,  x = 14.5, y = 14.2, name = "Blackfathom Deeps" },
    { id = 721,  min = 29, max = 38, zone = 1,    x = 24.3, y = 39.8, name = "Gnomeregan" },
    { id = 491,  min = 30, max = 40, zone = 17,   x = 42.9, y = 90.2, name = "Razorfen Kraul" },
    { id = 796,  min = 26, max = 45, zone = 85,   x = 82.6, y = 33.8, name = "Scarlet Monastery" },
    { id = 722,  min = 40, max = 50, zone = 17,   x = 49.0, y = 93.9, name = "Razorfen Downs" },
    { id = 1337, min = 42, max = 52, zone = 3,    x = 44.6, y = 12.1, name = "Uldaman" },
    { id = 1176, min = 44, max = 54, zone = 440,  x = 38.7, y = 20.1, name = "Zul'Farrak" },
    { id = 2100, min = 46, max = 55, zone = 405,  x = 29.1, y = 62.5, name = "Maraudon" },
    { id = 1477, min = 50, max = 60, zone = 8,    x = 69.9, y = 53.5, name = "The Temple of Atal'Hakkar" },
    { id = 1584, min = 52, max = 60, zone = 51,   x = 34.8, y = 85.3, name = "Blackrock Depths" },
    { id = 1583, min = 55, max = 60, zone = 51,   x = 34.8, y = 85.3, name = "Blackrock Spire" },
    { id = 2557, min = 55, max = 60, zone = 357,  x = 59.2, y = 45.1, name = "Dire Maul" },
    { id = 2057, min = 58, max = 60, zone = 28,   x = 69.7, y = 73.2, name = "Scholomance" },
    { id = 2017, min = 58, max = 60, zone = 139,  x = 26.5, y = 10.4, name = "Stratholme" },
}
ns.DUNGEONS = DUNGEONS
local DUNGEON_BY_ID = {}
for _, d in ipairs(DUNGEONS) do DUNGEON_BY_ID[d.id] = d end
local DUNGEON_TTL = 90
local ROLES = { "T", "H", "D" }

local myDungeon            -- { id, mode = "host"|"seek", started, ticker, needs = {T,H,D}, wasGrouped, inviteCount }
local dboard = {}          -- [id] = { [sender] = { mode, roles, level, class, members, t } }

function ns.DungeonName(id)
    local d = DUNGEON_BY_ID[id]
    return ZoneName(id) or (d and d.name) or ("#" .. tostring(id))
end

function ns.RoleName(r)
    return (r == "T" and L["Tank"]) or (r == "H" and L["Healer"]) or L["DPS"]
end

local function RoleString(t)
    local s = ""
    for _, r in ipairs(ROLES) do if t and t[r] then s = s .. r end end
    return s
end

function ns.RolesText(str)
    local out = {}
    for r in tostring(str or ""):gmatch("[THD]") do out[#out + 1] = ns.RoleName(r) end
    return table.concat(out, ", ")
end

function ns.MyRoles()
    if type(DB.roles) ~= "table" then DB.roles = { T = false, H = false, D = true } end
    return DB.roles
end

function ns.ToggleMyRole(r)
    local roles = ns.MyRoles()
    roles[r] = not roles[r]
    if not (roles.T or roles.H or roles.D) then roles[r] = true end    -- keep at least one
    if myDungeon and myDungeon.mode == "host" then ns.UpdateDungeonComposition(true) end
    if myDungeon then ns.DungeonBeacon() end
    ns.RequestRefresh()
end

function ns.ToggleNeed(r)
    if not myDungeon or myDungeon.mode ~= "host" then return end
    myDungeon.needs[r] = not myDungeon.needs[r]
    if myDungeon.needCount and myDungeon.needs[r] and (myDungeon.needCount[r] or 0) == 0 then myDungeon.needCount[r] = 1 end
    ns.DungeonBeacon()
    ns.RequestRefresh()
end

function ns.MyDungeon() return myDungeon end

-- which role(s) someone offered: from "+ heal", "+ Tank", "+ Heiler", a DJ message, etc.
local ROLE_WORDS = {
    T = { "tank", "tanque", "танк" },
    H = { "heal", "heiler", "soign", "sanad", "healer", "лекар", "хил", "хилер" },
    D = { "dps", "dd", "damage", "дд", "дпс", "damage" },
}
function ns.RolesFromText(text)
    local lower = tostring(text or ""):lower()
    local out = ""
    for _, r in ipairs(ROLES) do
        for _, w in ipairs(ROLE_WORDS[r]) do
            if lower:find(w, 1, true) then out = out .. r; break end
        end
    end
    return out
end

-- At most five players. Try their offered roles and keep the assignment that
-- fills the most standard party slots, including flexible roles on the host.
local function AssignDungeonRoles(members)
    local left = { T = 1, H = 1, D = 3 }
    local picks, best, bestScore = {}, {}, -1
    local function Assign(i, score)
        if bestScore == #members then return end
        if i > #members then
            if score > bestScore then
                bestScore = score
                for j, role in ipairs(picks) do best[j] = role end
            end
            return
        end
        for _, role in ipairs(ROLES) do
            if members[i].offered:find(role, 1, true) then
                picks[i] = role
                local filled = left[role] > 0
                left[role] = left[role] - 1
                Assign(i + 1, score + (filled and 1 or 0))
                left[role] = left[role] + 1
            end
        end
    end
    Assign(1, 0)
    for i, role in ipairs(best) do
        members[i].role = role
        left[role] = left[role] - 1
    end
    return left
end

-- a 5-player group: 1 tank, 1 healer, 3 DPS. Fill it with the host and every member, then list what's left.
function ns.UpdateDungeonComposition(quiet)
    if not myDungeon or myDungeon.mode ~= "host" then return end
    local members = {}
    for i = 1, 4 do
        local u = "party" .. i
        if UnitExists(u) then
            local name = UnitName(u)
            local full = (GetUnitName and GetUnitName(u, true)) or name
            local offered = myDungeon.offered[full] or myDungeon.offered[name] or ""
            members[#members + 1] = { name = name, offered = offered ~= "" and offered or "D" }
        end
    end
    local offered = RoleString(ns.MyRoles())
    members[#members + 1] = { offered = offered ~= "" and offered or "D" }
    local left = AssignDungeonRoles(members)
    table.remove(members) -- the roster shown to the host contains party members
    local before = RoleString(myDungeon.needs) .. ":" .. (myDungeon.needCount and myDungeon.needCount.D or "")
    for _, r in ipairs(ROLES) do left[r] = math.max(0, left[r]) end
    -- never ask for more players than there are free spots (an extra tank takes a DPS spot)
    local free = MAX_PARTY - 1 - #members
    for _, r in ipairs({ "D", "H", "T" }) do
        while left.T + left.H + left.D > free and left[r] > 0 do left[r] = left[r] - 1 end
    end
    myDungeon.needCount = { T = left.T, H = left.H, D = left.D }
    myDungeon.needs = { T = left.T > 0, H = left.H > 0, D = left.D > 0 }
    myDungeon.roster = members
    local after = RoleString(myDungeon.needs) .. ":" .. myDungeon.needCount.D
    if before ~= after then
        ns.DungeonBeacon()
        if not quiet then
            local need = ns.NeedText()
            if need ~= "" then
                Print(string.format(L["%s: now need %s. Click Post to General to update chat."], ns.DungeonName(myDungeon.id), need))
            end
        end
        ns.RequestRefresh()
    end
end

-- "Healer, 2 DPS"
function ns.NeedText()
    if not myDungeon then return "" end
    local c = myDungeon.needCount
    local out = {}
    for _, r in ipairs(ROLES) do
        if myDungeon.needs[r] then
            local n = c and c[r] or 1
            out[#out + 1] = (n > 1) and (n .. " " .. ns.RoleName(r)) or ns.RoleName(r)
        end
    end
    return table.concat(out, ", ")
end

function ns.OnDungeonJoinInfo(sender, roles)
    if not myDungeon or myDungeon.mode ~= "host" then return end
    myDungeon.offered[Ambiguate(sender, "none")] = tostring(roles or ""):gsub("[^THD]", "")
    ns.UpdateDungeonComposition()
end

function ns.DungeonBeacon()
    if not myDungeon then return end
    local _, class = UnitClass("player")
    local members = IsInGroup() and GetNumGroupMembers() or 1
    local roles = (myDungeon.mode == "host") and RoleString(myDungeon.needs) or RoleString(ns.MyRoles())
    Send(string.format("D|%d|%d|%s|%s|%s|%s|%d|%d", myDungeon.id, UnitLevel("player") or 1,
        myDungeon.mode == "host" and "H" or "S", roles, SID, class or "", members, ns.PendingHostInvites()))
end

function ns.StartDungeon(id, mode)
    if not DUNGEON_BY_ID[id] then return end
    if mode == "host" and MyState() == 1 then        -- a party member can't invite anyone
        Print(L["Only the group leader can invite."])
        return
    end
    if myDungeon then ns.StopDungeon(true) end
    myDungeon = { id = id, mode = mode, started = GetTime(), needs = { T = true, H = true, D = true },
                  wasGrouped = IsInGroup(), inviteCount = {}, offered = {} }
    if mode == "host" then ns.UpdateDungeonComposition(true) end
    ns.DungeonBeacon()
    myDungeon.ticker = C_Timer.NewTicker(30, function() pcall(ns.DungeonTick) end)
    if mode == "host" then
        Print(string.format(L["Group listed for %s. Players can whisper you + to join."], ns.DungeonName(id)))
    else
        Print(string.format(L["Looking for a %s group as %s."], ns.DungeonName(id), ns.RolesText(RoleString(ns.MyRoles()))))
    end
    ns.RequestRefresh()
end

-- a dungeon host who is no longer the group leader can't invite: take the listing down,
-- so nobody sees (or whispers) a group that can't take them
function ns.CheckDungeonLeader()
    if myDungeon and myDungeon.mode == "host" and MyState() == 1 then
        ns.StopDungeon(true)
        Print(L["Only the group leader can invite."] .. " " .. L["Dungeon search stopped."])
        return true
    end
    return false
end

function ns.DungeonTick()
    if not myDungeon then return end
    if ns.CheckDungeonLeader() then return end
    if GetTime() - myDungeon.started > 1800 then ns.StopDungeon(false) return end
    if IsInGroup() and GetNumGroupMembers() >= MAX_PARTY then ns.StopDungeon(false) return end
    if myDungeon.mode == "seek" and IsInGroup() and not myDungeon.wasGrouped then ns.StopDungeon(true) return end
    ns.DungeonBeacon()
end

function ns.StopDungeon(silent)
    if not myDungeon then return end
    Send("DC|" .. myDungeon.id)
    if myDungeon.ticker then myDungeon.ticker:Cancel() end
    myDungeon = nil
    if not silent then Print(L["Dungeon search stopped."]) end
    ns.RequestRefresh()
end

function ns.OnDungeonBeacon(sender, id, lvl, mode, roles, sid, class, members, pending)
    id = tonumber(id)
    if not id or not DUNGEON_BY_ID[id] or sid == SID then return end
    dboard[id] = dboard[id] or {}
    local isNew = not dboard[id][sender]
    dboard[id][sender] = { mode = (mode == "H") and "host" or "seek", roles = roles or "", level = tonumber(lvl),
        class = (class ~= "" and class) or nil, members = tonumber(members) or 1, t = GetTime(),
        pending = math.max(0, math.min(MAX_PARTY - 1, tonumber(pending) or 0)) }
    -- someone who fits what I'm doing showed up
    if isNew and myDungeon and myDungeon.id == id then
        local e = dboard[id][sender]
        if (myDungeon.mode == "host" and e.mode == "seek") or (myDungeon.mode == "seek" and e.mode == "host") then
            ns.Alert()
        end
    end
    ns.RequestRefresh()
end

function ns.OnDungeonCancel(sender, id)
    id = tonumber(id)
    if id and dboard[id] then dboard[id][sender] = nil end
    ns.RequestRefresh()
end

-- dungeons around your level, with everyone hosting or looking for each
local MyFaction = ns.PlayerFaction

function ns.DungeonList()
    local me, now, out = UnitLevel("player") or 1, GetTime(), {}
    local faction = MyFaction()
    for _, d in ipairs(DUNGEONS) do
        local hosts, seekers = {}, {}
        for name, e in pairs(dboard[d.id] or {}) do
            if now - e.t > DUNGEON_TTL then dboard[d.id][name] = nil
            else
                local row = { name = name, roles = e.roles, level = e.level, class = e.class,
                    members = e.members, pending = e.pending }
                if e.mode == "host" then hosts[#hosts + 1] = row else seekers[#seekers + 1] = row end
            end
        end
        local mineHere = myDungeon and myDungeon.id == d.id
        -- up to the dungeon's top level (above it the loot and XP aren't worth it), and only where your faction can get in
        local fits = me >= d.min - 3 and me <= d.max and not (d.faction and faction and d.faction ~= faction)
        if fits or #hosts > 0 or #seekers > 0 or mineHere or QuestynatorPrepDungeon == d.id then
            table.sort(hosts, function(a, b) return (a.members or 1) > (b.members or 1) end)
            table.sort(seekers, function(a, b) return (a.level or 0) > (b.level or 0) end)
            out[#out + 1] = { id = d.id, name = ns.DungeonName(d.id), min = d.min, max = d.max, d = d,
                              hosts = hosts, seekers = seekers, mine = mineHere, fits = fits }
        end
    end
    table.sort(out, function(a, b)
        if a.mine ~= b.mine then return a.mine end
        local an, bn = #a.hosts + #a.seekers, #b.hosts + #b.seekers
        if an ~= bn then return an > bn end
        return a.min < b.min
    end)
    return out
end

-- drop hosts/seekers whose beacons stopped; true if anything was removed
function ns.PruneDungeons()
    local now, removed = GetTime(), false
    for _, list in pairs(dboard) do
        for name, e in pairs(list) do
            if now - e.t > DUNGEON_TTL then list[name] = nil; removed = true end
        end
    end
    return removed
end

-- everyone hosting or looking (same count as the Dungeons tab shows)
function ns.DungeonActivity()
    ns.PruneDungeons()
    local n = 0
    for _, list in pairs(dboard) do
        for _ in pairs(list) do n = n + 1 end
    end
    return n
end

function ns.JoinDungeon(host, id)
    if TestBlocked("would whisper + to " .. tostring(host)) then return end
    ns.RememberDungeonRequest(id)
    ns.trustInviter = { who = host, t = GetTime() }
    local roles = ns.RolesText(RoleString(ns.MyRoles()))
    local send = (C_ChatInfo and C_ChatInfo.SendAddonMessage) or SendAddonMessage
    send(PREFIX, "DJ|" .. id .. "|" .. RoleString(ns.MyRoles()), "WHISPER", host)    -- exact roles for the host's addon
    SendChatMessage("+ " .. roles, "WHISPER", nil, host)
    Print(string.format(L["Asked %s for an invite."], Ambiguate(host, "none")))
end

function ns.PostDungeon()
    if not myDungeon or myDungeon.mode ~= "host" then return end
    local need = ns.NeedText()
    local msg = "Questynator: LFM [" .. ns.DungeonName(myDungeon.id) .. "]"
        .. (need ~= "" and (" " .. L["need"] .. " " .. need) or "") .. " - /w +"
    if TestBlocked("would post to General: " .. msg) then return end
    local id = ns.GeneralChannel()
    if id then
        ns.lastPost = { text = msg, plain = ns.PlainText(msg), t = GetTime() }
        SendChatMessage(msg, "CHANNEL", nil, id)
        Print(string.format(L["Posted to General chat (/%d)."], id))
    else
        Print(string.format(L["You're not in General chat. Your message: %s"], msg))
    end
end

-- a "+" whisper while I host a dungeon group: invite if there's room
function ns.OnDungeonWhisper(sender, text)
    if not myDungeon or myDungeon.mode ~= "host" then return false end
    -- lost the lead since listing: no invite, no counters, no "Invited" message
    if ns.CheckDungeonLeader() then return true end
    local who = Ambiguate(sender, "none")
    local said = ns.RolesFromText((tostring(text or ""):gsub("^%s*%S+", "")))
    if said ~= "" and not myDungeon.offered[who] then myDungeon.offered[who] = said end
    local count = myDungeon.inviteCount[sender] or 0
    if count < MAX_INVITES and Invite(sender, true) then
        myDungeon.inviteCount[sender] = count + 1
        ns.Alert()
        Print(string.format(L["Invited %s (whispered +) for: %s"], Ambiguate(sender, "none"), ns.DungeonName(myDungeon.id)))
    end
    return true
end

function ns.DungeonWaypoint(id)
    local d = DUNGEON_BY_ID[id]
    if d then ns.Waypoint(d.zone, d.x, d.y, ns.DungeonName(id)) end
end

end
InitializeQuestAndPartyFeatures()

---------------------------------------------------------------------------
-- admin tools: announcements, consented debug info, test mode (used by the private QuestynatorAdmin addon)
---------------------------------------------------------------------------
-- characters allowed to announce and ask for debug info, as chat shows them ("Name Surname" or "Name")
local ADMINS = { ["Bethrayer Forever"] = true, ["Bethrayer"] = true }
ns.ADMINS = ADMINS
function ns.IsAdmin(sender)
    if type(sender) ~= "string" then return false end
    local full = sender:gsub("%-.*$", ""):gsub("^%s+", ""):gsub("%s+$", "")
    return ADMINS[full] == true
end

-- the last few internal errors, for debug reports
ns.errors = {}
function ns.LogError(where, err)
    table.insert(ns.errors, 1, string.format("%s %s: %s", date and date("%H:%M") or "", where, tostring(err)))
    while #ns.errors > 10 do table.remove(ns.errors) end
end

local function SafeText(t)                     -- no links, textures or color codes from the network
    return (tostring(t or ""):gsub("|", "/"):sub(1, 200))
end

local seenAnnounce = {}
function ns.OnAnnounce(sender, text)
    if not ns.IsAdmin(sender) then return end
    local id, body = tostring(text):match("^A|([^|]*)|(.*)$")
    if not id or seenAnnounce[id] then return end
    seenAnnounce[id] = true
    body = SafeText(body)
    if body == "" then return end
    Print("|cffff9933" .. L["Announcement"] .. ":|r " .. body)
    if RaidNotice_AddMessage and RaidWarningFrame and ChatTypeInfo then
        pcall(RaidNotice_AddMessage, RaidWarningFrame, "Questynator: " .. body, ChatTypeInfo.RAID_WARNING)
    end
    if PlaySound and SOUNDKIT and SOUNDKIT.RAID_WARNING then PlaySound(SOUNDKIT.RAID_WARNING, "Master") end
end

-- "a newer version is out": once per session, from other users' hello messages
local function VersionParts(v)
    local a, b, c = tostring(v or ""):match("^(%d+)%.(%d+)%.?(%d*)")
    return tonumber(a) or 0, tonumber(b) or 0, tonumber(c) or 0
end
function ns.IsNewer(theirs, mine)
    local a1, b1, c1 = VersionParts(theirs)
    local a2, b2, c2 = VersionParts(mine)
    if a1 ~= a2 then return a1 > a2 end
    if b1 ~= b2 then return b1 > b2 end
    return c1 > c2
end
local toldNewer = false
function ns.CheckNewer(theirs)
    if toldNewer or type(theirs) ~= "string" or not theirs:match("^%d+%.%d+") then return end
    if ns.IsNewer(theirs, ns.Version()) then
        toldNewer = true
        Print(string.format(L["A newer Questynator (%s) is out. Update on CurseForge."], SafeText(theirs)))
    end
end

-- debug info, sent only after the player clicks Send
function ns.DebugReport()
    local _, class = UnitClass("player")
    local n = 0
    for _ in pairs(seeking) do n = n + 1 end
    local build = GetBuildInfo and select(4, GetBuildInfo()) or "?"
    local parts = {
        "v=" .. ns.Version(), "lang=" .. ((GetLocale and GetLocale()) or "?"), "region=" .. ns.Region(), "client=" .. tostring(build),
        "lvl=" .. tostring(UnitLevel("player")), "class=" .. tostring(class),
        "race=" .. tostring(select(2, UnitRace("player"))),
        "searching=" .. n, "online=" .. ns.OnlineCount(),
        "auto=" .. tostring(DB.autoAccept), "sound=" .. tostring(DB.sound), "chat=" .. tostring(DB.chatScan),
        "range=" .. tostring(DB.levelRange), "stats=" .. tostring(DB.stats.quests) .. "q/" .. tostring(DB.stats.groups) .. "g",
        "channel=" .. tostring(ChannelID() ~= nil), "questie=" .. tostring(QuestieLoader ~= nil),
        "errors=" .. (#ns.errors > 0 and table.concat(ns.errors, " || ") or "none"),
    }
    return (table.concat(parts, "; "):gsub("|", "/"):sub(1, 2000))
end

local function SendWhisperChunks(target, reqId, payload)
    local send = (C_ChatInfo and C_ChatInfo.SendAddonMessage) or SendAddonMessage
    local size, chunks = 200, {}
    for i = 1, #payload, size do chunks[#chunks + 1] = payload:sub(i, i + size - 1) end
    if #chunks == 0 then chunks[1] = "" end
    for i, c in ipairs(chunks) do
        send(PREFIX, string.format("DR|%s|%d|%d|%s", reqId, i, #chunks, c), "WHISPER", target)
    end
end

local asked = {}
function ns.OnAdminWhisper(text, sender)
    local kind, reqId = strsplit("|", text)
    if kind ~= "DQ" or not ns.IsAdmin(sender) or type(reqId) ~= "string" then return end
    if asked[reqId] then return end
    asked[reqId] = true
    if StaticPopupDialogs and StaticPopup_Show then
        StaticPopupDialogs["QUESTYNATOR_DEBUG"] = StaticPopupDialogs["QUESTYNATOR_DEBUG"] or {
            button1 = YES or "Yes", button2 = NO or "No", timeout = 60, whileDead = true, hideOnEscape = true,
            OnAccept = function(_, data) if data then SendWhisperChunks(data.who, data.id, ns.DebugReport()) end end,
        }
        StaticPopupDialogs["QUESTYNATOR_DEBUG"].text =
            L["Questynator admin %s asks for your debug info (version, settings, recent errors). Send it?"]
        StaticPopup_Show("QUESTYNATOR_DEBUG", SafeText(Ambiguate(sender, "none")), nil, { who = sender, id = reqId })
    end
end

-- what the admin addon can call (only exposed when QuestynatorAdmin is installed)
function ns.ExposeAdminAPI()
    local isLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    if not (isLoaded and isLoaded("QuestynatorAdmin")) then return end
    QuestynatorAdminAPI = {
        version = ns.Version,
        setTestMode = function(on) ns.testMode = on and true or false; ns.RequestRefresh() end,
        isTestMode = function() return ns.testMode end,
        inject = function(text, sender) return pcall(OnAddonMessage, PREFIX, text, "CHANNEL", sender) end,
        chat = function(text, sender) return pcall(ns.OnPublicChat, text, sender, "General", nil) end,
        seeking = function()
            local list = {}
            for qid in pairs(seeking) do list[#list + 1] = qid end
            return list
        end,
        questLog = function()
            local list = {}
            for i = 1, C_QuestLog.GetNumQuestLogEntries() do
                local info = C_QuestLog.GetInfo(i)
                if info and not info.isHeader and info.questID and not info.isHidden then
                    list[#list + 1] = { id = info.questID, title = info.title, level = info.level }
                end
            end
            return list
        end,
        errors = function() return ns.errors end,
        isAdmin = ns.IsAdmin,
        UI = ns.UI,
        isNewer = ns.IsNewer,
        report = ns.DebugReport,
        refresh = ns.RequestRefresh,
    }
end

function ns.RequestRefresh()
    if pendingRefresh then return end
    pendingRefresh = true
    C_Timer.After(0, function()
        pendingRefresh = false
        ns.RefreshPlanner()
        local ok, err = pcall(RefreshTracker)
        if not ok then
            if ns.LogError then ns.LogError("tracker", err) end
            if ns.debug then Print("tracker refresh failed: " .. tostring(err)) end
        end
        ok, err = pcall(RefreshPanel)
        if not ok then
            if ns.LogError then ns.LogError("panel", err) end
            if ns.debug then Print("panel refresh failed: " .. tostring(err)) end
        end
    end)
end

local function HookTracker()
    local function hook(obj, fn)
        if type(obj) == "table" and type(obj[fn]) == "function" then
            hooksecurefunc(obj, fn, function() ns.RequestRefresh() end)
            return true
        end
    end
    local any = false
    any = hook(QuestObjectiveTracker, "EndLayout") or any
    any = hook(QuestObjectiveTracker, "Update") or any
    any = hook(ObjectiveTrackerFrame, "Update") or any
    if type(ObjectiveTracker_Update) == "function" then
        hooksecurefunc("ObjectiveTracker_Update", function() ns.RequestRefresh() end)
        any = true
    end
    if not any then
        Print(L["Couldn't hook the objective tracker; use /qn list and /qn find <questID>."])
    end
end

---------------------------------------------------------------------------
-- minimap button (LibDBIcon) + Blizzard's addon compartment
---------------------------------------------------------------------------
local ICON_PATH = "Interface\\AddOns\\Questynator\\Media\\Icon"

local function StopAll()
    for questID in pairs(seeking) do ns.Stop(questID, "search cancelled") end
end

local function FillTooltip(tt)
    tt:AddLine("Questynator")
    ns.AddRouteTooltip(tt)
    for questID, search in pairs(seeking) do
        local peers = CountPeers(search)
        local status = search.listing and L["listed"] or (peers > 0 and string.format(L["%d found"], peers) or L["searching"])
        tt:AddDoubleLine(QuestTitle(questID), status, 1, 1, 1, 0.31, 0.82, 0.77)
    end
    local dungeon = ns.MyDungeon()
    if dungeon then
        local status = dungeon.mode == "host" and L["listed"] or L["searching"]
        tt:AddDoubleLine(ns.DungeonName(dungeon.id), status, 1, 1, 1, 0.31, 0.82, 0.77)
    end
    tt:AddLine("|cffffd100" .. L["Left-click:"] .. "|r " .. L["open Questynator"], 1, 1, 1)
    if next(seeking) then
        tt:AddLine("|cffffd100" .. L["Right-click:"] .. "|r " .. L["stop all quest searches"], 1, 1, 1)
    end
end

local function OnLauncherClick(button)
    if button == "RightButton" then StopAll() else ns.TogglePanel() end
end

function ns.SetupMinimap()
    local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
    local DBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
    if not (LDB and DBIcon) then return end
    ns.launcher = LDB:NewDataObject("Questynator", {
        type = "launcher",
        text = "Questynator",
        icon = ICON_PATH,
        OnClick = function(_, button) OnLauncherClick(button) end,
        OnTooltipShow = FillTooltip,
    })
    DBIcon:Register("Questynator", ns.launcher, DB.minimap)
end

function ns.ToggleMinimap()
    local DBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
    DB.minimap.hide = not DB.minimap.hide
    if DBIcon then
        if DB.minimap.hide then DBIcon:Hide("Questynator") else DBIcon:Show("Questynator") end
    end
    Print(DB.minimap.hide and L["Minimap button hidden (/qn minimap to show)"] or L["Minimap button shown"])
end

---------------------------------------------------------------------------
-- options (Interface > AddOns > Questynator), compass switch-off, What's new
---------------------------------------------------------------------------
do
local function IsLoaded(name)
    local f = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    return f and f(name) and true or false
end

-- every setting that used to be slash-only; get/set keep the old saved keys
ns.OPTIONS = {
    { key = "arrow",      section = "Features",  label = "Directions arrow (quest compass)" },
    { key = "partyChat",  section = "Features",  label = "Party chat messages (objectives done, quest completed)" },
    { key = "autoAccept", section = "Features",  label = "Auto-accept invites from matched players" },
    { key = "chatScan",   section = "Features",  label = "Chat scanner (find players looking for groups in chat)" },
    { key = "reminders",  section = "Features",  label = "Smart reminders for quests, rewards, groups, and treasures" },
    { key = "minimap",    section = "Interface", label = "Minimap button" },
    { key = "planner",    section = "Interface", label = "Show Route Planner" },
    { key = "sound",      section = "Interface", label = "Sound alerts" },
}

function ns.GetOption(key)
    if key == "reminders" then return DB.reminders ~= false end
    if key == "planner" then return not DB.plannerHidden end
    if key == "minimap" then return not (DB.minimap and DB.minimap.hide) end
    if key == "arrow" then return DB.arrow ~= false end
    return DB[key] and true or false
end

function ns.SetOption(key, on)
    on = on and true or false
    if key == "planner" then
        ns.ShowPlanner(on)
    elseif key == "minimap" then
        if type(DB.minimap) ~= "table" then DB.minimap = {} end
        DB.minimap.hide = not on
        local DBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
        if DBIcon then
            if on then pcall(DBIcon.Show, DBIcon, "Questynator") else pcall(DBIcon.Hide, DBIcon, "Questynator") end
        end
    else
        DB[key] = on
    end
    if key == "arrow" then
        if on then pcall(ns.ArrowUndismiss) end
        pcall(ns.ArrowRefresh)
    end
    if key == "reminders" then ns.StartSmartReminders() end
    if ns.RefreshOptionViews then pcall(ns.RefreshOptionViews) end
end

-- once, on the first login with this version: people who already have TomTom or Questie get the arrow off
function ns.ArrowAutoOff()
    if DB.arrowAutoChecked then return false end
    DB.arrowAutoChecked = true
    local found
    for _, n in ipairs({ "TomTom", "Questie" }) do
        if IsLoaded(n) then found = n; break end
    end
    if found and DB.arrow ~= false then
        DB.arrow = false
        Print(string.format(L["Quest arrow is off because you use %s. Turn it on with /qn arrow or in Interface > AddOns > Questynator."], found))
        return true
    end
    return false
end

-- compass right-click menu
local menu
function ns.ArrowMenuAction(kind)
    if menu then menu:Hide() end
    if kind == "off" then
        ns.SetOption("arrow", false)
        Print(L["Quest arrow turned off. Turn it back on with /qn arrow or in Interface > AddOns > Questynator."])
    else
        ns.ArrowDismiss()
    end
end

function ns.ShowArrowMenu(owner)
    local UI = ns.UI
    if not menu then
        menu = CreateFrame("Frame", "QuestynatorArrowMenu", UIParent)
        menu:SetSize(190, 70)
        menu:SetFrameStrata("DIALOG")
        menu:SetClampedToScreen(true)
        UI.Flat(menu, UI.C.bg, UI.C.line)
        local hide = UI.Button(menu, 174, 24, "ghost")
        hide:SetPoint("TOP", 0, -8)
        hide:SetText(L["Hide until next quest"])
        hide:SetScript("OnClick", function() ns.ArrowMenuAction("hide") end)
        local off = UI.Button(menu, 174, 24, "danger")
        off:SetPoint("TOP", hide, "BOTTOM", 0, -6)
        off:SetText(L["Turn off the arrow"])
        off:SetScript("OnClick", function() ns.ArrowMenuAction("off") end)
        menu:EnableMouse(true)
        menu:SetScript("OnShow", function(self) self.shownAt = GetTime() end)
        menu:SetScript("OnUpdate", function(self)
            -- closes by itself when the mouse has been away for a moment
            if self:IsMouseOver() or (owner and owner:IsMouseOver()) then self.awayAt = nil
            elseif not self.awayAt then self.awayAt = GetTime()
            elseif GetTime() - self.awayAt > 1.5 then self:Hide() end
        end)
    end
    menu:ClearAllPoints()
    menu:SetPoint("TOP", owner, "BOTTOM", 0, -4)
    menu.awayAt = nil
    menu:Show()
end

---------------------------------------------------------------------------
-- What's new: same plain text as the CurseForge changelog, newest first
---------------------------------------------------------------------------
-- the first entry is the version you are running (v = nil means "this version")
ns.CHANGELOG = {
    { v = nil, lines = {
        "The Route Planner opens compact with your next action. Click More for up to three actions, Snooze stop, and Undo. Its main button pauses and resumes the route.",
        "Speak-to quests become route stops at their NPC, a replan keeps your current task first, and the Quests tab's Skip button is now Snooze stop.",
        "Stop hosting keeps a quest search you started before hosting. Translated clients keep compass guidance after you finish one objective.",
        "Reward Hunting, Dungeon Prep, hosting, reminders, and the planner are translated into German, French, Spanish, and Russian.",
    } },
    { v = "1.6.2", lines = {
        "Get a one-click invite request when a group has room for an unfinished quest in your log.",
        "Use Host LFG in the planner or main window to host the selected quest. Stop hosting from the same button. Pending invites now reserve seats across quest and dungeon hosting.",
        "Near a quest turn-in, see a usable equipment reward and pin its NPC. After a turn-in, get a pin for a newly available follow-up in your zone.",
    } },
    { v = "1.6.1", lines = {
        "Smart reminders offer nearby treasure and dungeon quest pickups while you play. Pin the giver directly from the reminder.",
        "When preparing for Scarlet Monastery, route to missing pickups or request a share directly from a party member. Dismiss a reminder for 30 minutes, or disable reminders in Options.",
    } },
    { v = "1.6.0", lines = {
        "Open Dungeons and click Prep beside Scarlet Monastery to see your dungeon quests, missing prerequisites, and known equipment rewards.",
        "Pin a pickup or route through the available quest givers across zones. Your saved reward pursuit resumes afterward.",
        "Request share whispers a party member whose Questynator reports that they can share the quest.",
    } },
    { v = "1.5.3", lines = {
        "The compass labels a selected quest. Resume route returns you to your planned stop.",
        "Snooze a stop until you leave the zone. Use Undo snooze to restore it, even after a reload.",
        "Pins identify pickups, objectives, and turn-ins. Reward pins now match the pursuit destination.",
        "Hover over rewards to compare equipped gear and see the remaining quest count. Empty zone searches can expand to all zones with the same filters.",
        "Related tabs now sit together. The compass handles overlapping mob names and waits for confirmation before showing a turn-in.",
        "Quest listings withdraw after leadership changes, dungeon roles account for flexible hosts, and idle XP expires from the hourly estimate.",
    } },
    { v = "1.5.0", lines = {
        "Open Reward Hunting after Treasures or type /qn rewards to search 1,120 quest rewards for your character.",
        "Current zone shows rewards with a local pickup, unfinished objective, or turn-in. Turn it off to browse all zones.",
        "Filter by Weapon, Armor, Jewelry, or Trinkets. All weapon types opens inside the window. Armor follows your class and level.",
        "Ready turn-ins appear first. Pin a quest pickup or pursue a reward chain across zones with the Route Planner.",
        "All 18 Treasures entries now show their actual reward item icons.",
        "Quest availability and follow-up suggestions now recognize Alliance and Horde Skyborne restrictions.",
    } },
    { v = "1.4.0", lines = {
        "Quest Routes builds up to ten stops in your current zone from quest objectives, turn-ins, and eligible pickups within 300 yards.",
        "The route starts on login or reload. It replans as quests and objectives change, when you enter a new zone, and when you level up.",
        "The floating Route Planner shows the next three actions. Click Pin beside an action to mark its location, even when several tasks share a stop.",
        "Show or hide the window under Options > AddOns > Questynator, or type /qn planner. Its position and visibility are saved.",
        "The compass follows the quest selected in the objective tracker. Clear the selection to follow the route again.",
        "Hover over the minimap button for the current stop, distance when available, objective counts, and active searches.",
        "The planner checks quest completion before suggesting pickups and includes the Lost Journal that starts The Adventurer.",
        "Fixed quest searches and sharing treating a quest as active when the client returns a log index of zero.",
    } },
    { v = "1.3.1", lines = {
        "Two players who both created a group for the same quest now end up in one group instead of waiting on each other",
        "Invites are only accepted automatically from players whose level range and objectives match yours, while you're still searching",
        "A declined or cancelled invite can no longer be accepted later by mistake",
        "Dungeon hosting stops when you're no longer the group leader, instead of trying to invite",
        "Dungeon groups and players that went quiet now drop off the Dungeons tab on their own",
        "The window only redraws the tab you're looking at, so it's lighter while you search",
    } },
    { v = "1.3.0", lines = {
        "New Treasures tab: every bag quest and the Cozy Sleeping Bag for your character, what you already have, and where to go next",
        "Treasure quests get a gold tag in the Zones tab",
        "Wider window; Stats, About and settings moved behind the small chart icon at the top",
        "New Zones tab: every quest you can pick up now in the zones that fit your level, where to get it, quest chains, and a short guide",
        "Elite quests in the Zones tab have Find group, so you can gather people before you even pick the quest up",
        "Every quest in the Zones tab shows its XP, with a waypoint button and a ! button for the guide",
        "Dungeons tab lists only the dungeons that fit your level and faction",
        "Tank, Healer and DPS buttons use the role icons",
        "Quest arrow: right-click it to hide it until your next quest, or to turn it off",
        "Quest arrow: hover it to see how it works",
        "Quest arrow starts off if you already use TomTom or Questie (turn it on any time)",
        "New options page: Interface > AddOns > Questynator, with every setting in one place",
        "Quick settings on the Stats tab: quest arrow, party messages, sound",
        "This What's new window after each update",
    } },
    { v = "1.2.5", lines = {
        "New look: dark and flat with one teal accent, rounded corners and the Poppins font",
        "Search box on the Quests tab, tabs with live counts, XP, gold and reputation chips",
        "Quest arrow: points to the turn-in of finished quests, or to the next objective of the quest you select",
        "Party messages when all objectives are done and when a quest is turned in, with clickable quest links",
        "More accurate turn-in locations",
    } },
    { v = "1.2.0", lines = {
        "Dungeon finder with roles: look for a group or host one, the LFM text updates itself",
        "See your party's progress on each quest, and share quests with one click",
        "Clickable locations set a waypoint, quest chains show what comes next",
        "Popular near you, XP per hour and time to level",
        "Thank your party with kudos, weekly top helpers",
    } },
}

function ns.WhatsNewText()
    local out = {}
    for i, e in ipairs(ns.CHANGELOG) do
        local v = e.v or ns.Version()
        out[#out + 1] = (i == 1 and "|cff4fd1c5" or "|cffe8e6e3") .. "Questynator " .. v .. "|r"
        for _, line in ipairs(e.lines) do out[#out + 1] = "|cff5b606b-|r  " .. line end
        out[#out + 1] = " "
    end
    return table.concat(out, "\n")
end

function ns.WhatsNewShouldShow()
    return DB.whatsNewSkip ~= ns.Version()
end

function ns.SetWhatsNewSkip(on)
    DB.whatsNewSkip = on and ns.Version() or nil
end

local whatsNew
function ns.ShowWhatsNew()
    local UI = ns.UI
    local C = UI.C
    if not whatsNew then
        local f = UI.Window("QuestynatorWhatsNew", 460, 440)
        f:SetPoint("CENTER", 0, 40)
        f:SetFrameStrata("DIALOG")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        UI.Font(f.TitleText, 14, nil, "bold")
        f.TitleText:SetText(L["What's new in Questynator"])
        local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 14, -40)
        scroll:SetPoint("BOTTOMRIGHT", -32, 52)
        UI.SkinScroll(scroll)
        local child = CreateFrame("Frame", nil, scroll)
        child:SetSize(400, 10)
        scroll:SetScrollChild(child)
        f.text = UI.Text(child, 11, "text")
        f.text:SetPoint("TOPLEFT", 2, 0)
        f.text:SetWidth(396)
        f.text:SetJustifyH("LEFT")
        if f.text.SetSpacing then f.text:SetSpacing(4) end
        f.child = child

        -- [ ] Don't show until next update
        local box = CreateFrame("Button", nil, f)
        box:SetSize(16, 16)
        box:SetPoint("BOTTOMLEFT", 16, 18)
        UI.Flat(box, C.dark, C.line)
        box.mark = box:CreateTexture(nil, "ARTWORK")
        box.mark:SetPoint("TOPLEFT", 4, -4)
        box.mark:SetPoint("BOTTOMRIGHT", -4, 4)
        box.mark:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
        local label = UI.Text(f, 11, "muted")
        label:SetPoint("LEFT", box, "RIGHT", 8, 0)
        label:SetText(L["Don't show until next update"])
        local function paint() box.mark:SetShown(f.skip and true or false) end
        box:SetScript("OnClick", function() f.skip = not f.skip; paint() end)
        f.box, f.paint = box, paint

        local ok = UI.Button(f, 90, 24, "primary")
        ok:SetPoint("BOTTOMRIGHT", -14, 14)
        ok:SetText(L["Got it"])
        ok:SetScript("OnClick", function() f:Hide() end)
        f:SetScript("OnHide", function() ns.SetWhatsNewSkip(f.skip) end)
        if UISpecialFrames then tinsert(UISpecialFrames, "QuestynatorWhatsNew") end
        whatsNew = f
    end
    whatsNew.skip = not ns.WhatsNewShouldShow()
    whatsNew.paint()
    whatsNew.text:SetText(ns.WhatsNewText())
    whatsNew.child:SetHeight((tonumber(whatsNew.text:GetStringHeight()) or 300) + 10)
    whatsNew:Show()
end

---------------------------------------------------------------------------
-- Interface > AddOns > Questynator
---------------------------------------------------------------------------
local optionsPanel, optionsCategory
local SECTION_TITLE = { Features = "Features", Interface = "Interface" }

function ns.BuildOptionsPanel()
    if optionsPanel then return optionsPanel end
    local UI = ns.UI
    local p = CreateFrame("Frame", "QuestynatorOptionsPanel")
    p.name = "Questynator"
    p.checks = {}
    local title = UI.Text(p, 18, "text", nil, "bold")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("QUESTYNATOR")
    local ver = UI.Text(p, 11, "dim")
    ver:SetPoint("BOTTOMLEFT", title, "BOTTOMRIGHT", 8, 2)
    ver:SetText("v" .. ns.Version())
    local y = -52
    local lastSection
    for _, o in ipairs(ns.OPTIONS) do
        if o.section ~= lastSection then
            lastSection = o.section
            y = y - 8
            local h = UI.Text(p, 11, "accent", nil, "bold")
            h:SetPoint("TOPLEFT", 16, y)
            h:SetText(L[SECTION_TITLE[o.section]]:upper())
            y = y - 22
        end
        local cb = CreateFrame("CheckButton", nil, p, "UICheckButtonTemplate")
        cb:SetSize(24, 24)
        cb:SetPoint("TOPLEFT", 14, y)
        cb.key = o.key
        local text = UI.Text(p, 12, "text")
        text:SetPoint("LEFT", cb, "RIGHT", 6, 0)
        text:SetText(L[o.label])
        cb:SetScript("OnClick", function(self) ns.SetOption(self.key, self:GetChecked()) end)
        p.checks[#p.checks + 1] = cb
        y = y - 28
    end
    y = y - 10
    local h = UI.Text(p, 11, "accent", nil, "bold")
    h:SetPoint("TOPLEFT", 16, y)
    h:SetText(L["Shortcuts"]:upper())
    y = y - 26
    local x = 16
    for _, b in ipairs({
        { L["Open Questynator"], function() ns.ShowPanel() end },
        { L["Dungeons"], function() ns.ShowPanel(); ns.SelectTab(4) end },
        { L["Thank your party"], function() ns.ThankParty() end },
        { L["What's new"], function() ns.ShowWhatsNew() end },
    }) do
        local btn = UI.Button(p, 10, 24, "ghost")
        btn:SetText(b[1])
        btn:SetWidth((tonumber(btn.label:GetStringWidth()) or 80) + 26)
        btn:SetPoint("TOPLEFT", x, y)
        btn:SetScript("OnClick", b[2])
        x = x + (tonumber(btn:GetWidth()) or 100) + 8
    end
    y = y - 44
    local about = UI.Text(p, 11, "muted")
    about:SetPoint("TOPLEFT", 16, y)
    about:SetWidth(560)
    about:SetJustifyH("LEFT")
    about:SetText(ns.AuthorLine() .. "\n" .. "BattleTag " .. AUTHOR.battletag .. "    " .. L["Bugs & ideas: CurseForge"])
    local function refresh()
        for _, cb in ipairs(p.checks) do cb:SetChecked(ns.GetOption(cb.key)) end
    end
    p.refresh = refresh
    p:SetScript("OnShow", refresh)
    -- the Settings canvas asks for these
    p.OnCommit = function() end
    p.OnDefault = function() end
    p.OnRefresh = refresh
    p.okay, p.cancel, p.default = function() end, function() end, function() end
    optionsPanel = p
    return p
end

function ns.RegisterOptions()
    local p = ns.BuildOptionsPanel()
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        optionsCategory = Settings.RegisterCanvasLayoutCategory(p, "Questynator")
        Settings.RegisterAddOnCategory(optionsCategory)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(p)
    end
end

function ns.OpenOptions()
    if optionsCategory and Settings and Settings.OpenToCategory then
        local id = optionsCategory.GetID and optionsCategory:GetID() or optionsCategory.ID
        Settings.OpenToCategory(id)
    elseif InterfaceOptionsFrame_OpenToCategory and optionsPanel then
        InterfaceOptionsFrame_OpenToCategory(optionsPanel)
        InterfaceOptionsFrame_OpenToCategory(optionsPanel)      -- twice: the first call only opens the frame
    end
end

function ns.RefreshOptionViews()
    if optionsPanel and optionsPanel:IsShown() then optionsPanel.refresh() end
    if ns.RefreshQuickSettings then ns.RefreshQuickSettings() end
end
end

-- named in the .toc (AddonCompartmentFunc*)
function Questynator_OnCompartmentClick(_, button)
    OnLauncherClick(type(button) == "string" and button or "LeftButton")
end
function Questynator_OnCompartmentEnter(_, frame)
    GameTooltip:SetOwner(frame or UIParent, "ANCHOR_LEFT")
    FillTooltip(GameTooltip)
    GameTooltip:Show()
end
function Questynator_OnCompartmentLeave()
    GameTooltip:Hide()
end

---------------------------------------------------------------------------
-- slash commands
---------------------------------------------------------------------------
do
    local picker

    function ns.HostedQuest()
        local first
        for id, search in pairs(seeking) do
            if search.listing and (not first or id < first) then first = id end
        end
        return first
    end

    local function CanHost()
        return MyState() ~= 1 and not (IsInRaid and IsInRaid())
            and (not IsInGroup() or GetNumGroupMembers() < MAX_PARTY)
    end

    local function Eligible(id)
        return id and ns.QuestLogIndex(id) and ns.QuestState(id) == "inlog" and not ns.IsReadyToTurnIn(id)
    end

    local function Selected()
        local id = C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID and C_SuperTrack.GetSuperTrackedQuestID()
        return Eligible(id) and id or nil
    end

    function ns.MakeHostButton(parent)
        local b = ns.UI.Button(parent, 94, 22, "outline")
        b:SetMotionScriptsWhileDisabled(true)
        b:SetScript("OnClick", function() ns.ToggleQuestHost() end)
        b:SetScript("OnEnter", ns.UI.ShowTip)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        return b
    end

    function ns.PaintHostButton(b)
        local hosted = ns.HostedQuest()
        local target = hosted or Selected()
        local context = target and QuestTitle(target) or L["From your quest log"]
        local enabled = hosted or CanHost()
        if not enabled then context = L["Requires leadership and a free slot"] end
        local kind = hosted and "soft" or "outline"
        if b.kind ~= kind then b:SetKind(kind) end
        b:SetText(hosted and L["Stop hosting"] or L["Host LFG"])
        b.tip = hosted and string.format(L["Stop hosting %s."], context)
            or (target and enabled and string.format(L["Host a group for %s."], context) or context)
        if enabled then b:Enable() else b:Disable() end
        return hosted, context
    end

    function ns.QuickHostQuest(id)
        if not CanHost() then Print(L["Hosting requires a free party slot and group leadership."]); return end
        if not Eligible(id) then Print(L["Choose an unfinished quest in your log."]); return end
        if seeking[id] and seeking[id].listing then return end
        if not seeking[id] then
            ns.Start(id)
            if seeking[id] then seeking[id].quickHost = true end
        end
        local level = UnitLevel("player")
        ns.CreateListing(id, { min = math.max(1, level - DB.levelRange), max = level + DB.levelRange,
            want = ns.NeedMask(id), autoInvite = true })
        ns.RefreshPlanner()
    end

    local function ShowChoices(ids)
        if not picker then
            picker = ns.UI.Window("QuestynatorHostPicker", 320, 194)
            picker:SetPoint("CENTER")
            picker:SetFrameStrata("FULLSCREEN_DIALOG")
            picker:SetToplevel(true)
            picker:SetClampedToScreen(true)
            if UISpecialFrames then tinsert(UISpecialFrames, "QuestynatorHostPicker") end
            picker.TitleText:SetText(L["Choose a quest to host"])
            picker.CloseButton:SetScript("OnClick", function() picker:Hide() end)
            picker.rows = {}
            for i = 1, 5 do
                local button = ns.UI.Button(picker, 296, 23, "outline")
                button:SetPoint("TOPLEFT", 12, -32 - (i - 1) * 25)
                button.label:ClearAllPoints()
                button.label:SetPoint("LEFT", 9, 0)
                button.label:SetWidth(274)
                button.label:SetJustifyH("LEFT")
                button.label:SetWordWrap(false)
                button:SetScript("OnEnter", ns.UI.ShowTip)
                button:SetScript("OnLeave", function() GameTooltip:Hide() end)
                button:SetScript("OnClick", function(self)
                    picker:Hide()
                    ns.QuickHostQuest(self.id)
                end)
                picker.rows[i] = button
            end
            picker.prev = ns.UI.Button(picker, 80, 21, "ghost")
            picker.prev:SetPoint("BOTTOMLEFT", 12, 9)
            picker.prev:SetText(L["Previous"])
            picker.next = ns.UI.Button(picker, 80, 21, "ghost")
            picker.next:SetPoint("BOTTOMRIGHT", -12, 9)
            picker.next:SetText(L["Next"])
            function picker:Page(start)
                self.start = start
                for i, row in ipairs(self.rows) do
                    row.id = self.ids[start + i - 1]
                    row:SetShown(row.id ~= nil)
                    if row.id then
                        row.tip = QuestTitle(row.id)
                        row:SetText(row.tip)
                    end
                end
                self.prev:SetShown(start > 1)
                self.next:SetShown(start + #self.rows <= #self.ids)
                self:SetHeight(40 + math.min(#self.ids, #self.rows) * 25 + (#self.ids > #self.rows and 29 or 0))
            end
            picker.prev:SetScript("OnClick", function() picker:Page(picker.start - #picker.rows) end)
            picker.next:SetScript("OnClick", function() picker:Page(picker.start + #picker.rows) end)
        end
        picker.ids = ids
        picker:Page(1)
        picker:Show()
        picker:Raise()
    end

    function ns.ToggleQuestHost()
        local hosted = ns.HostedQuest()
        if hosted then
            ns.WithdrawListing(hosted)
            ns.RefreshPlanner()
            return
        end
        if not CanHost() then Print(L["Hosting requires a free party slot and group leadership."]); return end
        local tracked = Selected()
        if tracked then ns.QuickHostQuest(tracked); return end
        local ids = {}
        for i = 1, C_QuestLog.GetNumQuestLogEntries() do
            local info = C_QuestLog.GetInfo(i)
            if info and not info.isHeader and not info.isHidden and Eligible(info.questID) then ids[#ids + 1] = info.questID end
        end
        if #ids > 1 then ShowChoices(ids)
        elseif #ids == 1 then ns.QuickHostQuest(ids[1])
        else Print(L["Choose an unfinished quest in your log."]) end
    end
end

local function ListQuests()
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader then
            Print(string.format("%d  %s%s", info.questID, info.title or "?", seeking[info.questID] and "  (searching)" or ""))
        end
    end
end

local function Probe(questID)
    Print("Native Blizzard quest-group API on this client:")
    for _, fn in ipairs({ "CanCreateQuestGroup", "SetSearchToQuestID", "GetActivityIDForQuestID", "CreateListing", "Search" }) do
        Print("  C_LFGList." .. fn .. ": " .. tostring(C_LFGList and C_LFGList[fn] ~= nil))
    end
    Print("  LFGListUtil_FindQuestGroup: " .. tostring(_G.LFGListUtil_FindQuestGroup ~= nil))
    if questID and C_LFGList and C_LFGList.CanCreateQuestGroup then
        local ok, res = pcall(C_LFGList.CanCreateQuestGroup, questID)
        Print("  CanCreateQuestGroup(" .. questID .. ") -> " .. tostring(ok) .. ", " .. tostring(res))
    end
end

local function Debug()
    ns.debug = true
    Print("interface " .. tostring(select(4, GetBuildInfo())) .. ", channel id " .. tostring(ChannelID()))
    local m = QuestObjectiveTracker
    Print("QuestObjectiveTracker: " .. type(m) .. ", usedBlocks: " .. type(m and m.usedBlocks))
    local n = 0
    for _ in pairs(buttons) do n = n + 1 end
    Print("buttons created: " .. n)
    ns.RequestRefresh()
end

SLASH_QUESTYNATOR1, SLASH_QUESTYNATOR2 = "/questynator", "/qn"
SlashCmdList.QUESTYNATOR = function(msg)
    local cmd, arg = strsplit(" ", (msg or ""):lower(), 2)
    local id = tonumber(arg)
    if cmd == "find" and id then ns.Toggle(id)
    elseif cmd == "host" then ns.ToggleQuestHost()
    elseif cmd == "list" then ListQuests()
    elseif cmd == "auto" then
        DB.autoAccept = not DB.autoAccept
        Print(string.format(L["Auto-accept invites from matched players: %s"], DB.autoAccept and L["on"] or L["off"]))
    elseif cmd == "probe" then Probe(id)
    elseif cmd == "debug" then Debug()
    elseif cmd == "status" then
        local any
        for questID, s in pairs(seeking) do
            any = true
            Print(string.format("%s: %d peer(s)", QuestTitle(questID), CountPeers(s)))
            for name, p in pairs(s.peers) do
                Print(string.format("   %s  lvl %d  %s%s", name, p.level,
                    p.state == 2 and "leader" or (p.state == 1 and "in group" or "solo"), p.host and "  (hosting)" or ""))
            end
        end
        if not any then Print(L["Not searching"]) end
    elseif cmd == "" or cmd == "panel" then ns.TogglePanel()
    elseif cmd == "planner" then ns.SetOption("planner", not ns.GetOption("planner"))
    elseif cmd == "snooze" then ns.SnoozeRouteStop(false)
    elseif cmd == "undo" then ns.SnoozeRouteStop(true)
    elseif cmd == "minimap" then ns.ToggleMinimap()
    elseif cmd == "chat" then
        DB.chatScan = not DB.chatScan
        Print(string.format(L["Chat scanner: %s"], DB.chatScan and L["on"] or L["off"]))
    elseif cmd == "sound" then
        DB.sound = not DB.sound
        Print(string.format(L["Sound alerts: %s"], DB.sound and L["on"] or L["off"]))
    elseif cmd == "arrowdebug" then ns.ArrowDebug()
    elseif cmd == "arrow" then
        DB.arrow = not (DB.arrow ~= false)
        Print(string.format(L["Turn-in arrow: %s"], DB.arrow and L["on"] or L["off"]))
        ns.ArrowUndismiss()
        ns.ArrowRefresh()
    elseif cmd == "partychat" or cmd == "party" then
        DB.partyChat = not DB.partyChat
        Print(string.format(L["Party chat messages: %s"], DB.partyChat and L["on"] or L["off"]))
    elseif cmd == "about" then ns.PrintAbout(); ns.ShowCopyBattleTag()
    elseif cmd == "thanks" or cmd == "thank" then ns.ThankParty()
    elseif cmd == "dungeon" or cmd == "dungeons" then ns.ShowPanel(); ns.SelectTab(4)
    elseif cmd == "rewards" then ns.ShowPanel(); ns.SelectTab(8)
    elseif cmd == "version" then
        Print("Questynator " .. ns.Version())
    elseif cmd == "stats" then
        Print(L["Quests done with Questynator groups:"] .. " " .. DB.stats.quests .. "  -  " .. L["Groups formed:"] .. " " .. DB.stats.groups)
    elseif cmd == "online" then
        Print(string.format(L["Questynator users online: %d"], ns.OnlineCount()) .. " " .. L["(your realm and faction)"])
    else
        Print("/qn (open the window) | planner | dungeons | arrow | thanks | partychat | about | minimap | chat | sound | online | stats | list | find <questID> | status | auto | probe [questID] | debug")
    end
end

-- take /lfg only if no other addon (e.g. LFG Forever) already uses it
function ns.ClaimLFG()
    for key in pairs(SlashCmdList) do
        for i = 1, 10 do
            local cmd = _G["SLASH_" .. key .. i]
            if not cmd then break end
            if type(cmd) == "string" and cmd:lower() == "/lfg" then
                ns.lfgOwner = key
                return false
            end
        end
    end
    SLASH_QUESTYNATOR_LFG1 = "/lfg"
    SlashCmdList.QUESTYNATOR_LFG = SlashCmdList.QUESTYNATOR
    ns.hasLFG = true
    return true
end

---------------------------------------------------------------------------
-- events
---------------------------------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        if (...) ~= ADDON_NAME then return end
        QuestynatorDB = QuestynatorDB or {}
        DB = QuestynatorDB
        for k, v in pairs(DEFAULTS) do
            if DB[k] == nil then DB[k] = (type(v) == "table") and CopyTable and CopyTable(v) or v end
        end
        if type(DB.minimap) ~= "table" then DB.minimap = { hide = false } end
        if type(DB.collapsed) ~= "table" then DB.collapsed = {} end
        if type(DB.stats) ~= "table" then DB.stats = {} end
        DB.stats.quests = tonumber(DB.stats.quests) or 0
        DB.stats.groups = tonumber(DB.stats.groups) or 0
        f:UnregisterEvent("ADDON_LOADED")
        for _, e in ipairs({ "PLAYER_LOGIN", "CHAT_MSG_ADDON", "PARTY_INVITE_REQUEST", "GROUP_ROSTER_UPDATE",
                             "QUEST_REMOVED", "QUEST_TURNED_IN", "QUEST_LOG_UPDATE", "QUEST_WATCH_LIST_CHANGED",
                             "CHAT_MSG_WHISPER", "CHAT_MSG_CHANNEL", "CHAT_MSG_GUILD", "PLAYER_ENTERING_WORLD",
                             "PLAYER_XP_UPDATE", "PLAYER_LEVEL_UP", "ZONE_CHANGED_NEW_AREA" }) do
            f:RegisterEvent(e)
        end
    elseif event == "PLAYER_LOGIN" then
        if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
            C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
        end
        -- keep the channel's join/leave notices out of the chat window
        ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_NOTICE", function(_, _, ...)
            local ok, hit = pcall(function(...)
                local base, str = select(9, ...), select(4, ...)
                return base == CHANNEL or (type(str) == "string" and str:find(CHANNEL, 1, true) ~= nil)
            end, ...)
            return ok and hit or false
        end)
        HookTracker()
        ns.ClaimLFG()
        pcall(ns.SetupMinimap)
        pcall(ns.SetupTooltipTag)
        pcall(ns.ExposeAdminAPI)
        pcall(f.RegisterEvent, f, "SUPER_TRACKING_CHANGED")
        -- optional events: not every client has them
        pcall(f.RegisterEvent, f, "PARTY_INVITE_CANCEL")
        pcall(f.RegisterEvent, f, "PARTY_LEADER_CHANGED")
        -- a declined invite must not be accepted later by a late beacon
        if type(DeclineGroup) == "function" and hooksecurefunc then
            pcall(hooksecurefunc, "DeclineGroup", function() ns.ClearPendingInvite() end)
        end
        pcall(ns.OnXPChange)
        pcall(ns.CheckQuestDone)
        pcall(ns.CacheTitles)
        pcall(ns.ArrowAutoOff)
        if not DB.plannerHidden then ns.ShowPlanner(true) end
        pcall(ns.ArrowRefresh)
        pcall(ns.RegisterOptions)
        C_Timer.After(5, function()
            if ns.WhatsNewShouldShow() then pcall(ns.ShowWhatsNew) end
        end)
        wasGrouped = IsInGroup()
        if wasGrouped then ns.SchedulePartySync(true) end
        ns.RequestRefresh()
    elseif event == "CHAT_MSG_ADDON" then
        OnAddonMessage(...)
    elseif event == "PARTY_INVITE_REQUEST" then
        OnPartyInvite((...))
    elseif event == "CHAT_MSG_WHISPER" then
        OnWhisper(...)
    elseif event == "CHAT_MSG_CHANNEL" then
        local text, sender = ...
        pcall(ns.OnPublicChat, text, sender, (select(9, ...)), (select(12, ...)))
    elseif event == "CHAT_MSG_GUILD" then
        local text, sender = ...
        pcall(ns.OnPublicChat, text, sender, nil, (select(12, ...)))
    elseif event == "PLAYER_ENTERING_WORLD" then
        ns.StartSmartReminders()
        ns.StartInitialRoute(true)
        -- join the hidden channel after the default channels, so General keeps its number
        if not ns.presenceStarted then
            ns.presenceStarted = true
            C_Timer.After(10, ns.StartPresence)
        end
    elseif event == "GROUP_ROSTER_UPDATE" or event == "PARTY_LEADER_CHANGED" then
        OnGroupUpdate()
    elseif event == "PARTY_INVITE_CANCEL" then
        ns.ClearPendingInvite()
    elseif event == "QUEST_REMOVED" or event == "QUEST_TURNED_IN" then
        local questID = (...)
        if event == "QUEST_TURNED_IN" then
            ns.RecordQuestTurnIn(questID)
            ns.QueueRouteReplan(questID)
            pcall(ns.AnnounceTurnIn, questID, ns.titleCache and ns.titleCache[questID])
            ns.OnQuestTurnedIn()
        end
        if seeking[questID] then ns.Stop(questID, "quest left your log") end
        pcall(ns.ArrowRefresh)
        ns.RequestRefresh()
    elseif event == "SUPER_TRACKING_CHANGED" then
        pcall(ns.ArrowUndismiss)          -- picking a quest brings a hidden arrow back
        pcall(ns.ArrowRefresh)
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        ns.QueueRouteReplan()
    elseif event == "PLAYER_XP_UPDATE" or event == "PLAYER_LEVEL_UP" then
        pcall(ns.OnXPChange)
        if event == "PLAYER_LEVEL_UP" then ns.QueueRouteReplan() end
        ns.RequestRefresh()
    else -- QUEST_LOG_UPDATE / QUEST_WATCH_LIST_CHANGED
        if event == "QUEST_LOG_UPDATE" then ns.StartInitialRoute() end
        if IsInGroup() then ns.SchedulePartySync() end
        pcall(ns.CheckQuestDone)
        pcall(ns.CacheTitles)
        pcall(ns.ArrowRefresh)
        ns.RequestRefresh()
    end
end)
