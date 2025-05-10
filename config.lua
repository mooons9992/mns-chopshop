Config = {}

Config.Debug = false

-- UI framework configuration
Config.UI = {
    target = 'ox_target',  -- CHANGE THIS from 'ox_target' to match your export name
    fuel = 'lc_fuel',
    notify = 'qb',
    inventory = 'ps',
    menu = 'qb',
    progressbar = 'qb',
}

-- Notifications templates
Config.Notifications = {
    missionStart = {
        title = "CHOPSHOP",
        message = "Mission started! Check your map for the vehicle location.",
        type = "success", -- success, error, info
        duration = 5000,
    },
    missionCooldown = {
        title = "CHOPSHOP",
        message = "You need to wait %s seconds before starting another mission.",
        type = "error",
        duration = 5000,
    },
    alreadyOnMission = {
        title = "CHOPSHOP",
        message = "You are already on a mission.",
        type = "error",
        duration = 3000,
    },
    noLocations = {
        title = "CHOPSHOP",
        message = "No valid mission locations available.",
        type = "error",
        duration = 3000,
    },
    spawnFailed = {
        title = "CHOPSHOP",
        message = "Failed to spawn vehicle.",
        type = "error",
        duration = 3000,
    },
    noMission = {
        title = "CHOPSHOP",
        message = "You are not on a mission.",
        type = "error",
        duration = 3000,
    },
    missionCompleted = {
        title = "CHOPSHOP",
        message = "Mission completed! You earned your reward.",
        type = "success",
        duration = 5000,
    },
    missionFailed = {
        title = "CHOPSHOP",
        message = "Mission failed. Vehicle was not delivered.",
        type = "error",
        duration = 5000,
    },
    missionTimeout = {
        title = "CHOPSHOP",
        message = "Mission automatically timed out.",
        type = "error",
        duration = 5000,
    },
    sellCooldown = {
        title = "CHOPSHOP",
        message = "You need to wait %s seconds before selling another vehicle.",
        type = "error",
        duration = 5000,
    },
    noVehicleNearby = {
        title = "CHOPSHOP",
        message = "No vehicle found nearby.",
        type = "error",
        duration = 3000,
    },
    tooFarFromVehicle = {
        title = "CHOPSHOP",
        message = "Get closer to the vehicle.",
        type = "error",
        duration = 3000,
    },
    vehicleSold = {
        title = "CHOPSHOP",
        message = "Vehicle sold for $%s",
        type = "success",
        duration = 5000,
    },
    personalVehicle = {
        title = "CHOPSHOP",
        message = "You cannot sell your personal vehicle here.",
        type = "error",
        duration = 5000,
    }
}

-- General settings
Config.RewardRange = {min = 500, max = 1500}
Config.DeliveryRadius = 10.0
Config.InteractionDistance = 2.5

-- Mission settings
Config.MissionTimeout = 1800 -- Timeout for mission completion in seconds (default: 1800 seconds = 30 minutes)
Config.SellCooldown = 300 -- Cooldown before player can sell another stolen car (300 seconds = 5 minutes)
Config.SellVehicleEnabled = true -- Allow selling non-mission vehicles

-- NPC configuration
Config.Ped = {
    model = "g_m_m_armgoon_01", -- PED Model
    location = vector4(476.4, -1315.28, 28.225, 255.99), -- Hayes Auto by MRPD
    scenario = "WORLD_HUMAN_SMOKING", -- Ped animation
    disableGroundSnap = false -- Set to true if you want to manually position the Z coordinate
}

-- Multiple NPC locations around the map
Config.NPCLocations = {
    -- City locations
    vector4(476.4, -1315.28, 28.225, 255.99),    -- Hayes Auto (Original location)
    vector4(947.59, -1697.93, 29.98, 85.31),     -- La Mesa Garage
    vector4(-1428.14, -444.77, 35.53, 210.76),   -- Great Chaparral / Kortz Center
    vector4(1182.53, 2636.41, 37.75, 95.68),     -- Harmony Repair Shop
    vector4(106.21, 6627.77, 31.78, 224.91),     -- Paleto Bay Repair Shop
    vector4(731.7, -1088.84, 22.17, 88.78),      -- Little Seoul garage
    vector4(-580.95, -1796.84, 22.74, 231.46),   -- LSIA area garage
    vector4(2340.65, 3126.46, 48.21, 359.57),    -- Sandy Shores garage
}

-- Delivery locations (can be the same as NPC locations)
Config.DeliveryLocations = {
    -- Same locations as NPCs for simplicity
    vector4(476.4, -1315.28, 28.225, 255.99),    -- Hayes Auto
    vector4(947.59, -1697.93, 29.98, 85.31),     -- La Mesa Garage
    vector4(-1428.14, -444.77, 35.53, 210.76),   -- Great Chaparral / Kortz Center
    vector4(1182.53, 2636.41, 37.75, 95.68),     -- Harmony Repair Shop
    vector4(106.21, 6627.77, 31.78, 224.91),     -- Paleto Bay Repair Shop
    vector4(731.7, -1088.84, 22.17, 88.78),      -- Little Seoul garage
    vector4(-580.95, -1796.84, 22.74, 231.46),   -- LSIA area garage
    vector4(2340.65, 3126.46, 48.21, 359.57),    -- Sandy Shores garage
}

-- Mission system configuration
Config.Mission = {
    Radius = 100.0, -- Search area radius for finding the vehicle
    Cooldown = 300, -- Time between missions in seconds
    TimeLimit = 300, -- Time limit to deliver the vehicle in seconds (5 minutes)
    
    Blip = {
        Sprite = 161,
        Color = 1,
        Alpha = 100
    },
    
    VehicleModels = {
        -- Expanded vehicle list with 20+ options
        
        -- Supercars
        "zentorno",      -- Pegassi Zentorno
        "adder",         -- Truffade Adder
        "EntityXF",      -- Overflod Entity XF
        "t20",           -- Progen T20
        
        -- Sports cars
        "neon",          -- Pfister Neon
        "schlagen",      -- Benefactor Schlagen GT
        "pariah",        -- Ocelot Pariah
        "comet2",        -- Pfister Comet
        "tampa2",        -- Declasse Drift Tampa
        
        -- Muscle cars
        "dominator",     -- Vapid Dominator
        "gauntlet",      -- Bravado Gauntlet
        "sabregt",       -- Declasse Sabre Turbo
        "vigero",        -- Declasse Vigero
        "dukes",         -- Imponte Dukes
        "blade",         -- Vapid Blade
        
        -- Sedans
        "tailgater",     -- Obey Tailgater
        "primo",         -- Albany Primo
        "fugitive",      -- Cheval Fugitive
        "intruder",      -- Karin Intruder
        
        -- Coupes
        "windsor",       -- Enus Windsor
        "exemplar",      -- Dewbauchee Exemplar
        "felon",         -- Lampadati Felon
        
        -- SUVs
        "baller",        -- Gallivanter Baller
        "cavalcade",     -- Albany Cavalcade
        "granger",       -- Declasse Granger
        "huntley",       -- Enus Huntley S
        
        -- Compacts
        "blista",        -- Dinka Blista
        "brioso",        -- Grotti Brioso R/A
        "issi2",         -- Weeny Issi
        "panto",         -- Benefactor Panto
    },
    
    SpawnLocations = {
        -- Downtown
        vector4(286.63, -1036.36, 29.07, 89.83),
        -- La Mesa
        vector4(948.59, -1698.46, 29.65, 82.71),
        -- Popular Street
        vector4(802.95, -1354.56, 25.45, 88.43),
        -- Strawberry
        vector4(176.41, -1549.56, 29.26, 44.13),
        -- Davis
        vector4(324.6, -2012.99, 20.47, 318.38),
        -- Del Perro
        vector4(-1590.95, -817.45, 9.28, 140.53),
        -- Mirror Park
        vector4(1198.83, -1264.61, 34.56, 177.61),
        -- Sandy Shores
        vector4(1986.36, 3793.54, 32.18, 120.41),
        -- Harmony
        vector4(576.34, 2790.6, 42.13, 3.14),
        -- Paleto Bay
        vector4(-106.7, 6349.67, 31.49, 40.64)
    }
}

-- Vehicle class multipliers for reward calculation
Config.VehicleClassMultipliers = {
    [0] = 0.8,  -- Compacts
    [1] = 0.9,  -- Sedans
    [2] = 1.0,  -- SUVs
    [3] = 1.1,  -- Coupes
    [4] = 1.2,  -- Muscle
    [5] = 1.3,  -- Sports Classics
    [6] = 1.5,  -- Sports
    [7] = 2.0,  -- Super
    [8] = 0.7,  -- Motorcycles
    [9] = 1.1,  -- Off-road
    [10] = 0.8, -- Industrial
    [11] = 0.7, -- Utility
    [12] = 1.0, -- Vans
    [13] = 0.5, -- Cycles
    [14] = 0.8, -- Boats
    [15] = 1.2, -- Helicopters
    [16] = 1.5, -- Planes
    [17] = 1.0, -- Service
    [18] = 1.0, -- Emergency
    [19] = 1.5, -- Military
    [20] = 0.8, -- Commercial
    [21] = 1.6  -- Trains
}

-- Vehicle damage modifiers
Config.DamageMultipliers = {
    body = {
        min = 0.5,  -- Minimum multiplier for completely damaged body
        max = 1.0   -- Maximum multiplier for pristine body
    },
    engine = {
        min = 0.3,  -- Minimum multiplier for completely damaged engine
        max = 1.0   -- Maximum multiplier for pristine engine
    }
}

-- Performance value calculation factors
Config.PerformanceValueFactors = {
    speed = 0.4,        -- Vehicle top speed
    acceleration = 0.3,  -- Acceleration rate
    handling = 0.2,      -- Handling capability
    braking = 0.1,       -- Braking power
    baseMultiplier = 0.1 -- Base value multiplier
}
