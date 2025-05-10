local Config = {}
local configFile = LoadResourceFile(GetCurrentResourceName(), "config.lua")
if configFile then
    Config = load(configFile)() or {}
end

local UI = {}

-- Format string with arguments
function UI.FormatString(str, ...)
    return string.format(str, ...)
end

-- Notification handler
function UI.Notify(playerSource, data)
    if type(data) == "string" then
        data = {
            message = data,
            type = "primary",
            duration = 5000
        }
    end

    if Config.UI.notify == 'qb' then
        if playerSource then
            TriggerClientEvent('QBCore:Notify', playerSource, data.message, data.type, data.duration)
        else
            exports['qb-core']:GetCoreObject().Functions.Notify(data.message, data.type, data.duration)
        end
    elseif Config.UI.notify == 'ox' then
        if playerSource then
            TriggerClientEvent('ox_lib:notify', playerSource, {
                description = data.message,
                type = data.type,
                duration = data.duration
            })
        else
            lib.notify({
                description = data.message,
                type = data.type,
                duration = data.duration
            })
        end
    elseif Config.UI.notify == 'esx' then
        if playerSource then
            TriggerClientEvent('esx:showNotification', playerSource, data.message)
        else
            exports['esx']:ShowNotification(data.message)
        end
    elseif Config.UI.notify == 'custom' then
        -- Add your custom notification logic here
    end
end

-- Entity targeting
function UI.AddEntityTarget(entity, options)
    print("^3[CHOPSHOP DEBUG]^7 Adding target to entity: " .. entity)
    
    -- Handle ox_target implementation
    if Config.UI.target == 'ox_target' then
        if DoesEntityExist(entity) then
            -- Direct call to ox_target
            exports.ox_target:addLocalEntity({entity}, options)
            print("^2[MNS-CHOPSHOP]^7 Added target options to entity via ox_target")
            return true
        end
    -- Handle qb-target implementation
    elseif Config.UI.target == 'qb-target' then
        if DoesEntityExist(entity) then
            -- Convert options format for qb-target
            local qbOptions = {
                options = {},
                distance = options[1].distance or 2.0
            }
            
            for i, option in ipairs(options) do
                if option then -- Make sure option isn't nil
                    table.insert(qbOptions.options, {
                        type = "client",
                        icon = option.icon,
                        label = option.label,
                        action = function()
                            option.onSelect()
                        end,
                        canInteract = option.canInteract
                    })
                end
            end
            
            exports['qb-target']:AddTargetEntity(entity, qbOptions)
            print("^2[MNS-CHOPSHOP]^7 Added target options to entity via qb-target")
            return true
        end
    end
    
    print("^1[MNS-CHOPSHOP]^7 Failed to add target options to entity")
    return false
end

-- Set vehicle fuel
function UI.SetFuel(vehicle, level)
    if Config.UI.fuel == 'LegacyFuel' then
        exports['LegacyFuel']:SetFuel(vehicle, level)
    elseif Config.UI.fuel == 'cdn-fuel' then
        exports['cdn-fuel']:SetFuel(vehicle, level)
    elseif Config.UI.fuel == 'lc_fuel' then
        exports['lc_fuel']:SetFuel(vehicle, level)
    elseif Config.UI.fuel == 'ps-fuel' then
        exports['ps-fuel']:SetFuel(vehicle, level)
    end
end

return UI