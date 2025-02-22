
--Lock Pick
exports('lockpick', function(event, item, inventory, slot, data)
    if event == 'usingItem' then
        local player = GetPlayerPed(inventory.id)
        local coords = GetEntityCoords(player)
        local vehicles = lib.getClosestVehicle(coords, 5.0, true)
        local vehicle = Vehicles.GetVehicle(vehicles)
        local doorStatus = GetVehicleDoorLockStatus(vehicles)
        local Noty = function()
            Notification(source, {
                title = 'Vehiculo',
                description = (doorStatus == 2 and locale('open_door') or locale('close_door')),
                icon = (doorStatus == 2 and 'lock-open' or 'lock'),
                iconColor = (doorStatus == 2 and '#77e362' or '#e36462'),
            })
        end
        local skillCheck = lib.callback.await('mVehicle:PlayerItems', inventory.id, 'lockpick',
            NetworkGetNetworkIdFromEntity(vehicles))
        if skillCheck then
            if doorStatus == 2 then
                if vehicle then
                    vehicle.SetMetadata('DoorStatus', 0)
                end
                SetVehicleDoorsLocked(vehicles, 0)
                Noty()
                return false
            else
                if vehicle then
                    vehicle.SetMetadata('DoorStatus', 2)
                end
                SetVehicleDoorsLocked(vehicles, 2)
                Noty()
                return false
            end
        else

        end
        return false
    end
end)

--HotWire
exports('hotwire', function(event, item, inventory, slot, data)
    if event == 'usingItem' then
        lib.callback.await('mVehicle:PlayerItems', inventory.id, 'hotwire')
        return false
    end
end)



-- Fake Plate
exports('fakeplate', function(event, item, inventory, slot, data)
    if event == 'usingItem' then
        local player = GetPlayerPed(inventory.id)
        local coords = GetEntityCoords(player)
        local identifier = Identifier(inventory.id)
        local vehicles = lib.getClosestVehicle(coords, 5.0, true)
        local vehicle = Vehicles.GetVehicle(vehicles)
        local itemSlot = exports.ox_inventory:GetSlot(inventory.id, slot)
        if vehicle then
            if vehicle.owner == identifier then
                local newSpz = '        '
                local vehicleRealPlate = GetVehicleNumberPlateText(vehicles)
                if vehicleRealPlate ~= newSpz then
                    local anim = lib.callback.await('mVehicle:PlayerItems', inventory.id, 'changeplate')
                    if anim then
                        if not Entity(vehicles).state.realplate then
                            Entity(vehicles).state:set('realplate', vehicleRealPlate, true)
                        end

                        Entity(vehicles).state:set('fakeplate', newSpz, true)
                        SetVehicleNumberPlateText(vehicles, newSpz)
                        
                        if itemSlot.metadata and itemSlot.metadata.usesRemaining then
                            itemSlot.metadata.usesRemaining = itemSlot.metadata.usesRemaining - 1
                            if itemSlot.metadata.usesRemaining == 0 then
                                exports.ox_inventory:RemoveItem(inventory.id, 'fakeplate', 1, nil, slot)
                            else
                                exports.ox_inventory:SetMetadata(inventory.id, slot, {usesRemaining = itemSlot.metadata.usesRemaining, description = 'Specialní šroubovák se kterým můžete sundat spz. Zbývá '..itemSlot.metadata.usesRemaining..' použití'})
                            end
                        else
                            exports.ox_inventory:SetMetadata(inventory.id, slot, {usesRemaining = 9, description = 'Specialní šroubovák se kterým můžete sundat spz. Zbývá 9 použití'})
                        end

                        exports.ox_inventory:AddItem(inventory.id, 'spz', 1, {description = vehicleRealPlate})
                    end
                else
                    Notification(inventory.id, {
                        title = locale('fakeplate1'),
                        description = 'Toto vozidlo již má bílou SPZ',
                        icon = 'user',
                    })
                end
            else
                Notification(inventory.id, {
                    title = locale('fakeplate1'),
                    description = locale('fakeplate2'),
                    icon = 'user',
                })
            end
        else
            Notification(inventory.id, {
                title = locale('fakeplate1'),
                description = 'Nestojíš u žádného vozidla',
                icon = 'user',
            })
        end

        return
    end
end)

exports('plate', function(event, item, inventory, slot, data)
    if event == 'usingItem' then
        local player = GetPlayerPed(inventory.id)
        local coords = GetEntityCoords(player)
        local identifier = Identifier(inventory.id)
        local vehicles = lib.getClosestVehicle(coords, 5.0, true)
        local vehicle = Vehicles.GetVehicle(vehicles)
        local itemSlot = exports.ox_inventory:GetSlot(inventory.id, slot)
        if vehicle then
            if vehicle.owner == identifier then
                local newSpz = itemSlot.metadata.description
                
                local vehicleFakePlate = GetVehicleNumberPlateText(vehicles)
                if vehicleFakePlate ~= newSpz then
                    local anim = lib.callback.await('mVehicle:PlayerItems', inventory.id, 'changeplate')
                    if anim then

                        if not Entity(vehicles).state.realplate then
                            Entity(vehicles).state:set('realplate', vehicleFakePlate, true)
                        end

                        --Entity(vehicles).state:set('fakeplate', nil, true)
                        SetVehicleNumberPlateText(vehicles, newSpz)
                        
                        exports.ox_inventory:RemoveItem(inventory.id, 'spz', 1, nil, slot)
                        --exports.ox_inventory:AddItem(inventory.id, 'fakeplate', 1)
                    end
                else
                    Notification(inventory.id, {
                        title = locale('fakeplate1'),
                        description = 'Toto vozidlo již má reálnou SPZ',
                        icon = 'user',
                    })
                end
            else
                Notification(inventory.id, {
                    title = locale('fakeplate1'),
                    description = locale('fakeplate2'),
                    icon = 'user',
                })
            end
        else
            Notification(inventory.id, {
                title = locale('fakeplate1'),
                description = 'Nestojíš u žádného vozidla',
                icon = 'user',
            })
        end

        return
    end
end)

if Config.Inventory == 'ox' and GetResourceState('ox_inventory') == 'started' then
    exports.ox_inventory:registerHook('createItem', function(payload)
        local plate = Vehicles.GeneratePlate()
        local metadata = payload.metadata
        metadata.description = plate
        metadata.fakeplate = plate
        return metadata
    end, {
        itemFilter = {
            [Config.FakePlateItem.item] = true
        }
    })
end
