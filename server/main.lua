local QBCore = exports['qb-core']:GetCoreObject()

-- Ensure resource name is correct
if GetCurrentResourceName() ~= 'slrn_rolldice' then
    print('^1ERROR: The resource needs to be named slrn_rolldice.^0')
    return
end

local config = require 'config.shared'

-- Handle slip generation callback
QBCore.Functions.CreateCallback('slrn_rolldice:server:getNote', function(source, cb, randomType, noteString)
    local metadata
    if randomType == 'roll' then
        metadata = {
            label = 'Dice Roll Slip',
            diceRoll = string.sub(noteString, 7)
        }
    elseif randomType == 'flip' then
        metadata = {
            label = 'Coin Flip Slip',
            diceRoll = string.sub(noteString, 7)
        }
    end
    local success = exports.ox_inventory:AddItem(source, 'stickynote', 1, metadata)
    cb(success)
end)

-- Handle random dice or coin flip events
RegisterServerEvent('slrn_rolldice:server:random', function(sourceId, dices, sides)
    local callerLoc = GetEntityCoords(GetPlayerPed(sourceId))
    local tabler = {}
    for i = 1, dices do
        tabler[i] = math.random(1, sides)
    end
    local event = sides == 2 and 'slrn_rolldice:client:flipCoin' or 'slrn_rolldice:client:rollDice'
    TriggerClientEvent(event, -1, sourceId, tabler, sides, callerLoc)
end)

-- Register commands if enabled in the config
if config.useCommand then
    QBCore.Commands.Add(config.rollCommand, 'Roll a dice, a single six-sided dice without options', {
        { name = 'sides', help = 'How many sides of dice - Max: ' .. config.maxSides, type = 'number', optional = true },
        { name = 'dice', help = 'How many dice to roll - Max: ' .. config.maxDices, type = 'number', optional = true },
    }, function(source, args)
        local dice = args.dice or 1
        local sides = args.sides or 6
        if (sides > 2 and sides <= config.maxSides) and (dice > 0 and dice <= config.maxDices) then
            TriggerEvent('slrn_rolldice:server:random', source, dice, sides)
        else
            TriggerClientEvent('QBCore:Notify', source, 'Invalid amount. Try again', 'error')
        end
    end)

    QBCore.Commands.Add(config.flipCommand, 'Flip a coin, one flip without options', {
        { name = 'flips', help = 'How many coin flips - Max: ' .. config.maxFlips, type = 'number', optional = true }
    }, function(source, args)
        local flips = args.flips or 1
        if flips > 0 and flips <= config.maxFlips then
            TriggerEvent('slrn_rolldice:server:random', source, flips, 2)
        else
            TriggerClientEvent('QBCore:Notify', source, 'Invalid amount. Try again', 'error')
        end
    end)

    QBCore.Commands.Add(config.slipsCommand, 'Toggle your slip recording', {}, function(source)
        TriggerClientEvent('slrn_rolldice:client:toggleSlips', source)
    end)
end
