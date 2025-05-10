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
    'client/targets.lua' -- Add this new file
}

server_scripts {
    'server/sv_version.lua',
    'server/server.lua'
}

dependencies {
    'qb-core'
}

exports {
    'StartMission',
    'EndMission',
    'SellVehicleToChopshop'
}

