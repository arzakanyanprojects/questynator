# Questynator 1.7.0

## Starter guides
- **Quest guides for all seven starting areas, levels 1 to 6:** Northshire, Coldridge Valley, Shadowglen, Valley of Trials, Camp Narache, Deathknell and Zephras Isle.
- A new character is offered the guide for its starting area, or can pick another one. Open the guides any time with **Guides** in the Route Planner or `/qn guide`.
- The guide leads the Route Planner through every quest in order: pickups, objectives and turn-ins, including your class quests. It's named in the planner with a **Stop** button and a bar for its trips, and the normal route takes over when the guide ends.

## Route Planner
- **New look.** The current task is a card with the quest badge (**!** pickup, **?** turn-in, a dot for objectives), what to do and how far, who to see, level and XP, and **Pin** and **Snooze**. The next tasks sit under it; click one to mark it on the map.
- A pin you set on a route step moves on to the next step by itself once that step is done.
- Starting a guide, a reward pursuit or a dungeon prep route no longer drops a pin on your map; the in-world waypoint shows the stop.

## In-world waypoint
- Map pins from Questynator show the quest: **Pickup**, **Objective** or **Turn in**, who to see, and your objectives, instead of just "Map pin".
- Fades out when you reach the spot, so the NPC or object is in plain view, and fades back in if you walk away.
- Fades to 10% in combat.
- Sits higher: the card floats above the NPC's head and the beam is taller.

## Window
- The Stats tab is gone. The gear icon opens Questynator's settings under **Options → AddOns**, and the bottom line says **Made by Valacas#21304** (click to copy the BattleTag). `/qn stats` and `/qn about` still work.

## Fixes
- Fixed "Questynator tried to call the protected function Reload()" when you pick **Use Questynator's** in the WaypointUI prompt.
- Fixed WaypointUI staying on after you picked **Use Questynator's**.
- The "Two world pins are on" prompt is asked once instead of after every reload. **Options → Choose one** still opens it.

# Questynator 1.6.9

- **The in-world waypoint is rebuilt.** Far away, a dashed beam rises to a badge with the quest, distance and time. Under 100 yards, a card over the target shows what to do and your objectives. When the spot is off screen, the badge circles the middle of your screen and points the way.
- New animations: a new stop drops in and its beam unrolls, the card slides up, and the modes fade into each other.
- The waypoint also shows the quest you select in the tracker (its turn-in NPC once it's ready) and map pins you place yourself. Route stops no longer put a pin on your world map.
- If WaypointUI is also installed, you're asked which waypoint to keep. **Options** shows a **Choose one** button while both are on.
- Fixed a Lua error from the waypoint when the spot was at the edge of the screen.

# Questynator 1.6.7

- Fixed the in-world waypoint freezing on screen after you remove its map pin. It now hides when you remove the pin or pin somewhere else, and comes back with the next route stop.

# Questynator 1.6.6

- Fixed a Lua error from the in-world waypoint in combat and instances, where the game hides your run speed from addons. The time to the stop now uses normal running speed there.

# Questynator 1.6.5

## New look
- **Every tab has a two-column layout.** The left column holds the tab's summary and controls; the list sits on the right. The window is wider (640 px), the tabs are spread evenly, and small grey text is brighter.
- **Quests tab:** your route runs down the left, with the current stop as a card (what to do, where, level, XP, **Pin on map**), the next stops with their distance, and your quest log rewards and XP bar. Your quests are on the right as cards with the next objective, its count and a progress bar. Ready-to-turn-in quests come first with **Pin turn-in**, then the quests closest to done. **All**, **Group** and **Ready** filter the list.
- **Other tabs:** Zones shows your level and the zone with the most XP for you (**Route there**). Nearby shows your searches. Groups shows your group and **Host LFG**. Dungeons holds your roles. Treasures shows your bag progress. Rewards shows what you're pursuing, with **Stop**. **Reward Hunting** is now **Rewards** on the tab row.

## In-world waypoint
- A marker over your next route stop: a soft beam, pulsing rings on the exact spot, a badge (**!** pickup, **?** turn-in, a dot for an objective), the distance and time under it, and a label with the quest.
- It fades as you get close so it never hides the NPC, turns green with "You're here" on arrival, and shows an arrow at the screen edge when the spot is behind you.
- It steps aside while you follow a quest you picked in the tracker and never replaces a map pin you placed yourself. Turn it off under **Options → AddOns → Questynator**.

## Smarter routes
- Routes always go to the nearest stop next, and re-order as you move when another stop gets clearly closer.
- Leveling routes leave out dungeon and battleground quest givers. Dungeon prep and reward pursuit still include them when you start them yourself.
- When your zone has nothing left for your level, the planner suggests the **best next zone**. **Route there** guides you to it.
- Dungeon prep, reward pursuit and zone trips are named in the planner with a **Stop** button.
- Each planner action shows the quest's level, XP and tags, and for pickups what the quest asks for and where. Later stops show their distance.

## Quest data
- Quest data rebuilt for WoW Forever: 5,982 quests, about 440 more pickups (including quests that start from an item on the ground, like **Attack on Camp Narache**), XP for 950 more quests, Horde-specific quest givers, and more exact coordinates.
- **Quest tips:** short player tips for 20 Mulgore starter quests, in quest tooltips and "how to complete".

## Fixes and polish
- `/qn` and the minimap button always open the Quests tab.
- Questynator is listed under **Quests** in the AddOns list, and the minimap icon fits its round border.
- Objectives written as "0/6 Item" show the count on the right, like the others. Zone level ranges ignore quests listed at level 0.

# Questynator 1.6.3

- The Route Planner opens compact with your next action. Click **More** for up to three actions, **Snooze stop**, and **Undo**. Its main button pauses and resumes the route, and a paused route also pauses the compass.
- "Speak to" quests become route stops at their NPC. When nothing else is within reach, the route points to the nearest pickup in the zone. A replan keeps the task you are working on first.
- The Quests tab's **Skip** button is now **Snooze stop**.
- **Stop hosting** keeps a quest search you started before hosting.
- On German, French, Spanish, and Russian clients, the compass keeps guiding a selected quest after you finish one of its objectives.
- The route plans again when you enter a zone or level up without an active route.
- Reward Hunting, Dungeon Prep, hosting, reminders, and the planner are translated into German, French, Spanish, and Russian.

# Questynator 1.6.2

- **Host LFG** in the planner and main window lists the selected quest in one click. The planner shows the quest and hosting status. Use the same button to stop, or type `/qn host`.
- Quest and dungeon hosts reserve a slot for each outgoing invite, ignore duplicate automatic requests, and free unanswered reservations after 60 seconds. Listings advertise pending seats.
- Smart Reminders now cover matching open quest groups, empty searches, nearby turn-ins with wearable rewards, and recently unlocked follow-ups in your zone.

# Questynator 1.6.1

- Smart reminders surface nearby treasure and Scarlet Monastery quest pickups while playing. Pin the giver directly, request a confirmed quest share, or start a prep route when preparing for the dungeon.
- Reminders work with both addon windows closed and stay quiet in combat and instances. Dismiss a suggestion for 30 minutes across reloads or disable reminders in Options.

# Questynator 1.6.0

- Added **Dungeon Prep** to the Scarlet Monastery row in **Dungeons**. Check seven pre-entry quests across both factions, see your next prerequisite, and compare listed equipment rewards.
- Pin a quest giver or choose **Route to missing pickups** to collect available quests across zones. Your saved reward pursuit resumes after the prep route ends.
- **Request share** whispers an eligible party member who reports a shareable quest through Questynator.

# Questynator 1.5.3

## Route Planner and compass

- Selecting a quest in the tracker adds **Selected quest** beside the compass. The planner previews the next route stop. Click **Resume route** to return to it.
- **Snooze stop** skips a stop until you leave the zone. Snoozes survive replans and reloads. **Undo snooze** restores the most recent stop. You can also use `/qn snooze` and `/qn undo`.
- Pins now say **Pin pickup**, **Pin objective**, or **Pin turn-in**. When several tasks share a stop, **Pin stop** marks their destination.
- Fixed overlapping objective names. On *A New Threat*, finishing the regular Rockjaw Troggs leaves only Burly Rockjaw Troggs to track.
- Fixed premature turn-in guidance while quest objectives are loading.

## Reward Hunting and navigation

- Hover over a reward to compare it with equipped gear and see how many quests remain.
- Empty zone searches now offer a one-click search across all zones while keeping your filters. The button shows the match count when available.
- The current reward step’s pin and the pursuit now use the same destination. For *The Defias Brotherhood*, the hand-in for quest 65 correctly points to Wiley the Black in Redridge.
- Reordered the main tabs to keep Quests and Zones together, followed by Nearby, Groups, and Dungeons, then Treasures and Reward Hunting.

## Groups and XP

- Quest hosts withdraw their listing when they lose party leadership.
- Dungeon role counts account for flexible hosts. A tank/healer host joined by a dedicated tank can now advertise for three DPS.
- XP/hour drops to zero after a full hour without XP gains.

# Questynator 1.5.0

## Reward Hunting

- Open **Reward Hunting** after **Treasures**, or type `/qn rewards`. Search 1,120 quest rewards by item, slot, type, or final quest. Results account for your level, class, race, faction, equipment proficiencies, and quest progress. Completed reward quests disappear.
- **Current zone** starts enabled and shows rewards with a pickup, unfinished objective, or turn-in in your zone. Turn it off to browse all zones.
- Choose **All**, **Weapon**, **Armor**, **Jewelry**, or **Trinkets**. Weapon groups usable melee and ranged weapons, including bows, guns, crossbows, thrown weapons, and wands. Its type selector expands inside the window. Fishing poles check your Fishing skill.
- The Armor filter switches from mail to plate for warriors and paladins at level 40, and from leather to mail for hunters and shamans. Druids and rogues see leather. Mages, priests, and warlocks see cloth.
- Ready turn-ins appear first. Open a reward to see the remaining quest chain, each known pickup location, and its map pin. **Pursue Reward** follows one chain per character across zones. A quest selected in the tracker keeps compass priority.

## Treasures and quest eligibility

- All 18 Treasures entries use their actual reward item icons. Bag quests stay in **Treasures**.
- Restored Alliance and Horde Skyborne race restrictions in quest availability and follow-up suggestions.

# Questynator 1.4.0

## Quest Routes

- Quest Routes builds up to ten stops in your current zone from quest objectives, turn-ins, and eligible pickups within 300 yards.
- The route starts on login or reload. It replans as quests and objectives change, when you enter a new zone, and when you level up.
- The floating Route Planner shows the next three actions. Click Pin beside an action to mark its location, even when several tasks share a stop.
- Show or hide the window under Options > AddOns > Questynator, or type /qn planner. Its position and visibility are saved.
- The compass follows the quest selected in the objective tracker. Clear the selection to follow the route again.
- Hover over the minimap button for the current stop, distance when available, objective counts, and active searches.
- The planner checks quest completion before suggesting pickups and includes the Lost Journal that starts The Adventurer.

## Fixes

- Fixed quest searches and sharing treating a quest as active when the client returns a log index of zero.
