fx_version 'adamant'
game 'gta5'
lua54 'yes'

author 'Sentrix Development'
description '[SENTRIX] Jobcore'

version '1.0.0'

server_scripts {
    'src/server/**.lua',
    '@mysql-async/lib/MySQL.lua',
    'config.lua'
}

client_scripts {
    'src/client/**.lua'
}

shared_scripts {
    '@ox_lib/init.lua',
    '@es_extended/imports.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

escrow_ignore {
    'config.lua'
}
