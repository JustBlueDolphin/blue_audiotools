local shared = require 'config.shared'

-- Rockstar's emitter for script-placed boomboxes; there is only one, so one test radio at a time.
local EMITTER = 'SE_Script_Placed_Prop_Emitter_Boombox'
local RADIO_MODEL = `prop_boombox_01`

---@type table<string, integer>
local levels = {}
local radio, station

local function applyLevels(new)
    levels = new or {}
    for _, unit in ipairs(shared.units) do
        local glass = unit .. '_ps_glass'
        local level = levels[unit]
        if level then
            SetPortalSettingsOverride(glass, ('bp_ps_%03d'):format(level))
        else
            RemovePortalSettingsOverride(glass)
        end
    end
end

RegisterNetEvent('blue_audiotools:levels', applyLevels)

CreateThread(function()
    applyLevels(lib.callback.await('blue_audiotools:levels', false))
end)

local function removeRadio()
    if not radio then return end
    SetStaticEmitterEnabled(EMITTER, false)
    DeleteEntity(radio)
    radio, station = nil, nil
end

local function tune(name)
    SetEmitterRadioStation(EMITTER, name)
    SetStaticEmitterEnabled(EMITTER, true)
    station = name
end

local function placeRadio(name)
    removeRadio()
    lib.requestModel(RADIO_MODEL)
    local pos = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 0.8, 0.0)
    radio = CreateObject(RADIO_MODEL, pos.x, pos.y, pos.z, false, false, false)
    SetModelAsNoLongerNeeded(RADIO_MODEL)
    SetEntityHeading(radio, GetEntityHeading(cache.ped) + 180.0)
    PlaceObjectOnGroundProperly(radio)
    FreezeEntityPosition(radio, true)

    -- The emitter takes the radio's room; without this a prop placed inside can count as outside.
    local interior = GetInteriorFromEntity(cache.ped)
    if interior ~= 0 then ForceRoomForEntity(radio, interior, GetRoomKeyFromEntity(cache.ped)) end

    LinkStaticEmitterToEntity(EMITTER, radio)
    tune(name)
end

local function stations()
    local list = {}
    for i = 0, GetNumUnlockedRadioStations() - 1 do
        local name = GetRadioStationName(i)
        local label = GetLabelText(name)
        list[#list + 1] = { value = name, label = label ~= 'NULL' and label or name }
    end
    return list
end

local function pickStation(title)
    local input = lib.inputDialog(title, {
        { type = 'select', label = 'Station', options = stations(), default = station, required = true },
    })
    return input and input[1]
end

local function unitHere()
    local interior = GetInteriorFromEntity(cache.ped)
    if interior == 0 then return end
    local _, hash = GetInteriorLocationAndNamehash(interior)
    for _, unit in ipairs(shared.units) do
        if joaat(unit) == hash then return unit end
    end
end

local openMenu

local function editGlass(unit)
    local current = levels[unit] or shared.defaultBlock
    local input = lib.inputDialog(unit .. ' glass', {
        { type = 'slider', label = 'Sound the glass blocks (%)', min = 0, max = 100, step = 10, default = current },
        { type = 'checkbox', label = ('Reset to default (%d%%)'):format(shared.defaultBlock) },
    })
    if input then
        TriggerServerEvent('blue_audiotools:setLevel', unit, not input[2] and input[1] or nil)
        Wait(300) -- let the server's update arrive so the menu shows the new value
    end
    openMenu()
end

function openMenu()
    local here = unitHere()
    local options = {
        {
            title = radio and 'Move radio here' or 'Place radio here',
            description = 'A boombox playing a GTA station. Only you hear it.',
            icon = 'radio',
            onSelect = function()
                local name = pickStation('Radio station')
                if name then placeRadio(name) end
                openMenu()
            end,
        },
    }
    if radio then
        options[#options + 1] = {
            title = 'Change station',
            icon = 'music',
            onSelect = function()
                local name = pickStation('Radio station')
                if name and radio then tune(name) end
                openMenu()
            end,
        }
        options[#options + 1] = { title = 'Remove radio', icon = 'trash', onSelect = removeRadio }
    end

    local units = { here }          -- the unit you stand in first
    for _, unit in ipairs(shared.units) do
        if unit ~= here then units[#units + 1] = unit end
    end
    for _, unit in ipairs(units) do
        local level = levels[unit]
        options[#options + 1] = {
            title = ('%s glass blocks %d%%%s'):format(unit, level or shared.defaultBlock, level and '' or ' (default)'),
            description = (unit == here and 'You are in this unit. ' or '') .. 'Lower lets more sound through, both ways.',
            icon = unit == here and 'location-dot' or 'store',
            onSelect = function() editGlass(unit) end,
        }
    end

    lib.registerContext({ id = 'blue_audiotools', title = 'Sound check', options = options })
    lib.showContext('blue_audiotools')
end

RegisterNetEvent('blue_audiotools:menu', openMenu)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    removeRadio()
    applyLevels({})
end)
