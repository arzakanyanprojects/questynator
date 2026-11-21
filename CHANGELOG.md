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
