--- @param blip_x number
--- @param blip_y number
--- @param blip_z number
--- @param sprite number
--- @param scale number
--- @param colour number
--- @param route boolean
--- @param blip_name string
function CreateBlip(blip_x, blip_y, blip_z, sprite, scale, colour, route, blip_name)
    local blip = AddBlipForCoord(blip_x, blip_y, blip_z)
    SetBlipSprite(blip, sprite)
    SetBlipScale(blip, scale)
    SetBlipColour(blip, colour)
    SetBlipRoute(blip, route)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(blip_name)
    EndTextCommandSetBlipName(blip)
    return blip
end

--- @param player number
--- @param message string
--- @param message_head string
function CreatePoliceReport(player, message, message_head)
    local player_coords = GetEntityCoords(player)
    local alert = {
        message = message,
        location = player_coords,
    }

    TriggerServerEvent('qs-smartphone:server:sendJobAlert', alert, "police") 
    TriggerServerEvent('qs-smartphone:server:AddNotifies', {
        head = message_head, 
        msg = message,
        app = 'business'
    })
end

local function PlayerIsInRange(player, coords)
    while true do
        Citizen.Wait(1500)
        local player_coords = GetEntityCoords(player)
        local distance = #(coords - player_coords)

        if distance < 200 then
            return true
        end
    end
end

local function TeleportPlayerToLocation(player_coords, player_heading)
    local playerPed = GetPlayerPed(-1)
    DoScreenFadeOut(Config.HeistInformation['BlackScreenTimer'])
    Citizen.Wait(Config.HeistInformation['BlackScreenTimer'])
    SetEntityHeading(playerPed, player_heading)
    SetEntityCoords(playerPed, player_coords.x, player_coords.y, player_coords.z, true, false, false, false)
    Citizen.Wait(Config.HeistInformation['BlackScreenTimer'])
    DoScreenFadeIn(Config.HeistInformation['BlackScreenTimer'])
end

CreateThread(function()
    AddDoorToSystem(`door_camera_building`, `v_ilev_rc_door2`, 1005.2922363281, -2998.2661132812, -47.496891021729, false, false, false)
    DoorSystemSetDoorState(`door_camera_building`, 1, false, true)

    local heist_npc = Config.HeistNPC

    RequestModel(GetHashKey(heist_npc.model))
    while not HasModelLoaded(GetHashKey(heist_npc.model)) do
        Wait(1)
    end

    npc = CreatePed(2, heist_npc.model, heist_npc.location.x, heist_npc.location.y, heist_npc.location.z - 1, heist_npc.heading,  false, true)

    SetPedFleeAttributes(npc, 0, 0)
    SetPedDropsWeaponsWhenDead(npc, false)
    SetPedDiesWhenInjured(npc, false)
    SetEntityInvincible(npc , true)
    FreezeEntityPosition(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)

    TaskStartScenarioInPlace(npc, 'WORLD_HUMAN_GUARD_STAND_FACILITY', 0, true)

    exports.ox_target:addBoxZone({
        coords = vec3(heist_npc.location.x, heist_npc.location.y, heist_npc.location.z),
        size = vec3(1, 1, 1),
        rotation = 360,
        debug = Config.Debugger,
        options = {
            {
                serverEvent = 'ac-yacht-heist:server:PassAllChecks',
                distance = Config.GeneralTargetDistance,
                icon = 'fa fa-ship',
                label = Config.HeistNPC.target_label,
            },
        }
    })
    
end)

RegisterNetEvent('ac-yacht-heist:client:OpenMenuHeist', function ()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "open",
    })
end)

RegisterNUICallback('ac-yacht-heist:client:CloseMenuHeist', function ()
    SetNuiFocus(false, false)
end)

RegisterNUICallback("ac-yacht-heist:client:StartHackingPreperation", function ()
    TriggerServerEvent("ac-yacht-heist:server:HeistStarted")
    SetNuiFocus(false,false)

    lib.notify({
        title = Config.HeistNPC.boss_title,
        description = Config.HeistNPC.introduction_round.message,
        duration = Config.HeistNPC.introduction_round.timer, 
        position = Config.Notifies.position,
        type = 'info'
    })

    local hack_building_entrance_blip = CreateBlip(Config.HeistLocations.HackerBuilding.entrance.coords.x, Config.HeistLocations.HackerBuilding.entrance.coords.y, Config.HeistLocations.HackerBuilding.entrance.coords.z, 472, 1.0, 59, true, "Camera's hacken")
    
    Camera_Building_Zone = exports.ox_target:addBoxZone({
        coords = vec3(Config.HeistLocations.HackerBuilding.entrance.coords.x, Config.HeistLocations.HackerBuilding.entrance.coords.y, Config.HeistLocations.HackerBuilding.entrance.coords.z),
        size = vec3(1, 1, 1),
        rotation = 360,
        debug = Config.Debugger,
        options = {
            {
                onSelect = function ()
                    TriggerEvent('ac-yacht-heist:client:EnterCameraBuilding', hack_building_entrance_blip)
                end,
                distance = Config.GeneralTargetDistance,
                icon = 'fa fa-door-open',
                label = Config.HeistLocations.HackerBuilding.entrance.target_label,
            },
        }
    })
end)

RegisterNetEvent("ac-yacht-heist:client:EnterCameraBuilding", function (entrance_blip)
    RemoveBlip(entrance_blip)
    local security_panel_coords = Config.HeistLocations.Security_panel_hack_scene.scene_location
    exports.ox_target:removeZone(Camera_Building_Zone)

    TeleportPlayerToLocation(vec3(1004.1747, -2997.6816, -47.6471), 82.7456)

    local security_panel = CreateObject(`hei_prop_hei_securitypanel`, security_panel_coords.x, security_panel_coords.y, security_panel_coords.z, true, true, false)
    SetEntityHeading(security_panel, Config.HeistLocations.Security_panel_hack_scene.scene_rotation.z)

    Hacking_Zone = exports.ox_target:addBoxZone({
        coords = vec3(security_panel_coords.x, security_panel_coords.y, security_panel_coords.z),
        size = vec3(1, 1, 1),
        rotation = 360,
        debug = Config.Debugger,
        options = {
            {
                event = 'ac-yacht-heist:client:StartHackCamera',
                distance = Config.GeneralTargetDistance,
                icon = 'fa fa-camera',
                label = Config.HeistLocations.Security_panel_hack_scene.target_label,
            },
        }
    })
end)

RegisterNetEvent("ac-yacht-heist:client:ExitCameraBuilding", function ()

    lib.notify({
        title = Config.HeistNPC.boss_title,
        description = Config.HeistLocations.Security_panel_hack_scene.notification.label,
        duration = Config.HeistLocations.Security_panel_hack_scene.notification.timer, 
        position = Config.Notifies.position,
        type = 'info'
    })

    Hacking_Zone = exports.ox_target:addBoxZone({
        coords = vec3(Config.HeistLocations.HackerBuilding.exit.coords.x, Config.HeistLocations.HackerBuilding.exit.coords.y, Config.HeistLocations.HackerBuilding.exit.coords.z),
        size = vec3(1, 1, 1),
        rotation = 360,
        debug = Config.Debugger,
        options = {
            {
                onSelect = function ()
                    TeleportPlayerToLocation(vec3(-297.6677, 6391.5552, 30.6124), 123.6319)
                    TriggerServerEvent("ac-yacht-heist:server:SpawnBoatToSteal")
                end,
                distance = Config.GeneralTargetDistance,
                icon = 'fa fa-door-open',
                label = Config.HeistLocations.HackerBuilding.exit.target_label,
            },
        }
    })
end)
