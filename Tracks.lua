-- Original Perfect World filenames from element/music.
-- Durations are seconds; adjust them if your files differ.
PWZoneMusicTracks = {
    city_a2 = { file = "city_a2.mp3", duration = 114 },
    city_d1 = { file = "city_d1.mp3", duration = 221 },
    city_f1 = { file = "city_f1.mp3", duration = 138 },
    common_a1 = { file = "common_a1.mp3", duration = 105 },
    common_b1 = { file = "common_b1.mp3", duration = 129 },
    common_c1 = { file = "common_c1.mp3", duration = 195 },
    common_d1 = { file = "common_d1.mp3", duration = 211 },
    common_e1 = { file = "common_e1.mp3", duration = 313 },
    common_f1 = { file = "common_f1.mp3", duration = 178 },
    village_b1 = { file = "village_b1.mp3", duration = 107 },
    village_d = { file = "village_d.mp3", duration = 125 },
    dungeon_a1 = { file = "dungeon_a1.mp3", duration = 220 },
    dungeon_b1 = { file = "dungeon_b1.mp3", duration = 197 },
    dungeon_d1 = { file = "dungeon_d1.mp3", duration = 177 },
}

-- Order used by the Previous and Next buttons.
PWZoneMusicOrder = {
    "common_a1", "common_b1", "common_c1", "common_d1", "common_e1", "common_f1",
    "village_b1", "village_d", "city_a2", "city_d1", "city_f1",
    "dungeon_a1", "dungeon_b1", "dungeon_d1",
}

-- Atmosphere-based zone selection. Use /pwm map to check the current map ID.
PWZoneMusicZones = {
    -- Kalimdor
    [1] = "common_d1",   -- Durotar
    [7] = "common_b1",   -- Mulgore
    [10] = "common_b1",  -- The Barrens
    [57] = "common_f1",  -- Teldrassil
    [62] = "dungeon_b1", -- Darkshore
    [63] = "common_f1",  -- Ashenvale
    [64] = "common_d1",  -- Thousand Needles
    [65] = "common_d1",  -- Stonetalon Mountains
    [66] = "dungeon_b1", -- Desolace
    [69] = "common_a1",  -- Feralas
    [70] = "dungeon_b1", -- Dustwallow Marsh
    [71] = "common_d1",  -- Tanaris
    [76] = "common_f1",  -- Azshara
    [77] = "dungeon_a1", -- Felwood
    [78] = "common_c1",  -- Un'Goro Crater
    [80] = "common_f1",  -- Moonglade
    [81] = "dungeon_d1", -- Silithus
    [83] = "common_d1",  -- Winterspring
    [85] = "city_a2",    -- Orgrimmar
    [88] = "city_d1",   -- Thunder Bluff
    [89] = "city_d1",    -- Darnassus

    -- Eastern Kingdoms
    [14] = "common_b1",  -- Arathi Highlands
    [15] = "common_d1",  -- Badlands
    [17] = "dungeon_d1", -- Blasted Lands
    [18] = "dungeon_a1", -- Tirisfal Glades
    [21] = "dungeon_a1", -- Silverpine Forest
    [22] = "dungeon_a1", -- Western Plaguelands
    [23] = "dungeon_d1", -- Eastern Plaguelands
    [25] = "common_b1",  -- Hillsbrad Foothills
    [26] = "common_a1",  -- The Hinterlands
    [29] = "common_d1",  -- Dun Morogh
    [32] = "dungeon_d1", -- Searing Gorge
    [36] = "dungeon_d1", -- Burning Steppes
    [37] = "common_a1",  -- Elwynn Forest
    [42] = "dungeon_a1", -- Deadwind Pass
    [47] = "dungeon_a1", -- Duskwood
    [48] = "common_b1",  -- Loch Modan
    [49] = "common_c1",  -- Redridge Mountains
    [50] = "common_c1",  -- Northern Stranglethorn
    [51] = "dungeon_b1", -- Swamp of Sorrows
    [52] = "common_b1",  -- Westfall
    [56] = "dungeon_b1", -- Wetlands
    [84] = "city_a2",    -- Stormwind
    [87] = "city_f1",    -- Ironforge
    [90] = "city_d1",   -- Undercity
    [210] = "common_c1", -- Cape of Stranglethorn
}

-- Other Retail zones use the default track.
PWZoneMusicDefaultTrack = "common_a1"

-- A zone selects a theme; each theme rotates through compatible tracks.
PWZoneMusicPools = {
    city_a2 = { "city_a2", "city_f1", "city_d1" },
    city_d1 = { "city_d1", "city_a2", "city_f1" },
    city_f1 = { "city_f1", "city_a2", "city_d1" },
    common_a1 = { "common_a1", "common_c1", "common_f1", "village_b1" },
    common_b1 = { "common_b1", "village_b1", "common_c1", "city_f1" },
    common_c1 = { "common_c1", "common_a1", "village_d", "common_f1" },
    common_d1 = { "common_d1", "common_e1", "dungeon_d1", "village_d" },
    common_e1 = { "common_e1", "common_d1", "dungeon_d1", "common_c1" },
    common_f1 = { "common_f1", "common_a1", "common_c1", "village_b1" },
    village_b1 = { "village_b1", "common_b1", "city_f1", "common_a1" },
    village_d = { "village_d", "common_c1", "city_d1", "common_d1" },
    dungeon_a1 = { "dungeon_a1", "dungeon_b1", "dungeon_d1", "common_d1" },
    dungeon_b1 = { "dungeon_b1", "dungeon_a1", "dungeon_d1", "common_e1" },
    dungeon_d1 = { "dungeon_d1", "dungeon_b1", "dungeon_a1", "common_d1" },
}
