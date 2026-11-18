# Questynator

Adds a small **LFG** button to every quest in the objective tracker. Click it and Questynator
looks for other Questynator players on the same quest, then invites / auto-accepts into a party.

## Install
Copy the `Questynator` folder into your WoW Forever `Interface/AddOns/` folder, then `/reload`.

## The window
Open it with `/qn` (or `/lfg`) or the minimap button. Three tabs:
- **Quests:** quest cards with a level badge, objective progress bar and group badges. Quests you're searching for glow green and sit at the top.
- **Nearby:** everyone found for your quests, through Questynator or in chat, with class icon, class-colored name and level, plus **Whisper** and **Invite**.
- **Groups:** every group created with Questynator on your realm and faction, even for quests you don't have. Shows the host, quest, level range, zone and size. **Join** asks the host for an invite and accepts it automatically.
- **Rewards header:** XP, money and reputation for finishing every quest in your log, with a small XP bar showing where that gets you.
- **Stats:** users online, quests done with Questynator groups, groups formed, active searches.

## Use
- Type `/qn` to open the **Questynator panel**: your quest log with a **Find Group** button per quest (drag to move, Esc to close).
  Quests in collapsed zones of your quest log won't show; expand the zone in the log.
- Or click **LFG** next to a quest. It turns green and shows how many players it found. Click again to cancel.
- Searching stops by itself when the quest is complete or leaves your log, the party is full, or after 10 minutes.
- Matches must be within 6 levels of you.

## Quest Routes

Questynator automatically plans your route after you log in or run `/reload`.
**Questynator : Route Planner** shows the current destination and up to three pending actions, numbered by stop.
Click **Pin** beside any action to mark its pickup, objective, or turn-in location. In the Quests tab, **Mark on map** marks the current stop.
Drag the window to move it. Click **x** to hide it or type `/qn planner` to toggle it.
Questynator remembers its position and visibility across sessions.

Questynator uses known
locations in your current zone to plan up to ten stops from your active
objectives, ready turn-ins, and eligible quest pickups within 300 yards of you. Nearby tasks can share a stop. The compass
advances after all tasks at the current stop are done. Selecting a quest in the objective tracker directs the compass to that quest. Clear the selection to resume route guidance.

The route replans when you finish an individual objective, complete a quest, or turn one in.
If the route is paused, it replans when you resume.

Use **Pause** to suspend route guidance, **Skip** to move to the next stop, or
**Replan** to build a fresh route from your current location and quest progress.

## Dungeon finder
The **Dungeons** tab lists the dungeons around your level. Pick your roles (Tank, Healer, DPS), then:
- **Look**: tell everyone you want a group, as your roles. Hosts see you and can invite you.
- **Host**: list your group and mark which roles you still need. Players click **Join** (or whisper you +) and get invited automatically. **Post to General** announces it in chat too.
The pin button sets a waypoint to the dungeon entrance.

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
Quest locations, objectives and reputation rewards in `Data/QuestData.lua` come from the QuestieDB database of the
Questie project (https://github.com/Questie/Questie), used under the GNU GPL v3. Many thanks to its authors and
data contributors.

Questynator is free software, licensed under the GNU General Public License v3 (see `LICENSE` and `gpl-3.0.md`).
The bundled libraries (LibStub, CallbackHandler, LibDataBroker, LibDBIcon) keep their own licenses.
