# Questynator

Adds a small **LFG** button to every quest in the objective tracker. Click it and Questynator
looks for other Questynator players on the same quest, then invites / auto-accepts into a party.

## Install
Copy the `Questynator` folder into your WoW Forever `Interface/AddOns/` folder, then `/reload`.

## The window
Open it with `/qn`, the minimap button, or `/lfg` when that command is available.
- **Quests:** your route on the left, your quest log on the right. The route column shows the current stop as a card (what to do, where, level, XP and **Pin on map**), the next stops with their distance, and your quest log rewards with the XP bar at the bottom. Quest cards show a level badge, the next objective with its count and a progress bar, and the search or party status. Ready-to-turn-in quests come first with **Pin turn-in**, then the quests closest to done. The **All**, **Group** and **Ready** chips filter the list. Quests you're searching for get a teal outline.
- **Nearby:** everyone found for your quests, through Questynator or in chat, with class icon, class-colored name and level, plus **Whisper** and **Invite**.
- **Groups:** every group created with Questynator on your realm and faction, even for quests you don't have. Shows the host, quest, level range, zone and size. **Join** asks the host for an invite and accepts it automatically.
- **Dungeons:** find a party by dungeon and role.
- **Zones:** see which quests you can pick up and where to find their givers.
- **Treasures:** track bag quests and the Cozy Sleeping Bag for your character.
- **Rewards:** quest rewards worth chasing for your class and level (see Reward Hunting).
- **Quest log rewards:** XP, money and reputation for finishing every quest in your log, with a small XP bar showing where that gets you, at the bottom of the Quests tab's route column.
- **Gear icon** (top right): opens Questynator's settings under **Options → AddOns**. The bottom line shows your searches, users online and **Made by Valacas#21304** (click it to copy the BattleTag).

## Use
- Type `/qn` to open the **Questynator panel**: your quest log with a **Find Group** button per quest (drag to move, Esc to close).
  Quests in collapsed zones of your quest log won't show; expand the zone in the log.
- Or click **LFG** next to a quest. It turns green and shows how many players it found. Click again to cancel.
- Searching stops by itself when the quest is complete or leaves your log, the party is full, or after 10 minutes.
- Matches must be within 6 levels of you.

## Reward Hunting

Open the **Rewards** tab after **Treasures**, or type `/qn rewards`. It shows weapons, armor, and jewelry that fit your class, learned proficiencies, and level. Search by item, slot, type, or final quest. Bag quests are in **Treasures**.

**Current zone** starts enabled. A reward appears when its next pickup, unfinished objective, or turn-in has a known location in your zone. Turn the filter off to browse all zones. A pursuit follows the chain when it takes you into another zone.

Search works with **All**, **Weapon**, **Armor**, **Jewelry** (rings and necklaces), or **Trinkets**. **Weapon** opens on **All weapon types**. Its menu lists the weapon types in your matching rewards, so you can narrow the results to a specific type, including ranged weapons. Fishing poles also require the appropriate Fishing skill.

If your current zone has no matches, use the button in the empty list to search all zones with the same filters. It shows the matching item count once the item data is ready and the search finds results.

The Armor button shows your character's armor type. Warriors and paladins switch from mail to plate at level 40. Hunters and shamans switch from leather to mail at 40. Druids and rogues use leather, and priests, mages, and warlocks use cloth. The same body armor rule applies in **All**, where cloaks and held off-hands can also appear.

Ready turn-ins appear first. Among pursuits you can start, **Closest to earning** sorts by remaining quest steps. Completed reward quests disappear, including choices you passed over.

Hover over a reward to compare it with your equipped gear and see how many quests remain. For weapons, the item tooltips show damage, speed, and DPS.

Open a reward to see the remaining quests in order. The current step has a **Pin pickup**, **Pin objective**, or **Pin turn-in** button when its location is known. Later steps show their pickups. **Pursue Reward** directs the Route Planner through the chain, even across zones. The pursuit is saved per character. Selecting a quest in the objective tracker still takes priority on the compass. Use **Stop pursuit** or finish the reward quest to restore normal planning.

## Quest Routes

Questynator automatically plans your route after you log in or run `/reload`.
The floating **Route Planner** shows your next task as a card: a quest badge (**!** pickup, **?** turn-in, a dot for an objective), what to do and how far, the quest, and who to see. **Pin** marks it on the map and **Snooze** skips it. Under the card, **Then** lists the next two tasks (**More** shows four); click one to mark it on the map. A route mode you started (a starter guide, dungeon prep, a reward pursuit or a zone trip) is named at the top with **Stop**, and a guide shows its trips as a bar.
A grey line on the card shows the quest's level, XP and Elite or group tag. For a quest you haven't picked up yet, it also says what the quest asks for and where, for example "Get Tear of the Moons from General Twinbraid's Strongbox (49, 84)". Later stops show how far away they are, and the stop counter shows the distance to the current stop.
The Quests tab can also pin a whole stop when several tasks share it.

**Snooze stop** hides the current stop for this visit to the zone, including after a replan or reload. **Undo snooze** restores the most recently snoozed stop. Both actions are also available through `/qn snooze` and `/qn undo`. Snoozing a reward stop keeps the pursuit saved while the planner looks for other work.
Drag the window to move it. Use **Options → AddOns → Questynator → Show Route Planner** or `/qn planner` to show or hide it. The window’s **x** also hides it.
Questynator remembers its position and visibility across sessions.

Questynator uses known
locations in your current zone to plan up to ten stops from your active
objectives, ready turn-ins, "speak to" quests, and eligible quest pickups within 300 yards of you. Dungeon and battleground quest givers are left out; use a prep route for dungeon quests. When nothing else is in reach, it points to the nearest pickup in the zone. Nearby tasks can share a stop. The compass
advances after all tasks at the current stop are done. When you select a quest in the objective tracker, the compass shows **Selected quest** and the floating planner previews your next route stop under **Up next when you resume**. Click **Resume route** to return to that stop or reward pursuit.

When the zone has nothing left for your level, the planner shows **Best next**: the zone with the most pickups and quests from your log, with a zone on another continent counting half. **Route there** guides you to that zone and hands back to normal planning when you arrive. The trip isn't saved, so it ends when you log out. **Show zones** opens the Zones tab.

A starter guide, a dungeon prep route, a reward pursuit and a zone trip are named at the top of the planner, with a **Stop** button beside the name. Only one of them runs at a time: starting one ends the other.

### Starter guides
Quest guides for the seven starting areas, levels 1 to 6: Northshire (Human), Coldridge Valley (Dwarf, Gnome), Shadowglen (Night Elf), Valley of Trials (Orc, Troll), Camp Narache (Tauren), Deathknell (Undead) and Zephras Isle (Skyborne). A new character is offered the guide for the area it stands in, and can pick another starting area of its faction instead. Open the guides any time with `/qn guide`.

Each guide is a series of trips through the area. The Route Planner shows the current trip's pickups, objectives and turn-ins, and class quests for your class only. Steps are quests only: no tips, trainer visits or shortcuts. When a step needs a higher level, the planner says which level. Once every step is done, the guide ends and the normal route takes over for the next town.

The route replans when quests enter or leave your log, when you finish an objective or turn in a quest, when you enter a new zone, and when you level up.
If the route is paused, it replans when you resume.

The planner's main button pauses route guidance and the compass; click **Resume route** to continue. In the Quests tab's route column, use **Pause**, **Snooze** to skip the current stop, or
**Replan** to build a fresh route from your current location and quest progress.

### In-world waypoint
Your next route stop gets a marker in the world. Far away, a dashed beam rises to a badge (**!** pickup, **?** turn-in, a dot for an objective) with the quest, the distance and the time to get there. Under 100 yards, a card over the target shows what to do, who to talk to and your objectives. When you reach the spot, the marker fades out so you can see the NPC or object; it fades back in if you walk away. When the spot is behind you, the badge circles the middle of your screen and points the way.

The marker also shows the quest you pick in the objective tracker and map pins you place yourself. Route stops don't add a pin to your world map, and a pin you placed is never replaced. If WaypointUI is also installed, Questynator asks once which waypoint to keep; **Choose one** under Options asks again. Turn it off with **In-world waypoint over the next route stop** under Options.

## Dungeon finder
The **Dungeons** tab lists the dungeons around your level. Pick your roles (Tank, Healer, DPS), then:
- **Look**: tell everyone you want a group, as your roles. Hosts see you and can invite you.
- **Host**: list your group and mark which roles you still need. Players click **Join** (or whisper you +) and get invited automatically. **Post to General** announces it in chat too.
The pin button sets a waypoint to the dungeon entrance.

Click **Prep** beside any dungeon in **Dungeons** for its pre-run checklist. The 28 checklists cover the classic dungeons and the nine Forever additions. Scarlet Monastery, Blackrock Spire, Dire Maul and Stratholme each share one checklist across their wings. The checklist uses quests picked up outside the instance, filters them for your character, and shows the next known prerequisite or your current objectives. Hover over a listed equipment reward to compare it with your gear.

**Pin pickup** marks one quest giver. **Route to missing pickups** visits the available givers, including prerequisite starters in other zones. Picking up a quest advances the route. The route is saved per character and your previous reward pursuit resumes when the pickups are finished or you click **Stop prep route**. Selecting a quest in the tracker keeps compass priority.

**Request share** whispers a party member who has the quest and whose Questynator reports it as shareable. Both players need version 1.6.0 or later for this button.

### Smart reminders

Questynator checks for opportunities while you play, even with the panel and Route Planner closed. Within 200 yards of an eligible dungeon or treasure quest giver, **Pin pickup** marks the giver. **Request share** whispers a party member who can share a missing dungeon quest. Hosting, looking for a group, requesting to join, or approaching the instance entrance can also bring up **Route to pickups**.

One reminder appears at a time. **Later (30 min)** dismisses that suggestion for your character across reloads. Unanswered reminders also snooze after about 25 seconds. Turn the feature off under **Options → AddOns → Questynator → Smart reminders**.

Reminders also offer **Request invite** for a matching quest group with space, **Host LFG** after an empty quest search, and **Pin turn-in** when you are within 200 yards of a quest giver with wearable reward gear. For ten minutes after a hand-in, a newly available follow-up in your zone can also offer **Pin pickup**.

## Playing together
- **Party progress**: in a party, each quest card shows how far your partners are ("Lunaria 9/12", "done", "doesn't have it") with a **Share quest** link.
- **Party messages**: when all objectives of a quest are done, and when you turn it in, Questynator tells your party in party chat.
- **Kudos**: after a quest done together you can thank your party. Kudos show in tooltips.
- **Popular near you**: on the Nearby tab, quests other Questynator players in your zone are doing right now.

## Smarter quest cards
- **Turn-in arrow**: when a quest is ready, a compass on screen points to where you hand it in, with the distance in yards (and the zone name if it's in another zone). Drag to move, right-click to hide.
- Locations in "How to do it" are clickable: TomTom arrow if you have it, otherwise a map pin.
- **Next:** shows which quest this one unlocks.
- The XP bar tooltip shows XP per hour and the time to your next level.

## How to do a quest
Click a quest card to open it. You get the objective, your progress, and a short **How to do it** list:
which mobs to kill (with their level and where they are), what to loot and who drops it, what to use, and who to
turn it in to, with zone and map coordinates. Tips warn you about elite enemies, group quests and mobs above your level.
Finished quests only show the turn-in. No other addon is needed: the quest data comes bundled (see Credits).

## Players in chat
Questynator watches public chat and guild chat for players looking for one of your quests (a quest link, or the
quest name together with words like "LFG", "group" or "help"). A small popup lets you **Whisper** or **Invite** them,
and the quest's row in the window shows how many are looking. `/qn chat` turns this off.

## Group quests
Quests Blizzard marks as group, dungeon, raid or elite get a badge (for example **Group 3+**) and are listed first.
Their LFG button on the tracker is orange.

## Alerts
A sound plays and your taskbar icon flashes when a player is found, someone whispers "+", or someone in chat is
looking for your quest. `/qn sound` turns this off.

## Stats
Questynator counts the groups it formed for you and the quests you turned in while in them.
Type `/qn stats` to see them.

## Spot other users
Hover a player: if they run Questynator, their tooltip says **Questynator user**.

## Languages
English, Deutsch, Français, Español and Русский. The chat scanner also understands "looking for group" words in those
languages. Translation fixes are welcome.

## Minimap button
Left-click opens Questynator, right-click stops all searches, hover shows your next route stop and active searches.
Drag it around the minimap. `/qn minimap` hides or shows it. Questynator is also in Blizzard's addon menu on the minimap.

## Create Group
Click **Host LFG** in the floating planner or the main window, or type `/qn host`. Questynator lists the unfinished quest selected in the tracker. With no eligible selection, it uses your only unfinished quest or lets you pick from your log. Quick hosting uses your configured level range and unfinished objectives, accepts invite requests, and lists the group on the addon board. **Stop hosting** withdraws the listing. If you were already searching for that quest before you hosted it, the search keeps running.

An outgoing Questynator invite reserves one slot across quest and dungeon hosting. Joining clears that reservation, and an unanswered invite expires after 60 seconds. Updated hosts advertise pending seats to the Groups and Dungeons tabs.

If a search finds nobody after 10 seconds, the row offers two buttons: **Keep Searching** (asks again in 30 seconds) and **Create Group**, which opens a dialog where you pick
which objectives to do together, the player level range, whether to auto-invite whispers of "inv", and whether to post to
General chat (/1). Your group is then listed to other Questynator users (they're invited if they fit your levels and still
need one of your objectives). While listed, the row shows **Repost** (to General) and **Stop**.

Blizzard's own LFG board can't be filled in by addons (listing titles are protected), so this hosts through Questynator plus a General chat post.

## Commands (`/qn`)
| Command | What it does |
|---|---|
| `/qn`, `/questynator` (or `/lfg` if no other addon uses it) | Opens/closes the window |
| `/qn dungeons` | Open the Dungeons tab |
| `/qn rewards` | Open the Reward Hunting tab |
| `/qn planner` | Show or hide the floating Route Planner |
| `/qn guide` | Start or stop a starter guide |
| `/qn snooze`, `/qn undo` | Snooze the current route stop, or restore the last snoozed stop |
| `/qn host` | Host LFG for the selected quest, or stop hosting |
| `/qn arrow` | Turn the turn-in arrow on/off |
| `/qn thanks` | Thank your party (+1 kudos each) |
| `/qn partychat` | Turn the "objectives done" and "quest completed" party messages on/off |
| `/qn about` | Who made Questynator and how to contact him |
| `/qn minimap` | Hide/show the minimap button |
| `/qn chat` | Turn the chat scanner on/off |
| `/qn sound` | Turn sound alerts on/off |
| `/qn version` | Show the installed version |
| `/qn stats` | Show quests done with Questynator groups |
| `/qn online` | Show how many Questynator users are online |
| `/qn list` | Lists quests in your log with their IDs |
| `/qn find <questID>` | Start/stop searching without the tracker button |
| `/qn status` | Shows active searches |
| `/qn auto` | Toggle auto-accepting invites from matched players |
| `/qn probe [questID]` | Reports which native Blizzard quest-group APIs this client has |
| `/qn debug` | Prints tracker/channel diagnostics |

## Limits
Only players who also run Questynator can find each other. There is no server; discovery uses a hidden
addon channel (`QuestynatorLFG`), so it's same-faction only, like any chat channel.

## If something breaks
Install BugSack + BugGrabber, reproduce, and send the error. If the button doesn't show, run `/qn debug`
and send the output. The `## Interface:` number in the .toc is 16001; verify with `/dump select(4, GetBuildInfo())`.

### Running QA

From the addon repository, ask **“Run the Questynator QA agent.”** The agent checks the working copy, runs the tests and reports which behaviors still need an in-game check.

To run the same offline checks yourself, use `python tools/qa.py` with Python 3 and Lupa installed (`python -m pip install lupa`). It checks the TOC and XML references, compiles the shipped Lua files, and runs the simulated-client tests. A failing case prints its name and returns a nonzero exit code. With standalone Lua 5.1, `lua tests/review.lua` runs the simulated-client tests directly.

## Contact
Made by **Bethrayer Forever** (Horde, PvE). BattleTag: **Valacas#21304**.
In game: `/qn about`, or click **Made by Valacas#21304** at the bottom of the window. Bugs and ideas are welcome in the CurseForge comments.

## Credits and license
Quest locations, objectives and reputation rewards in `Data/QuestData.lua` and the additional item reward sources in `Data/RewardCatalog.lua` come from the QuestieDB database of the
Questie project (https://github.com/Questie/Questie), used under the GNU GPL v3. Many thanks to its authors and
data contributors.

Questynator is free software, licensed under the GNU General Public License v3 (see `LICENSE` and `gpl-3.0.md`).
The bundled libraries (LibStub, CallbackHandler, LibDataBroker, LibDBIcon) keep their own licenses.
