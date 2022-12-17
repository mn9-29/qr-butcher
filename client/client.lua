MenuData = {}

local QRCore = exports['qr-core']:GetCoreObject()


TriggerEvent("rdr_menu:getData", function(call)
    MenuData = call
end)

local sellPrompt
local active = false
local ButcherGroup = GetRandomIntInRange(0, 0xffffff)
local cooldownnasell = false
--print('BlueBerrygroup: ' .. ButcherGroup)

function ButcherSell()
    Citizen.CreateThread(function()
        local str = 'Sell'
        local wait = 0
        sellPrompt = Citizen.InvokeNative(0x04F97DE45A519419)
        PromptSetControlAction(sellPrompt, 0xC7B5340A)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(sellPrompt, str)
        PromptSetEnabled(sellPrompt, true)
        PromptSetVisible(sellPrompt, true)
        PromptSetHoldMode(sellPrompt, true)
        PromptSetGroup(sellPrompt, ButcherGroup)
        PromptRegisterEnd(sellPrompt)
    end)
end

Citizen.CreateThread(function()
    ButcherSell()
    while true do
        Wait(1)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local canWait = true
        for k, v in pairs(Config.Butchers) do
            local distance = Vdist(coords, v.x, v.y, v.z)
            if distance < 10 then
                canWait = false
            end
            if distance < 2 and not active then
                local ButcherGroupName = CreateVarString(10, 'LITERAL_STRING', "Butcher")
                PromptSetActiveGroupThisFrame(ButcherGroup, ButcherGroupName)
                if PromptHasHoldModeCompleted(sellPrompt) then
                    local carriage = Citizen.InvokeNative(0xD806CD2A4F2C2996, ped)
                    if carriage then
                        local quality = Citizen.InvokeNative(0x31FEF6A20F00B963, carriage)
                        local model = GetEntityModel(carriage)
                        Citizen.InvokeNative(0xC7F0B43DCDC57E3D, PlayerPedId(), carriage, GetEntityCoords(PlayerPedId()), 10.0, true)
                        Wait(1000)
                        DetachEntity(carriage, 1, 1)
                        SetEntityAsMissionEntity(carriage, true, true)
                        Wait(500)
                        DeleteEntity(carriage)
                        TriggerServerEvent("rdr_butcher:SellPelt", false, {model = model , quality = quality})
                    else
                        local id , vehicle = GetClostestCoachId()
                        if id then
                            --print(id)
                            TriggerServerEvent("rdr_coaches:GetPelts", id , vehicle)
                        end
                    end

                    Wait(1000)
                end
            end
        end
        if canWait then
            Wait(1000)
        end
    end
end)

Citizen.CreateThread(function()
    for k, v in pairs(Config.Butchers) do
        local blip = Citizen.InvokeNative(0x554d9d53f696d002, 1664425300,  v.x, v.y, v.z)
        SetBlipSprite(blip, 1369919445)
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, "Butcher")
    end
end)


RegisterNetEvent('rdr_butcher:OpenSellMenu')
AddEventHandler('rdr_butcher:OpenSellMenu', function(pelts , id , vehicle)
    while IsControlPressed(0, 0xC7B5340A) do Wait(100) end
	active = true
    MenuData.CloseAll()
    local elements = {}
    for k, v in pairs(pelts) do
		--print(json.encode(v))
        table.insert(elements, {
            label = GetModelName(v.model , v.quality),
            value = v,
            desc = "Press if you want sell this pelt"
        })
    end

    MenuData.Open('default', GetCurrentResourceName(), 'butcher_menu', {

        title = 'Butcher',

        subtext = 'Options',

        align = 'top-left',

        elements = elements

    }, function(data, menu)
	if cooldownnasell == false then
        cooldownnasell = true
        TriggerServerEvent("rdr_butcher:SellPelt", id, data.current.value, vehicle)
        exports.rdr_progressbar:DisplayProgressBar(2500, "Unloading from the wagon")
        exports.rdr_progressbar:DisplayProgressBar(2500, "Sale")
		cooldownnasell = false
	else 
		TriggerEvent('redem_roleplay:Tip', "Not so fast, wait a minute, I have to unload the cart!", 1000)
	end
    end, function(data, menu)
        menu.close()
        cooldownnasell = false
		active = false
    end)

end)

function StartCooldownNaSell()
	while cooldownnasell > 0 do
		Wait(1)
		cooldownnasell = cooldownnasell - 1
	end
end

function GetClostestCoachId()
    local playerped = PlayerPedId()
    local itemSet = CreateItemset(true)
    local size = Citizen.InvokeNative(0x59B57C4B06531E1E, GetEntityCoords(playerped), 20.0, itemSet, 2, Citizen.ResultAsInteger())
    if size > 0 then
        for index = 0, size - 1 do
            local entity = GetIndexedItemInItemset(index, itemSet)
            local model_hash = GetEntityModel(entity)
            if model_hash ==  GetHashKey("HUNTERCART01") or model_hash ==  GetHashKey("CART03")  or model_hash ==  GetHashKey("CART06") or model_hash ==  GetHashKey("CART08") then
                local coachid = DecorGetInt(entity, "coachid")
                if coachid > 0 then
				if IsItemsetValid(itemSet) then
					DestroyItemset(itemSet)
				end
                return coachid , entity
            end
            end
        end
    else
    end

    if IsItemsetValid(itemSet) then
        DestroyItemset(itemSet)
    end
end

function GetModelName(model , quality)
    for k,v in pairs(Config.Animal) do
       if v.model == model then
          return v.name
       end
	   if v.poor == quality then
          return v.name
       end
	   if v.good == quality then
          return v.name
       end
	   if v.perfect == quality then
          return v.name
       end
    end
    return "Unknown"
end
