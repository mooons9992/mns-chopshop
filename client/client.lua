local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local missionVehicle = nil
local missionBlip = nil
local missionRadiusBlip = nil
local isOnMission = false
local lastMissionTime = 0
local missionTimeout = nil
local missionDeliveryLocation = nil

-- Debug print function
local function DebugPrint(msg)
    if Config.Debug then
        print("^3[MNS-CHOPSHOP]^7 " .. msg)
    end
end

-- Notification function that works with any framework
local function Notify(message, type)
    if type == nil then type = "primary" end
    
    -- QBCore notification
    QBCore.Functions.Notify(message, type)
end

-- Get random spawn location from config
local function GetRandomSpawnLocation()
    if #Config.Mission.SpawnLocations == 0 then
        return nil
    end
    
    return Config.Mission.SpawnLocations[math.random(1, #Config.Mission.SpawnLocations)]
end

-- Get random vehicle model from config
local function GetRandomVehicleModel()
    if #Config.Mission.VehicleModels == 0 then
        return nil
    end
    
    return Config.Mission.VehicleModels[math.random(1, #Config.Mission.VehicleModels)]
end

-- Calculate reward based on vehicle class and condition
local function CalculateReward(vehicle)
    if not DoesEntityExist(vehicle) then return 0 end
    
    -- Get vehicle class
    local vehicleClass = GetVehicleClass(vehicle)
    local classMultiplier = Config.VehicleClassMultipliers[vehicleClass] or 1.0
    
    -- Get vehicle condition
    local engineHealth = GetVehicleEngineHealth(vehicle) / 1000.0
    local bodyHealth = GetVehicleBodyHealth(vehicle) / 1000.0
    
    -- Calculate condition multiplier
    local engineMultiplier = Config.DamageMultipliers.engine.min + 
                           (engineHealth * (Config.DamageMultipliers.engine.max - Config.DamageMultipliers.engine.min))
    
    local bodyMultiplier = Config.DamageMultipliers.body.min + 
                         (bodyHealth * (Config.DamageMultipliers.body.max - Config.DamageMultipliers.body.min))
    
    local conditionMultiplier = (engineMultiplier + bodyMultiplier) / 2
    
    -- Calculate base reward
    local baseReward = math.random(Config.RewardRange.min, Config.RewardRange.max)
    
    -- Apply multipliers
    local finalReward = math.floor(baseReward * classMultiplier * conditionMultiplier)
    
    DebugPrint("Reward calculation: " .. baseReward .. " * " .. classMultiplier .. " * " .. conditionMultiplier .. " = " .. finalReward)
    
    return finalReward
end

-- Create a stolen vehicle with random damage and fuel
local function CreateStolenVehicle(model, coords)
    -- Request the model
    local modelHash = GetHashKey(model)
    RequestModel(modelHash)
    
    -- Wait until the model is loaded
    local timeWaited = 0
    while not HasModelLoaded(modelHash) do
        Wait(100)
        timeWaited = timeWaited + 100
        if timeWaited > 10000 then
            DebugPrint("Failed to load model: " .. model)
            return nil
        end
    end
    
    -- Get spawn coordinates
    local x, y, z, heading = coords.x, coords.y, coords.z, coords.w
    
    -- Clear the area
    ClearAreaOfVehicles(x, y, z, 10.0, false, false, false, false, false)
    
    -- Spawn the vehicle
    local vehicle = CreateVehicle(modelHash, x, y, z, heading, true, false)
    if not vehicle or vehicle == 0 then
        DebugPrint("Failed to create vehicle!")
        return nil
    end
    
    -- Set entity as mission entity
    SetEntityAsMissionEntity(vehicle, true, true)
    
    -- Set a stolen plate
    local plate = "CSHOP" .. math.random(100, 999)
    SetVehicleNumberPlateText(vehicle, plate)
    
    -- Lock the vehicle and turn engine off
    SetVehicleDoorsLocked(vehicle, 1) -- Unlocked so player can enter
    SetVehicleEngineOn(vehicle, false, true, true)
    
    -- Apply random damage (more randomized now)
    local engineDamage = math.random(500, 950) -- More varied engine damage
    local bodyDamage = math.random(500, 950)   -- More varied body damage
    
    SetVehicleEngineHealth(vehicle, engineDamage)
    SetVehicleBodyHealth(vehicle, bodyDamage)
    
    -- Random dirt level
    SetVehicleDirtLevel(vehicle, math.random(1.0, 15.0))
    
    -- Random door/window damage
    if math.random() > 0.7 then -- 30% chance for door damage
        SetVehicleDoorBroken(vehicle, math.random(0, 5), true)
    end
    
    if math.random() > 0.6 then -- 40% chance for window damage
        SmashVehicleWindow(vehicle, math.random(0, 7))
    end
    
    -- Set fuel level (using different fuel scripts)
    local fuelLevel = math.random(20, 80) -- More varied fuel levels
    if Config.UI.fuel == "lc_fuel" then
        exports['lc_fuel']:SetFuel(vehicle, fuelLevel)
    elseif Config.UI.fuel == "LegacyFuel" then
        exports['LegacyFuel']:SetFuel(vehicle, fuelLevel)
    elseif Config.UI.fuel == "ps-fuel" then
        exports['ps-fuel']:SetFuel(vehicle, fuelLevel)
    elseif Config.UI.fuel == "cdn-fuel" then
        exports['cdn-fuel']:SetFuel(vehicle, fuelLevel)
    end
    
    -- Return the created vehicle
    return vehicle
end

-- Create a radius blip at location
local function CreateRadiusBlip(coords, radius, color, alpha)
    local blip = AddBlipForRadius(coords.x, coords.y, coords.z, radius)
    SetBlipColour(blip, color or Config.Mission.Blip.Color)
    SetBlipAlpha(blip, alpha or Config.Mission.Blip.Alpha)
    return blip
end

-- Create a normal blip at coords
local function CreateBlip(coords, sprite, color, scale, name)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite or 1)
    SetBlipColour(blip, color or 0)
    SetBlipScale(blip, scale or 1.0)
    SetBlipAsShortRange(blip, true)
    
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(name or "Blip")
    EndTextCommandSetBlipName(blip)
    
    return blip
end

-- Clean up mission resources
local function CleanupMission()
    if missionVehicle and DoesEntityExist(missionVehicle) then
        SetEntityAsNoLongerNeeded(missionVehicle)
    end
    
    if missionBlip then
        RemoveBlip(missionBlip)
        missionBlip = nil
    end
    
    if missionRadiusBlip then
        RemoveBlip(missionRadiusBlip)
        missionRadiusBlip = nil
    end
    
    missionVehicle = nil
    isOnMission = false
end

-- Get delivery location that's far from start location
local function GetFarDeliveryLocation(startCoords)
    -- Create a copy of delivery locations
    local availableLocations = {}
    for _, location in pairs(Config.DeliveryLocations) do
        table.insert(availableLocations, location)
    end
    
    -- Shuffle the locations for more randomness
    for i = #availableLocations, 2, -1 do
        local j = math.random(i)
        availableLocations[i], availableLocations[j] = availableLocations[j], availableLocations[i]
    end
    
    -- Find a location that's far enough from the start
    local minDistance = 1000.0 -- Minimum distance in units
    local bestLocation = nil
    
    for _, location in pairs(availableLocations) do
        local distance = #(vector3(startCoords.x, startCoords.y, startCoords.z) - 
                          vector3(location.x, location.y, location.z))
        
        if distance > minDistance then
            return location
        end
        
        -- If we can't find any location far enough, just use the first one
        if not bestLocation then
            bestLocation = location
        end
    end
    
    return bestLocation or availableLocations[1]
end

-- Start a mission
function StartMission(startLocation)
    -- Check if player is already on a mission
    if isOnMission then
        Notify("You are already on a mission.", "error")
        return
    end
    
    -- Check cooldown
    local currentTime = GetGameTimer() / 1000
    if (currentTime - lastMissionTime) < Config.Mission.Cooldown then
        local remainingTime = math.ceil(Config.Mission.Cooldown - (currentTime - lastMissionTime))
        Notify("Wait " .. remainingTime .. " seconds before starting a new mission.", "error")
        return
    end
    
    -- Get random location and model
    local spawnLocation = GetRandomSpawnLocation()
    local vehicleModel = GetRandomVehicleModel()
    
    if not spawnLocation or not vehicleModel then
        Notify("No valid mission available right now.", "error")
        return
    end
    
    -- Create the stolen vehicle
    missionVehicle = CreateStolenVehicle(vehicleModel, spawnLocation)
    
    if missionVehicle then
        -- Create a radius blip to show approximate location
        missionRadiusBlip = CreateRadiusBlip(spawnLocation, Config.Mission.Radius)
        
        -- Create a blip for the vehicle (but make it invisible initially for players to search)
        missionBlip = AddBlipForEntity(missionVehicle)
        SetBlipSprite(missionBlip, Config.Mission.Blip.Sprite)
        SetBlipColour(missionBlip, Config.Mission.Blip.Color)
        SetBlipScale(missionBlip, 0.8)
        SetBlipDisplay(missionBlip, 8) -- Not displayed on the map unless close
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName("Target Vehicle")
        EndTextCommandSetBlipName(missionBlip)
        
        -- Set mission state
        isOnMission = true
        lastMissionTime = currentTime
        
        -- Show success notification
        Notify("Mission started! Find the marked vehicle within the radius.", "success")
        
        -- Start a thread to check when player gets into the vehicle
        CreateThread(function()
            while isOnMission and DoesEntityExist(missionVehicle) do
                Wait(1000)
                
                -- If player entered the vehicle, make the blip visible
                if GetPedInVehicleSeat(missionVehicle, -1) == PlayerPedId() then
                    SetBlipDisplay(missionBlip, 4) -- Make it visible on map
                    
                    -- Don't create a delivery blip - removed this section
                    -- Instead, notify player they can deliver to any chopshop
                    Notify("Vehicle found! Deliver it to any chopshop location.", "success")
                    
                    -- Break the loop - we only need to run this once
                    break
                end
            end
        end)
    else
        Notify("Failed to start mission.", "error")
    end
end

-- End mission and deliver vehicle
function DeliverVehicle()
    if not isOnMission or not missionVehicle or not DoesEntityExist(missionVehicle) then
        Notify("No active mission or vehicle.", "error")
        return
    end
    
    -- Check if player is in the mission vehicle
    if GetPedInVehicleSeat(missionVehicle, -1) ~= PlayerPedId() then
        Notify("You must be in the stolen vehicle to deliver it.", "error")
        return
    end
    
    -- Check if in delivery zone
    local playerPos = GetEntityCoords(PlayerPedId())
    local isNearDelivery = false
    
    -- Check all delivery locations, as the player might deliver to any
    for _, location in pairs(Config.DeliveryLocations) do
        local deliveryLocation = vector3(location.x, location.y, location.z)
        local distance = #(playerPos - deliveryLocation)
        
        if distance <= Config.DeliveryRadius then
            isNearDelivery = true
            break
        end
    end
    
    if not isNearDelivery then
        Notify("Move closer to a delivery point.", "error")
        return
    end
    
    -- Calculate reward
    local reward = CalculateReward(missionVehicle)
    
    -- Start the delivery process
    TaskLeaveVehicle(PlayerPedId(), missionVehicle, 0)
    Wait(1500)
    
    QBCore.Functions.Progressbar("delivering_vehicle", "Delivering vehicle...", 5000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",
        anim = "machinic_loop_mechandplayer",
        flags = 49,
    }, {}, {}, function() -- Done
        -- Give reward to player
        TriggerServerEvent('mns-chopshop:server:RewardPlayer', reward)
        
        -- Delete the vehicle
        DeleteEntity(missionVehicle)
        
        -- Clean up mission
        CleanupMission()
        
        -- Notify player
        Notify("Vehicle delivered! You received $" .. reward, "success")
    end, function() -- Cancel
        Notify("Delivery canceled", "error")
    end)
end

-- Create delivery points and NPCs
CreateThread(function()
    Wait(1000) -- Wait for everything to initialize
    
    -- Create NPCs at all locations
    for i, location in ipairs(Config.NPCLocations) do
        -- Create a blip for each location
        local blip = AddBlipForCoord(location.x, location.y, location.z)
        SetBlipSprite(blip, 527) -- Wrench icon
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.7)
        SetBlipColour(blip, 47) -- Orange color
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName("Chopshop") -- Removed the number to group all blips
        EndTextCommandSetBlipName(blip)
        
        -- Create the NPC
        local pedCoords = location
        RequestModel(GetHashKey(Config.Ped.model))
        
        while not HasModelLoaded(GetHashKey(Config.Ped.model)) do
            Wait(0)
        end
        
        -- Fix for NPC being halfway in the ground by properly adjusting Z position
        local groundZ = pedCoords.z
        if not Config.Ped.disableGroundSnap then
            -- Get ground Z properly
            local success, groundZ = GetGroundZFor_3dCoord(pedCoords.x, pedCoords.y, pedCoords.z, false)
            if not success then
                groundZ = pedCoords.z -- Fallback to original if ground detection fails
            end
        end
        
        -- Create the ped with proper Z coordinate
        local ped = CreatePed(4, GetHashKey(Config.Ped.model), pedCoords.x, pedCoords.y, groundZ, pedCoords.w, false, true)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        
        -- Give each NPC a slightly different animation
        local scenarios = {
            "WORLD_HUMAN_SMOKING",
            "WORLD_HUMAN_STAND_IMPATIENT",
            "WORLD_HUMAN_STAND_MOBILE",
            "WORLD_HUMAN_CLIPBOARD"
        }
        local scenario = scenarios[math.random(#scenarios)]
        TaskStartScenarioInPlace(ped, scenario, 0, true)
        
        -- Store the location for reference when starting a mission
        local thisLocation = location
        
        -- Add interaction with ped using ox_target
        if Config.UI.target == 'ox_target' then
            exports.ox_target:addLocalEntity(ped, {
                {
                    name = 'chopshop_start_mission_' .. i,
                    icon = 'fas fa-car',
                    label = 'Start Mission',
                    onSelect = function()
                        StartMission(thisLocation)
                    end
                },
                {
                    name = 'chopshop_deliver_vehicle_' .. i,
                    icon = 'fas fa-truck-loading',
                    label = 'Deliver Vehicle',
                    onSelect = function()
                        DeliverVehicle()
                    end
                }
            })
        elseif Config.UI.target == 'qb-target' then
            exports['qb-target']:AddTargetEntity(ped, {
                options = {
                    {
                        type = "client",
                        icon = 'fas fa-car',
                        label = 'Start Mission',
                        action = function()
                            StartMission(thisLocation)
                        end
                    },
                    {
                        type = "client",
                        icon = 'fas fa-truck-loading',
                        label = 'Deliver Vehicle',
                        action = function()
                            DeliverVehicle()
                        end
                    }
                },
                distance = 2.5
            })
        else
            -- Fallback to basic interaction when no target system is available
            -- We create a separate thread for each NPC to handle interactions
            CreateThread(function()
                while true do
                    Wait(0)
                    local plyCoords = GetEntityCoords(PlayerPedId())
                    local dist = #(plyCoords - vector3(pedCoords.x, pedCoords.y, pedCoords.z))
                    
                    if dist < 2.0 then
                        DrawText3D(pedCoords.x, pedCoords.y, pedCoords.z + 1.0, "Press [E] to interact")
                        if IsControlJustPressed(0, 38) then -- E key
                            local elements = {}
                            
                            if isOnMission then
                                table.insert(elements, {header = "Deliver Vehicle", params = {event = "mns-chopshop:client:DeliverVehicle"}})
                            else
                                table.insert(elements, {header = "Start Mission", params = {
                                    event = "mns-chopshop:client:StartMission", 
                                    args = {location = thisLocation}
                                }})
                            end
                            
                            exports['qb-menu']:openMenu(elements)
                        end
                    elseif dist < 10.0 then
                        DrawMarker(2, pedCoords.x, pedCoords.y, pedCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 255, 50, 50, 100, false, true, 2, false, nil, nil, false)
                    else
                        Wait(1000)
                    end
                end
            end)
        end
    end
end)

-- Draw text 3D function for fallback
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
    local factor = (string.len(text)) / 370
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
end

-- setTimeout function since it's not available in FiveM by default
function setTimeout(cb, ms)
    local timer = {}
    timer._created = GetGameTimer()
    timer._time = ms
    
    timer.handle = CreateThread(function()
        Wait(ms)
        if timer and not timer.destroyed then
            cb()
        end
    end)
    
    timer.destroyed = false
    timer.destroy = function()
        if timer.handle and not timer.destroyed then
            timer.destroyed = true
            return true
        end
        return false
    end
    
    return timer
end

function clearTimeout(t)
    if t and t.destroy then
        return t.destroy()
    end
    return false
end

-- Register events for client-side menu interactions
RegisterNetEvent('mns-chopshop:client:StartMission', function(data)
    local location = data and data.location
    StartMission(location)
end)

RegisterNetEvent('mns-chopshop:client:DeliverVehicle', function()
    DeliverVehicle()
end)
