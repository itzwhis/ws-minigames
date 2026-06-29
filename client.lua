
local RSGCore = exports['rsg-core']:GetCoreObject()
local PlayerJob = {}
local isTaming = false
local successCount = 0
local currentHorse = nil

-- Fetch job data on player load
RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    PlayerJob = RSGCore.Functions.GetPlayerData().job
end)

-- Update job data on job change
RegisterNetEvent('RSGCore:Client:OnJobUpdate', function(job)
    PlayerJob = job
end)

-- Notification wrapper using ox_lib
local function SendNotify(title, description, type)
    lib.notify({
        title = title,
        description = description,
        type = type or 'inform',
        position = 'top-right',
        duration = 4000
    })
end

-- Start the taming minigame
function StartTamingMiniGame()
    isTaming = true
    successCount = 0
    
    -- Open NUI and focus keyboard
    SetNuiFocus(true, false) 
    SendNUIMessage({
        action = "start_minigame",
        score = successCount
    })
    
    -- If player is on a horse, trigger wild agitation movement
    if currentHorse and currentHorse ~= 0 then
        TaskVehicleTempAction(PlayerPedId(), currentHorse, 9, 10000) 
    end
end

-- Stop the minigame and close UI
function StopMiniGame()
    isTaming = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "stop_minigame" })
end

-- Callback when player inputs the correct number
RegisterNUICallback('success', function(data, cb)
    successCount = successCount + 1
    if successCount >= 6 then
        StopMiniGame()
        SendNotify('Taming System', 'Excellent! You successfully calmed and tamed the horse.', 'success')
        
        if currentHorse and currentHorse ~= 0 then
            ClearPedTasks(currentHorse)
            local horseModel = GetEntityModel(currentHorse)
            TriggerServerEvent('rsg-horsetrainer:server:tameSuccess', horseModel)
        end
    else
        SendNUIMessage({
            action = "update_score",
            score = successCount
        })
    end
    cb('ok')
end)

-- Callback when player misses or runs out of time
RegisterNUICallback('failed', function(data, cb)
    StopMiniGame()
    local playerPed = PlayerPedId()
    
    SendNotify('Taming System', 'You lost control and fell off the horse!', 'error')
    
    -- Ragdoll the player onto the ground
    SetPedToRagdoll(playerPed, 3000, 3000, 0, 0, 0, 0)
    
    -- Make horse flee if it exists
    if currentHorse and currentHorse ~= 0 then
        TaskSmartFleePed(currentHorse, playerPed, 100.0, -1, false, false)
    end
    cb('ok')
end)

-- Test Command /wildgames (Works on foot or mounted)
RegisterCommand('wildgames', function()
    local playerPed = PlayerPedId()
    
    -- Job check restriction
    if not PlayerJob or PlayerJob.name ~= "valhorsetrainer" then
        SendNotify('Access Denied', 'This command is restricted to Horse Trainers (valhorsetrainer)!', 'error')
        return
    end

    if isTaming then
        SendNotify('Warning', 'The minigame is already running!', 'warning')
        return
    end

    -- Check if mounted
    if IsPedInAnyVehicle(playerPed, false) then
        currentHorse = GetVehiclePedIsIn(playerPed, false)
        SendNotify('Test Started', 'Starting taming minigame test on horse...', 'info')
        StartTamingMiniGame()
    else
        -- Fallback test mode (on foot)
        currentHorse = 0
        SendNotify('Test Mode', 'Starting minigame in on-foot test mode...', 'info')
        StartTamingMiniGame()
    end
end, false)
