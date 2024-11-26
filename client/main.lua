local QBCore = exports['qb-core']:GetCoreObject()

local config = require 'config.shared'
local recordSlips = true

local function distCheck(location)
    local coords = GetEntityCoords(PlayerPedId(), false)
    local dist = #(location - coords)

    if dist > config.maxDistance then
        return false
    end
    return true
end

local function createFlipString(flipTable)
    local text = 'Flip: '
    for k, roll in pairs(flipTable) do
        local side = roll == 1 and 'Heads' or 'Tails'
        if k == 1 then
            text = text .. side
        else
            text = text .. ' | ' .. side
        end
    end

    return text
end

local function createRollString(rollTable, sides)
    local text = 'Roll: '
    local total = 0

    for k, roll in pairs(rollTable) do
        total = total + roll
        if k == 1 then
            text = text .. roll .. '/' .. sides
        else
            text = text .. ' | ' .. roll .. '/' .. sides
        end
    end

    text = text .. ' | (Total: '..total..')'
    return text
end

local function requestAnimDictLoad(animDict)
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(0)
    end
end

local function diceRollAnimation(animDict)
    TaskPlayAnim(PlayerPedId(), animDict, 'wank', 8.0, -8.0, -1, 49, 0, false, false, false)
    Wait(2400)
    ClearPedTasks(PlayerPedId())
end

local function flipCoinAnimation(animDict)
    TaskPlayAnim(PlayerPedId(), animDict, 'coin_roll_and_toss', 8.0, -8.0, -1, 49, 0, false, false, false)
    Wait(4800)
    ClearPedTasks(PlayerPedId())
end

local function showRoll(text, sourceId)
    local currentCoords = GetOffsetFromEntityInWorldCoords(GetPlayerPed(GetPlayerFromServerId(sourceId)), 0.0, 1.5, -0.7)
    CreateThread(function()
        local displayTime = config.showTime * 1000 + GetGameTimer()
        while displayTime > GetGameTimer() do
            DrawText3D(currentCoords, text)
            Wait(0)
        end
    end)
end

local function showFlip(text, sourceId)
    CreateThread(function()
        local displayTime = config.showTime * 1000 + GetGameTimer()
        while displayTime > GetGameTimer() do
            local currentCoords = GetOffsetFromEntityInWorldCoords(GetPlayerPed(GetPlayerFromServerId(sourceId)), 0.0, 0.5, 0.4)
            DrawText3D(currentCoords, text)
            Wait(0)
        end
    end)
end

local function DrawText3D(coords, text)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = #(coords - vector3(px, py, pz))

    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

RegisterNetEvent('slrn_rolldice:client:rollDice', function(sourceId, rollTable, sides, location)
    if not distCheck(location) then return end
    local rollString = createRollString(rollTable, sides)
    SetTimeout(2200, function()
        showRoll(rollString, sourceId)
    end)
    if GetPlayerServerId(PlayerId()) == sourceId then
        local animDict = 'anim@mp_player_intcelebrationmale@wank'
        requestAnimDictLoad(animDict)
        diceRollAnimation(animDict)
        if config.giveCoinSlip and recordSlips then TriggerServerEvent('slrn_rolldice:server:getNote', 'roll', rollString) end
    end
end)

RegisterNetEvent('slrn_rolldice:client:flipCoin', function(sourceId, flipTable, _, location)
    if not distCheck(location) then return end
    local flipString = createFlipString(flipTable)
    SetTimeout(3050, function()
        showFlip(flipString, sourceId)
    end)
    if GetPlayerServerId(PlayerId()) == sourceId then
        local animDict = 'anim@mp_player_intcelebrationmale@coin_roll_and_toss'
        requestAnimDictLoad(animDict)
        flipCoinAnimation(animDict)
        if config.giveFlipSlip and recordSlips then TriggerServerEvent('slrn_rolldice:server:getNote', 'flip', flipString) end
    end
end)

RegisterNetEvent('slrn_rolldice:client:toggleSlips', function()
    recordSlips = not recordSlips
    local notify = recordSlips and 'You are saving your slips' or 'You are not saving your slips'
    QBCore.Functions.Notify(notify)
end)

-- Metadata registration for ox_inventory compatibility
exports.ox_inventory:displayMetadata({
    diceRoll = 'Roll',
    coinFlip = 'Flip'
})
