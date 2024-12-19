lib.locale()

local isAdminMenuVisible = false

RegisterNetEvent('d-adminpanel:openAdmin', function()
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'showAdminMenu'
    })
    TriggerServerEvent('admin:getPlayers')
    isAdminMenuVisible = true
end)

function hideAdminMenu()
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'hideAdminMenu'
    })
    isAdminMenuVisible = false
end


RegisterCommand("ban", function()
    SetNuiFocus(true, true)
    SendNUIMessage({ type = "openBanModal" })
end)

---------------- js

RegisterNetEvent('admin:sendPlayers')
AddEventHandler('admin:sendPlayers', function(players)
    SendNUIMessage({
        type = 'showPlayerList',
        players = players
    })
end)

RegisterNetEvent('d-adminpanel:receiveAllWarns')
AddEventHandler('d-adminpanel:receiveAllWarns', function(warns)
    SendNUIMessage({
        type = 'receiveAllWarns',
        warns = warns
    })
end)

RegisterNetEvent("d-adminpanel:addLog")
AddEventHandler("d-adminpanel:addLog", function(type, message)
    SendNUIMessage({
        action = "addLog",
        type = type,
        message = message
    })
end)


---------------- EVENTS

RegisterNUICallback('getAllWarns', function(_, cb)
    TriggerServerEvent('d-adminpanel:getAllWarns')
    AddEventHandler('d-adminpanel:receiveAllWarns', function(warns)
        cb(warns)
    end)
end)

RegisterNUICallback('removeWarn', function(data, cb)
    local warnId = data.warnId
    TriggerServerEvent('d-adminpanel:removeWarn', warnId)
    cb('ok')
end)

RegisterNUICallback("submitBan", function(data, cb)
    TriggerServerEvent("d-adminpanel:banPlayer", data)
    cb("ok")
end)

RegisterNUICallback("closeBanModal", function(_, cb)
    SetNuiFocus(false, false)
    cb("ok")
end)

---------------- NUI CALLBACKS

RegisterNUICallback('gotoPlayer', function(data, cb)
    local playerId = data.playerId
    local success = lib.callback.await('d-adminpanel:goto', false, playerId)
    if success then
        return true
    else
        return false
    end
end)

RegisterNUICallback('bringPlayer', function(data, cb)
    local playerId = data.playerId
    local success, errorMessage = lib.callback.await('d-adminpanel:bring', false, playerId)
    if success then
        return true
    else
       return false
    end
end)

RegisterNUICallback('spectatePlayer', function(data, cb)
    local playerId = data.playerId
    local adminId = source

    if playerId then
        TriggerServerEvent('d-adminpanel:spectatePlayer', adminId, playerId)
        cb({ success = true })
    else
        cb({ success = false, error = 'Player has not been found.' })
    end
end)

RegisterNUICallback('sendMessageToPlayer', function(data, cb)
    local playerId = data.playerId
    local message = data.message
    if playerId then
        TriggerEvent('chat:addMessage', {
            args = { "[ADMIN]", "Privatna poruka." ..message.. "" },
            color = { 255, 0, 0 }
        })
        cb({ success = true })
    else
        cb({ success = false, error = 'Player has not been found.' })
    end
end)

RegisterNUICallback('revivePlayer', function(data, cb)
    local playerId = tonumber(data.playerId)
    if playerId then
        TriggerServerEvent('d-adminpanel:revivePlayer', playerId)
        cb({ status = 'success', message = 'Revive request sent.' })
    else
        cb({ status = 'error', message = 'Player ID invalid.' })
    end
end)

RegisterNUICallback('healPlayer', function(data, cb)
    local playerId = data.playerId
    local maxHealth = GetEntityMaxHealth(playerPed)
    if playerId ~= 0 then
        SetEntityHealth(playerPed, 200)
        cb({ success = true })
    else
        cb({ success = false, error = 'Player has not been found.' })
    end
end)

RegisterNUICallback('slayPlayer', function(data, cb)
    local playerId = tonumber(data.playerId)
    if playerId then
        TriggerServerEvent('d-adminpanel:slayPlayer', playerId)
        cb({ status = 'success', message = 'slay request sent.' })
    else
        cb({ status = 'error', message = 'Player ID invalid.' })
    end
end)

---------------- EVENTS

RegisterNetEvent('d-adminpanel:client:goto')
AddEventHandler('d-adminpanel:client:goto', function(coords, targetPlayerId)
    local playerPed = PlayerPedId() 
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    while not HasCollisionLoadedAroundEntity(playerPed) do
        Citizen.Wait(0)
    end
    SetEntityCoords(playerPed, coords.x, coords.y, coords.z, false, false, false, true)
end)

RegisterNetEvent('d-adminpanel:revivePlayerClient')
AddEventHandler('d-adminpanel:revivePlayerClient', function()
    local playerPed = PlayerPedId()
    local maxHealth = GetEntityMaxHealth(playerPed)

    if IsEntityDead(playerPed) then
        NetworkResurrectLocalPlayer(GetEntityCoords(playerPed), GetEntityHeading(playerPed), true, false)
        ClearPedTasksImmediately(playerPed)
        SetEntityHealth(playerPed, 200)
        ClearPedBloodDamage(playerPed)
       SetEntityInvincible(playerPed, false)
      SetEntityHealth(playerPed, maxHealth)
        TriggerEvent('chat:addMessage', {
            args = { "[ADMIN]", "Oživljeni ste od strane admina." },
            color = { 0, 255, 0 }
        })
    end
end)


RegisterNetEvent('d-adminpanel:slayPlayerClient')
AddEventHandler('d-adminpanel:slayPlayerClient', function()
    local playerPed = PlayerPedId()
    SetEntityHealth(playerPed, 0)
    TriggerEvent('chat:addMessage', {
        args = { "[ADMIN]", "Admin te je ubio." },
        color = { 255, 0, 0 }
    })
end)

local isSpectating = false 

RegisterNetEvent('d-adminpanel:startSpectate')
AddEventHandler('d-adminpanel:startSpectate', function(targetId)
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
    local playerPed = PlayerPedId()

    NetworkSetInSpectatorMode(true, targetPed)
    isSpectating = true

    SetEntityInvincible(playerPed, true)
    SetEntityVisible(playerPed, false, false)
    SetEntityAlpha(playerPed, 0, false)

    lib.notify({
        title = locale('spectate_started'),
        description = string.format(locale('spectating_player'), GetPlayerName(GetPlayerFromServerId(targetId))),
        type = 'success'
    })


    Citizen.CreateThread(function()
        while isSpectating do
            Citizen.Wait(0)
            if IsControlJustReleased(0, 177) then 
                NetworkSetInSpectatorMode(false, targetPed)
                SetEntityInvincible(playerPed, false)
                SetEntityVisible(playerPed, true, true)
                ResetEntityAlpha(playerPed)
                isSpectating = false
            end
        end
    end)
end)

---------------- CLOSE MENU

RegisterNUICallback('closeMenu', function(data, cb)
    hideAdminMenu()
    cb('ok')
end)



-- Ovo je primer iz neke client.lua skripte
RegisterCommand("testlog", function()
    SendNUIMessage({
        action = "addLog",
        type = "info",
        message = "Test log poruka iz Lua koda"
    })
end)

