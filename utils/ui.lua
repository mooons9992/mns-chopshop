local QBCore = exports['qb-core']:GetCoreObject()
local lib = exports.ox_lib

local UI = {}

-- Format string with arguments
function UI.FormatString(str, ...)
    return string.format(str, ...)
end

-- Notification handler - Simplified to just use QBCore's notification system
function UI.Notify(playerSource, data)
    if type(data) == "string" then
        data = {
            message = data,
            type = "primary",
            duration = 5000
        }
    end

    -- Default to QBCore notifications since we removed notify from config
    if playerSource then
        TriggerClientEvent('QBCore:Notify', playerSource, data.message, data.type, data.duration)
    else
        QBCore.Functions.Notify(data.message, data.type, data.duration)
    end
end

-- Entity targeting - Keep this as is since we still have target in config
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

-- Set vehicle fuel - Keep this as is since we still have fuel in config
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

-- Simplified ProgressBar function that just uses QBCore
function UI.ProgressBar(data, cb)
    -- Default to QBCore progressbar since we removed progressbar from config
    exports['qb-progressbar']:Progress({
        name = data.id or "progress_action",
        duration = data.duration,
        label = data.label,
        useWhileDead = data.useWhileDead or false,
        canCancel = data.canCancel or false,
        controlDisables = {
            disableMovement = data.disable and data.disable.move or true,
            disableCarMovement = data.disable and data.disable.car or true,
            disableMouse = data.disable and data.disable.mouse or false,
            disableCombat = data.disable and data.disable.combat or true,
        },
        animation = {
            animDict = data.anim and data.anim.dict or nil,
            anim = data.anim and data.anim.clip or nil,
            flags = data.anim and data.anim.flag or 1,
        },
    }, cb)
end

return UI