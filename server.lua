lib.locale()



RegisterCommand("adminm", function(source)
    local isAdmin = exports['d-adminpanel']:IsPlayerAdminAndOnDuty(source)
    if isAdmin then
        TriggerClientEvent("d-adminpanel:openAdmin", source)
    else
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            title = locale('title'),
            description = locale('no_access')
        })
    end
end)

RegisterNetEvent('admin:getPlayers')
AddEventHandler('admin:getPlayers', function()
    local source = source
    local players = {}

    for _, playerId in ipairs(GetPlayers()) do
        local name = GetPlayerName(playerId)
        table.insert(players, { id = playerId, name = name })
    end

    TriggerClientEvent('admin:sendPlayers', source, players)
end)

---------------- DATABASE

-- BAN

RegisterServerEvent("d-adminpanel:banPlayer")
AddEventHandler("d-adminpanel:banPlayer", function(data)
    local src = source
    local isAdmin = exports['d-adminpanel']:IsPlayerAdminAndOnDuty(src)

    if not isAdmin then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            title = 'title',
            description = locale('no_access')
        })
        return
    end
    local targetId = tonumber(data.playerId)
    local reason = data.reason
    local duration = tonumber(data.duration)
    local bannedBy = GetPlayerName(src)
    local targetPlayer = ESX.GetPlayerFromId(targetId)

    if not targetPlayer then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            title = locale('title'),
            description = locale('no_player_found')
        })
        return
    end

    local targetIdentifier = targetPlayer.getIdentifier()
    local bannedName = GetPlayerName(targetId)

    local expireDate = os.date('%Y-%m-%d %H:%M:%S', os.time() + (duration * 86400))

    MySQL.Async.execute('INSERT INTO adminpanel_bans (license, banned, banned_by, reason, expire_date) VALUES (@license, @banned, @banned_by, @reason, @expire_date)', {
        ['@license'] = targetIdentifier,
        ['@banned'] = bannedName,
        ['@banned_by'] = bannedBy,
        ['@reason'] = reason,
        ['@expire_date'] = expireDate
    }, function(rowsAffected)
        if rowsAffected > 0 then
            DropPlayer(targetId, 'Banovan si. Razlog: ' .. reason .. '. Ban ističe: ' .. expireDate)
            TriggerClientEvent('ox_lib:notify', src, {
                type = 'success',
                title = locale('title'),
                description = locale('player_banned')
            })
        else
            TriggerClientEvent('ox_lib:notify', src, {
                type = 'error',
                title = 'title',
                description = locale('error')
            })
        end
    end)
end)

-- WARN

RegisterNetEvent('d-adminpanel:getAllWarns')
AddEventHandler('d-adminpanel:getAllWarns', function()
    local src = source
    local isAdmin = exports['d-adminpanel']:IsPlayerAdminAndOnDuty(src)

    if not isAdmin then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            title = 'title',
            description = locale('no_access')
        })
        return
    end

    MySQL.Async.fetchAll('SELECT * FROM warnings', {}, function(result)
        if result and #result > 0 then
            local warns = {}
            for _, warn in ipairs(result) do
                table.insert(warns, {
                    playerName = warn.warned,
                    warnedBy = warn.warned_by,
                    reason = warn.last_reason,
                    timestamp = warn.last_timestamp,
                    license = warn.license,
                    warnId = warn.id
                })
            end
            TriggerClientEvent('d-adminpanel:receiveAllWarns', src, warns)
        else
           return false
        end
    end)
end)

-- REMOVE WARN

RegisterNetEvent('d-adminpanel:removeWarn')
AddEventHandler('d-adminpanel:removeWarn', function(warnId)
    local src = source
    print('Primljen warnId:', warnId)
    if not warnId then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            title = locale('title'),
            description = locale('warn_id_invalid')
        })
        return
    end
    MySQL.Async.execute('DELETE FROM warnings WHERE id = @id', {
        ['@id'] = warnId
    }, function(rowsAffected)
        if rowsAffected > 0 then
            TriggerClientEvent('ox_lib:notify', src, {
                type = 'success',
                title = locale('title'),
                description = locale('warn_removed')
            })
            TriggerClientEvent('d-adminpanel:receiveAllWarns')        
        else
            TriggerClientEvent('ox_lib:notify', src, {
                type = 'error',
                title = 'title',
                description = locale('warn_id_invalid')
            })
        end
    end)
end)

---------------- EVENTS

-- goto

lib.callback.register('d-adminpanel:goto', function(source, playerId)
    local sourcePlayer = source
    local isAdmin, errorMessage = exports['d-adminpanel']:IsPlayerAdminAndOnDuty(source)

    if isAdmin then
        print("Admin status confirmed for player: " .. sourcePlayer)
        local adminName = GetPlayerName(sourcePlayer)
        local playerName = GetPlayerName(playerId)
        local targetCoords = GetEntityCoords(GetPlayerPed(playerId))
        local xPlayer = ESX.GetPlayerFromId(source)
        local adminGroup = xPlayer.getGroup(src)
        print("Teleporting to coordinates: " .. targetCoords.x .. ", " .. targetCoords.y .. ", " .. targetCoords.z)
        TriggerClientEvent('d-adminpanel:client:goto', sourcePlayer, targetCoords)
        TriggerClientEvent('ox_lib:notify', source, {
            title = locale('title'),
            description = locale('teleported_to_player', playerName),
            type = "success"
        })
        
        TriggerClientEvent('ox_lib:notify', playerId, {
            title = locale('title'),
            description = locale('admin_teleported_to_you', adminName),
            type = "success"
        })
        local message = string.format("%s (%s) teleported to %s (ID: %d).", adminGroup, adminName, playerName, playerId)
            TriggerClientEvent("d-adminpanel:addLog", -1, "ADMIN", message)
        return true
    else
        print("Admin status failed for player: " .. sourcePlayer .. " - ")
        TriggerClientEvent('ox_lib:notify', sourcePlayer, {
            title = locale('title'),
            description = locale('error'),
            type = "error"
        })

        return false, 'neuspjesno'
    end
end)

-- bring

lib.callback.register('d-adminpanel:bring', function(sourcePlayer, targetPlayerId)
    local isAdmin, errorMessage = exports['d-adminpanel']:IsPlayerAdminAndOnDuty(sourcePlayer)
    local xPlayer = ESX.GetPlayerFromId(sourcePlayer)
    local targetPlayer = tonumber(targetPlayerId)
    local adminGroup = xPlayer.getGroup(sourcePlayer)
    local adminName = GetPlayerName(sourcePlayer) 
    local targetName = GetPlayerName(targetPlayer)
    if isAdmin then
        local adminCoords = GetEntityCoords(GetPlayerPed(sourcePlayer))
        TriggerClientEvent('d-adminpanel:client:goto', targetPlayerId, adminCoords)
        TriggerClientEvent('ox_lib:notify', sourcePlayer, {
            title = locale('title'),
            description = string.format(locale('player_brought'), GetPlayerName(targetPlayerId)),
            type = "success"
        })
        local message = string.format("%s (%s) has brought %s (ID: %d", adminGroup, adminName, targetName, targetPlayerId)
            TriggerClientEvent("d-adminpanel:addLog", -1, "ADMIN", message)

        TriggerClientEvent('ox_lib:notify', targetPlayerId, {
            title = locale('title'),
            description = string.format(locale('player_brought_you'), GetPlayerName(sourcePlayer)),
            type = "inform"
        })
       
        return true
    else
        return false, errorMessage
    end
end)

-- revive

RegisterNetEvent('d-adminpanel:revivePlayer')
AddEventHandler('d-adminpanel:revivePlayer', function(targetId)
    local src = source 
    local xPlayer = ESX.GetPlayerFromId(source)
    local targetPlayer = tonumber(targetId)
    local adminGroup = xPlayer.getGroup(src)
    local adminName = GetPlayerName(src) 
    local targetName = GetPlayerName(targetPlayer)

    if GetPlayerName(targetId) then
        TriggerClientEvent('d-adminpanel:revivePlayerClient', targetId)
        local message = string.format("%s (%s) revived player %s (ID: %d).", adminGroup, adminName, targetName, targetId)
        TriggerClientEvent("d-adminpanel:addLog", -1, "ADMIN", message)
    else
        TriggerClientEvent('ox_lib:notify', sourceId, {
            title = locale('title'),
            description = locale('no_player_found'),
            type = 'error'
        })
    end
end)

-- slay 

RegisterNetEvent('d-adminpanel:slayPlayer')
AddEventHandler('d-adminpanel:slayPlayer', function(targetId, args)
    local src = source 
    local xPlayer = ESX.GetPlayerFromId(source)
    local targetPlayer = tonumber(targetId)
    local adminGroup = xPlayer.getGroup(src)
    local adminName = GetPlayerName(src) 
    local targetName = GetPlayerName(targetPlayer)

    if targetName then
        local message = string.format("%s (%s) killed %s (ID: %d).", adminGroup, adminName, targetName, targetId)
        TriggerClientEvent("d-adminpanel:addLog", -1, "PLAYER_DEATH", message)
        TriggerClientEvent('d-adminpanel:slayPlayerClient', targetPlayer)
    else
        TriggerClientEvent('ox_lib:notify', sourceId, {
            title = locale('title'),
            description = locale('no_player_found'),
            type = 'error'
        })
    end
end)


RegisterServerEvent('d-adminpanel:spectatePlayer')
AddEventHandler('d-adminpanel:spectatePlayer', function(playerId)
    local sourceId = source
    if playerId then
        TriggerClientEvent('d-adminpanel:startSpectate', sourceId, playerId)
    else
        TriggerClientEvent('ox_lib:notify', sourceId, {
            title = locale('title'),
            description = locale('no_player_found'),
            type = 'error'
        })
    end
end)



RegisterCommand("clear", function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    TriggerClientEvent("chat:clear", source)
end, false)