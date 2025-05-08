local QBCore = exports['qb-core']:GetCoreObject()
local UI = require 'utils.ui'
local VehicleUtils = require 'utils.vehicles'

-- State variables
local playerMissions = {}
local currentTime = GetGameTimer()
local lastMissionTime = {}
local lastSellTime = {}
local showPlateText = false
local targetPlate = ""

-- Debugging helper function
function DebugPrint(message)
    if Config.Debug then
        print("^3[DEBUG]^7 " .. tostring(message))
    end
end

-- Show text on screen
function ShowPlateText(plate)
    targetPlate = plate
    showPlateText = true
    DebugPrint("Showing plate text: " .. plate)
end

-- Hide the text
function HidePlateText()
    showPlateText = false
    DebugPrint("Hiding plate text.")
end

-- Draw GTA-style mission text on screen
CreateThread(function()
    while true do
        if showPlateText then
            SetTextColour(255, 255, 255, 255)
            SetTextFont(0)
            SetTextScale(0.5, 0.5)
            SetTextCentre(true)
            SetTextOutline()
            BeginTextCommandDisplayText("STRING")
            AddTextComponentSubstringPlayerName("Find and enter the car with plate: ~r~" .. targetPlate)
            EndTextCommandDisplayText(0.5, 0.95)
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- Select a random location from Config.Mission.SpawnLocations
function SelectRandomLocation()
    local locations = Config.Mission.SpawnLocations
    if #locations == 0 then
        DebugPrint("Config.Mission.SpawnLocations is empty! Please add some spawn locations.")
        return nil
    end
    local location = locations[math.random(#locations)]
    DebugPrint("Selected random location: " .. json.encode(location))
    return location
end

-- Spawn a random vehicle at the specified location
function SpawnRandomVehicle(spawnLocation)
    -- Validate Vehicle Models in Config
    local models = Config.Mission.VehicleModels
    if not models or #models == 0 then
        DebugPrint("Config.Mission.VehicleModels is empty or not defined!")
        return nil
    end

    -- Extract position and heading from the spawnLocation vector4
    local x, y, z, heading = spawnLocation.x, spawnLocation.y, spawnLocation.z, spawnLocation.w

    -- Select a random vehicle model
    local randomModel = models[math.random(#models)]
    local modelHash = GetHashKey(randomModel)
    DebugPrint(string.format("Spawning vehicle model: %s at x: %.2f, y: %.2f, z: %.2f, heading: %.2f", 
        randomModel, x, y, z, heading))

    -- Request and load the model
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 30 do
        timeout = timeout + 1
        Wait(100)
    end
    
    if timeout >= 30 then
        DebugPrint("Failed to load model: " .. randomModel)
        return nil
    end

    -- Clear the area to prevent interference
    ClearAreaOfVehicles(x, y, z, 10.0, false, false, false, false, false)
    ClearAreaOfObjects(x, y, z, 10.0, 0)
    ClearAreaOfPeds(x, y, z, 10.0, 0)

    -- Spawn the vehicle
    local vehicle = CreateVehicle(modelHash, x, y, z + 0.7, heading, true, false)
    if not vehicle or vehicle == 0 then
        DebugPrint("Failed to create the vehicle!")
        return nil
    end

    -- Stabilize vehicle position and physics
    FreezeEntityPosition(vehicle, true)
    SetEntityCoords(vehicle, x, y, z + 0.7, false, false, false, true)
    SetEntityHeading(vehicle, heading)
    SetVehicleOnGroundProperly(vehicle)
    FreezeEntityPosition(vehicle, false)

    -- Generate a unique plate
    local randomPlate = VehicleUtils.GenerateRandomPlate()
    SetVehicleNumberPlateText(vehicle, randomPlate)
    
    -- Set entity flags
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleDoorsLocked(vehicle, 2)
    SetVehicleEngineOn(vehicle, false, false, false)

    -- Apply some random damage for realism
    VehicleUtils.ApplyRandomDamage(vehicle, 700, 1000)

    -- Set fuel level
    local fuelLevel = math.random(30, 100)
    UI.SetFuel(vehicle, fuelLevel)

    -- Create mission blip
    local blip = AddBlipForEntity(vehicle)
    SetBlipSprite(blip, Config.Mission.Blip.Sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, Config.Mission.Blip.Color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Target Vehicle")
    EndTextCommandSetBlipName(blip)
    
    return vehicle
end

-- Monitor player entering the correct vehicle
CreateThread(function()
    while true do
        Wait(1000)
        local playerId = GetPlayerServerId(PlayerId())
        local missionData = playerMissions[playerId]

        if missionData and missionData.isOnMission and missionData.vehicle then
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            if vehicle ~= 0 then
                local currentPlate = GetVehicleNumberPlateText(vehicle)
                currentPlate = string.upper(string.gsub(currentPlate, "%s+", ""))
                local expectedPlate = GetVehicleNumberPlateText(missionData.vehicle)
                expectedPlate = string.upper(string.gsub(expectedPlate, "%s+", ""))
                if currentPlate == expectedPlate then
                    DebugPrint("Player entered the correct vehicle with plate: " .. currentPlate)
                    HidePlateText()
                else
                    DebugPrint("Player entered a vehicle, but the plate does not match: " .. currentPlate)
                end
            end
        end
    end
end)

-- Create Ped and interaction with the target menu
CreateThread(function()
    local model = GetHashKey(Config.Ped.model)
    RequestModel(model)

    while not HasModelLoaded(model) do
        Wait(10)
    end

    -- Create the ped
    local ped = CreatePed(4, model, Config.Ped.location.x, Config.Ped.location.y, Config.Ped.location.z, Config.Ped.location.w, false, true)
    if not DoesEntityExist(ped) then
        DebugPrint("Failed to create ped!")
        return
    end

    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    
    -- Set ped scenario/animation
    if Config.Ped.scenario then
        TaskStartScenarioInPlace(ped, Config.Ped.scenario, 0, true)
    end

    -- Define interaction options
    local options = {
        {
            name = 'chopshop_start_mission',
            icon = 'fas fa-car',
            label = 'Start Mission',
            distance = Config.InteractionDistance,
            onSelect = function()
                StartMission()
            end
        },
        {
            name = 'chopshop_end_mission',
            icon = 'fas fa-flag-checkered',
            label = 'End Mission',
            distance = Config.InteractionDistance,
            onSelect = function()
                EndMission()
            end
        }
    }

    if Config.SellVehicleEnabled then
        table.insert(options, {
            name = 'chopshop_sell_vehicle',
            icon = 'fas fa-hand-holding-usd',
            label = 'Sell Vehicle',
            distance = Config.InteractionDistance,
            canInteract = function(entity, distance, data)
                local playerId = GetPlayerServerId(PlayerId())
                local missionData = playerMissions[playerId]
                return not (missionData and missionData.isOnMission)
            end,
            onSelect = function()
                SellVehicleToChopshop()
            end
        })
    end

    -- Add interaction to targeting system
    UI.AddEntityTarget(ped, options)
end)

-- Start Mission
function StartMission()
    local playerId = GetPlayerServerId(PlayerId())
    local currentTime = GetGameTimer() / 1000

    DebugPrint("Attempting to start mission for player ID: " .. playerId)

    -- Check cooldown
    if lastMissionTime[playerId] and (currentTime - lastMissionTime[playerId]) < Config.Mission.Cooldown then
        local remainingTime = math.ceil(Config.Mission.Cooldown - (currentTime - lastMissionTime[playerId]))
        UI.Notify(nil, {
            message = UI.FormatString(Config.Notifications.missionCooldown.message, remainingTime),
            type = Config.Notifications.missionCooldown.type,
            duration = Config.Notifications.missionCooldown.duration
        })
        return
    end

    if not playerMissions[playerId] then
        playerMissions[playerId] = {}
    end

    local missionData = playerMissions[playerId]

    if missionData.isOnMission then
        UI.Notify(nil, Config.Notifications.alreadyOnMission)
        return
    end

    local randomLocation = SelectRandomLocation()
    if not randomLocation then
        UI.Notify(nil, Config.Notifications.noLocations)
        return
    end

    local vehicle = SpawnRandomVehicle(randomLocation)
    if vehicle then
        missionData.isOnMission = true
        missionData.startTime = GetGameTimer()
        missionData.vehicle = vehicle
        missionData.location = randomLocation
        missionData.vehicleDelivered = false
        missionData.blipRadius = CreateMissionRadius(randomLocation)

        local plate = GetVehicleNumberPlateText(vehicle)
        plate = string.upper(string.gsub(plate, "%s+", ""))
        ShowPlateText(plate)

        lastMissionTime[playerId] = currentTime
        UI.Notify(nil, Config.Notifications.missionStart)
    else
        UI.Notify(nil, Config.Notifications.spawnFailed)
    end
end

function CreateMissionRadius(location)
    local radiusBlip = AddBlipForRadius(location.x, location.y, location.z, Config.Mission.Radius)
    SetBlipAlpha(radiusBlip, Config.Mission.Blip.Alpha)
    SetBlipColour(radiusBlip, Config.Mission.Blip.Color)
    return radiusBlip
end

function EndMission()
    local playerId = GetPlayerServerId(PlayerId())
    local missionData = playerMissions[playerId]

    if not missionData or not missionData.isOnMission then
        UI.Notify(nil, Config.Notifications.noMission)
        return
    end

    if missionData.vehicleDelivered then
        TriggerServerEvent('mns-chopshop:server:addCash')
        UI.Notify(nil, Config.Notifications.missionCompleted)
    else
        UI.Notify(nil, Config.Notifications.missionFailed)
    end

    DeleteMissionVehicle(playerId)
    RemoveBlip(missionData.blipRadius)

    playerMissions[playerId] = nil
    HidePlateText()
end

function DeleteMissionVehicle(playerId)
    local missionData = playerMissions[playerId]
    if missionData and missionData.vehicle and DoesEntityExist(missionData.vehicle) then
        SetEntityAsMissionEntity(missionData.vehicle, true, true)
        DeleteVehicle(missionData.vehicle)
    end
end

function IsAtDeliveryLocation(playerCoords)
    for _, location in ipairs(Config.DeliveryLocations) do
        local distance = #(playerCoords - vector3(location.x, location.y, location.z))
        if distance <= Config.DeliveryRadius then
            return true
        end
    end
    return false
end

CreateThread(function()
    while true do
        Wait(1000)
        local playerId = GetPlayerServerId(PlayerId())
        local missionData = playerMissions[playerId]

        if missionData and missionData.isOnMission and missionData.vehicle and not missionData.vehicleDelivered then
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            local missionVehicle = missionData.vehicle

            if vehicle == missionVehicle then
                local playerCoords = GetEntityCoords(ped)
                local currentPlate = GetVehicleNumberPlateText(vehicle)
                currentPlate = string.upper(string.gsub(currentPlate, "%s+", ""))
                local expectedPlate = GetVehicleNumberPlateText(missionVehicle)
                expectedPlate = string.upper(string.gsub(expectedPlate, "%s+", ""))

                if currentPlate == expectedPlate and IsAtDeliveryLocation(playerCoords) then
                    missionData.vehicleDelivered = true
                end
            end
        end
    end
end)

-- Mission timeout check
CreateThread(function()
    while true do
        Wait(5000)
        local playerId = GetPlayerServerId(PlayerId())
        local missionData = playerMissions[playerId]

        if missionData and missionData.isOnMission then
            local elapsedTime = (GetGameTimer() - missionData.startTime) / 1000
            if elapsedTime >= Config.MissionTimeout then
                EndMission()
                UI.Notify(nil, Config.Notifications.missionTimeout)
            end
        end
    end
end)

-- Sell non-mission vehicle to chopshop
function SellVehicleToChopshop()
    local playerId = GetPlayerServerId(PlayerId())
    local currentTime = GetGameTimer()

    -- Check cooldown
    if lastSellTime[playerId] and (currentTime - lastSellTime[playerId]) / 1000 < Config.SellCooldown then
        local remainingTime = math.ceil(Config.SellCooldown - (currentTime - lastSellTime[playerId]) / 1000)
        UI.Notify(nil, {
            message = UI.FormatString(Config.Notifications.sellCooldown.message, remainingTime),
            type = Config.Notifications.sellCooldown.type,
            duration = Config.Notifications.sellCooldown.duration
        })
        return
    end

    -- Find closest vehicle
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local closestVehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 10.0, 0, 70)

    if closestVehicle == 0 then
        UI.Notify(nil, Config.Notifications.noVehicleNearby)
        return
    end

    -- Check distance
    local distance = #(coords - GetEntityCoords(closestVehicle))
    if distance > 10.0 then
        UI.Notify(nil, Config.Notifications.tooFarFromVehicle)
        return
    end

    -- Get vehicle info
    local plate = GetVehicleNumberPlateText(closestVehicle)
    plate = string.upper(string.gsub(plate, "%s+", ""))
    local vehicleNetId = NetworkGetNetworkIdFromEntity(closestVehicle)

    -- Calculate value based on vehicle condition and class
    local reward = VehicleUtils.CalculateVehicleValue(closestVehicle)
    
    -- Send to server for processing
    TriggerServerEvent('mns-chopshop:server:sellVehicle', plate, vehicleNetId, reward)
    lastSellTime[playerId] = currentTime
end

-- Handle the deletion of a sold vehicle
RegisterNetEvent('mns-chopshop:client:deleteVehicle', function(vehicleNetId, plate)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if DoesEntityExist(vehicle) then
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)
        TriggerEvent('qb-vehiclekeys:client:removeKey', plate)
    end
end)

-- Force start mission (admin command handler)
RegisterNetEvent('mns-chopshop:client:forceStartMission', function()
    local playerId = GetPlayerServerId(PlayerId())
    if playerMissions[playerId] and playerMissions[playerId].isOnMission then
        EndMission() -- End current mission if exists
    end
    StartMission()
end)

-- Resource cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Clean up all mission data and entities
    for playerId, missionData in pairs(playerMissions) do
        if missionData.vehicle and DoesEntityExist(missionData.vehicle) then
            DeleteEntity(missionData.vehicle)
        end
        if missionData.blipRadius then
            RemoveBlip(missionData.blipRadius)
        end
    end
end)
