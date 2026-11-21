# Path maker: real paths instead of straight lines

## Problem
The arrow and the route measure straight-line distance, so the arrow points over mountains and cliffs, and the stop order assumes you can walk straight there.

## What we can't do
The addon API can't see the terrain: there's no height map, no collision check and no line of sight. So paths have to come from data, not from the game at runtime.

## Plan

1. **Road graph per zone (data).** Each zone gets a list of nodes (x, y) with edges between nodes you can walk between: roads, passes, ramps and cave mouths. Ship it as `Data/Paths.lua`, about 30–80 nodes per zone. Start with the starter zones and The Barrens, then grow.
2. **Recorded by players (how we get the data).** A hidden `/qn record` mode samples your position every 2 seconds while you're mounted or running. A segment counts as walkable if you actually walked it. Questynator users can send their tracks over the existing addon channel. We merge tracks into the graph offline with a small script (snap to a 15-yard grid and keep edges seen at least 3 times). No manual map tracing.
3. **Pathfinding (runtime).** A* search over the zone graph: enter at the node nearest the player, leave at the node nearest the target, with the open ground at each end walked straight. It's cheap, because each zone has under 100 nodes.
4. **Use the path everywhere:**
   - The arrow points at the next path node, not the final target.
   - Route stop ordering uses path length instead of straight-line yards.
   - The new in-world waypoint shows "via [pass name]" when the path bends.
5. **Fallback:** if a zone has no graph, keep today's straight line.

## Milestones
1. Graph format, A* and the arrow following nodes, with one hand-made zone (Mulgore) to prove it works.
2. `/qn record` and an offline merge script that turns tracks into a graph.
3. Route ordering by path length, and a "via" hint on the waypoint.
4. Collect tracks from users and cover the leveling zones.

## Open questions
- Should players' tracks be shared automatically (opt-in) or only exported by hand?
- Should flight paths count as edges (graph links between zones)?
