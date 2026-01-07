ESX = exports['es_extended']:getSharedObject()

RegisterNetEvent('vehiclekeys:checkOwnedVehicle', function(plate, model)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local identifier = xPlayer.identifier
    local job = xPlayer.job.name

    -- Kennzeichen bereinigen (SEHR WICHTIG)
    local cleanPlate = plate:gsub("%s+", "")

    ----------------------------------------------------------------
    -- 1️⃣ JOBFAHRZEUG-PRÜFUNG
    ----------------------------------------------------------------
    if Config.JobVehicle[job] then
        for _, jobVeh in pairs(Config.JobVehicle[job]) do
            if jobVeh:lower() == model then
                TriggerClientEvent('vehiclekeys:allowLock', src, true)
                return
            end
        end
    end

    ----------------------------------------------------------------
    -- 2️⃣ PRIVATES FAHRZEUG (owned_vehicles)
    ----------------------------------------------------------------
    exports.oxmysql:query(
        'SELECT plate FROM owned_vehicles WHERE owner = ? AND REPLACE(plate, " ", "") = ?',
        { identifier, cleanPlate },
        function(result)
            if result and result[1] then
                TriggerClientEvent('vehiclekeys:allowLock', src, true)
            else
                TriggerClientEvent('vehiclekeys:allowLock', src, false)
            end
        end
    )
end)
