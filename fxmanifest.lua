fx_version 'cerulean'
game 'gta5'
lua54 'yes'

client_scripts {
    'client/main.lua',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config/shared.lua'
}

server_scripts {
    'server/main.lua',
}

dependencies {
    'qb-core',
    'ox_inventory'
}