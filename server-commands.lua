RegisterCommand(Config.WarnCommand, function(source, args, rawCommand)
    local isAdmin = exports['d-adminpanel']:IsPlayerAdminAndOnDuty(source)

    if isAdmin then
        local xPlayer = ESX.GetPlayerFromId(source)
        local targetId = tonumber(args[1])
        local reason = table.concat(args, " ", 2)

        local targetPlayer = ESX.GetPlayerFromId(targetId)
        if not targetPlayer then
            lib.notify({
                title = locale('title'),
                description = locale('player_not_found', { id = targetId }),
                type = 'error'
            })
            return
        end

        local targetIdentifier = targetPlayer.getIdentifier()
        local warnedByName = GetPlayerName(source)
        local warnedName = GetPlayerName(targetId)
        MySQL.Async.execute('INSERT INTO warnings (license, warned, warned_by, last_reason, last_admin_id, last_timestamp) VALUES (@license, @warned, @warned_by, @reason, @admin_id, NOW())', {
            ['@license'] = targetIdentifier,
            ['@warned'] = warnedName,
            ['@warned_by'] = warnedByName,
            ['@reason'] = reason,
            ['@admin_id'] = xPlayer.identifier
        }, function(affectedRows)
            if affectedRows > 0 then
                TriggerClientEvent('chat:addMessage', source, { args = { '^2SYSTEM', 'Player ' .. warnedName .. ' has been warned for: ' .. reason } })
                TriggerClientEvent('chat:addMessage', targetId, { args = { '^1SYSTEM', 'You have been warned for: ' .. reason } })
            else
                TriggerClientEvent('ox_lib:notify', source, {
                    title = locale('title'),
                    description = locale('error'),
                    type = 'error'
                })
            end
        end)
    else
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            title = locale('title'),
            description = locale('no_access')
        })
    end
end)