-- Selected Forever quest rewards. Item and quest IDs are shared with the game tooltip.
-- Equipment records checked against Forever Dungeon Journal. Paths list required
-- quests in play order (QuestieDB preQuestSingle), excluding optional breadcrumbs.
local _, ns = ...
ns.RewardCatalog = {}

local function Quest(steps, choice, items)
    for _, item in ipairs(items) do
        ns.RewardCatalog[item[1]] = {
            item = item[1], name = item[2], kind = item[3], proficiency = item[4], fishingRank = item[5], steps = steps, choice = choice,
        }
    end
end

-- Learned proficiency spell IDs (including one-handed versus two-handed training).
local STAFF, SWORD, DAGGER, MACE, TWO_HAND_MACE, TWO_HAND_AXE = 227, 201, 1180, 198, 199, 197
local LEATHER, MAIL, PLATE = 9077, 8737, 750
Quest({ 865 }, false, { { 5343, "Barkeeper's Cloak", "Back" } })
Quest({ 1486 }, true, {
    { 6480, "Slick Deviate Leggings", "Leather Legs", LEATHER },
})
Quest({ 870, 877, 880, 1489, 1490, 914 }, true, {
    { 6505, "Crescent Staff", "Staff", STAFF },
    { 6504, "Wingblade", "Sword", SWORD },
    { 270018, "Hammerbone", "Two-handed Mace", TWO_HAND_MACE },
})
Quest({ 65, 132, 135, 141, 142, 155, 166 }, true, {
    { 2041, "Tunic of Westfall", "Leather Chest", LEATHER },
    { 2042, "Staff of Westfall", "Staff", STAFF },
    { 6087, "Chausses of Westfall", "Mail Legs", MAIL },
})
Quest({ 65, 132, 135, 141, 142, 155, 214 }, true, {
    { 2074, "Solid Shortblade", "Sword", SWORD },
    { 2089, "Scrimshaw Dagger", "Dagger", DAGGER },
    { 6094, "Piercing Axe", "Two-handed Axe", TWO_HAND_AXE },
    { 270005, "Monastic Hammer", "Mace", MACE },
})
Quest({ 1740 }, true, {
    { 15109, "Staff of Soran'ruk", "Staff", STAFF },
    { 6898, "Orb of Soran'ruk", "Off-hand" },
})
Quest({ 386 }, true, {
    { 1317, "Hardened Root Staff", "Staff", STAFF },
    { 3400, "Lucine Longsword", "Sword", SWORD },
})
Quest({ 971 }, false, { { 6743, "Sustaining Ring", "Finger" } })
Quest({ 1014 }, false, { { 6414, "Seal of Sylvanas", "Finger" } })
Quest({ 8366 }, true, {
    { 20640, "Southsea Head Bucket", "Plate Head", PLATE },
    { 20641, "Southsea Mojo Boots", "Cloth Feet" },
})
Quest({ 2770 }, false, { { 11122, "Carrot on a Stick", "Trinket" } })

-- Equipment reward sources derived from QuestieDB Forever 1.1.3 (GPL-3.0).
-- These records identify the reward quest but do not distinguish guaranteed from choice.
Quest({ 1141 }, nil, { { 12225, "Blump Family Fishing Pole", "Fishing Pole", nil, 1 } })
Quest({ 7815 }, nil, { { 19022, "Nat Pagle's Extreme Angler FC-5000", "Fishing Pole", nil, 100 } })
Quest({ 783, 18, 6 }, nil, {
    { 60, "Layered Tunic", "Leather", 9077 },
    { 3070, "Ensign Cloak", "Cloth" },
    { 6076, "Tapered Pants", "Cloth" },
})
Quest({ 9 }, nil, {
    { 1561, "Harvester's Robe", "Cloth" },
    { 3578, "Harvester's Pants", "Leather", 9077 },
    { 276695, "Harvester's Pestslayer", "Bow", 264 },
})
Quest({ 62, 76, 11 }, nil, {
    { 2238, "Urchin's Pants", "Cloth" },
    { 2249, "Militia Buckler", "Shield", 9116 },
    { 287059, "Footman's Pocketknife", "Thrown", 2567 },
})
Quest({ 12, 13, 14 }, nil, {
    { 1480, "Fist of the People's Militia", "Mace", 198 },
    { 1566, "Edge of the People's Militia", "Two-handed Sword", 202 },
    { 12296, "Spark of the People's Militia", "Wand", 5009 },
    { 270006, "Boots of the People's Militia", "Leather", 9077 },
})
Quest({ 783, 18 }, nil, {
    { 1159, "Militia Quarterstaff", "Staff", 227 },
    { 1161, "Militia Shortsword", "Sword", 201 },
    { 2224, "Militia Dagger", "Dagger", 1180 },
    { 5579, "Militia Warhammer", "Two-handed Mace", 199 },
    { 5580, "Militia Hammer", "Mace", 198 },
})
Quest({ 783, 7, 15, 21 }, nil, {
    { 2186, "Outfitter Belt", "Leather", 9077 },
    { 2691, "Outfitter Boots", "Mail", 8737 },
    { 11192, "Outfitter Gloves", "Cloth" },
})
Quest({ 33 }, nil, {
    { 80, "Soft Fur-lined Shoes", "Cloth" },
    { 6070, "Wolfskin Bracers", "Leather", 9077 },
})
Quest({ 34 }, nil, {
    { 2562, "Bouquet of Scarlet Begonias", "Accessory" },
})
Quest({ 36, 38 }, nil, {
    { 1479, "Salma's Oven Mitts", "Cloth" },
    { 2225, "Sharp Kitchen Knife", "Dagger", 1180 },
})
Quest({ 40, 35, 37, 45, 71, 39, 46 }, nil, {
    { 1008, "Well-used Sword", "Sword", 201 },
    { 1158, "Solid Metal Club", "Mace", 198 },
    { 4840, "Long Bayonet", "Dagger", 1180 },
    { 276686, "Junior's Hunting Bow", "Bow", 264 },
})
Quest({ 48, 49, 50, 51, 53 }, nil, {
    { 744, "Thunderbrew's Boot Flask", "Accessory" },
})
Quest({ 783, 7, 15, 21, 54 }, nil, {
    { 6078, "Pikeman Shield", "Shield", 9116 },
})
Quest({ 95, 230, 262, 265, 266, 453, 268, 323, 269, 270, 321, 324, 322, 325, 55 }, nil, {
    { 1282, "Sparkmetal Coif", "Mail", 8737 },
    { 2953, "Watch Master's Cloak", "Cloth" },
    { 2954, "Night Watch Pantaloons", "Cloth" },
    { 7344, "Torch of Holy Flame", "Accessory" },
})
Quest({ 40, 35, 37, 45, 71, 39, 59 }, nil, {
    { 1171, "Well-stitched Robe", "Cloth" },
    { 2237, "Patched Pants", "Leather", 9077 },
})
Quest({ 83 }, nil, {
    { 983, "Red Linen Sash", "Cloth" },
    { 2575, "Red Linen Shirt", "Accessory" },
})
Quest({ 85, 86, 84, 87 }, nil, {
    { 1359, "Lion-stamped Gloves", "Leather", 9077 },
})
Quest({ 88 }, nil, {
    { 1173, "Weather-worn Boots", "Leather", 9077 },
    { 1182, "Brass-studded Bracers", "Mail", 8737 },
    { 11191, "Farmer's Boots", "Cloth" },
})
Quest({ 125, 89 }, nil, {
    { 1303, "Bridgeworker's Gloves", "Mail", 8737 },
    { 1304, "Riding Gloves", "Cloth" },
    { 1310, "Smith's Trousers", "Leather", 9077 },
})
Quest({ 66, 67, 68, 69, 70, 72, 74, 75, 78, 79, 80, 97, 98 }, nil, {
    { 2043, "Ring of Forlorn Spirits", "Accessory" },
    { 2044, "Crescent of Forlorn Spirits", "Axe", 196 },
})
Quest({ 421, 422, 423, 424, 99 }, nil, {
    { 3570, "Bonegrinding Pestle", "Mace", 198 },
    { 3586, "Logsplitter", "Two-handed Axe", 197 },
    { 5242, "Cinder Wand", "Wand", 5009 },
})
Quest({ 101 }, nil, {
    { 1131, "Totem of Infliction", "Accessory" },
})
Quest({ 102 }, nil, {
    { 710, "Bracers of the People's Militia", "Cloth" },
    { 1154, "Belt of the People's Militia", "Mail", 8737 },
})
Quest({ 104 }, nil, {
    { 1172, "Grayson's Torch", "Accessory" },
    { 1557, "Buckler of the Seas", "Shield", 9116 },
    { 5240, "Torchlight Wand", "Wand", 5009 },
})
Quest({ 116 }, nil, {
    { 1270, "Finely Woven Cloak", "Cloth" },
})
Quest({ 118, 119, 122 }, nil, {
    { 1302, "Black Whelp Gloves", "Leather", 9077 },
    { 6092, "Black Whelp Boots", "Leather", 9077 },
})
Quest({ 118, 119, 124, 126 }, nil, {
    { 1319, "Ring of Iron Will", "Accessory" },
    { 2910, "Gold Militia Boots", "Mail", 8737 },
})
Quest({ 150 }, nil, {
    { 3567, "Dwarven Fishing Pole", "Gun", 266 },
})
Quest({ 151 }, nil, {
    { 2165, "Old Blanchy's Blanket", "Cloth" },
})
Quest({ 153 }, nil, {
    { 3511, "Cloak of the People's Militia", "Cloth" },
    { 5944, "Greaves of the People's Militia", "Mail", 8737 },
    { 12295, "Leggings of the People's Militia", "Cloth" },
})
Quest({ 167 }, nil, {
    { 1893, "Miner's Revenge", "Two-handed Axe", 197 },
    { 270012, "Miner's Workgloves", "Cloth" },
    { 270013, "Miner's Workboots", "Leather", 9077 },
})
Quest({ 168 }, nil, {
    { 2036, "Dusty Mining Gloves", "Leather", 9077 },
    { 2037, "Tunneler's Boots", "Mail", 8737 },
    { 270007, "Worn Miner's Waistcord", "Cloth" },
})
Quest({ 179, 170 }, nil, {
    { 2172, "Rustic Belt", "Mail", 8737 },
    { 6173, "Snow Boots", "Cloth" },
    { 6185, "Bear Shawl", "Cloth" },
})
Quest({ 176 }, nil, {
    { 6084, "Stormwind Guard Leggings", "Mail", 8737 },
    { 6085, "Footman Tunic", "Leather", 9077 },
    { 6215, "Balanced Fighting Stick", "Staff", 227 },
    { 270000, "Apprentice Wizard's Gown", "Cloth" },
})
Quest({ 179 }, nil, {
    { 719, "Rabbit Handler Gloves", "Cloth" },
    { 2547, "Boar Handler Gloves", "Mail", 8737 },
    { 6171, "Wolf Handler Gloves", "Leather", 9077 },
})
Quest({ 174, 175, 177, 181 }, nil, {
    { 7106, "Zodiac Gloves", "Cloth" },
    { 7107, "Belt of the Stars", "Mail", 8737 },
})
Quest({ 182 }, nil, {
    { 2047, "Anvilmar Hand Axe", "Axe", 196 },
    { 2048, "Anvilmar Hammer", "Mace", 198 },
    { 2195, "Anvilmar Knife", "Dagger", 1180 },
    { 5761, "Anvilmar Sledge", "Two-handed Mace", 199 },
})
Quest({ 183 }, nil, {
    { 61, "Dwarven Leather Pants", "Leather", 9077 },
    { 79, "Dwarven Cloth Britches", "Cloth" },
})
Quest({ 583, 185, 186, 187, 188 }, nil, {
    { 4107, "Tiger Hunter Gloves", "Leather", 9077 },
})
Quest({ 583, 190, 191, 192, 193 }, nil, {
    { 4108, "Panther Hunter Leggings", "Leather", 9077 },
})
Quest({ 583, 194, 195, 196, 197 }, nil, {
    { 4119, "Raptor Hunter Tunic", "Leather", 9077 },
})
Quest({ 204 }, nil, {
    { 4126, "Guerrilla Cleaver", "Axe", 196 },
    { 4140, "Palm Frond Mantle", "Cloth" },
})
Quest({ 213 }, nil, {
    { 4121, "Gemmed Gloves", "Cloth" },
})
Quest({ 182, 218 }, nil, {
    { 5581, "Smooth Walking Staff", "Staff", 227 },
    { 6176, "Dwarven Kite Shield", "Shield", 9116 },
})
Quest({ 219 }, nil, {
    { 1275, "Deputy Chain Coat", "Mail", 8737 },
    { 3431, "Bone-studded Leather", "Leather", 9077 },
    { 3555, "Robe of Solomon", "Cloth" },
})
Quest({ 173, 221, 222, 223 }, nil, {
    { 1547, "Shield of the Faith", "Shield", 9116 },
    { 2902, "Cloak of the Faith", "Cloth" },
    { 5244, "Consecrated Wand", "Wand", 5009 },
})
Quest({ 225, 227, 228, 229, 231 }, nil, {
    { 2000, "Archeus", "Two-handed Sword", 202 },
})
Quest({ 245 }, nil, {
    { 3559, "Night Watch Gauntlets", "Mail", 8737 },
})
Quest({ 94, 248, 249 }, nil, {
    { 5274, "Rose Mantle", "Cloth" },
    { 270033, "Demonhide Bracers", "Leather", 9077 },
    { 270034, "Shadow Gauntlets", "Mail", 8737 },
})
Quest({ 148, 149, 154, 157, 158, 156, 159, 133, 134, 160, 251, 401, 252, 253 }, nil, {
    { 3560, "Mantle of Honor", "Cloth" },
    { 6223, "Crest of Darkshire", "Shield", 9116 },
    { 270044, "Darkshire Shoulderguards", "Leather", 9077 },
})
Quest({ 256 }, nil, {
    { 1449, "Minor Channeling Ring", "Accessory" },
    { 6189, "Durable Chain Shoulders", "Mail", 8737 },
    { 6191, "Kimbra Boots", "Cloth" },
    { 270019, "Loch Walkers", "Leather", 9077 },
})
Quest({ 257 }, nil, {
    { 2903, "Daryl's Hunting Bow", "Bow", 264 },
    { 2904, "Daryl's Hunting Rifle", "Gun", 266 },
})
Quest({ 257, 258 }, nil, {
    { 859, "Fine Cloth Shirt", "Accessory" },
    { 3572, "Daryl's Shortsword", "Sword", 201 },
})
Quest({ 276, 277, 275 }, nil, {
    { 1273, "Forest Chain", "Mail", 8737 },
    { 2263, "Phytoblade", "Sword", 201 },
    { 3558, "Fen Keeper Robe", "Cloth" },
})
Quest({ 250, 199, 161, 274, 278, 280, 283 }, nil, {
    { 2907, "Dwarven Tree Chopper", "Two-handed Axe", 197 },
    { 2908, "Thornblade", "Dagger", 1180 },
})
Quest({ 279, 281, 284, 285, 286 }, nil, {
    { 2949, "Mariner Boots", "Leather", 9077 },
    { 2950, "Icicle Rod", "Staff", 227 },
})
Quest({ 287 }, nil, {
    { 2900, "Stone Buckler", "Shield", 9116 },
    { 3216, "Warm Winter Robe", "Cloth" },
})
Quest({ 288, 289, 290, 292, 293 }, nil, {
    { 2943, "Eye of Paleth", "Accessory" },
})
Quest({ 294, 295, 296 }, nil, {
    { 3493, "Raptor's End", "Bow", 264 },
    { 3566, "Raptorbane Armor", "Leather", 9077 },
    { 5246, "Excavation Rod", "Wand", 5009 },
})
Quest({ 297 }, nil, {
    { 3154, "Thelsamar Axe", "Axe", 196 },
    { 5241, "Dwarven Flamestick", "Wand", 5009 },
    { 6186, "Trogg Slicer", "Two-handed Sword", 202 },
})
Quest({ 299 }, nil, {
    { 2913, "Silk Mantle of Gamn", "Cloth" },
})
Quest({ 304 }, nil, {
    { 2916, "Gold Lion Shield", "Shield", 9116 },
    { 2917, "Tranquil Ring", "Accessory" },
})
Quest({ 307 }, nil, {
    { 3160, "Ironplate Buckler", "Shield", 9116 },
    { 3161, "Robe of the Keeper", "Cloth" },
    { 3166, "Ironheart Chain", "Mail", 8737 },
})
Quest({ 298, 301, 302, 273, 454, 309 }, nil, {
    { 3217, "Foreman Belt", "Cloth" },
    { 6188, "Mud Stompers", "Mail", 8737 },
})
Quest({ 312 }, nil, {
    { 6177, "Ironwrought Bracers", "Mail", 8737 },
    { 10550, "Wooly Mittens", "Cloth" },
})
Quest({ 314 }, nil, {
    { 2817, "Soft Leather Tunic", "Leather", 9077 },
    { 3103, "Coldridge Hammer", "Two-handed Mace", 199 },
    { 10549, "Rancher's Trousers", "Cloth" },
})
Quest({ 315 }, nil, {
    { 2326, "Ivy-weave Bracers", "Cloth" },
    { 2905, "Goat Fur Cloak", "Cloth" },
})
Quest({ 317, 318, 319, 320 }, nil, {
    { 1010, "Gnarled Short Staff", "Staff", 227 },
    { 1011, "Sharp Axe", "Axe", 196 },
    { 10547, "Camping Knife", "Dagger", 1180 },
})
Quest({ 215, 200, 328 }, nil, {
    { 4122, "Bookmaker's Scepter", "Mace", 198 },
})
Quest({ 215, 200, 328, 329, 330, 331 }, nil, {
    { 4123, "Frost Metal Pauldrons", "Mail", 8737 },
    { 4139, "Junglewalker Sandals", "Cloth" },
})
Quest({ 583, 338 }, nil, {
    { 17688, "Jungle Boots", "Plate", 750 },
})
Quest({ 343, 344, 345, 347, 346 }, nil, {
    { 6095, "Wandering Boots", "Cloth" },
})
Quest({ 348 }, nil, {
    { 4113, "Medicine Blanket", "Cloth" },
})
Quest({ 358 }, nil, {
    { 3439, "Zombie Skin Boots", "Leather", 9077 },
    { 6063, "Cold Steel Gauntlets", "Mail", 8737 },
})
Quest({ 364 }, nil, {
    { 3275, "Flax Gloves", "Cloth" },
    { 11847, "Battered Cloak", "Cloth" },
})
Quest({ 367, 368, 369 }, nil, {
    { 3442, "Apprentice Sash", "Cloth" },
})
Quest({ 427, 370, 371, 372 }, nil, {
    { 3071, "Striking Hatchet", "Axe", 196 },
    { 3445, "Ceremonial Knife", "Dagger", 1180 },
})
Quest({ 427, 374 }, nil, {
    { 3435, "Zombie Skin Bracers", "Leather", 9077 },
    { 3437, "Clasped Belt", "Mail", 8737 },
    { 12299, "Netted Gloves", "Cloth" },
})
Quest({ 375 }, nil, {
    { 3833, "Adept's Cloak", "Cloth" },
    { 5939, "Sewing Gloves", "Leather", 9077 },
})
Quest({ 376 }, nil, {
    { 2173, "Old Leather Belt", "Leather", 9077 },
    { 6060, "Flax Bracers", "Cloth" },
})
Quest({ 377 }, nil, {
    { 2033, "Ambassador's Boots", "Leather", 9077 },
    { 2906, "Darkshire Mail Leggings", "Mail", 8737 },
    { 270029, "Town Clerk's Mittens", "Cloth" },
})
Quest({ 303, 378 }, nil, {
    { 1264, "Headbasher", "Two-handed Mace", 199 },
    { 3562, "Belt of Vindication", "Leather", 9077 },
    { 270036, "Magistrate's Pantaloons", "Cloth" },
})
Quest({ 376, 380 }, nil, {
    { 3270, "Flax Vest", "Cloth" },
    { 3272, "Zombie Skin Leggings", "Leather", 9077 },
    { 3273, "Rugged Mail Vest", "Mail", 8737 },
})
Quest({ 376, 380, 381 }, nil, {
    { 3267, "Forsaken Shortsword", "Sword", 201 },
    { 3268, "Forsaken Dagger", "Dagger", 1180 },
    { 3269, "Forsaken Maul", "Mace", 198 },
    { 5779, "Forsaken Bastard Sword", "Two-handed Sword", 202 },
})
Quest({ 376, 380, 381, 382 }, nil, {
    { 3276, "Deathguard Buckler", "Shield", 9116 },
    { 3277, "Executor Staff", "Staff", 227 },
})
Quest({ 385 }, nil, {
    { 2240, "Rugged Cape", "Cloth" },
})
Quest({ 386 }, nil, {
    { 270027, "Ursine Hammer", "Two-handed Mace", 199 },
})
Quest({ 335, 336, 397 }, nil, {
    { 3556, "Dread Mage Hat", "Cloth" },
})
Quest({ 398 }, nil, {
    { 3444, "Tiller's Vest", "Leather", 9077 },
    { 5941, "Brass Scale Pants", "Mail", 8737 },
})
Quest({ 358, 405, 357, 366, 409, 411 }, nil, {
    { 5940, "Bone Buckler", "Shield", 9116 },
})
Quest({ 412 }, nil, {
    { 3152, "Driving Gloves", "Leather", 9077 },
    { 3153, "Oil-stained Cloak", "Cloth" },
})
Quest({ 416 }, nil, {
    { 860, "Cavalier's Boots", "Cloth" },
    { 3158, "Burnt Hide Bracers", "Leather", 9077 },
})
Quest({ 419, 417 }, nil, {
    { 1009, "Compact Hammer", "Mace", 198 },
    { 2218, "Craftsman's Dagger", "Dagger", 1180 },
})
Quest({ 419 }, nil, {
    { 3151, "Siege Brigade Vest", "Mail", 8737 },
})
Quest({ 429, 430, 91920, 91921, 425 }, nil, {
    { 3453, "Quilted Bracers", "Cloth" },
    { 3583, "Weathered Belt", "Leather", 9077 },
})
Quest({ 404, 426 }, nil, {
    { 3447, "Cryptwalker Boots", "Mail", 8737 },
    { 3834, "Sturdy Cloth Trousers", "Cloth" },
})
Quest({ 435 }, nil, {
    { 3455, "Deathstalker Shortsword", "Sword", 201 },
})
Quest({ 437 }, nil, {
    { 3454, "Reconnaissance Boots", "Cloth" },
})
Quest({ 437, 438, 439, 443, 444, 446, 448, 442 }, nil, {
    { 3461, "High Robe of the Adjudicator", "Cloth" },
    { 3462, "Talonstrike", "Sword", 201 },
    { 270020, "Gnollhide Pants", "Leather", 9077 },
    { 276722, "Gnoll Shackles", "Mail", 8737 },
})
Quest({ 447, 450, 451 }, nil, {
    { 3451, "Nightglow Concoction", "Accessory" },
    { 3582, "Acidproof Cloak", "Cloth" },
    { 276723, "Wise Gauntlets", "Mail", 8737 },
})
Quest({ 452 }, nil, {
    { 2818, "Stretched Leather Trousers", "Leather", 9077 },
    { 3449, "Mystic Shawl", "Cloth" },
    { 3450, "Faerleia's Shield", "Shield", 9116 },
})
Quest({ 456 }, nil, {
    { 5394, "Archery Training Gloves", "Leather", 9077 },
    { 11187, "Stemleaf Bracers", "Cloth" },
})
Quest({ 456, 457 }, nil, {
    { 5405, "Draped Cloak", "Cloth" },
    { 6058, "Blackened Leather Belt", "Leather", 9077 },
})
Quest({ 458, 459 }, nil, {
    { 5398, "Canopy Leggings", "Leather", 9077 },
    { 5399, "Tracking Boots", "Mail", 8737 },
    { 11190, "Viny Gloves", "Cloth" },
})
Quest({ 466 }, nil, {
    { 3565, "Beerstained Gloves", "Cloth" },
})
Quest({ 475, 476, 483 }, nil, {
    { 9599, "Barkmail Leggings", "Mail", 8737 },
    { 9603, "Gritroot Staff", "Staff", 227 },
})
Quest({ 475, 476, 483, 486 }, nil, {
    { 5459, "Defender Axe", "Axe", 196 },
    { 5587, "Thornroot Club", "Mace", 198 },
})
Quest({ 498 }, nil, {
    { 3733, "Orcish War Chain", "Mail", 8737 },
    { 3752, "Grunt Vest", "Cloth" },
})
Quest({ 501 }, nil, {
    { 2230, "Gloves of Brawn", "Mail", 8737 },
    { 3741, "Stomping Boots", "Leather", 9077 },
    { 6482, "Firewalker Boots", "Cloth" },
    { 276724, "Trophy Belt", "Mail", 8737 },
})
Quest({ 500, 504 }, nil, {
    { 3763, "Lunar Buckler", "Shield", 9116 },
    { 5249, "Burning Sliver", "Wand", 5009 },
})
Quest({ 505 }, nil, {
    { 3758, "Crusader Belt", "Mail", 8737 },
    { 3759, "Insulated Sage Gloves", "Cloth" },
})
Quest({ 498, 533, 503, 506, 507, 508 }, nil, {
    { 3764, "Mantis Boots", "Cloth" },
    { 3765, "Brigand's Pauldrons", "Mail", 8737 },
})
Quest({ 509, 513, 515 }, nil, {
    { 3747, "Meditative Sash", "Leather", 9077 },
    { 3749, "High Apothecary Cloak", "Cloth" },
})
Quest({ 516 }, nil, {
    { 5252, "Wand of Decay", "Wand", 5009 },
})
Quest({ 518, 519, 520, 521 }, nil, {
    { 4430, "Ethereal Talisman", "Accessory" },
})
Quest({ 437, 438, 439, 440, 441, 530 }, nil, {
    { 3235, "Ring of Scorn", "Accessory" },
})
Quest({ 527, 546 }, nil, {
    { 3739, "Skull Ring", "Accessory" },
})
Quest({ 547 }, nil, {
    { 3750, "Ribbed Breastplate", "Leather", 9077 },
    { 3751, "Mercenary Leggings", "Mail", 8737 },
})
Quest({ 549 }, nil, {
    { 276720, "Criminal's Pauldrons", "Mail", 8737 },
})
Quest({ 527, 528, 529, 532, 539, 541, 550 }, nil, {
    { 3760, "Band of the Undercity", "Accessory" },
    { 3761, "Deadskull Shield", "Shield", 9116 },
    { 3822, "Runic Darkblade", "Two-handed Sword", 202 },
    { 6282, "Sacred Burial Trousers", "Cloth" },
})
Quest({ 536, 559, 560, 561, 562 }, nil, {
    { 3755, "Fish Gutter", "Axe", 196 },
})
Quest({ 564 }, nil, {
    { 3753, "Shepherd's Girdle", "Leather", 9077 },
    { 3754, "Shepherd's Gloves", "Leather", 9077 },
})
Quest({ 565 }, nil, {
    { 2805, "Yeti Fur Cloak", "Cloth" },
    { 287069, "Yeti Skinner", "Thrown", 2567 },
})
Quest({ 549, 566 }, nil, {
    { 2231, "Inferno Robe", "Cloth" },
})
Quest({ 567 }, nil, {
    { 3732, "Hooded Cowl", "Cloth" },
    { 3742, "Bow of Plunder", "Bow", 264 },
    { 3743, "Sentry Buckler", "Shield", 9116 },
    { 5250, "Charred Wand", "Wand", 5009 },
})
Quest({ 568, 569 }, nil, {
    { 4115, "Grom'gol Buckler", "Shield", 9116 },
})
Quest({ 570, 572, 571, 573 }, nil, {
    { 4112, "Choker of the High Shaman", "Accessory" },
})
Quest({ 595, 597, 576 }, nil, {
    { 4114, "Darktide Cape", "Cloth" },
})
Quest({ 581, 582 }, nil, {
    { 4132, "Darkspear Armsplints", "Mail", 8737 },
    { 4133, "Darkspear Cuffs", "Cloth" },
})
Quest({ 596 }, nil, {
    { 4135, "Bloodbone Band", "Accessory" },
})
Quest({ 605, 600 }, nil, {
    { 4128, "Silver Spade", "Two-handed Mace", 199 },
    { 5253, "Goblin Igniter", "Wand", 5009 },
    { 287071, "Goblin Switchblade", "Thrown", 2567 },
})
Quest({ 595, 597, 599, 604, 608 }, nil, {
    { 4138, "Blackwater Tunic", "Mail", 8737 },
})
Quest({ 616, 578, 601, 602, 603, 610, 611 }, nil, {
    { 4120, "Robe of Crystal Waters", "Cloth" },
})
Quest({ 606, 607, 609, 613 }, nil, {
    { 4129, "Collection Plate", "Shield", 9116 },
})
Quest({ 617 }, nil, {
    { 4117, "Scorching Sash", "Cloth" },
})
Quest({ 621 }, nil, {
    { 4131, "Belt of Corruption", "Leather", 9077 },
})
Quest({ 210, 627, 622 }, nil, {
    { 4124, "Cap of Harmony", "Leather", 9077 },
})
Quest({ 575, 577, 628 }, nil, {
    { 4109, "Excelsior Boots", "Leather", 9077 },
})
Quest({ 631, 632, 633 }, nil, {
    { 4504, "Dwarven Guard Cloak", "Cloth" },
    { 4505, "Swampland Trousers", "Cloth" },
})
Quest({ 639, 640, 641, 643, 644, 645, 646 }, nil, {
    { 4507, "Pit Fighter's Shield", "Shield", 9116 },
    { 4508, "Blood-tinged Armor", "Mail", 8737 },
})
Quest({ 659, 658, 657, 660, 661 }, nil, {
    { 15455, "Dustfall Robes", "Cloth" },
    { 15456, "Lightstep Leggings", "Leather", 9077 },
})
Quest({ 663, 662 }, nil, {
    { 4511, "Black Water Hammer", "Mace", 198 },
})
Quest({ 663, 664 }, nil, {
    { 4509, "Seawolf Gloves", "Leather", 9077 },
})
Quest({ 663, 665, 666 }, nil, {
    { 4547, "Gnomish Zapper", "Wand", 5009 },
    { 4548, "Servomechanic Sledgehammer", "Two-handed Mace", 199 },
})
Quest({ 663, 665, 666, 668, 669, 670, 667 }, nil, {
    { 4549, "Seafire Band", "Accessory" },
    { 4550, "Coldwater Ring", "Accessory" },
})
Quest({ 671, 673 }, nil, {
    { 4543, "White Drakeskin Cap", "Leather", 9077 },
    { 4545, "Radiant Silver Bracers", "Cloth" },
})
Quest({ 677, 678, 679 }, nil, {
    { 9520, "Silent Hunter", "Dagger", 1180 },
    { 9521, "Skullsplitter", "Two-handed Axe", 197 },
})
Quest({ 677, 678, 680 }, nil, {
    { 4976, "Mistspray Kilt", "Leather", 9077 },
    { 4977, "Sword of Hammerfall", "Sword", 201 },
})
Quest({ 681, 682 }, nil, {
    { 4741, "Stromgarde Cavalry Leggings", "Mail", 8737 },
})
Quest({ 684 }, nil, {
    { 4744, "Arcane Runed Bracers", "Cloth" },
})
Quest({ 685 }, nil, {
    { 4745, "War Rider Bracers", "Mail", 8737 },
    { 5247, "Rod of Sorrow", "Wand", 5009 },
})
Quest({ 691, 693, 694, 695, 696, 697 }, nil, {
    { 4975, "Vigilant Buckler", "Shield", 9116 },
    { 15104, "Wingborne Boots", "Cloth" },
})
Quest({ 738, 739, 704 }, nil, {
    { 4980, "Prospector Gloves", "Leather", 9077 },
    { 270059, "Restorer's Fine Gloves", "Cloth" },
    { 270060, "Excavator Gauntlets", "Mail", 8737 },
})
Quest({ 705 }, nil, {
    { 4086, "Flash Rifle", "Gun", 266 },
    { 5248, "Flash Wand", "Wand", 5009 },
})
Quest({ 709 }, nil, {
    { 4746, "Doomsayer's Robe", "Cloth" },
    { 270074, "Doomcaller's Pants", "Leather", 9077 },
    { 270075, "Fists of Impending Doom", "Mail", 8737 },
})
Quest({ 710, 711, 712, 716 }, nil, {
    { 4979, "Enchanted Stonecloth Bracers", "Cloth" },
})
Quest({ 719 }, nil, {
    { 4978, "Ryedol's Hammer", "Mace", 198 },
})
Quest({ 718, 733 }, nil, {
    { 4652, "Salbac Shield", "Shield", 9116 },
    { 4653, "Ironheel Boots", "Mail", 8737 },
})
Quest({ 738 }, nil, {
    { 4982, "Ripped Prospector Belt", "Leather", 9077 },
})
Quest({ 738, 739 }, nil, {
    { 4983, "Rock Pulverizer", "Two-handed Mace", 199 },
})
Quest({ 729, 731, 741 }, nil, {
    { 5629, "Hammerfist Gloves", "Leather", 9077 },
    { 5630, "Windfelt Gloves", "Leather", 9077 },
    { 11936, "Relic Hunter Belt", "Cloth" },
})
Quest({ 744 }, nil, {
    { 4967, "Tribal Warrior's Shield", "Shield", 9116 },
    { 4968, "Bound Harness", "Leather", 9077 },
})
Quest({ 746 }, nil, {
    { 4969, "Fortified Bindings", "Mail", 8737 },
    { 4970, "Rough-hewn Kodo Leggings", "Leather", 9077 },
})
Quest({ 747 }, nil, {
    { 4910, "Painted Chain Gloves", "Mail", 8737 },
    { 4954, "Nomadic Belt", "Leather", 9077 },
})
Quest({ 747, 750 }, nil, {
    { 4908, "Nomadic Bracers", "Leather", 9077 },
    { 4913, "Painted Chain Belt", "Mail", 8737 },
})
Quest({ 753, 755, 757 }, nil, {
    { 1382, "Rock Mace", "Mace", 198 },
    { 1383, "Stone Tomahawk", "Axe", 196 },
    { 2137, "Whittling Knife", "Dagger", 1180 },
    { 5776, "Elder's Cane", "Staff", 227 },
    { 5777, "Brave's Axe", "Two-handed Axe", 197 },
})
Quest({ 748, 754, 756, 758 }, nil, {
    { 4963, "Thunderhorn Cloak", "Cloth" },
})
Quest({ 720, 721, 722, 723, 724, 725, 726, 762 }, nil, {
    { 4987, "Dwarf Captain's Sword", "Sword", 201 },
})
Quest({ 749, 751, 765 }, nil, {
    { 4964, "Goblin Smasher", "Two-handed Mace", 199 },
    { 4974, "Compact Fighting Knife", "Dagger", 1180 },
})
Quest({ 766 }, nil, {
    { 4972, "Cliff Runner Boots", "Mail", 8737 },
    { 4973, "Plains Hunter Wristguards", "Leather", 9077 },
})
Quest({ 767, 771, 772 }, nil, {
    { 4906, "Rainwalker Boots", "Leather", 9077 },
    { 4958, "Sun-beaten Cloak", "Cloth" },
})
Quest({ 767, 771, 772, 773, 775, 776 }, nil, {
    { 4909, "Kodo Hunter's Leggings", "Leather", 9077 },
})
Quest({ 747, 750, 780 }, nil, {
    { 6059, "Nomadic Vest", "Leather", 9077 },
})
Quest({ 786 }, nil, {
    { 4933, "Seasoned Fighter's Cloak", "Cloth" },
    { 6062, "Heavy Cord Bracers", "Cloth" },
})
Quest({ 788 }, nil, {
    { 4914, "Battleworn Leather Gloves", "Leather", 9077 },
    { 4915, "Soft Wool Boots", "Cloth" },
})
Quest({ 788, 789 }, nil, {
    { 4919, "Soft Wool Belt", "Cloth" },
    { 4920, "Battleworn Cape", "Cloth" },
})
Quest({ 792 }, nil, {
    { 4923, "Primitive Hatchet", "Axe", 196 },
    { 4924, "Primitive Club", "Mace", 198 },
})
Quest({ 790, 804 }, nil, {
    { 4916, "Soft Wool Vest", "Cloth" },
    { 4917, "Battleworn Chain Leggings", "Mail", 8737 },
})
Quest({ 823, 806 }, nil, {
    { 4942, "Tiger Hide Boots", "Leather", 9077 },
})
Quest({ 812 }, nil, {
    { 4929, "Light Scorpid Armor", "Leather", 9077 },
    { 4937, "Charging Buckler", "Shield", 9116 },
})
Quest({ 816 }, nil, {
    { 4944, "Handsewn Cloak", "Cloth" },
})
Quest({ 784, 825 }, nil, {
    { 4928, "Sandrunner Wristguards", "Leather", 9077 },
    { 4935, "Wide Metal Girdle", "Mail", 8737 },
    { 4936, "Dirt-trodden Boots", "Cloth" },
})
Quest({ 826 }, nil, {
    { 4940, "Veiled Grips", "Leather", 9077 },
    { 4946, "Lightweight Boots", "Mail", 8737 },
})
Quest({ 823, 806, 828, 827 }, nil, {
    { 4939, "Steady Bastard Sword", "Two-handed Sword", 202 },
    { 4947, "Jagged Dagger", "Dagger", 1180 },
    { 4948, "Stinging Mace", "Mace", 198 },
})
Quest({ 834, 835 }, nil, {
    { 4931, "Hickory Shortbow", "Bow", 264 },
    { 4932, "Harpy Wing Clipper", "Sword", 201 },
    { 4938, "Blemished Wooden Staff", "Staff", 227 },
})
Quest({ 843, 846, 849 }, nil, {
    { 5313, "Totemic Clan Ring", "Accessory" },
})
Quest({ 850, 851, 852 }, nil, {
    { 5351, "Bounty Hunter's Ring", "Accessory" },
})
Quest({ 848, 853 }, nil, {
    { 5340, "Cauldron Stirrer", "Staff", 227 },
})
Quest({ 855 }, nil, {
    { 5344, "Pointed Axe", "Axe", 196 },
    { 5345, "Stonewood Hammer", "Two-handed Mace", 199 },
    { 5346, "Orcish Battle Bow", "Bow", 264 },
})
Quest({ 858, 863 }, nil, {
    { 5326, "Flaring Baton", "Wand", 5009 },
    { 5327, "Greasy Tinker's Pants", "Leather", 9077 },
})
Quest({ 868 }, nil, {
    { 6502, "Violet Scale Armor", "Mail", 8737 },
    { 6503, "Harlequin Robes", "Cloth" },
})
Quest({ 871, 872 }, nil, {
    { 5275, "Binding Girdle", "Leather", 9077 },
    { 5328, "Cinched Belt", "Mail", 8737 },
})
Quest({ 844, 845, 903, 881, 905, 3261, 882, 907, 913, 874, 873 }, nil, {
    { 5355, "Beastmaster's Girdle", "Leather", 9077 },
    { 5356, "Branding Rod", "Wand", 5009 },
    { 5357, "Ward of the Vale", "Shield", 9116 },
})
Quest({ 867, 875, 876 }, nil, {
    { 5279, "Harpy Skinner", "Dagger", 1180 },
    { 5318, "Zhovur Axe", "Two-handed Axe", 197 },
    { 5321, "Elegant Shortsword", "Sword", 201 },
})
Quest({ 887, 890, 892, 888 }, nil, {
    { 5320, "Padded Lamellar Boots", "Mail", 8737 },
    { 5337, "Wayfaring Gloves", "Cloth" },
})
Quest({ 891 }, nil, {
    { 5309, "Privateer Musket", "Gun", 266 },
    { 5310, "Sea Dog Britches", "Cloth" },
})
Quest({ 893 }, nil, {
    { 5322, "Demolition Hammer", "Two-handed Mace", 199 },
})
Quest({ 898 }, nil, {
    { 5311, "Buckled Boots", "Leather", 9077 },
    { 5312, "Riveted Gauntlets", "Mail", 8737 },
    { 270011, "Embroidered Leggings", "Cloth" },
})
Quest({ 899 }, nil, {
    { 5314, "Boar Hunter's Cape", "Cloth" },
    { 6477, "Grassland Sash", "Cloth" },
})
Quest({ 894, 900, 901, 902 }, nil, {
    { 5324, "Engineer's Hammer", "Mace", 198 },
    { 5325, "Welding Shield", "Shield", 9116 },
})
Quest({ 878, 5052, 879, 906 }, nil, {
    { 5316, "Barkshell Tunic", "Leather", 9077 },
    { 5317, "Dry Moss Tunic", "Leather", 9077 },
})
Quest({ 844, 845, 903, 881, 905, 3261, 882, 907, 913 }, nil, {
    { 5299, "Gloves of the Moon", "Leather", 9077 },
    { 5302, "Cobalt Buckler", "Shield", 9116 },
    { 5306, "Wind Rider Staff", "Staff", 227 },
})
Quest({ 916 }, nil, {
    { 5392, "Thistlewood Dagger", "Dagger", 1180 },
    { 5393, "Thistlewood Staff", "Staff", 227 },
    { 5586, "Thistlewood Blade", "Sword", 201 },
    { 10544, "Thistlewood Maul", "Mace", 198 },
})
Quest({ 916, 917 }, nil, {
    { 4907, "Woodland Tunic", "Leather", 9077 },
    { 5395, "Woodland Shield", "Shield", 9116 },
    { 11189, "Woodland Robes", "Cloth" },
})
Quest({ 919 }, nil, {
    { 5606, "Gardening Gloves", "Cloth" },
    { 6061, "Graystone Bracers", "Mail", 8737 },
})
Quest({ 918, 922, 923 }, nil, {
    { 5605, "Pruning Knife", "Dagger", 1180 },
})
Quest({ 823, 806, 828, 827, 829, 809, 924 }, nil, {
    { 5420, "Banshee Armor", "Cloth" },
})
Quest({ 932 }, nil, {
    { 2571, "Viny Wrappings", "Cloth" },
    { 5419, "Feral Bracers", "Leather", 9077 },
})
Quest({ 937 }, nil, {
    { 5591, "Rain-spotted Cape", "Cloth" },
    { 5592, "Shackled Girdle", "Mail", 8737 },
})
Quest({ 938 }, nil, {
    { 5590, "Cord Bracers", "Cloth" },
    { 5593, "Crag Buckler", "Shield", 9116 },
    { 5618, "Scout's Cloak", "Cloth" },
})
Quest({ 937, 98392, 98398, 940 }, nil, {
    { 281250, "Forest Oracle's Cloak", "Accessory" },
})
Quest({ 729, 731, 741, 942, 943 }, nil, {
    { 5626, "Skullchipper", "Two-handed Axe", 197 },
    { 5627, "Relic Blade", "Dagger", 1180 },
    { 270022, "Archaeologist's Gown", "Cloth" },
})
Quest({ 947 }, nil, {
    { 5610, "Gustweald Cloak", "Cloth" },
})
Quest({ 947, 948, 944, 949, 950, 951 }, nil, {
    { 5615, "Woodsman Sword", "Two-handed Sword", 202 },
    { 5757, "Hardwood Cudgel", "Mace", 198 },
})
Quest({ 954, 955, 956, 957 }, nil, {
    { 5604, "Elven Wand", "Wand", 5009 },
    { 5617, "Vagabond Leggings", "Leather", 9077 },
    { 7229, "Explorer's Vest", "Mail", 8737 },
})
Quest({ 958 }, nil, {
    { 5612, "Ivy Cuffs", "Leather", 9077 },
})
Quest({ 962 }, nil, {
    { 270008, "Heat Resistant Mitts", "Leather", 9077 },
    { 270009, "Safety Boots", "Mail", 8737 },
})
Quest({ 963 }, nil, {
    { 5611, "Tear of Grief", "Accessory" },
})
Quest({ 965, 966, 967, 970, 973 }, nil, {
    { 5613, "Staff of the Purifier", "Staff", 227 },
    { 5622, "Clergy Ring", "Accessory" },
})
Quest({ 965, 966, 967, 970, 973, 976 }, nil, {
    { 6721, "Chestplate of Kor", "Mail", 8737 },
})
Quest({ 965, 966, 967, 970, 973, 1140, 1167, 1143, 981 }, nil, {
    { 5614, "Seraph's Strike", "Two-handed Sword", 202 },
    { 10043, "Pious Legwraps", "Cloth" },
})
Quest({ 982 }, nil, {
    { 15401, "Welldrip Gloves", "Cloth" },
    { 15402, "Noosegrip Gauntlets", "Mail", 8737 },
    { 270004, "Murloc-hide Gloves", "Leather", 9077 },
})
Quest({ 984, 985, 986, 993, 994 }, nil, {
    { 5609, "Steadfast Cinch", "Leather", 9077 },
})
Quest({ 984, 985, 986, 993, 995 }, nil, {
    { 6659, "Scarab Trousers", "Cloth" },
})
Quest({ 1007, 1009 }, nil, {
    { 5812, "Robes of Antiquity", "Cloth" },
})
Quest({ 1011, 1012 }, nil, {
    { 5813, "Emil's Brand", "Two-handed Sword", 202 },
})
Quest({ 1013 }, nil, {
    { 4534, "Steel-clasped Bracers", "Mail", 8737 },
    { 6335, "Grizzled Boots", "Leather", 9077 },
    { 270030, "Tattered Mittens", "Cloth" },
})
Quest({ 1021, 1031 }, nil, {
    { 5820, "Faerie Mantle", "Cloth" },
    { 11229, "Brightscale Girdle", "Mail", 8737 },
})
Quest({ 1010, 1020, 1033, 1034, 1035 }, nil, {
    { 5814, "Snapbrook Armor", "Leather", 9077 },
    { 6722, "Beastial Manacles", "Mail", 8737 },
    { 17047, "Luminescent Amice", "Cloth" },
})
Quest({ 1022, 1037, 1038, 1039, 1040, 1041, 1042, 1043, 1044 }, nil, {
    { 5817, "Lunaris Bow", "Bow", 264 },
    { 5818, "Moonbeam Wand", "Wand", 5009 },
})
Quest({ 991, 1023, 1024, 1026, 1027, 1028, 1055, 1029, 1030, 1045, 1046 }, nil, {
    { 1116, "Ring of Pure Silver", "Accessory" },
    { 5815, "Glacial Stone", "Two-handed Mace", 199 },
    { 17046, "Gutterblade", "Axe", 196 },
})
Quest({ 1048 }, nil, {
    { 6802, "Sword of Omen", "Sword", 201 },
    { 6803, "Prophetic Cane", "Accessory" },
    { 10711, "Dragon's Blood Necklace", "Accessory" },
})
Quest({ 1049 }, nil, {
    { 7747, "Vile Protector", "Shield", 9116 },
    { 7749, "Omega Orb", "Accessory" },
    { 17508, "Forcestone Buckler", "Shield", 9116 },
})
Quest({ 1050 }, nil, {
    { 7746, "Explorers' League Commendation", "Accessory" },
})
Quest({ 261, 1052, 1053 }, nil, {
    { 6829, "Sword of Serenity", "Sword", 201 },
    { 6830, "Bonebiter", "Two-handed Axe", 197 },
    { 6831, "Black Menace", "Dagger", 1180 },
    { 11262, "Orb of Lorica", "Accessory" },
})
Quest({ 1058 }, nil, {
    { 6664, "Voodoo Mantle", "Cloth" },
    { 6665, "Hexed Bracers", "Mail", 8737 },
})
Quest({ 1057, 1059 }, nil, {
    { 6675, "Tempered Bracers", "Mail", 8737 },
    { 6676, "Constable Buckler", "Shield", 9116 },
    { 270035, "Reclaimer's Robes", "Cloth" },
})
Quest({ 1078 }, nil, {
    { 6677, "Spellcrafter Wand", "Wand", 5009 },
})
Quest({ 1087, 1088, 1089 }, nil, {
    { 6669, "Sacred Band", "Accessory" },
    { 6670, "Panther Armor", "Leather", 9077 },
    { 6671, "Juggernaut Leggings", "Mail", 8737 },
})
Quest({ 1090, 1092 }, nil, {
    { 6666, "Dredge Boots", "Mail", 8737 },
})
Quest({ 1093, 1094, 1095, 1096 }, nil, {
    { 6667, "Engineer's Cloak", "Cloth" },
    { 6668, "Draftsman Boots", "Leather", 9077 },
})
Quest({ 1098 }, nil, {
    { 3324, "Ghostly Mantle", "Cloth" },
    { 270023, "Tanned Shoulderpads", "Leather", 9077 },
    { 270024, "Bronzed Shoulderguards", "Mail", 8737 },
})
Quest({ 1135 }, nil, {
    { 6719, "Windborne Belt", "Leather", 9077 },
})
Quest({ 1131, 1136 }, nil, {
    { 6720, "Spirit Hunter Headdress", "Leather", 9077 },
})
Quest({ 1138 }, nil, {
    { 15405, "Shucking Gloves", "Leather", 9077 },
    { 15406, "Crustacean Boots", "Mail", 8737 },
})
Quest({ 720, 721, 722, 723, 724, 725, 726, 762, 1139 }, nil, {
    { 270095, "Medal of Valor", "Accessory" },
})
Quest({ 893, 1153 }, nil, {
    { 6741, "Orcish War Sword", "Two-handed Sword", 202 },
})
Quest({ 1164 }, nil, {
    { 2032, "Gallan Cuffs", "Cloth" },
    { 4443, "Grim Pauldrons", "Mail", 8737 },
})
Quest({ 1166 }, nil, {
    { 10702, "Enormous Ogre Boots", "Leather", 9077 },
})
Quest({ 1168 }, nil, {
    { 9705, "Tharg's Shoelace", "Leather", 9077 },
    { 9706, "Tharg's Disk", "Shield", 9116 },
})
Quest({ 1169 }, nil, {
    { 9703, "Scorched Cape", "Cloth" },
    { 9704, "Rustler Gloves", "Leather", 9077 },
})
Quest({ 1169, 1170, 1171, 1172 }, nil, {
    { 10700, "Encarmine Boots", "Cloth" },
    { 10701, "Boots of Zua'tec", "Mail", 8737 },
})
Quest({ 1169, 1170, 1171, 1172, 1173 }, nil, {
    { 10703, "Fiendish Skiv", "Dagger", 1180 },
    { 10704, "Chillnail Splinter", "Wand", 5009 },
})
Quest({ 1177 }, nil, {
    { 9518, "Mud's Crushers", "Leather", 9077 },
    { 9519, "Durtfeet Stompers", "Cloth" },
})
Quest({ 1176, 1178, 1180, 1181, 1182, 1183, 1186, 1187, 1188, 1189 }, nil, {
    { 6726, "Razzeric's Customized Seatbelt", "Cloth" },
    { 6727, "Razzeric's Racing Grips", "Leather", 9077 },
})
Quest({ 1195, 1196, 1197 }, nil, {
    { 6739, "Cliffrunner's Aim", "Bow", 264 },
    { 6740, "Azure Sash", "Leather", 9077 },
})
Quest({ 1199 }, nil, {
    { 6998, "Nimbus Boots", "Cloth" },
    { 7000, "Heartwood Girdle", "Leather", 9077 },
    { 270025, "Silvered Gauntlets", "Mail", 8737 },
})
Quest({ 1218, 1206, 1203 }, nil, {
    { 5016, "Artisan's Trousers", "Cloth" },
    { 9622, "Reedknot Ring", "Accessory" },
})
Quest({ 1204, 1258 }, nil, {
    { 6801, "Baroque Apron", "Cloth" },
})
Quest({ 1274, 1241, 1242, 1243, 1244, 1245, 1246, 1447, 1247, 1248, 1249, 1250, 1264, 1265, 1266, 1324, 1267 }, nil, {
    { 6757, "Jaina's Signet Ring", "Accessory" },
})
Quest({ 1269, 1273 }, nil, {
    { 6797, "Eyepoker", "Wand", 5009 },
    { 6798, "Blasting Hackbut", "Gun", 266 },
})
Quest({ 1275 }, nil, {
    { 7003, "Beetle Clasps", "Mail", 8737 },
    { 7004, "Prelacy Cape", "Cloth" },
    { 270021, "Staghide Armguards", "Leather", 9077 },
})
Quest({ 435, 449, 3221, 1359, 1358 }, nil, {
    { 10637, "Brewer's Gloves", "Cloth" },
    { 10638, "Long Draping Cape", "Cloth" },
})
Quest({ 1363, 1364 }, nil, {
    { 10747, "Teacher's Sash", "Cloth" },
    { 10748, "Wanderlust Boots", "Leather", 9077 },
})
Quest({ 1365, 1366 }, nil, {
    { 6780, "Lilac Sash", "Cloth" },
    { 6784, "Braced Handguards", "Leather", 9077 },
})
Quest({ 1372, 1383 }, nil, {
    { 6832, "Cloak of Blight", "Cloth" },
    { 11265, "Cragwood Maul", "Two-handed Mace", 199 },
})
Quest({ 1387 }, nil, {
    { 6790, "Ring of Calm", "Accessory" },
})
Quest({ 1393 }, nil, {
    { 6828, "Visionary Buckler", "Shield", 9116 },
})
Quest({ 1149, 1150, 1151, 1152, 1154, 6627, 1159, 1160, 6628, 1394 }, nil, {
    { 6804, "Windstorm Hammer", "Mace", 198 },
    { 6806, "Dancing Flame", "Wand", 5009 },
})
Quest({ 698, 699, 1422, 1426, 1427 }, nil, {
    { 9678, "Tok'kar's Murloc Basher", "Two-handed Mace", 199 },
    { 9679, "Tok'kar's Murloc Chopper", "Two-handed Axe", 197 },
    { 9680, "Tok'kar's Murloc Shanker", "Dagger", 1180 },
})
Quest({ 1430 }, nil, {
    { 9682, "Leather Chef's Belt", "Leather", 9077 },
})
Quest({ 1437, 1465, 1438, 1439, 1440 }, nil, {
    { 9687, "Grappler's Belt", "Leather", 9077 },
    { 9698, "Gloves of Insight", "Leather", 9077 },
    { 9699, "Garrison Cloak", "Cloth" },
    { 11884, "Moonlit Amice", "Cloth" },
})
Quest({ 1446 }, nil, {
    { 11123, "Rainstrider Leggings", "Cloth" },
    { 11124, "Helm of Exile", "Mail", 8737 },
    { 270115, "Leggings of Freedom and Sorrow", "Leather", 9077 },
})
Quest({ 1453, 1454, 1455, 1456, 1457 }, nil, {
    { 6791, "Hellion Boots", "Cloth" },
    { 6792, "Sanguine Pauldrons", "Mail", 8737 },
})
Quest({ 1453, 1458, 1459, 1466, 1467 }, nil, {
    { 6793, "Auric Bracers", "Mail", 8737 },
    { 6794, "Stormfire Gauntlets", "Leather", 9077 },
})
Quest({ 1487 }, nil, {
    { 6481, "Dagmire Gauntlets", "Mail", 8737 },
    { 8071, "Sizzle Stick", "Wand", 5009 },
})
Quest({ 1560 }, nil, {
    { 9638, "Chelonian Cuffs", "Mail", 8737 },
    { 9642, "Band of the Great Tortoise", "Accessory" },
})
Quest({ 1699, 1702 }, nil, {
    { 6970, "Furen's Favor", "Shield", 9116 },
})
Quest({ 1699, 1702, 1701, 1782, 1705, 1706 }, nil, {
    { 6971, "Fire Hardened Coif", "Mail", 8737 },
})
Quest({ 1699, 1702, 1701, 1782, 1708, 1709 }, nil, {
    { 6974, "Fire Hardened Gauntlets", "Mail", 8737 },
})
Quest({ 1699, 1702, 1701, 1782, 1710, 1711 }, nil, {
    { 6973, "Fire Hardened Leggings", "Mail", 8737 },
})
Quest({ 1699, 1702, 1701, 1782 }, nil, {
    { 6972, "Fire Hardened Hauberk", "Mail", 8737 },
})
Quest({ 1718, 1719, 1791, 1712, 1713, 1792 }, nil, {
    { 6975, "Whirlwind Axe", "Two-handed Axe", 197 },
    { 6976, "Whirlwind Warhammer", "Two-handed Mace", 199 },
    { 6977, "Whirlwind Sword", "Two-handed Sword", 202 },
})
Quest({ 1824 }, nil, {
    { 7120, "Ruga's Bulwark", "Shield", 9116 },
})
Quest({ 1824, 1838, 1848, 1844, 1845 }, nil, {
    { 7130, "Brutal Helm", "Mail", 8737 },
})
Quest({ 1824, 1838, 1848, 1846, 1847 }, nil, {
    { 7132, "Brutal Legguards", "Mail", 8737 },
})
Quest({ 1824, 1838, 1848 }, nil, {
    { 7133, "Brutal Hauberk", "Mail", 8737 },
})
Quest({ 1920, 1921, 1941 }, nil, {
    { 7509, "Manaweave Robe", "Cloth" },
})
Quest({ 1938, 1940, 1942 }, nil, {
    { 7511, "Astral Knot Robe", "Cloth" },
    { 9516, "Astral Knot Blouse", "Cloth" },
})
Quest({ 1944, 1945, 1946 }, nil, {
    { 7512, "Nether-lace Robe", "Cloth" },
    { 9515, "Nether-lace Tunic", "Cloth" },
})
Quest({ 1954, 1955, 1956, 1957, 1958 }, nil, {
    { 7515, "Celestial Orb", "Accessory" },
    { 9517, "Celestial Stave", "Staff", 227 },
})
Quest({ 1960, 1961, 1962 }, nil, {
    { 7510, "Lesser Spellfire Robes", "Cloth" },
})
Quest({ 2038 }, nil, {
    { 12522, "Bingles' Flying Gloves", "Leather", 9077 },
})
Quest({ 2040 }, nil, {
    { 7606, "Polar Gauntlets", "Mail", 8737 },
    { 7607, "Sable Wand", "Wand", 5009 },
    { 270015, "Bravo's Armbands", "Leather", 9077 },
    { 270016, "Dreamer's Leggings", "Leather", 9077 },
})
Quest({ 2118, 2138, 2139 }, nil, {
    { 7738, "Evergreen Gloves", "Cloth" },
    { 7739, "Timberland Cape", "Cloth" },
})
Quest({ 2418 }, nil, {
    { 9522, "Energized Stone Circle", "Shield", 9116 },
    { 10358, "Duracin Bracers", "Mail", 8737 },
    { 10359, "Everlast Boots", "Cloth" },
    { 270055, "Charged Leather Bracers", "Leather", 9077 },
})
Quest({ 918, 922, 923, 2498, 2499 }, nil, {
    { 5458, "Dirtwood Belt", "Cloth" },
    { 5589, "Moss-covered Gauntlets", "Mail", 8737 },
})
Quest({ 2518, 2520 }, nil, {
    { 9600, "Lace Pants", "Cloth" },
    { 9601, "Cushioned Boots", "Leather", 9077 },
})
Quest({ 2541, 2561 }, nil, {
    { 9598, "Sleeping Robes", "Cloth" },
    { 18957, "Brushwood Blade", "Sword", 201 },
})
Quest({ 2768 }, nil, {
    { 9533, "Masons Fraternity Ring", "Accessory" },
    { 9534, "Engineer's Guild Headpiece", "Leather", 9077 },
    { 270099, "Magister Cowl", "Cloth" },
})
Quest({ 2821 }, nil, {
    { 9630, "Pratt's Handcrafted Boots", "Leather", 9077 },
    { 9631, "Pratt's Handcrafted Gloves", "Leather", 9077 },
})
Quest({ 2822 }, nil, {
    { 9632, "Jangdor's Handcrafted Gloves", "Leather", 9077 },
    { 9633, "Jangdor's Handcrafted Boots", "Leather", 9077 },
})
Quest({ 2844, 2845 }, nil, {
    { 9656, "Granite Grips", "Plate", 750 },
    { 9657, "Vinehedge Cinch", "Leather", 9077 },
})
Quest({ 2846 }, nil, {
    { 9527, "Spellshifter Rod", "Staff", 227 },
    { 9531, "Gemshale Pauldrons", "Plate", 750 },
    { 270098, "Dank Shoulderpads", "Leather", 9077 },
})
Quest({ 2866, 2867, 3130, 2869, 2870, 2871 }, nil, {
    { 9663, "Dawnrider's Chestpiece", "Mail", 8737 },
    { 9664, "Sentinel's Guard", "Plate", 750 },
})
Quest({ 2873, 2874 }, nil, {
    { 9636, "Swashbuckler Sash", "Cloth" },
    { 9637, "Shinkicker Boots", "Plate", 750 },
})
Quest({ 2862, 2863, 2902, 2903 }, nil, {
    { 9661, "Earthclasp Barrier", "Shield", 9116 },
    { 9662, "Rushridge Boots", "Plate", 750 },
})
Quest({ 2928 }, nil, {
    { 9608, "Shoni's Disarming Tool", "Axe", 196 },
    { 9609, "Shilly Mitts", "Cloth" },
    { 270045, "Operator's Gloves", "Leather", 9077 },
})
Quest({ 2930 }, nil, {
    { 9604, "Mechanic's Pipehammer", "Two-handed Mace", 199 },
    { 9605, "Repairman's Cape", "Cloth" },
})
Quest({ 2933, 2934, 2935, 2936, 2937, 2938 }, nil, {
    { 9649, "Royal Highmark Vestments", "Cloth" },
    { 9650, "Honorguard Chestpiece", "Mail", 8737 },
    { 10686, "Aegis of Battle", "Shield", 9116 },
})
Quest({ 2939, 2940, 2941, 2944, 2943, 2879, 2942 }, nil, {
    { 9654, "Cairnstone Sliver", "Wand", 5009 },
    { 9655, "Seedtime Hoop", "Accessory" },
})
Quest({ 2969, 2970, 2972 }, nil, {
    { 10705, "Firwillow Wristbands", "Cloth" },
    { 10706, "Nightscale Girdle", "Mail", 8737 },
})
Quest({ 2973, 2974, 2976 }, nil, {
    { 11858, "Battlehard Cape", "Cloth" },
    { 11859, "Jademoon Orb", "Accessory" },
})
Quest({ 2987 }, nil, {
    { 9658, "Boots of the Maharishi", "Cloth" },
    { 9660, "Stargazer Cloak", "Cloth" },
    { 287073, "Orwin's Axe", "Thrown", 2567 },
})
Quest({ 2988, 2989, 2990, 2991, 2992, 2993, 2994 }, nil, {
    { 9651, "Gryphon Rider's Stormhammer", "Mace", 198 },
    { 9652, "Gryphon Rider's Leggings", "Leather", 9077 },
})
Quest({ 3062 }, nil, {
    { 9665, "Wingcrest Gloves", "Cloth" },
    { 9666, "Stronghorn Girdle", "Mail", 8737 },
})
Quest({ 3161 }, nil, {
    { 10826, "Staff of Lore", "Staff", 227 },
    { 10827, "Surveyor's Tunic", "Leather", 9077 },
})
Quest({ 869, 3281 }, nil, {
    { 2694, "Settler's Leggings", "Mail", 8737 },
    { 11853, "Rambling Boots", "Leather", 9077 },
})
Quest({ 870, 877, 880, 3301 }, nil, {
    { 10820, "Jackseed Belt", "Cloth" },
    { 10821, "Sower's Cloak", "Cloth" },
})
Quest({ 3376 }, nil, {
    { 10635, "Painted Chain Leggings", "Mail", 8737 },
    { 10636, "Nomadic Gloves", "Leather", 9077 },
})
Quest({ 3377, 3378 }, nil, {
    { 10745, "Kaylari Shoulders", "Leather", 9077 },
    { 10746, "Runesteel Vambraces", "Plate", 750 },
})
Quest({ 3448, 3449, 3461 }, nil, {
    { 10707, "Steelsmith Greaves", "Plate", 750 },
    { 10708, "Skullspell Orb", "Accessory" },
})
Quest({ 3441, 3442, 3443, 3452, 3453, 3454, 3462, 3463 }, nil, {
    { 10742, "Dragonflight Leggings", "Cloth" },
    { 10743, "Drakefire Headguard", "Mail", 8737 },
    { 10744, "Axe of the Ebon Drake", "Axe", 196 },
})
Quest({ 3504, 3505, 3506, 3507 }, nil, {
    { 10709, "Pyrestone Orb", "Accessory" },
    { 11120, "Belgrom's Hammer", "Mace", 198 },
})
Quest({ 4495, 3519, 3521, 3522 }, nil, {
    { 10655, "Sedgeweed Britches", "Cloth" },
    { 10656, "Barkmail Vest", "Mail", 8737 },
})
Quest({ 3520, 3527, 4787, 3528 }, nil, {
    { 10749, "Avenguard Helm", "Plate", 750 },
    { 10750, "Lifeforce Dirk", "Dagger", 1180 },
    { 10751, "Gemburst Circlet", "Cloth" },
})
Quest({ 3367, 3368, 3371, 3372, 3566 }, nil, {
    { 10739, "Ring of Fortitude", "Accessory" },
    { 10740, "Centurion Legplates", "Plate", 750 },
    { 10741, "Lordrec Helmet", "Leather", 9077 },
})
Quest({ 3702, 3701 }, nil, {
    { 12102, "Ring of the Aristocrat", "Accessory" },
})
Quest({ 3764, 3781, 3791 }, nil, {
    { 11888, "Quintis' Research Gloves", "Cloth" },
    { 11889, "Bark Iron Pauldrons", "Plate", 750 },
})
Quest({ 3821, 3822 }, nil, {
    { 11869, "Sha'ni's Ring", "Accessory" },
})
Quest({ 3823, 3824, 3825 }, nil, {
    { 11867, "Maddening Gauntlets", "Mail", 8737 },
    { 11868, "Choking Band", "Accessory" },
})
Quest({ 3882 }, nil, {
    { 11908, "Archaeologist's Quarry Boots", "Cloth" },
    { 11909, "Excavator's Utility Belt", "Leather", 9077 },
})
Quest({ 364, 3901 }, nil, {
    { 3274, "Flax Boots", "Cloth" },
    { 11851, "Scavenger Tunic", "Leather", 9077 },
    { 11852, "Roamer's Leggings", "Mail", 8737 },
})
Quest({ 376, 3902 }, nil, {
    { 11848, "Flax Belt", "Cloth" },
    { 11849, "Rustmetal Bracers", "Mail", 8737 },
    { 11850, "Short Duskbat Cape", "Cloth" },
})
Quest({ 783, 18, 3904, 3905 }, nil, {
    { 2690, "Latched Belt", "Mail", 8737 },
    { 11475, "Wine-stained Cloak", "Cloth" },
})
Quest({ 894, 900, 901, 902, 3921, 3922, 3923, 3924 }, nil, {
    { 11854, "Samophlange Screwdriver", "Two-handed Sword", 202 },
    { 11855, "Tork Wrench", "Accessory" },
})
Quest({ 3844, 3845, 3908, 3909, 3912, 3913, 3914, 3941, 3942, 4084, 4005, 3961, 3962 }, nil, {
    { 11902, "Linken's Sword of Mastery", "Sword", 201 },
    { 11904, "Spirit of Aquementas", "Accessory" },
    { 11905, "Linken's Boomerang", "Accessory" },
})
Quest({ 4061, 4062, 4063 }, nil, {
    { 12108, "Basaltscale Armor", "Mail", 8737 },
    { 12109, "Azure Moon Amice", "Cloth" },
    { 12110, "Raincaster Drape", "Cloth" },
    { 12111, "Lavaplate Gauntlets", "Plate", 750 },
})
Quest({ 4081, 4082, 4122, 4121, 4132 }, nil, {
    { 12059, "Conqueror's Medallion", "Accessory" },
})
Quest({ 4136 }, nil, {
    { 11865, "Rancor Boots", "Cloth" },
    { 11963, "Penance Spaulders", "Leather", 9077 },
    { 12049, "Splintsteel Armor", "Mail", 8737 },
})
Quest({ 4124, 4125, 4127, 4129, 4130, 4131, 4135, 4265, 4266 }, nil, {
    { 11856, "Ceremonial Elven Blade", "Dagger", 1180 },
    { 11857, "Sanctimonial Rod", "Staff", 227 },
})
Quest({ 4290, 4291, 4292 }, nil, {
    { 11876, "Plainstalker Tunic", "Leather", 9077 },
    { 11882, "Outrider Leggings", "Mail", 8737 },
})
Quest({ 4300 }, nil, {
    { 11862, "White Bone Band", "Accessory" },
    { 11863, "White Bone Shredder", "Fist Weapon", 15590 },
    { 11864, "White Bone Spear", "Polearm", 200 },
})
Quest({ 4289, 4301 }, nil, {
    { 11906, "Beastsmasher", "Mace", 198 },
    { 11907, "Beastslayer", "Two-handed Axe", 197 },
})
Quest({ 4449, 4450 }, nil, {
    { 11860, "Charged Lightning Rod", "Wand", 5009 },
    { 11861, "Girdle of Reprisal", "Mail", 8737 },
})
Quest({ 4492, 4491 }, nil, {
    { 11910, "Bejeweled Legguards", "Plate", 750 },
    { 11911, "Treetop Leggings", "Cloth" },
    { 11913, "Clayridge Helm", "Mail", 8737 },
})
Quest({ 4501 }, nil, {
    { 11918, "Grotslab Gloves", "Mail", 8737 },
    { 11919, "Cragplate Greaves", "Plate", 750 },
})
Quest({ 4503 }, nil, {
    { 11915, "Shizzle's Drizzle Blocker", "Shield", 9116 },
    { 11916, "Shizzle's Muzzle", "Leather", 9077 },
    { 11917, "Shizzle's Nozzle Wiper", "Cloth" },
})
Quest({ 4512, 4513 }, nil, {
    { 12050, "Hazecover Boots", "Cloth" },
    { 12051, "Brazen Gauntlets", "Mail", 8737 },
})
Quest({ 3524, 4681 }, nil, {
    { 15398, "Sandcomber Boots", "Cloth" },
    { 15399, "Dryweed Belt", "Leather", 9077 },
    { 15400, "Clamshell Bracers", "Mail", 8737 },
})
Quest({ 4740 }, nil, {
    { 5315, "Timberland Armguards", "Cloth" },
    { 15403, "Ridgeback Bracers", "Leather", 9077 },
    { 15404, "Breakwater Girdle", "Mail", 8737 },
})
Quest({ 984, 4761, 4762, 4763 }, nil, {
    { 15202, "Wildkeeper Leggings", "Leather", 9077 },
    { 15203, "Guststorm Legguards", "Mail", 8737 },
    { 15204, "Moonstone Wand", "Wand", 5009 },
})
Quest({ 4726, 4808, 4809, 4810, 4734, 4735, 5522, 5531, 4771 }, nil, {
    { 15853, "Windreaper", "Axe", 196 },
    { 15854, "Dancing Sliver", "Staff", 227 },
})
Quest({ 1796, 4781, 4782, 4783, 4784, 4786 }, nil, {
    { 6900, "Enchanted Gold Bloodrobe", "Cloth" },
})
Quest({ 4726, 4808, 4809, 4810 }, nil, {
    { 15862, "Blitzcleaver", "Axe", 196 },
    { 15863, "Grave Scepter", "Mace", 198 },
})
Quest({ 4811, 4812, 4813 }, nil, {
    { 15335, "Briarsteel Shortsword", "Sword", 201 },
    { 15396, "Curvewood Dagger", "Dagger", 1180 },
    { 15397, "Oakthrush Staff", "Staff", 227 },
})
Quest({ 974, 980, 4842 }, nil, {
    { 15789, "Deep River Cloak", "Cloth" },
})
Quest({ 4866 }, nil, {
    { 15873, "Ragged John's Neverending Cup", "Accessory" },
})
Quest({ 3661, 978, 979, 4901, 4902 }, nil, {
    { 16622, "Thornflinger", "Bow", 264 },
    { 16623, "Opaline Medallion", "Accessory" },
})
Quest({ 4904 }, nil, {
    { 15468, "Windsong Drape", "Cloth" },
    { 15469, "Windsong Cinch", "Leather", 9077 },
})
Quest({ 4421, 4906 }, nil, {
    { 11875, "Breezecloud Bracers", "Cloth" },
})
Quest({ 4971 }, nil, {
    { 15812, "Orchid Amice", "Cloth" },
    { 15813, "Gold Link Belt", "Mail", 8737 },
})
Quest({ 5054, 5055, 5056 }, nil, {
    { 15782, "Beaststalker Blade", "Sword", 201 },
    { 15783, "Beasthunter Dagger", "Dagger", 1180 },
})
Quest({ 5054, 5055, 5056, 5057 }, nil, {
    { 15704, "Hunter's Insignia Medal", "Accessory" },
})
Quest({ 5060 }, nil, {
    { 13474, "Farmer Dalson's Shotgun", "Gun", 266 },
    { 13475, "Dalson Family Wedding Ring", "Accessory" },
})
Quest({ 4841, 5064 }, nil, {
    { 15457, "Desert Shoulders", "Cloth" },
    { 15458, "Tundra Boots", "Leather", 9077 },
    { 15459, "Grimtoll Wristguards", "Mail", 8737 },
})
Quest({ 4821, 4865, 5062, 5088 }, nil, {
    { 15464, "Brute Hammer", "Two-handed Mace", 199 },
    { 15465, "Stingshot Wand", "Wand", 5009 },
    { 15466, "Clink Shield", "Shield", 9116 },
})
Quest({ 5147 }, nil, {
    { 15470, "Plainsguard Leggings", "Mail", 8737 },
    { 15471, "Brawnhide Armor", "Leather", 9077 },
})
Quest({ 5151 }, nil, {
    { 15467, "Inventor's League Ring", "Accessory" },
    { 287066, "Wizlo's Tuning Wrench", "Thrown", 2567 },
})
Quest({ 5212, 5213 }, nil, {
    { 13209, "Seal of the Dawn", "Accessory" },
    { 19812, "Rune of the Dawn", "Accessory" },
})
Quest({ 5214 }, nil, {
    { 13171, "Smokey's Lighter", "Accessory" },
})
Quest({ 5155, 5157, 5158, 5159, 5165, 5242 }, nil, {
    { 15707, "Brantwood Sash", "Cloth" },
    { 15708, "Blight Leather Gloves", "Leather", 9077 },
    { 15709, "Gearforge Girdle", "Plate", 750 },
})
Quest({ 5243 }, nil, {
    { 13216, "Crown of the Penitent", "Cloth" },
    { 13217, "Band of the Penitent", "Accessory" },
})
Quest({ 5281, 5282 }, nil, {
    { 13315, "Testament of Hope", "Accessory" },
})
Quest({ 5321 }, nil, {
    { 15205, "Owlsight Rifle", "Gun", 266 },
    { 15206, "Jadefinger Baton", "Accessory" },
    { 15207, "Steelcap Shield", "Shield", 9116 },
    { 270014, "Deerhide Pants", "Leather", 9077 },
})
Quest({ 5341, 5342 }, nil, {
    { 14022, "Barov Peasant Caller", "Accessory" },
})
Quest({ 5343, 5344 }, nil, {
    { 14023, "Barov Peasant Caller", "Accessory" },
})
Quest({ 5382, 5515, 5384 }, nil, {
    { 13544, "Spectral Essence", "Accessory" },
    { 15805, "Penelope's Rose", "Accessory" },
    { 15806, "Mirah's Song", "Sword", 201 },
})
Quest({ 5501 }, nil, {
    { 15690, "Kodobone Necklace", "Accessory" },
})
Quest({ 5527, 5526 }, nil, {
    { 18535, "Milli's Shield", "Shield", 9116 },
    { 18536, "Milli's Lexicon", "Accessory" },
})
Quest({ 5561 }, nil, {
    { 15697, "Kodo Rustler Boots", "Cloth" },
    { 15698, "Wrangling Spaulders", "Mail", 8737 },
})
Quest({ 5381, 5581 }, nil, {
    { 16794, "Gripsteel Wristguards", "Mail", 8737 },
    { 16873, "Braidfur Gloves", "Leather", 9077 },
})
Quest({ 5621 }, nil, {
    { 16604, "Moon Robes of Elune", "Cloth" },
})
Quest({ 5648 }, nil, {
    { 16606, "Juju Hex Robes", "Cloth" },
})
Quest({ 5650 }, nil, {
    { 16607, "Acolyte's Sacrificial Robes", "Cloth" },
})
Quest({ 5725 }, nil, {
    { 15449, "Ghastly Trousers", "Cloth" },
    { 15450, "Dredgemire Leggings", "Leather", 9077 },
    { 15451, "Gargoyle Leggings", "Mail", 8737 },
})
Quest({ 5726, 5727, 5728, 5729, 5730 }, nil, {
    { 15424, "Axe of Orgrimmar", "Two-handed Axe", 197 },
    { 15443, "Kris of Orgrimmar", "Dagger", 1180 },
    { 15444, "Staff of Orgrimmar", "Staff", 227 },
    { 15445, "Hammer of Orgrimmar", "Mace", 198 },
})
Quest({ 5821 }, nil, {
    { 15689, "Trader's Ring", "Accessory" },
})
Quest({ 5863 }, nil, {
    { 16738, "Witherseed Gloves", "Cloth" },
    { 16739, "Rugwood Mantle", "Leather", 9077 },
})
Quest({ 5943 }, nil, {
    { 15691, "Sidegunner Shottie", "Gun", 266 },
    { 15692, "Kodo Brander", "Wand", 5009 },
    { 15695, "Studded Ring Shield", "Shield", 9116 },
})
Quest({ 6024 }, nil, {
    { 15814, "Hameya's Slayer", "Sword", 201 },
    { 15815, "Hameya's Cloak", "Cloth" },
})
Quest({ 5741, 6027 }, nil, {
    { 16791, "Silkstream Cuffs", "Cloth" },
    { 16793, "Arcmetal Shoulders", "Mail", 8737 },
})
Quest({ 6026, 6041 }, nil, {
    { 16992, "Smokey's Explosive Launcher", "Gun", 266 },
    { 16993, "Smokey's Fireshooter", "Wand", 5009 },
    { 17523, "Smokey's Drape", "Cloth" },
})
Quest({ 6134 }, nil, {
    { 15864, "Condor Bracers", "Cloth" },
    { 15865, "Anchorhold Buckler", "Shield", 9116 },
})
Quest({ 6142 }, nil, {
    { 15585, "Pardoc Grips", "Cloth" },
    { 15587, "Ringtail Girdle", "Leather", 9077 },
    { 15588, "Bracesteel Belt", "Mail", 8737 },
})
Quest({ 6161 }, nil, {
    { 16788, "Captain Rackmore's Wheel", "Shield", 9116 },
    { 16789, "Captain Rackmore's Tiller", "Wand", 5009 },
})
Quest({ 6282, 6283 }, nil, {
    { 16987, "Screecher Belt", "Leather", 9077 },
    { 16990, "Spritekin Cloak", "Cloth" },
    { 270028, "Harpy Bangles", "Cloth" },
})
Quest({ 6284 }, nil, {
    { 16891, "Claystone Shortsword", "Sword", 201 },
    { 16894, "Clear Crystal Rod", "Staff", 227 },
})
Quest({ 6301, 6381 }, nil, {
    { 16985, "Windseeker Boots", "Cloth" },
    { 16986, "Sandspire Gloves", "Mail", 8737 },
})
Quest({ 6421, 6481 }, nil, {
    { 1306, "Wolfmane Wristguards", "Leather", 9077 },
    { 16981, "Owlbeard Bracers", "Cloth" },
    { 270010, "Raptorcrest Bracers", "Mail", 8737 },
})
Quest({ 6504 }, nil, {
    { 16740, "Shredder Operating Gloves", "Cloth" },
    { 16741, "Oilrag Handwraps", "Leather", 9077 },
})
Quest({ 6544 }, nil, {
    { 16889, "Polished Walking Staff", "Staff", 227 },
    { 16890, "Slatemetal Cutlass", "Sword", 201 },
})
Quest({ 6571 }, nil, {
    { 16975, "Warsong Sash", "Cloth" },
    { 16977, "Warsong Boots", "Leather", 9077 },
    { 16978, "Warsong Gauntlets", "Mail", 8737 },
})
Quest({ 216, 6621 }, nil, {
    { 17005, "Boorguard Tunic", "Leather", 9077 },
    { 17006, "Cobalt Legguards", "Mail", 8737 },
})
Quest({ 6641 }, nil, {
    { 17692, "Horn Ring", "Accessory" },
})
Quest({ 7003 }, nil, {
    { 19040, "Zorbin's Mega-Slicer", "Sword", 201 },
})
Quest({ 7028 }, nil, {
    { 17775, "Acumen Robes", "Cloth" },
    { 17776, "Sprightring Helm", "Leather", 9077 },
    { 17777, "Relentless Chain", "Mail", 8737 },
    { 17779, "Hulkstone Pauldrons", "Plate", 750 },
})
Quest({ 7067 }, nil, {
    { 17774, "Mark of the Chosen", "Accessory" },
})
Quest({ 3906, 7201 }, nil, {
    { 12038, "Lagrave's Seal", "Accessory" },
})
Quest({ 7441 }, nil, {
    { 18410, "Sprinter's Sword", "Two-handed Sword", 202 },
    { 18411, "Spry Boots", "Leather", 9077 },
})
Quest({ 1238, 1239, 1240, 1261, 1262, 7541 }, nil, {
    { 18585, "Band of Allegiance", "Accessory" },
    { 18586, "Lonetree's Circle", "Accessory" },
})
Quest({ 7601, 7602, 7603 }, nil, {
    { 18762, "Shard of the Green Flame", "Accessory" },
})
Quest({ 7701 }, nil, {
    { 19127, "Charred Leather Tunic", "Leather", 9077 },
    { 19128, "Seared Mail Vest", "Mail", 8737 },
})
Quest({ 7721 }, nil, {
    { 19039, "Zorbin's Water Resistant Hat", "Leather", 9077 },
})
Quest({ 7723 }, nil, {
    { 19126, "Slagplate Gauntlets", "Plate", 750 },
})
Quest({ 7724 }, nil, {
    { 19125, "Seared Mail Girdle", "Mail", 8737 },
})
Quest({ 7727 }, nil, {
    { 19141, "Luffa", "Accessory" },
})
Quest({ 7728 }, nil, {
    { 19123, "Everwarm Handwraps", "Cloth" },
    { 19124, "Slagplate Leggings", "Plate", 750 },
})
Quest({ 2821, 7733 }, nil, {
    { 19041, "Pratt's Handcrafted Tunic", "Leather", 9077 },
})
Quest({ 2822, 7734 }, nil, {
    { 19042, "Jangdor's Handcrafted Tunic", "Leather", 9077 },
})
Quest({ 7841, 7842, 7843 }, nil, {
    { 19119, "Owlbeast Hide Gloves", "Leather", 9077 },
})
Quest({ 7845, 7846, 7847 }, nil, {
    { 19114, "Highland Bow", "Bow", 264 },
    { 19115, "Flask of Forest Mojo", "Accessory" },
})
Quest({ 7849 }, nil, {
    { 19116, "Greenleaf Handwraps", "Cloth" },
    { 19117, "Laquered Wooden Plate Legplates", "Plate", 750 },
})
Quest({ 7850 }, nil, {
    { 19118, "Nature's Breath", "Wand", 5009 },
})
Quest({ 7861 }, nil, {
    { 19121, "Deep Woodlands Cloak", "Cloth" },
    { 19159, "Woven Ivy Necklace", "Accessory" },
})
Quest({ 7862 }, nil, {
    { 19120, "Rune of the Guard Captain", "Accessory" },
})
Quest({ 8056 }, nil, {
    { 19830, "Zandalar Augur's Bracers", "Mail", 8737 },
})
Quest({ 8057 }, nil, {
    { 19840, "Zandalar Haruspex's Bracers", "Leather", 9077 },
})
Quest({ 8058 }, nil, {
    { 19824, "Zandalar Vindicator's Armguards", "Plate", 750 },
})
Quest({ 8059 }, nil, {
    { 19848, "Zandalar Demoniac's Wraps", "Cloth" },
})
Quest({ 8060 }, nil, {
    { 19846, "Zandalar Illusionist's Wraps", "Cloth" },
})
Quest({ 8061 }, nil, {
    { 19843, "Zandalar Confessor's Wraps", "Cloth" },
})
Quest({ 8062 }, nil, {
    { 19833, "Zandalar Predator's Bracers", "Mail", 8737 },
})
Quest({ 8063 }, nil, {
    { 19836, "Zandalar Madcap's Bracers", "Leather", 9077 },
})
Quest({ 8064 }, nil, {
    { 19839, "Zandalar Haruspex's Belt", "Leather", 9077 },
})
Quest({ 8065 }, nil, {
    { 19838, "Zandalar Haruspex's Tunic", "Leather", 9077 },
})
Quest({ 8066 }, nil, {
    { 19832, "Zandalar Predator's Belt", "Mail", 8737 },
})
Quest({ 8067 }, nil, {
    { 19831, "Zandalar Predator's Mantle", "Mail", 8737 },
})
Quest({ 8068 }, nil, {
    { 19845, "Zandalar Illusionist's Mantle", "Cloth" },
})
Quest({ 8069 }, nil, {
    { 20034, "Zandalar Illusionist's Robe", "Cloth" },
})
Quest({ 8070 }, nil, {
    { 19842, "Zandalar Confessor's Bindings", "Cloth" },
})
Quest({ 8071 }, nil, {
    { 19841, "Zandalar Confessor's Mantle", "Cloth" },
})
Quest({ 8072 }, nil, {
    { 19835, "Zandalar Madcap's Mantle", "Leather", 9077 },
})
Quest({ 8073 }, nil, {
    { 19834, "Zandalar Madcap's Tunic", "Leather", 9077 },
})
Quest({ 8074 }, nil, {
    { 19829, "Zandalar Augur's Belt", "Mail", 8737 },
})
Quest({ 8075 }, nil, {
    { 19828, "Zandalar Augur's Hauberk", "Mail", 8737 },
})
Quest({ 8076 }, nil, {
    { 19849, "Zandalar Demoniac's Mantle", "Cloth" },
})
Quest({ 8077 }, nil, {
    { 20033, "Zandalar Demoniac's Robe", "Cloth" },
})
Quest({ 8078 }, nil, {
    { 19823, "Zandalar Vindicator's Belt", "Plate", 750 },
})
Quest({ 8079 }, nil, {
    { 19822, "Zandalar Vindicator's Breastplate", "Plate", 750 },
})
Quest({ 3520, 3527, 4787, 3528, 5065, 4788, 8181 }, nil, {
    { 20218, "Faded Hakkari Cloak", "Cloth" },
    { 20219, "Tattered Hakkari Cape", "Cloth" },
})
Quest({ 8201 }, nil, {
    { 20213, "Belt of Shrunken Heads", "Plate", 750 },
    { 20215, "Belt of Shriveled Heads", "Mail", 8737 },
    { 20216, "Belt of Preserved Heads", "Leather", 9077 },
    { 20217, "Belt of Tiny Heads", "Cloth" },
})
Quest({ 8151, 8153, 8231, 8232 }, nil, {
    { 19991, "Devilsaur Eye", "Accessory" },
    { 19992, "Devilsaur Tooth", "Accessory" },
    { 20083, "Hunting Spear", "Polearm", 200 },
})
Quest({ 8233, 8234, 8235, 8236 }, nil, {
    { 19982, "Duskbat Drape", "Cloth" },
    { 19984, "Ebon Mask", "Leather", 9077 },
    { 20255, "Whisperwalk Boots", "Leather", 9077 },
})
Quest({ 8251, 8252, 8253 }, nil, {
    { 20035, "Glacial Spike", "Dagger", 1180 },
    { 20036, "Fire Ruby", "Accessory" },
    { 20037, "Arcane Crystal Pendant", "Accessory" },
})
Quest({ 8254, 8255, 8256, 8257 }, nil, {
    { 19990, "Blessed Prayer Beads", "Accessory" },
    { 20006, "Circle of Hope", "Accessory" },
    { 20082, "Woestave", "Wand", 5009 },
})
Quest({ 7667, 8258 }, nil, {
    { 20134, "Skyfury Helm", "Mail", 8737 },
})
Quest({ 2742, 2782, 8273 }, nil, {
    { 20642, "Antiquated Nobleman's Tunic", "Cloth" },
    { 20643, "Undercity Reservist's Cap", "Leather", 9077 },
})
Quest({ 8283 }, nil, {
    { 20646, "Sandstrider's Mark", "Bow", 264 },
    { 20647, "Black Crystal Dagger", "Dagger", 1180 },
})
Quest({ 8304, 8306 }, nil, {
    { 20724, "Corrupted Blackwood Staff", "Staff", 227 },
})
Quest({ 8320, 8321 }, nil, {
    { 20649, "Sunprism Pendant", "Accessory" },
    { 20650, "Desert Wind Gauntlets", "Plate", 750 },
})
Quest({ 8415, 8414, 8416, 8418 }, nil, {
    { 20504, "Lightforged Blade", "Two-handed Sword", 202 },
    { 20505, "Chivalrous Signet", "Accessory" },
    { 20512, "Sanctified Orb", "Accessory" },
})
Quest({ 8423, 8424, 8425 }, nil, {
    { 20130, "Diamond Flask", "Accessory" },
    { 20517, "Razorsteel Shoulders", "Plate", 750 },
    { 20521, "Fury Visor", "Plate", 750 },
})
Quest({ 8460 }, nil, {
    { 21311, "Earth Warder's Vest", "Cloth" },
    { 21312, "Belt of the Den Watcher", "Mail", 8737 },
})
Quest({ 8461 }, nil, {
    { 21316, "Leggings of the Ursa", "Plate", 750 },
    { 21317, "Helm of the Pathfinder", "Leather", 9077 },
})
Quest({ 8464 }, nil, {
    { 21318, "Earth Warder's Gloves", "Cloth" },
    { 21319, "Gloves of the Pathfinder", "Leather", 9077 },
    { 21320, "Vest of the Den Watcher", "Mail", 8737 },
    { 21322, "Ursa's Embrace", "Plate", 750 },
})
Quest({ 8556 }, nil, {
    { 21393, "Signet of Unyielding Strength", "Accessory" },
})
Quest({ 8557 }, nil, {
    { 21394, "Drape of Unyielding Strength", "Cloth" },
})
Quest({ 8558 }, nil, {
    { 21392, "Sickle of Unyielding Strength", "Axe", 196 },
})
Quest({ 8689 }, nil, {
    { 21412, "Shroud of Infinite Wisdom", "Cloth" },
})
Quest({ 8690 }, nil, {
    { 21400, "Cloak of the Gathering Storm", "Cloth" },
})
Quest({ 8691 }, nil, {
    { 21415, "Drape of Vaulted Secrets", "Cloth" },
})
Quest({ 8692 }, nil, {
    { 21409, "Cloak of Unending Life", "Cloth" },
})
Quest({ 8693 }, nil, {
    { 21406, "Cloak of Veiled Shadows", "Cloth" },
})
Quest({ 8694 }, nil, {
    { 21418, "Shroud of Unspoken Names", "Cloth" },
})
Quest({ 8695 }, nil, {
    { 21397, "Cape of Eternal Justice", "Cloth" },
})
Quest({ 8696 }, nil, {
    { 21403, "Cloak of the Unseen Path", "Cloth" },
})
Quest({ 8697 }, nil, {
    { 21411, "Ring of Infinite Wisdom", "Accessory" },
})
Quest({ 8698 }, nil, {
    { 21399, "Ring of the Gathering Storm", "Accessory" },
})
Quest({ 8699 }, nil, {
    { 21414, "Band of Vaulted Secrets", "Accessory" },
})
Quest({ 8700 }, nil, {
    { 21408, "Band of Unending Life", "Accessory" },
})
Quest({ 8701 }, nil, {
    { 21405, "Band of Veiled Shadows", "Accessory" },
})
Quest({ 8702 }, nil, {
    { 21417, "Ring of Unspoken Names", "Accessory" },
})
Quest({ 8703 }, nil, {
    { 21396, "Ring of Eternal Justice", "Accessory" },
})
Quest({ 8704 }, nil, {
    { 21402, "Signet of the Unseen Path", "Accessory" },
})
Quest({ 8705 }, nil, {
    { 21410, "Gavel of Infinite Wisdom", "Mace", 198 },
})
Quest({ 8706 }, nil, {
    { 21398, "Hammer of the Gathering Storm", "Mace", 198 },
})
Quest({ 8707 }, nil, {
    { 21413, "Blade of Vaulted Secrets", "Sword", 201 },
})
Quest({ 8708 }, nil, {
    { 21407, "Mace of Unending Life", "Mace", 198 },
})
Quest({ 8709 }, nil, {
    { 21404, "Dagger of Veiled Shadows", "Dagger", 1180 },
})
Quest({ 8710 }, nil, {
    { 21416, "Kris of Unspoken Names", "Dagger", 1180 },
})
Quest({ 8711 }, nil, {
    { 21395, "Blade of Eternal Justice", "Sword", 201 },
})
Quest({ 8712 }, nil, {
    { 21401, "Scythe of the Unseen Path", "Axe", 196 },
})
Quest({ 8908 }, nil, {
    { 22088, "Soulforge Bracers", "Plate", 750 },
})
Quest({ 8918 }, nil, {
    { 22095, "Bindings of The Five Thunders", "Mail", 8737 },
})
Quest({ 9023 }, nil, {
    { 22347, "Fahrad's Reloading Repeater", "Crossbow", 5011 },
    { 22348, "Doomulus Prime", "Two-handed Mace", 199 },
    { 22377, "The Thunderwood Poker", "Dagger", 1180 },
    { 22378, "Ravenholdt Slicer", "Sword", 201 },
    { 22379, "Shivsprocket's Shiv", "Dagger", 1180 },
    { 22380, "Simone's Cultivating Hammer", "Mace", 198 },
})
Quest({ 9052, 9051, 9053 }, nil, {
    { 22272, "Forest's Embrace", "Leather", 9077 },
    { 22274, "Grizzled Pelt", "Leather", 9077 },
    { 22458, "Moonshadow Stave", "Staff", 227 },
})
Quest({ 76156, 76160, 76240 }, nil, {
    { 277988, "Hoof-Holstered Blade", "Dagger", 1180 },
    { 278002, "Valley Cosh", "Mace", 198 },
})
Quest({ 78093 }, nil, {
    { 277205, "Cloak of the Divine Storm", "Accessory" },
})
Quest({ 86574 }, nil, {
    { 281251, "Courier's Wristguards", "Leather", 9077 },
})
Quest({ 86576 }, nil, {
    { 281252, "Harpy Claw Ring", "Accessory" },
})
Quest({ 86585 }, nil, {
    { 281253, "Mountaineer's Greataxe", "Two-handed Axe", 197 },
    { 281254, "Invader's Mace", "Mace", 198 },
})
Quest({ 86614 }, nil, {
    { 281256, "Repurposed Hair Band", "Cloth" },
})
Quest({ 86758 }, nil, {
    { 281257, "Daggerfang's Daggerfang", "Dagger", 1180 },
})
Quest({ 91285 }, nil, {
    { 246164, "Skullthumper", "Mace", 198 },
    { 246165, "Driftwood Smasher", "Two-handed Mace", 199 },
})
Quest({ 91285, 91294, 91316 }, nil, {
    { 246265, "Salvaged Wooden Tower Shield", "Shield", 9116 },
})
Quest({ 3504, 3505, 91497, 91500, 91531 }, nil, {
    { 287075, "Belgrom's Revenge", "Thrown", 2567 },
})
Quest({ 91794 }, nil, {
    { 287077, "Demonbane Knife", "Thrown", 2567 },
})
Quest({ 92401 }, nil, {
    { 251485, "Edward's Knife", "Dagger", 1180 },
    { 251486, "Tabitha's Cuffs", "Cloth" },
})
Quest({ 92421 }, nil, {
    { 279874, "The Stitcher", "Mace", 198 },
    { 279875, "Spare Part Bindings", "Leather", 9077 },
})
Quest({ 356, 99156, 92422 }, nil, {
    { 251533, "Forsaken Greataxe", "Two-handed Axe", 197 },
    { 251534, "Gnarled Necromancer's Staff", "Staff", 227 },
})
Quest({ 92456 }, nil, {
    { 279835, "Vine Pruner's Cloak", "Accessory" },
    { 279836, "Thorn Protecting Girdle", "Mail", 8737 },
})
Quest({ 92432, 92457 }, nil, {
    { 279837, "Fallen Guard's Pendant", "Accessory" },
    { 279838, "Arcane Infused Rod", "Accessory" },
})
Quest({ 92432, 92458 }, nil, {
    { 279839, "Spellguard Pauldrons", "Mail", 8737 },
    { 279840, "Renewing Footpads", "Leather", 9077 },
    { 279841, "Defender of Dalaran", "Two-handed Mace", 199 },
})
Quest({ 92460 }, nil, {
    { 264908, "Ancient Heirloom", "Accessory" },
})
Quest({ 92460, 92461 }, nil, {
    { 257280, "Vuldren Hide Bracers", "Leather", 9077 },
    { 257281, "Fur-Lined Shoes", "Cloth" },
})
Quest({ 92460, 92462, 92463 }, nil, {
    { 263408, "Exterminator's Vest", "Leather", 9077 },
    { 263409, "Gardening Pants", "Cloth" },
    { 263410, "Watcher's Mail Chest", "Mail", 8737 },
})
Quest({ 92465, 92469 }, nil, {
    { 257272, "Skychain Belt", "Mail", 8737 },
    { 257277, "Windblown Short Cloak", "Accessory" },
})
Quest({ 92471, 92470 }, nil, {
    { 257276, "Peacekeeper's Pickhammer", "Mace", 198 },
    { 257282, "Novice's Quarterstaff", "Staff", 227 },
    { 257283, "Scout Ranger's Dagger", "Dagger", 1180 },
    { 258882, "Worn Greatsword", "Two-handed Sword", 202 },
    { 273879, "Refined Shortbow", "Bow", 264 },
})
Quest({ 92471, 92473 }, nil, {
    { 257257, "Thendal Ranger's Shoes", "Mail", 8737 },
    { 257263, "Thendal Ranger's Belt", "Leather", 9077 },
    { 257264, "Thendal Ranger's Gloves", "Cloth" },
})
Quest({ 92489 }, nil, {
    { 251962, "Violet Sash", "Cloth" },
    { 279849, "Runebound Gloves", "Leather", 9077 },
})
Quest({ 92679, 92683 }, nil, {
    { 263329, "Flutterfly Swatter", "Mace", 198 },
})
Quest({ 92679, 92684 }, nil, {
    { 257331, "Brass-Banded Bracers", "Mail", 8737 },
    { 257334, "Well-Worn Pants", "Leather", 9077 },
    { 257340, "Farmer's Field Boots", "Cloth" },
})
Quest({ 92867 }, nil, {
    { 278567, "Stromgarde Hood", "Cloth" },
    { 280505, "Old Leather Jacket", "Leather", 9077 },
})
Quest({ 93159, 93172 }, nil, {
    { 263309, "Freedom Walkers", "Leather", 9077 },
    { 263310, "Sorrowsong Gloves", "Cloth" },
    { 263311, "Scuffed Cuffs", "Mail", 8737 },
})
Quest({ 92702, 92064, 96559, 93383 }, nil, {
    { 275721, "Rocketeer Leggings", "Leather", 9077 },
})
Quest({ 95350, 93739 }, nil, {
    { 286426, "Honorbound Cloak", "Accessory" },
})
Quest({ 94947, 93963 }, nil, {
    { 286427, "Cloak of the Honored Guest", "Accessory" },
})
Quest({ 94003 }, nil, {
    { 275290, "Stormforged Protector", "Shield", 9116 },
})
Quest({ 92596, 94413 }, nil, {
    { 263428, "Dowsing Rod", "Wand", 5009 },
})
Quest({ 94556 }, nil, {
    { 274952, "Jom-jom's Gabbar", "Dagger", 1180 },
})
Quest({ 94881, 94907, 94984 }, nil, {
    { 279854, "Twilight Initiate's Belt", "Leather", 9077 },
    { 279855, "Torn Cultist Cloak", "Accessory" },
})
Quest({ 94924, 95064 }, nil, {
    { 274959, "Farholde Horns", "Mail", 8737 },
})
Quest({ 91858, 91859, 91860, 91861, 91862, 96204, 95034, 95036, 95111, 95125, 95126 }, nil, {
    { 268484, "Moonsilver Blade", "Two-handed Sword", 202 },
})
Quest({ 91858, 91859, 91860, 91861, 91862, 96204, 95034, 95036, 95111, 95125, 95126, 95140 }, nil, {
    { 267369, "Wolfsbane", "Two-handed Sword", 202 },
})
Quest({ 447, 450, 451, 95216 }, nil, {
    { 279876, "Plaguefang", "Sword", 201 },
    { 279877, "Blight Gloves", "Cloth" },
})
Quest({ 276, 277, 275, 95646 }, nil, {
    { 271664, "Hornbeam Heft", "Axe", 196 },
})
Quest({ 95697 }, nil, {
    { 280805, "Serrated Raptor Claw", "Dagger", 1180 },
})
Quest({ 95789 }, nil, {
    { 279882, "Rusted Troll War Belt", "Mail", 8737 },
    { 279930, "Saltseer's Helm", "Leather", 9077 },
})
Quest({ 95791 }, nil, {
    { 279883, "Mutinous Cuffs", "Cloth" },
    { 279884, "South Seas Shroud", "Accessory" },
})
Quest({ 95912 }, nil, {
    { 287072, "Bladewhisper's Namesake", "Thrown", 2567 },
})
Quest({ 94877, 95561, 95913 }, nil, {
    { 274931, "Fur-Lined Bracers", "Leather", 9077 },
    { 274932, "Coyote Hide Wraps", "Leather", 9077 },
})
Quest({ 95924 }, nil, {
    { 279903, "Diemetradon Scale Spaulders", "Mail", 8737 },
    { 279905, "Ravasaur Hide Footpads", "Leather", 9077 },
})
Quest({ 95925 }, nil, {
    { 279908, "Crystal-Infused Cleaver", "Axe", 196 },
    { 279910, "Beastslayer's Trident", "Polearm", 200 },
    { 279912, "Faintly Glowing Orb", "Accessory" },
})
Quest({ 95928 }, nil, {
    { 279904, "Crystalline Pauldrons", "Mail", 8737 },
    { 279906, "Potent Treads", "Leather", 9077 },
})
Quest({ 477, 478, 481, 482, 95981 }, nil, {
    { 281265, "Roadwatcher's Confidence", "Accessory" },
})
Quest({ 95999 }, nil, {
    { 277218, "Incinerator's Boots", "Cloth" },
    { 277226, "Disjointed Shoes", "Leather", 9077 },
    { 277234, "Alacritous Treads", "Mail", 8737 },
})
Quest({ 629, 95748, 95770, 95775, 96078 }, nil, {
    { 279885, "Ceremonial Mallet", "Two-handed Mace", 199 },
    { 279886, "Sacrificial Sword", "Sword", 201 },
    { 279887, "I'lalai Flayer", "Axe", 196 },
})
Quest({ 753, 755, 757, 96130 }, nil, {
    { 281266, "Furred Belt", "Leather", 9077 },
})
Quest({ 96259, 96261 }, nil, {
    { 276895, "Transformative Cocoon", "Accessory" },
})
Quest({ 95284, 95285, 96332 }, nil, {
    { 279824, "Kor'kron Battle Gauntlets", "Plate", 750 },
})
Quest({ 95284, 95285, 96334 }, nil, {
    { 279448, "Bloodsplattered Bandana", "Leather", 9077 },
    { 279473, "Makeshift Belt", "Cloth" },
})
Quest({ 95194, 95196, 95198, 96381 }, nil, {
    { 279825, "Theramore Defender's Gauntlets", "Plate", 750 },
})
Quest({ 96394 }, nil, {
    { 279897, "Dusty Belt", "Leather", 9077 },
    { 280095, "Cryptwalker Bracers", "Mail", 8737 },
})
Quest({ 96403 }, nil, {
    { 279898, "Dwarven Tome", "Accessory" },
    { 280096, "Tomb Robber's Gloves", "Cloth" },
})
Quest({ 96609 }, nil, {
    { 276903, "Shimmerwine Shanker", "Dagger", 1180 },
})
Quest({ 96986 }, nil, {
    { 251963, "Gravewalker Boots", "Leather", 9077 },
    { 251965, "Undead Knight's Bracers", "Mail", 8737 },
})
Quest({ 96988 }, nil, {
    { 279847, "Unstable Power Core", "Wand", 5009 },
    { 279848, "Construct Cloak", "Accessory" },
})
Quest({ 97049 }, nil, {
    { 279902, "Reinforced Muck Protectors", "Plate", 750 },
})
Quest({ 97223 }, nil, {
    { 281267, "Raptorscale Pants", "Mail", 8737 },
})
Quest({ 97225 }, nil, {
    { 281268, "Depleted Ritual Band", "Accessory" },
})
Quest({ 97250 }, nil, {
    { 277286, "Encroacher's Claim", "Two-handed Axe", 197 },
    { 277288, "Pathfinder's Clearway", "Axe", 196 },
    { 277289, "Traveler's Shawl", "Accessory" },
})
Quest({ 97246, 97249, 97326 }, nil, {
    { 281269, "Mogra's Friendship Bracelet", "Cloth" },
    { 281270, "Thra's Friendship Bracelet", "Leather", 9077 },
    { 281271, "Puk's Friendship Bracelet", "Leather", 9077 },
    { 281272, "Brog's Friendship Bracelet", "Mail", 8737 },
    { 281273, "Migi's Friendship Bracelet", "Mail", 8737 },
})
Quest({ 97558 }, nil, {
    { 281283, "Patchwing Pants", "Cloth" },
    { 281284, "Howlhide Vest", "Leather", 9077 },
    { 281285, "Finscale Soles", "Mail", 8737 },
})
Quest({ 98025 }, nil, {
    { 281289, "Swordfeather Cloak", "Accessory" },
})
Quest({ 98071 }, nil, {
    { 279388, "Brewer's Bracers", "Mail", 8737 },
})
Quest({ 527, 528, 98094, 98095 }, nil, {
    { 281293, "Weathered Deathstalker's Blade", "Sword", 201 },
    { 281294, "Expended Apothecary Vial", "Accessory" },
})
Quest({ 279, 281, 284, 285, 286, 98189, 98190, 98191 }, nil, {
    { 281296, "Knight's Lance", "Polearm", 200 },
    { 281297, "Royal Dagger", "Dagger", 1180 },
})
Quest({ 421, 422, 423, 424, 99, 98298 }, nil, {
    { 281315, "Foulfur Gloves", "Cloth" },
})
Quest({ 299, 98216, 98310 }, nil, {
    { 281319, "Golem War Cloak", "Accessory" },
})
Quest({ 98326 }, nil, {
    { 281322, "Frosthowl's Footwarmers", "Leather", 9077 },
})
Quest({ 932, 98403 }, nil, {
    { 282284, "Webwood Slicer", "Dagger", 1180 },
})
Quest({ 99048, 99049, 99051, 99052 }, nil, {
    { 286730, "Pristine Orcish Dagger", "Dagger", 1180 },
    { 286731, "Aggor's Refitted Belt", "Mail", 8737 },
})
Quest({ 99053 }, nil, {
    { 286735, "Sentinel's Slasher", "Sword", 201 },
})
Quest({ 99079, 99081, 99101, 99080, 99082 }, nil, {
    { 286740, "Proud Brave's Guard", "Shield", 9116 },
    { 286741, "Centaur Skull Basher", "Two-handed Mace", 199 },
})
Quest({ 99123 }, nil, {
    { 286728, "Kolkar Hammer", "Mace", 198 },
    { 286729, "Kolkar Bow", "Bow", 264 },
})
Quest({ 99127, 99128, 99129, 99130 }, nil, {
    { 286733, "Fightin' Fish", "Mace", 198 },
})
Quest({ 356, 99156 }, nil, {
    { 286742, "Riptear's Cleaver", "Two-handed Axe", 197 },
    { 286743, "Riptear's Spare Arm", "Wand", 5009 },
    { 286744, "Thrice-Stitched Flesh", "Accessory" },
})
Quest({ 99159, 99160, 99161 }, nil, {
    { 286737, "Avala's Binding", "Accessory" },
})
