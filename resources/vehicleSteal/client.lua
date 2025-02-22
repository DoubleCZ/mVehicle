local animDictLockPick = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
local animLockPick = "machinic_loop_mechandplayer"
local animDicHotWire = "veh@std@ds@base"
local animHotWire = "hotwire"

lib.callback.register('cat_lockpick:startLockpiking', function(vehicle)
    if Config.EnableAlarm == true then
        SetVehicleAlarm(vehicle, true)
        SetVehicleAlarmTimeLeft(vehicle, Config.AlarmTimer * 15000)
        StartVehicleAlarm(vehicle)
    end

    -- Zavolání minihry pro lockpick z t3_lockpick
    local success = exports["t3_lockpick"]:startLockpick("lockpick", nil, nil)

    -- Před spuštěním minihry pro lockpick zkontrolujeme náhodnou šanci na dispatch
    local chance = math.random(1, 100)  -- Generování náhodného čísla mezi 1 a 100
    local dispatchChance = 20  -- 20% šance na odeslání dispatch zprávy při začátku lockpicku

    if chance <= dispatchChance then
        -- Odeslání dispatch zprávy při začátku lockpicku
        TriggerServerEvent('rcore_dispatch:addCall', {
            job = 'police',  -- Příklad: Policejní dispatch
            message = 'Podezřelé lockpickování auta na lokaci!',
            coords = GetEntityCoords(vehicle),
            priority = 2,  -- Můžete změnit prioritu dle potřeby
        })
        print("Dispatch call sent at the start of lockpicking!")
    else
        print("No dispatch call at the start of lockpicking.")
    end

    -- Pokud minihra selže, pošleme na server požadavek na odstranění lockpicku
    if not success then
        TriggerServerEvent('cat_lockpick:removeLockpick', 'lockpick', 1)
    end

    -- Pokud je úspěch při lockpicku, odešleme obrázek krádeže auta a další detaily
    if success then
        -- Po úspěšném lockpicku poslat obrázek a alert pro krádež auta
        exports['screenshot-basic']:requestScreenshotUpload(CL_CONFIG.CarRobberyPictureWebhook, "files[]", function(val)
            local image = json.decode(val)
            local data = {
                code = '10-64 - Krádež auta',  -- Kód pro krádež auta
                default_priority = 'low',  -- Priorita alertu
                coords = GetEntityCoords(vehicle),  -- Souřadnice krádeže
                job = 'police',  -- Job, který bude přijímat alert
                text = 'Podezřelá aktivita při krádeži auta.',  -- Text alertu
                type = 'car_robbery',  -- Typ alertu
                blip_time = 5,  -- Doba, po kterou bude blip viditelný
                image = image.attachments[1].proxy_url,  -- URL obrázku
                --custom_sound = 'url_to_sound.mp3',  -- Zvuk pro alert (volitelné)
                blip = {  -- Nastavení blipu
                    sprite = 54,  -- Sprite pro blip
                    colour = 3,  -- Barva blipu
                    scale = 0.7,  -- Měřítko blipu
                    text = '10-64 | Krádež auta',  -- Text na blipu
                    flashes = false,  -- Pokud má blip blikat
                    radius = 3,  -- Radius pro blip (volitelné)
                }
            }
            TriggerServerEvent('rcore_dispatch:server:sendAlert', data)  -- Odeslání alertu
        end)
        print("Car robbery alert sent with screenshot!")
    end

    -- Pokud lockpick uspěje, odemkneme vozidlo a umožníme vstup
    if success then
        SetVehicleDoorsLocked(vehicle, 1)
        SetVehicleDoorsLockedForAllPlayers(vehicle, false)
        SetVehicleNeedsToBeHotwired(vehicle, true)
        IsVehicleNeedsToBeHotwired(vehicle)
        TaskEnterVehicle(PlayerPedId(), vehicle, 5.0, -1, 1.0, 1, 0)
    end

    return success
end)



-- Callback pro získání vozidla pro hotwire (používáno, když hráč sedí v autě)
lib.callback.register('rep-enginewire:getClosestVehicle', function()
    local ped = cache.ped
    local vehicle = GetVehiclePedIsIn(ped, false) -- Získání vozidla, ve kterém hráč sedí

    if vehicle and vehicle ~= 0 then -- Pokud vozidlo existuje a hráč v něm sedí
        local lock = GetVehicleDoorLockStatus(vehicle)
        return vehicle, lock
    else
        return nil
    end
end)

-- Callback pro spuštění minihry pro hotwire (spustí "hotwire" minihru)
lib.callback.register('rep-enginewire:startHotwireMinigame', function()
    -- Zavolání minihry pro hotwire
    local success = exports["rep-enginewire"]:MiniGame()

    -- Vrátit výsledek minihry
    return success
end)
lib.callback.register('mVehicle:PlayerItems', function(action, entity)
    local ped = cache.ped
    if action == 'changeplate' then
        if lib.progressBar({
                duration = Config.FakePlateItem.ChangePlateTime,
                label = locale('fakeplate4'),
                useWhileDead = false,
                canCancel = true,
                disable = {
                    car = true,
                    move = true,
                },
                anim = {
                    dict = animDictLockPick,
                    clip = animLockPick,
                    flag = 1,
                },
                prop = {
                    model = 'p_num_plate_01',
                    pos = vec3(0.0, 0.2, 0.1),
                    rot = vec3(100, 100.0, 0.0)
                },
            }) then
            return true
        else
            return false
        end
    elseif action == 'lockpick' then
        if not NetworkDoesNetworkIdExist(entity) then return false end
        local vehicle = NetToVeh(entity)
        local pedInVehicle = IsPedInVehicle(ped, vehicle)
        if pedInVehicle then return end

        -- Spuštění alarmu
        SetVehicleAlarm(vehicle, true)
        SetVehicleAlarmTimeLeft(vehicle, 10000) -- 10 sekund (v milisekundách)
        StartVehicleAlarm(vehicle)

        lib.requestAnimDict(animDictLockPick)
        TaskPlayAnim(ped, animDictLockPick, animLockPick, 8.0, 8.0, -1, 48, 1, false, false, false)

        -- Zavolání minihry pro lockpick
        local success = exports["t3_lockpick"]:startLockpick("lockpick", nil, nil)

        if success then
            SetVehicleDoorsLocked(vehicle, 1)
            SetVehicleDoorsLockedForAllPlayers(vehicle, false)
            SetVehicleNeedsToBeHotwired(vehicle, true)
            IsVehicleNeedsToBeHotwired(vehicle)
            TaskEnterVehicle(PlayerPedId(), vehicle, 5.0, -1, 1.0, 1, 0)
        end

        ClearPedTasks(ped)
        return success
    elseif action == 'hotwire' then
        local vehicle = GetVehiclePedIsIn(ped, false)
        if not vehicle then return false end
        local pedInVehicle = IsPedInVehicle(ped, vehicle, -1)
        if not pedInVehicle then return false end

        -- Spuštění animace pro hotwire
        lib.requestAnimDict(animDicHotWire)
        TaskPlayAnim(ped, animDicHotWire, animHotWire, 8.0, 8.0, -1, 48, 1, false, false, false)

        -- Zavolání minihry z rep-enginewire
        local success = exports["rep-enginewire"]:MiniGame()

        -- Výsledek minihry (true/false)
        if success then
            -- Po úspěšném dokončení minihry nastavit motor na zapnutý
            SetVehicleEngineOn(vehicle, true, true, true)
            print("Hotwire successful!")
        else
            -- Pokud minihra selhala
            print("Hotwire failed!")
        end

        ClearPedTasks(ped)
        return success
    end
end)

