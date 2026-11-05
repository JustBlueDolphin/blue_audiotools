fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

name 'blue_audiotools'
description '/soundcheck: place a test radio and tune how much sound the blue_plazas shop glass lets through, live'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

files {
    'config/shared.lua',
}

dependencies {
    'ox_lib',
}
