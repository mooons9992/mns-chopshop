local QBCore = exports['qb-core']:GetCoreObject()
local VehicleUtils = require 'utils.vehicles'

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
            TriggerClientEvent('QBCore:Notify', src, Config.Notifications.personalVehicle.message, 
                Config.Notifications.personalVehicle.type, 
                Config.Notifications.personalVehicle.duration)
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
            
            -- Notify player
            TriggerClientEvent('QBCore:Notify', src, 
                string.format(Config.Notifications.vehicleSold.message, reward), 
                Config.Notifications.vehicleSold.type, 
                Config.Notifications.vehicleSold.duration)

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
    
    -- Notify player
    TriggerClientEvent('QBCore:Notify', src, 
        string.format(Config.Notifications.vehicleSold.message, reward), 
        Config.Notifications.vehicleSold.type, 
        Config.Notifications.vehicleSold.duration)
    
    -- Log if debug is enabled
    if Config.Debug then
        print("^2[mns-chopshop]^7 Player " .. GetPlayerName(src) .. " completed a mission and received $" .. reward)
    end
end)

-- Add admin command to force start a mission
QBCore.Commands.Add('forcechopshop', 'Force start a chopshop mission (Admin Only)', {}, true, function(source)
    TriggerClientEvent('mns-chopshop:client:forceStartMission', source)
end, 'admin')

