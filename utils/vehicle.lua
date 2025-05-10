local VehicleUtils = {}

-- Get vehicle performance stats
function VehicleUtils.GetVehiclePerformance(vehicle)
    if not DoesEntityExist(vehicle) then return nil end
    
    local performance = {
        speed = GetVehicleEstimatedMaxSpeed(vehicle),
        acceleration = GetVehicleAcceleration(vehicle),
        braking = GetVehicleMaxBraking(vehicle),
        handling = GetVehicleMaxTraction(vehicle),
        class = GetVehicleClass(vehicle)
    }
    
    return performance
end

-- Calculate vehicle value based on performance and damage
function VehicleUtils.CalculateVehicleValue(vehicle)
    if not DoesEntityExist(vehicle) then return 0 end
    
    -- Get vehicle performance stats
    local performance = VehicleUtils.GetVehiclePerformance(vehicle)
    if not performance then return 0 end
    
    -- Get vehicle damage
    local bodyHealth = GetVehicleBodyHealth(vehicle) / 1000.0
    local engineHealth = GetVehicleEngineHealth(vehicle) / 1000.0
    
    -- Calculate base value from performance
    local baseValue = 
        (performance.speed * Config.PerformanceValueFactors.speed) + 
        (performance.acceleration * Config.PerformanceValueFactors.acceleration) + 
        (performance.handling * Config.PerformanceValueFactors.handling) + 
        (performance.braking * Config.PerformanceValueFactors.braking)
    
    -- Apply vehicle class multiplier
    local classMultiplier = Config.VehicleClassMultipliers[performance.class] or 1.0
    
    -- Apply damage multipliers
    local bodyMultiplier = Config.DamageMultipliers.body.min + 
        (bodyHealth * (Config.DamageMultipliers.body.max - Config.DamageMultipliers.body.min))
    
    local engineMultiplier = Config.DamageMultipliers.engine.min + 
        (engineHealth * (Config.DamageMultipliers.engine.max - Config.DamageMultipliers.engine.min))
    
    -- Calculate final reward
    local finalMultiplier = classMultiplier * bodyMultiplier * engineMultiplier
    local baseReward = Config.RewardRange.min + 
        (baseValue * Config.PerformanceValueFactors.baseMultiplier * (Config.RewardRange.max - Config.RewardRange.min))
    
    return math.floor(baseReward * finalMultiplier)
end

-- Check if vehicle is owned by a player
function VehicleUtils.IsVehicleOwned(plate)
    if not plate or type(plate) ~= "string" or #plate < 1 then return false end
    
    -- Clean plate string
    plate = string.upper(string.gsub(plate, "%s+", ""))
    
    local result = exports.oxmysql:executeSync('SELECT 1 FROM player_vehicles WHERE plate = ? LIMIT 1', {plate})
    return result and result[1] ~= nil
end

-- Generate a random unique plate
function VehicleUtils.GenerateRandomPlate()
    local letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local numbers = "0123456789"
    local plate = ""
    
    -- Format: LL NNNN (2 letters, space, 4 numbers)
    plate = plate .. string.char(letters:byte(math.random(1, #letters)))
    plate = plate .. string.char(letters:byte(math.random(1, #letters)))
    plate = plate .. " "
    plate = plate .. string.char(numbers:byte(math.random(1, #numbers)))
    plate = plate .. string.char(numbers:byte(math.random(1, #numbers)))
    plate = plate .. string.char(numbers:byte(math.random(1, #numbers)))
    plate = plate .. string.char(numbers:byte(math.random(1, #numbers)))
    
    return plate
end

-- Apply damage to a vehicle for more realistic stolen appearance
function VehicleUtils.ApplyRandomDamage(vehicle, minDamage, maxDamage)
    if not DoesEntityExist(vehicle) then return end
    
    -- Set reasonable defaults
    minDamage = minDamage or 700
    maxDamage = maxDamage or 1000
    
    -- Set random body health
    local bodyHealth = math.random(minDamage, maxDamage)
    SetVehicleBodyHealth(vehicle, bodyHealth)
    
    -- Set random engine health
    local engineHealth = math.random(minDamage, maxDamage)
    SetVehicleEngineHealth(vehicle, engineHealth)
    
    -- Set random dirt level (0.0 - 15.0)
    SetVehicleDirtLevel(vehicle, math.random(0, 15) * 0.1)
    
    -- Random chance to break windows
    for i = 0, 7 do -- Vehicle has windows 0-7
        if math.random(1, 10) <= 3 then -- 30% chance per window
            SmashVehicleWindow(vehicle, i)
        end
    end
    
    -- Random chance to damage doors
    for i = 0, 5 do -- Vehicle has doors 0-5
        if math.random(1, 10) <= 2 then -- 20% chance per door
            SetVehicleDoorBroken(vehicle, i, true)
        end
    end
    
    -- Random chance for flat tires
    for i = 0, 7 do -- Vehicle has wheels 0-7 (including spare wheels)
        if math.random(1, 10) <= 1 then -- 10% chance per wheel
            SetVehicleTyreBurst(vehicle, i, true, 1000.0)
        end
    end
end

-- Get vehicle name from model
function VehicleUtils.GetVehicleName(vehicle)
    if not DoesEntityExist(vehicle) then return "Unknown" end
    
    local vehicleModel = GetEntityModel(vehicle)
    local displayName = GetDisplayNameFromVehicleModel(vehicleModel)
    local vehicleName = GetLabelText(displayName)
    
    -- If the label text returns "NULL", use the display name instead
    if vehicleName == "NULL" then
        vehicleName = displayName
    end
    
    return vehicleName
end

-- Determine the base price of a vehicle based on model
function VehicleUtils.GetVehicleBasePrice(vehicle)
    if not DoesEntityExist(vehicle) then return 0 end
    
    local vehicleModel = GetEntityModel(vehicle)
    local displayName = GetDisplayNameFromVehicleModel(vehicleModel)
    local vehicleClass = GetVehicleClass(vehicle)
    
    -- Base price ranges by class
    local classPrices = {
        [0] = {min = 1000, max = 5000},     -- Compacts
        [1] = {min = 2000, max = 7000},     -- Sedans
        [2] = {min = 3000, max = 9000},     -- SUVs
        [3] = {min = 2500, max = 8000},     -- Coupes
        [4] = {min = 4000, max = 12000},    -- Muscle
        [5] = {min = 5000, max = 25000},    -- Sports Classics
        [6] = {min = 8000, max = 30000},    -- Sports
        [7] = {min = 15000, max = 50000},   -- Super
        [8] = {min = 500, max = 5000},      -- Motorcycles
        [9] = {min = 2000, max = 10000},    -- Off-road
        [10] = {min = 1000, max = 5000},    -- Industrial
        [11] = {min = 1000, max = 4000},    -- Utility
        [12] = {min = 1500, max = 6000},    -- Vans
        [13] = {min = 100, max = 1000},     -- Bicycles
        [14] = {min = 3000, max = 15000},   -- Boats
        [15] = {min = 10000, max = 40000},  -- Helicopters
        [16] = {min = 20000, max = 100000}, -- Planes
        [17] = {min = 3000, max = 8000},    -- Service
        [18] = {min = 3000, max = 8000},    -- Emergency
        [19] = {min = 10000, max = 30000},  -- Military
        [20] = {min = 5000, max = 15000},   -- Commercial
        [21] = {min = 20000, max = 50000}   -- Trains
    }
    
    local classInfo = classPrices[vehicleClass] or {min = 1000, max = 10000}
    local modelHash = GetHashKey(displayName:lower())
    
    -- Generate a consistent price for each model
    math.randomseed(modelHash)
    local basePrice = math.random(classInfo.min, classInfo.max)
    math.randomseed(os.time()) -- Reset randomseed
    
    return basePrice
end

-- Set fuel level using the configured fuel system
function VehicleUtils.SetFuel(vehicle, level)
    if not DoesEntityExist(vehicle) then return false end
    if not level or type(level) ~= "number" or level < 0 or level > 100 then return false end
    
    -- Use the appropriate fuel system
    if Config.UI.fuel == 'LegacyFuel' then
        exports['LegacyFuel']:SetFuel(vehicle, level)
    elseif Config.UI.fuel == 'cdn-fuel' then
        exports['cdn-fuel']:SetFuel(vehicle, level)
    elseif Config.UI.fuel == 'lc_fuel' then
        exports['lc_fuel']:SetFuel(vehicle, level)
    elseif Config.UI.fuel == 'ps-fuel' then
        exports['ps-fuel']:SetFuel(vehicle, level)
    else
        SetVehicleFuelLevel(vehicle, level)
    end
    
    return true
end

-- Generate a unique drop-off location for the mission
function VehicleUtils.GetDropOffLocation(excludeLocation)
    local locations = Config.DeliveryLocations
    if not locations or #locations == 0 then return nil end
    
    if #locations == 1 then
        return locations[1]
    end
    
    -- If we need to exclude a location (e.g., the pickup location)
    if excludeLocation then
        local validLocations = {}
        for _, loc in ipairs(locations) do
            if #(vector3(loc.x, loc.y, loc.z) - vector3(excludeLocation.x, excludeLocation.y, excludeLocation.z)) > 100.0 then
                table.insert(validLocations, loc)
            end
        end
        
        if #validLocations == 0 then
            return locations[1] -- Fall back to first location if all excluded
        end
        
        return validLocations[math.random(#validLocations)]
    end
    
    -- No exclusion, just pick a random location
    return locations[math.random(#locations)]
end

return VehicleUtils