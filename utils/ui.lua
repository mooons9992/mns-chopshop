local QBCore = exports['qb-core']:GetCoreObject()

local UI = {}

-- Notification function that handles different notification systems
function UI.Notify(player, data)
    local src = type(player) == "number" and player or nil
    local message = data
    
    -- If data is a string, convert it to the format we need
    if type(data) == "string" then
        message = {
            title = "CHOPSHOP",
            message = data,
            type = "primary",
            duration = 5000
        }
    end
    
    -- If data is a table but doesn't have the right structure
    if type(data) == "table" and not data.message and data[1] then
        message = {
            title = "CHOPSHOP",
            message = data[1],
            type = data[2] or "primary",
            duration = data[3] or 5000
        }
    end
    
    -- Handle server-side notifications
    if src then
        if Config.UI.notify == 'qb' then
            TriggerClientEvent('QBCore:Notify', src, message.message, message.type, message.duration)
        elseif Config.UI.notify == 'ox' then
            TriggerClientEvent('ox_lib:notify', src, {
                title = message.title,
                description = message.message,
                type = message.type,
                duration = message.duration
            })
        elseif Config.UI.notify == 'custom' then
            TriggerClientEvent('your-custom-notification:show', src, message)
        end
    -- Handle client-side notifications
    else
        if Config.UI.notify == 'qb' then
            QBCore.Functions.Notify(message.message, message.type, message.duration)
        elseif Config.UI.notify == 'ox' then
            lib.notify({
                title = message.title,
                description = message.message,
                type = message.type,
                duration = message.duration
            })
        elseif Config.UI.notify == 'custom' then
            -- Implement your custom client notification here
        end
    end
end

-- Format string template with values
function UI.FormatString(template, ...)
    local args = {...}
    return template:gsub("%%s", function() return table.remove(args, 1) or "N/A" end)
end

-- Progress bar function that handles different systems
function UI.ProgressBar(data, cb)
    if Config.UI.progressbar == 'qb' then
        QBCore.Functions.Progressbar(data.id or "progress_action", data.label, data.duration, false, data.canCancel or false, {
            disableMovement = data.disable and data.disable.move or true,
            disableCarMovement = data.disable and data.disable.car or true,
            disableMouse = data.disable and data.disable.mouse or false,
            disableCombat = data.disable and data.disable.combat or true,
        }, {
            animDict = data.anim and data.anim.dict or nil,
            anim = data.anim and data.anim.clip or nil,
            flags = data.anim and data.anim.flag or 1,
        }, {}, {}, function() -- Done
            if cb then cb(true) end
        end, function() -- Cancel
            if cb then cb(false) end
        end)
    elseif Config.UI.progressbar == 'ox' then
        lib.progressBar({
            duration = data.duration,
            label = data.label,
            position = data.position or 'bottom',
            useWhileDead = data.useWhileDead or false,
            canCancel = data.canCancel or false,
            disable = {
                car = data.disable and data.disable.car or true,
                move = data.disable and data.disable.move or true,
                combat = data.disable and data.disable.combat or true,
                mouse = data.disable and data.disable.mouse or false,
            },
            anim = data.anim and {
                dict = data.anim.dict,
                clip = data.anim.clip,
                flag = data.anim.flag or 1,
                blendIn = data.anim.blendIn or 1.0,
                blendOut = data.anim.blendOut or 1.0,
            } or nil,
        }, function(cancelled)
            if cb then cb(not cancelled) end
        end)
    end
end

-- Add target to entity with appropriate system
function UI.AddEntityTarget(entity, options)
    if Config.UI.target == 'qb-target' then
        -- Convert options format for qb-target
        local qbOptions = {
            options = {},
            distance = options[1].distance or Config.InteractionDistance
        }
        
        for _, option in pairs(options) do
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
        
        exports['qb-target']:AddTargetEntity(entity, qbOptions)
    elseif Config.UI.target == 'ox_target' then
        exports.ox_target:addLocalEntity(entity, options)
    end
end

-- Remove target from entity
function UI.RemoveEntityTarget(entity)
    if Config.UI.target == 'qb-target' then
        exports['qb-target']:RemoveTargetEntity(entity)
    elseif Config.UI.target == 'ox_target' then
        exports.ox_target:removeLocalEntity(entity)
    end
end

-- Open a menu with the appropriate system
function UI.OpenMenu(title, options, position)
    if Config.UI.menu == 'ox' then
        lib.registerContext({
            id = 'mns_chopshop_menu',
            title = title,
            options = options,
            position = position or 'bottom-right'
        })
        lib.showContext('mns_chopshop_menu')
    elseif Config.UI.menu == 'qb' then
        -- Convert options to qb-menu format
        local qbOptions = {
            {
                header = title,
                isMenuHeader = true
            }
        }
        
        for _, option in ipairs(options) do
            table.insert(qbOptions, {
                header = option.title,
                txt = option.description,
                params = {
                    event = option.event,
                    args = option.args,
                    isAction = option.isAction,
                    disabled = option.disabled
                }
            })
        end
        
        exports['qb-menu']:openMenu(qbOptions)
    elseif Config.UI.menu == 'nh-context' then
        local nhOptions = {}
        for _, option in ipairs(options) do
            table.insert(nhOptions, {
                header = option.title,
                context = option.description,
                event = option.event,
                args = option.args,
                disabled = option.disabled
            })
        end
        TriggerEvent('nh-context:createMenu', nhOptions)
    end
end

-- Set fuel level with appropriate system
function UI.SetFuel(vehicle, level)
    if not vehicle or level < 0 or level > 100 then
        return false
    end
    
    if Config.UI.fuel == 'LegacyFuel' then
        exports['LegacyFuel']:SetFuel(vehicle, level)
    elseif Config.UI.fuel == 'cdn-fuel' then
        exports['cdn-fuel']:SetFuel(vehicle, level)
    elseif Config.UI.fuel == 'lc_fuel' then
        exports['lc_fuel']:SetFuel(vehicle, level)
    elseif Config.UI.fuel == 'ps-fuel' then
        exports['ps-fuel']:SetFuel(vehicle, level)
    else
        -- Default FiveM fuel level
        SetVehicleFuelLevel(vehicle, level)
    end
    return true
end

return UI