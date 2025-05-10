local QBCore = exports['qb-core']:GetCoreObject()

local function isDebug()
    return Config.Debug
end

-- Function to handle the chopshop NPC spawning and target creation
function SetupChopshopTargets()
    -- Create the ped
    local pedCoords = Config.Ped.location
    
    if isDebug() then
        print("^3[MNS-CHOPSHOP]^7 Setting up chopshop target at: " .. 
              pedCoords.x .. ", " .. pedCoords.y .. ", " .. pedCoords.z)
    end
    
    -- Clear any existing ped
    local existingPeds = GetGamePool('CPed')
    for _, existingPed in ipairs(existingPeds) do
        if #(GetEntityCoords(existingPed) - vector3(pedCoords.x, pedCoords.y, pedCoords.z)) < 1.0 then
            DeleteEntity(existingPed)
        end
    end
    
    -- Load the ped model
    local pedModel = Config.Ped.model
    RequestModel(GetHashKey(pedModel))
    while not HasModelLoaded(GetHashKey(pedModel)) do
        Wait(10)
    end
    
    -- Create the ped
    local ped = CreatePed(4, GetHashKey(pedModel), pedCoords.x, pedCoords.y, pedCoords.z - 1.0, pedCoords.w, false, true)
    
    if isDebug() then
        print("^3[MNS-CHOPSHOP]^7 Created ped entity: " .. ped)
    end
    
    -- Set the ped properties
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskStartScenarioInPlace(ped, Config.Ped.scenario, 0, true)
    
    -- Create target options
    local options = {
        {
            name = 'chopshop_start_mission',
            icon = 'fas fa-car',
            label = 'Start Mission',
            onSelect = function()
                TriggerEvent('mns-chopshop:client:StartMission')
            end
        },
        {
            name = 'chopshop_end_mission',
            icon = 'fas fa-flag-checkered',
            label = 'End Mission',
            onSelect = function()
                TriggerEvent('mns-chopshop:client:EndMission')
            end
        }
    }
    
    if Config.SellVehicleEnabled then
        table.insert(options, {
            name = 'chopshop_sell_vehicle',
            icon = 'fas fa-hand-holding-usd',
            label = 'Sell Vehicle',
            onSelect = function()
                TriggerEvent('mns-chopshop:client:SellVehicleToChopshop')
            end
        })
    end
    
    -- Create a permanent blip
    local blip = AddBlipForCoord(pedCoords.x, pedCoords.y, pedCoords.z)
    SetBlipSprite(blip, 326)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.7)
    SetBlipColour(blip, 1)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Chopshop")
    EndTextCommandSetBlipName(blip)
    
    -- Create target based on configured system
    if Config.UI.target == 'ox_target' then
        -- For ox_target
        exports.ox_target:addLocalEntity(ped, options)
        
        if isDebug() then
            print("^3[MNS-CHOPSHOP]^7 Added targets with ox_target")
        end
    elseif Config.UI.target == 'qb-target' then
        -- Convert options for qb-target
        local qbOptions = {
            options = {},
            distance = 2.5
        }
        
        for _, option in ipairs(options) do
            table.insert(qbOptions.options, {
                type = "client",
                icon = option.icon,
                label = option.label,
                action = option.onSelect
            })
        end
        
        exports['qb-target']:AddTargetEntity(ped, qbOptions)
        
        if isDebug() then
            print("^3[MNS-CHOPSHOP]^7 Added targets with qb-target")
        end
    else
        -- Fallback to zone if target system not recognized
        print("^1[MNS-CHOPSHOP]^7 Unknown target system: " .. Config.UI.target .. ", creating zone instead")
        
        -- Create a marker as fallback
        CreateThread(function()
            while true do
                local sleep = 1000
                local plyCoords = GetEntityCoords(PlayerPedId())
                local dist = #(plyCoords - vector3(pedCoords.x, pedCoords.y, pedCoords.z))
                
                if dist < 10.0 then
                    sleep = 0
                    DrawMarker(2, pedCoords.x, pedCoords.y, pedCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 255, 0, 0, 100, false, true, 2, false, nil, nil, false)
                    
                    if dist < 2.0 then
                        DrawText3D(pedCoords.x, pedCoords.y, pedCoords.z + 1.0, "Press ~g~E~w~ to interact with Chopshop")
                        
                        if IsControlJustPressed(0, 38) then -- E key
                            -- Open menu with simple UI
                            local menuItems = {
                                {header = "Chopshop", txt = "Select an option"},
                                {header = "Start Mission", params = {event = 'mns-chopshop:client:StartMission'}},
                                {header = "End Mission", params = {event = 'mns-chopshop:client:EndMission'}}
                            }
                            
                            if Config.SellVehicleEnabled then
                                table.insert(menuItems, {header = "Sell Vehicle", params = {event = 'mns-chopshop:client:SellVehicleToChopshop'}})
                            end
                            
                            exports['qb-menu']:openMenu(menuItems)
                        end
                    end
                end
                
                Wait(sleep)
            end
        end)
    end
    
    return ped
end

-- Function to draw 3D text for fallback
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

-- Initialize targets when resource starts
CreateThread(function()
    Wait(1000) -- Wait for resource to initialize
    SetupChopshopTargets()
    
    if isDebug() then
        print("^2[MNS-CHOPSHOP]^7 Target setup complete!")
    end
end)

-- Register events that can be called from client.lua
RegisterNetEvent('mns-chopshop:client:StartMission', function()
    -- Call the original StartMission function from client.lua
    exports['mns-chopshop']:StartMission()
end)

RegisterNetEvent('mns-chopshop:client:EndMission', function()
    -- Call the original EndMission function from client.lua
    exports['mns-chopshop']:EndMission()
end)

RegisterNetEvent('mns-chopshop:client:SellVehicleToChopshop', function()
    -- Call the original SellVehicleToChopshop function from client.lua
    exports['mns-chopshop']:SellVehicleToChopshop()
end)