# Questynator

Adds a small **LFG** button to every quest in the objective tracker. Click it and Questynator
looks for other Questynator players on the same quest, then invites / auto-accepts into a party.

## Install
Copy the `Questynator` folder into your WoW Forever `Interface/AddOns/` folder, then `/reload`.

## The window
Open it with `/qn`, the minimap button, or `/lfg` when that command is available.
- **Quests:** quest cards with a level badge, objective progress bar and group badges. Quests you're searching for glow green and sit at the top.
- **Nearby:** everyone found for your quests, through Questynator or in chat, with class icon, class-colored name and level, plus **Whisper** and **Invite**.
- **Groups:** every group created with Questynator on your realm and faction, even for quests you don't have. Shows the host, quest, level range, zone and size. **Join** asks the host for an invite and accepts it automatically.
- **Dungeons:** find a party by dungeon and role.
- **Zones:** see which quests you can pick up and where to find their givers.
- **Treasures:** track bag quests and the Cozy Sleeping Bag for your character.
- **Rewards header:** XP, money and reputation for finishing every quest in your log, with a small XP bar showing where that gets you.
- **Stats:** users online, quests done with Questynator groups, groups formed, active searches.

## Use
- Type `/qn` to open the **Questynator panel**: your quest log with a **Find Group** button per quest (drag to move, Esc to close).
  Quests in collapsed zones of your quest log won't show; expand the zone in the log.
- Or click **LFG** next to a quest. It turns green and shows how many players it found. Click again to cancel.
- Searching stops by itself when the quest is complete or leaves your log, the party is full, or after 10 minutes.
- Matches must be within 6 levels of you.

## Reward Hunting

Open the **Reward Hunting** tab after **Treasures**, or type `/qn rewards`. It shows weapons, armor, and jewelry that fit your class, learned proficiencies, and level. Search by item, slot, type, or final quest. Bag quests are in **Treasures**.

**Current zone** starts enabled. A reward appears when its next pickup, unfinished objective, or turn-in has a known location in your zone. Turn the filter off to browse all zones. A pursuit follows the chain when it takes you into another zone.

Search works with **All**, **Weapon**, **Armor**, **Jewelry** (rings and necklaces), or **Trinkets**. **Weapon** opens on **All weapon types**. Its menu lists the weapon types in your matching rewards, so you can narrow the results to a specific type, including ranged weapons. Fishing poles also require the appropriate Fishing skill.

If your current zone has no matches, use the button in the empty list to search all zones with the same filters. It shows the matching item count once the item data is ready and the search finds results.

The Armor button shows your character's armor type. Warriors and paladins switch from mail to plate at level 40. Hunters and shamans switch from leather to mail at 40. Druids and rogues use leather, and priests, mages, and warlocks use cloth. The same body armor rule applies in **All**, where cloaks and held off-hands can also appear.

Ready turn-ins appear first. Among pursuits you can start, **Closest to earning** sorts by remaining quest steps. Completed reward quests disappear, including choices you passed over.

Hover over a reward to compare it with your equipped gear and see how many quests remain. For weapons, the item tooltips show damage, speed, and DPS.

Open a reward to see the remaining quests in order. The current step has a **Pin pickup**, **Pin objective**, or **Pin turn-in** button when its location is known. Later steps show their pickups. **Pursue Reward** directs the Route Planner through the chain, even across zones. The pursuit is saved per character. Selecting a quest in the objective tracker still takes priority on the compass. Use **Stop pursuit** or finish the reward quest to restore normal planning.

## Quest Routes

Questynator automatically plans your route after you log in or run `/reload`.
**Questynator : Route Planner** shows the current destination and up to three pending actions, numbered by stop.
Click the pin beside an action to mark its pickup, objective, or turn-in. The Quests tab can also pin a whole stop when several tasks share it.

**Snooze stop** hides the current stop for this visit to the zone, including after a replan or reload. **Undo snooze** restores the most recently snoozed stop. Both actions are also available through `/qn snooze` and `/qn undo`. Snoozing a reward stop keeps the pursuit saved while the planner looks for other work.
Drag the window to move it. Use **Options → AddOns → Questynator → Show Route Planner** or `/qn planner` to show or hide it. The window’s **x** also hides it.
Questynator remembers its position and visibility across sessions.

Questynator uses known
locations in your current zone to plan up to ten stops from your active
objectives, ready turn-ins, and eligible quest pickups within 300 yards of you. Nearby tasks can share a stop. The compass
advances after all tasks at the current stop are done. When you select a quest in the objective tracker, the compass shows **Selected quest** and the floating planner previews your next route stop under **Up next when you resume**. Click **Resume route** to return to that stop or reward pursuit.

The route replans when quests enter or leave your log, when you finish an objective or turn in a quest, when you enter a new zone, and when you level up.
If the route is paused, it replans when you resume.

Use **Pause** to suspend route guidance, **Skip** to move to the next stop, or
**Replan** to build a fresh route from your current location and quest progress.

## Dungeon finder
The **Dungeons** tab lists the dungeons around your level. Pick your roles (Tank, Healer, DPS), then:
- **Look**: tell everyone you want a group, as your roles. Hosts see you and can invite you.
- **Host**: list your group and mark which roles you still need. Players click **Join** (or whisper you +) and get invited automatically. **Post to General** announces it in chat too.
The pin button sets a waypoint to the dungeon entrance.

Click **Prep** beside **Scarlet Monastery** for its pre-run checklist. It covers seven quests with pickups outside the instance, filtered for your character. Each row shows the first unfinished prerequisite or the objectives in your log. Hover over a listed reward to compare it with your gear.

**Pin pickup** marks one quest giver. **Route to missing pickups** visits the available givers, including prerequisite starters in other zones. Picking up a quest advances the route. The route is saved per character and your previous reward pursuit resumes when the pickups are finished or you click **Stop prep route**. Selecting a quest in the tracker keeps compass priority.

**Request share** whispers a party member who has the quest and whose Questynator reports it as shareable. Both players need version 1.6.0 or later for this button.

### Smart reminders

Questynator checks for opportunities while you play, even with the panel and Route Planner closed. Within 200 yards of an eligible Scarlet Monastery or treasure quest giver, **Pin pickup** marks the NPC. When a party member can share a missing Scarlet Monastery quest, **Request share** whispers them. Hosting, looking for a group, requesting to join, or approaching the instance entrance can also bring up **Route to pickups**.

One reminder appears at a time. **Later (30 min)** dismisses that suggestion for your character across reloads. Unanswered reminders also snooze after about 25 seconds. Turn the feature off under **Options → AddOns → Questynator → Smart reminders**.

Reminders also offer **Request invite** for a matching quest group with space, **Host LFG** after an empty quest search, and **Pin turn-in** when you are within 200 yards of a quest giver with wearable reward gear. For ten minutes after a hand-in, a newly available follow-up in your zone can also offer **Pin pickup**.

## Playing together
- **Party progress**: in a party, each quest card shows how far your partners are ("Lunaria 9/12", "done", "doesn't have it") with a **Share quest** link.
- **Party messages**: when all objectives of a quest are done, and when you turn it in, Questynator tells your party in party chat.
- **Kudos**: after a quest done together you can thank your party. Kudos show in tooltips.
- **Top helpers this week**: groups formed and quests done together, on the Stats tab.
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
Open the Stats panel or type `/qn stats`.

## Spot other users
Hover a player: if they run Questynator, their tooltip says **Questynator user**.

## Languages
English, Deutsch, Français, Español and Русский. The chat scanner also understands "looking for group" words in those
languages. Translation fixes are welcome.

## Minimap button
Left-click opens Questynator, right-click stops all searches, hover shows your next route stop and active searches.
Drag it around the minimap. `/qn minimap` hides or shows it. Questynator is also in Blizzard's addon menu on the minimap.

## Create Group
Click **Host LFG** in the floating planner or the main window, or type `/qn host`. Questynator lists the unfinished quest selected in the tracker. With no eligible selection, it uses your only unfinished quest or lets you pick from your log. Quick hosting uses your configured level range and unfinished objectives, accepts invite requests, and lists the group on the addon board. **Stop hosting** withdraws the displayed listing.

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
| `/qn planner` | Show or hide the floating Route Planner |
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

## Contact
Made by **Bethrayer Forever** (Horde, PvE). BattleTag: **Valacas#21304**.
In game: `/qn about`, or the About box on the Stats tab. Bugs and ideas are welcome in the CurseForge comments.

## Credits and license
Quest locations, objectives and reputation rewards in `Data/QuestData.lua` and the additional item reward sources in `Data/RewardCatalog.lua` come from the QuestieDB database of the
Questie project (https://github.com/Questie/Questie), used under the GNU GPL v3. Many thanks to its authors and
data contributors.

Questynator is free software, licensed under the GNU General Public License v3 (see `LICENSE` and `gpl-3.0.md`).
The bundled libraries (LibStub, CallbackHandler, LibDataBroker, LibDBIcon) keep their own licenses.
