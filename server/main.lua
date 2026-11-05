local shared = require 'config.shared'
local serverConfig = require 'config.server'

local FILE = 'data/levels.json'

---@type table<string, integer> unit -> percent of sound its glass blocks
local levels = json.decode(LoadResourceFile(cache.resource, FILE) or '{}') or {}

local validUnit = {}
for _, unit in ipairs(shared.units) do validUnit[unit] = true end

local function isAdmin(src)
    if IsPlayerAceAllowed(tostring(src), 'blue_audiotools.admin') then return true end
    for _, kind in ipairs({ 'license', 'license2' }) do
        local identifier = GetPlayerIdentifierByType(src, kind)
        if identifier then
            identifier = identifier:gsub('^license2:', 'license:')
            for _, admin in ipairs(serverConfig.admins) do
                if admin == identifier then return true end
            end
        end
    end
    return false
end

lib.callback.register('blue_audiotools:levels', function()
    return levels
end)

lib.addCommand('soundcheck', {
    help = 'Place a test radio and tune how much sound the shop glass lets through (admin)',
}, function(src)
    if not isAdmin(src) then
        return TriggerClientEvent('ox_lib:notify', src, { description = 'You are not an audio admin', type = 'error' })
    end
    TriggerClientEvent('blue_audiotools:menu', src)
end)

---@param level integer? nil resets the unit to the built-in default
RegisterNetEvent('blue_audiotools:setLevel', function(unit, level)
    local src = source
    if not isAdmin(src) or not validUnit[unit] then return end
    if level ~= nil then
        level = math.tointeger(level) -- NUI sliders can arrive as 90.0
        if not level or level < 0 or level > 100 or level % 10 ~= 0 then return end
    end

    levels[unit] = level
    SaveResourceFile(cache.resource, FILE, json.encode(levels), -1)
    lib.logger(src, 'blue_audiotools:setLevel', ('%s glass blocks %s'):format(unit, level and level .. '%' or 'default'))
    TriggerClientEvent('blue_audiotools:levels', -1, levels)
end)
