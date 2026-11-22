# World pin rework (2026-11-22)

## Intent
Rebuild the in-world waypoint over the current route stop so it behaves like the WaypointUI addon
(three modes, smooth animations) but looks like Questynator (dark card, teal accent, gold `!`/`?`).
Approved from the drawn mockups in the session.

## Behaviour
- **Far** (100 yd or more, on screen): a dashed teal beam from the spot up to the badge. The dashes march upward.
  Quest name above the badge, distance and time to get there under it. Shrinks with distance (0.7–1.1 scale).
  No ring on the ground.
- **Near** (under 100 yd, on screen): the beam goes away and a card floats above the target: badge and title,
  "Pickup / Turn in / Objective · who", a divider, up to three objective lines (green when done),
  "+N more here", the distance. A small arrow under the card bobs toward the target. Within 8 yd it turns
  green and reads "You're here". The card fades to half strength in the last few yards so the NPC stays visible.
- **Off screen** (the navigation frame is clamped or near the screen edge): the badge orbits the screen centre
  on an oval (WaypointUI's 200×100 at camera zoom 35, scaled with zoom, max 500), with an arrow pointing at
  the target and the distance under it.
- Mode switches wait about 0.35 s so a brief flip doesn't flicker, and there's a 95/110 yd gap for near and far.

## Animations (timings copied from WaypointUI)
- New stop: badge drops from 2.2× to 1× (0.5 s, ease-in), the frame fades in (1 s), the beam unrolls upward
  (0.5 s after a 0.175 s wait).
- Beam: the dashes march upward continuously.
- Near card: slides up 57 px and fades in (1 s ease-in-out). On leaving, it drops 12 px and fades (0.25 s).
- Off screen: position glides a third of the way per frame, arrow turns half the way per frame.
- Mode switch: 0.175 s crossfade.

## WaypointUI conflict
- If WaypointUI is loaded and our pin is on, at login show a Questynator-styled prompt:
  "Use Questynator's" (turns WaypointUI off for this character, reloads), "Use WaypointUI's" (turns our pin off).
  Closing it asks again next login.
- Settings: under the world pin checkbox, while both are on: "WaypointUI is also on." plus a "Choose one" button that
  opens the same prompt.

## No map pin
The game only gives addons an on-screen spot for a tracked target, so the route stop is still set as the
map waypoint, but its pin on the world map is made invisible and unclickable (as WaypointUI does). It is
hidden again whenever the map opens, changes zone or the waypoint moves. A pin the player places stays visible.
Tracking the quest instead was rejected: it can't do pickups and lands on the game's quest area, not our stop.

## Unchanged
Places the route stop as the map waypoint only when the player has no pin of their own. Steps aside when a quest is
picked in the tracker or the player removes/moves the pin. Clients without C_Navigation keep the compass only.

## Approaches
1. **Rewrite WorldMarker.lua in place with plain frames and per-frame tweens** (chosen): no new libraries,
   works on every client and in the test fakes.
2. Use the game's AnimationGroups for everything: less code for fades, but they can't do the oval orbit or
   marching dashes, and Scale animations have different APIs on different clients.
3. Embed WaypointUI's ui-anim package: a big dependency for a handful of tweens.
