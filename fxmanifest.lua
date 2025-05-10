fx_version 'cerulean'
game 'gta5'

author 'Mooons'
description 'MNS Chopshop Script'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'utils/ui.lua',
    'utils/vehicle.lua',
    'client/client.lua',
    -- Comment out one of these files to prevent duplicate NPCs
    -- 'client/targets.lua'
}

server_scripts {
    'server/sv_version.lua',
    'server/server.lua'
}

dependencies {
    'qb-core',
    'ox_lib'
}

exports {
    'StartMission',
    'EndMission',
    'SellVehicleToChopshop'
}

