fx_version 'cerulean'
game 'gta5'

author 'Djonza'
description 'FiveM Admin Panel'
version '1.0.0'
lua54 'yes'

shared_scripts {
    'config.lua',
    '@ox_lib/init.lua',
    '@es_extended/imports.lua',
}


client_scripts {
    'client.lua',
    'duty-client.lua',
    'id-client.lua',
    'client-commands.lua',
    'admintag_cl.lua'
}

server_scripts {
    'server.lua',
    'duty-server.lua',
    'id-server.lua',
    'admintag_sv.lua',
    'server-commands.lua',
    "server-staffchat.lua",
    '@oxmysql/lib/MySQL.lua'
}

ui_page {
 'html/index.html',
}

files {
    'html/index.html',
    'html/styles.css',
    'html/script.js',
    'locales/*.json'
}

exports {
    'IsPlayerAdminAndOnDuty'
}server_scripts { '@mysql-async/lib/MySQL.lua' }