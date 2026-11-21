-- Pickups omitted from the generated availability index.
-- Lost Journals: QuestieDB Forever (GPLv3), quest fields 4-7, 13, 16, 22 and 27.
local _, ns = ...
local pickups = {
    [96630] = "4;6;4294967373;0;;921;96627,96628,96638,96652,96656,96659,96606;1;0;A;The Adventurer",
    [96652] = "4;6;8589934770;0;;794;96627,96628,96630,96638,96656,96659,96604;1;0;H;The Adventurer",
    -- Attack on Camp Narache starts from a Dirt-stained Map lying in a Mulgore cave (Wowhead Forever:
    -- quest 781, level 4, requires 1, Horde; the map is object 3076).
    [781] = "1;4;8589934770;0;;;;;0;H;Attack on Camp Narache",
}
-- Quests that start from an item picked up off the ground: point the pickup at the object holding it.
local itemStarts = {
    [781] = "o3076",
}
for id, row in pairs(pickups) do
    ns.QDATA.a[id] = ns.QDATA.a[id] or row
end
for id, object in pairs(itemStarts) do
    local raw = ns.QDATA.q[id]
    if raw and raw:match("^i%d+") then ns.QDATA.q[id] = raw:gsub("^i%d+", object) end
end
