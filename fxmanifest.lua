fx_version 'cerulean'
game 'gta5'

name 'mns-chopshop'
author 'Mooons'
version '1.0.0'

description 'Advanced Chopshop Mission and Vehicle Selling System'
repository 'https://github.com/mooons9992/mns-chopshop'

lua54 'yes'

shared_scripts {
    '@oxmysql/lib/MySQL.lua',
    '@qb-core/shared/locale.lua',
    'config.lua',
    'utils/*.lua'
}

client_scripts {
    'client/*.lua',
}

server_scripts {
    'server/sv_version.lua',
    'server/*.lua'
}

dependencies {
    'qb-core',
    'oxmysql'
}

