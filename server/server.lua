local QBCore = exports['qb-core']:GetCoreObject()

-- Debug print function
local function DebugPrint(msg)
    if Config.Debug then
        print("^3[MNS-CHOPSHOP]^7 " .. msg)
    end
end

-- Direct inclusion of VehicleUtils from file
local VehicleUtils = {}
local vehicleUtilsFile = LoadResourceFile(GetCurrentResourceName(), "utils/vehicles.lua")
if vehicleUtilsFile then
    VehicleUtils = load(vehicleUtilsFile)() or {}
    print("^2[MNS-CHOPSHOP]^7 Vehicle utils module loaded successfully")
else
    print("^1[MNS-CHOPSHOP]^7 Failed to load vehicle utils module")
end

-- Helper function for notifications
local function NotifyPlayer(src, notification, formatArgs)
    if not notification then return end
    
    local message = notification.message
    if formatArgs then
        message = string.format(message, table.unpack(formatArgs))
    end
    
    TriggerClientEvent('QBCore:Notify', src, message, notification.type, notification.duration)
end

-- Register server events
RegisterNetEvent('mns-chopshop:server:sellVehicle', function(plate, vehicleNetId, suggestedReward)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end

    -- Normalize plate format
    plate = string.upper(string.gsub(plate, "%s+", ""))

    -- Check if the vehicle is owned by a player
    exports.oxmysql:execute('SELECT 1 FROM player_vehicles WHERE plate = ? LIMIT 1', {plate}, function(result)
        if result and result[1] then
            -- Using direct QBCore notification for personal vehicle
            NotifyPlayer(src, Config.Notifications.personalVehicle)
        else
            -- Add security check for reward value
            local reward = suggestedReward
            if not reward or reward <= 0 or reward > 50000 then
                -- If the client-suggested reward seems invalid, generate a safe random one
                reward = math.random(Config.RewardRange.min, Config.RewardRange.max)
            else
                -- Cap the reward to prevent exploits
                reward = math.min(reward, Config.RewardRange.max * 2)
            end
            
            -- Give reward
            Player.Functions.AddMoney('cash', reward)
            
            -- Notify player with direct QBCore notification
            NotifyPlayer(src, Config.Notifications.vehicleSold, {reward})

            -- Remove vehicle and keys on client
            TriggerClientEvent('mns-chopshop:client:deleteVehicle', src, vehicleNetId, plate)
            
            -- Log transaction if debug is enabled
            if Config.Debug then
                print("^2[mns-chopshop]^7 Player " .. GetPlayerName(src) .. " sold vehicle with plate " .. plate .. " for $" .. reward)
            end
        end
    end)
end)

-- Add cash for completed missions
RegisterNetEvent('mns-chopshop:server:addCash', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Generate reward based on configured range
    local reward = math.random(Config.RewardRange.min, Config.RewardRange.max)
    
    -- Add money to player
    Player.Functions.AddMoney('cash', reward)
    
    -- Notify player with direct QBCore notification
    NotifyPlayer(src, Config.Notifications.vehicleSold, {reward})
    
    -- Log if debug is enabled
    if Config.Debug then
        print("^2[mns-chopshop]^7 Player " .. GetPlayerName(src) .. " completed a mission and received $" .. reward)
    end
end)

-- Reward player for completing mission
RegisterNetEvent('mns-chopshop:server:RewardPlayer', function(amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Validate reward amount to prevent exploits
    if type(amount) ~= "number" or amount < Config.RewardRange.min or amount > (Config.RewardRange.max * 3) then
        DebugPrint("Player " .. src .. " tried to claim an invalid reward: " .. tostring(amount))
        return
    end
    
    -- Add money to player
    Player.Functions.AddMoney('cash', amount, 'chopshop-mission-reward')
    
    -- Log the transaction
    DebugPrint("Player " .. src .. " received $" .. amount .. " from chopshop mission")
    
    -- Send notification to player using direct QBCore notification
    TriggerClientEvent('QBCore:Notify', src, "You received $" .. amount, "success")
end)

-- Add admin command to force start a mission
QBCore.Commands.Add('forcechopshop', 'Force start a chopshop mission (Admin Only)', {}, true, function(source)
    TriggerClientEvent('mns-chopshop:client:forceStartMission', source)
end, 'admin')

-- Version check notification
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print("^2[MNS-CHOPSHOP]^7 Resource started successfully")
    end
end)

