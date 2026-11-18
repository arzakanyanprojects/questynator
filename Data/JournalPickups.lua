-- Lost Journal pickups omitted from the generated availability index.
-- Source: QuestieDB Forever (GPLv3), quest fields 4-7, 13, 16, 22 and 27.
local _, ns = ...
local pickups = {
    [96630] = "4;6;4294967373;0;;921;96627,96628,96638,96652,96656,96659,96606;1;0;A;The Adventurer",
    [96652] = "4;6;8589934770;0;;794;96627,96628,96630,96638,96656,96659,96604;1;0;H;The Adventurer",
}
for id, row in pairs(pickups) do
    ns.QDATA.a[id] = ns.QDATA.a[id] or row
end
