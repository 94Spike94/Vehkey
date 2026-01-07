ESX = exports['es_extended']:getSharedObject()

local waitingVehicle = nil

--------------------------------------------------
-- UTILS
--------------------------------------------------

local function RequestControl(entity)
    if not NetworkHasControlOfEntity(entity) then
        NetworkRequestControlOfEntity(entity)
        local timeout = 0
        while not NetworkHasControlOfEntity(entity) and timeout < 50 do
            Wait(10)
            timeout += 1
        end
    end
end

local function GetNearbyVehicle(radius)
    local ped = PlayerPedId()
    local pCoords = GetEntityCoords(ped)
    local vehicles = GetGamePool('CVehicle')

    local closest, closestDist = nil, radius + 1.0

    for _, veh in ipairs(vehicles) do
        local vCoords = GetEntityCoords(veh)
        local dist = #(pCoords - vCoords)
        if dist < closestDist then
            closest = veh
            closestDist = dist
        end
    end

    return closest
end

local function FlashIndicators(vehicle)
    RequestControl(vehicle)
    SetVehicleLights(vehicle, 2)
    SetVehicleIndicatorLights(vehicle, 0, true)
    SetVehicleIndicatorLights(vehicle, 1, true)
    Wait(450)
    SetVehicleIndicatorLights(vehicle, 0, false)
    SetVehicleIndicatorLights(vehicle, 1, false)
    SetVehicleLights(vehicle, 0)
end

local function PlayLockSound(vehicle, locked)
    RequestControl(vehicle)
    if locked then
        PlayVehicleDoorCloseSound(vehicle, 1)
    else
        PlayVehicleDoorOpenSound(vehicle, 0)
    end
end

local function PlayKeyFobAnim()
    local ped = PlayerPedId()
    local dict = 'anim@mp_player_intmenu@key_fob@'

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end

    TaskPlayAnim(
        ped,
        dict,
        'fob_click_fp',
        8.0,
        -8.0,
        1000,
        48,
        0,
        false,
        false,
        false
    )
end

--------------------------------------------------
-- SERVER RESPONSE
--------------------------------------------------

RegisterNetEvent('vehiclekeys:allowLock', function(allowed)
    if not waitingVehicle or waitingVehicle == 0 then return end

    local veh = waitingVehicle
    waitingVehicle = nil

    if not allowed then
        TriggerEvent('codem-notification:Create', 'Du hast keine Schlüssel für dieses Fahrzeug!', 'error', nil, 4000)
        return
    end

    RequestControl(veh)

    local lockState = GetVehicleDoorLockStatus(veh)
    local locking = (lockState == 1 or lockState == 0)

    PlayKeyFobAnim()

    if locking then
        SetVehicleDoorsLocked(veh, 2)
        if Config.UseSound then PlayLockSound(veh, true) end
        if Config.UseIndicators then FlashIndicators(veh) end
        TriggerEvent('codem-notification:Create', 'Fahrzeug abgeschlossen', 'success', nil, 4000)
    else
        SetVehicleDoorsLocked(veh, 1)
        if Config.UseSound then PlayLockSound(veh, false) end
        if Config.UseIndicators then FlashIndicators(veh) end
        TriggerEvent('codem-notification:Create', 'Fahrzeug aufgeschlossen', 'success', nil, 4000)
    end
end)

--------------------------------------------------
-- TOGGLE LOCK
--------------------------------------------------

local function ToggleVehicleLock()
    local ped = PlayerPedId()
    local vehicle

    if IsPedInAnyVehicle(ped, false) then
        vehicle = GetVehiclePedIsIn(ped, false)
    else
        vehicle = GetNearbyVehicle(6.0)
    end

    if not vehicle or vehicle == 0 then
        TriggerEvent('codem-notification:Create', 'Kein Fahrzeug in der Nähe!', 'error', nil, 4000)
        return
    end

    waitingVehicle = vehicle

    local plate = GetVehicleNumberPlateText(vehicle)
    local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)):lower()

    TriggerServerEvent('vehiclekeys:checkOwnedVehicle', plate, model)
end

--------------------------------------------------
-- KEYBIND (U)
--------------------------------------------------

CreateThread(function()
    while true do
        Wait(0)
        if IsControlJustReleased(0, 303) then -- U
            ToggleVehicleLock()
        end
    end
end)
