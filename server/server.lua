local boost_id = 1
local QRCore = exports['qr-core']:GetCoreObject()

RegisterServerEvent("rdr_butcher:SellPelt")
AddEventHandler("rdr_butcher:SellPelt", function(id, data , vehicle)
    local src = source
    local model = data.model
    local quality = data.quality
    local Player = QRCore.Functions.GetPlayer(src)
    local price = GetPrice(model, quality)
    print(model, quality)
	local itemas = GetItemas(model)
    if price then
        Player.Functions.AddMoney("cash", price, "butcher")
    else
        TriggerClientEvent('QRCore:Notify', src, Lang:t("You Don't have money", 'error'))
    end
	if itemas then
		local RandomNumber = math.random(1, 2)
		if not Player.Functions.AddItem(itemas, RandomNumber, false, info) then
            TriggerClientEvent('QRCore:Notify', src, Lang:t("You don't have enough space!", 'error'))
        else
			local name = itemas
            TriggerClientEvent('QRCore:Notify', src, Lang:t("You Get: ".. name.."<br>+"..tonumber(RandomNumber)), 'error')
		end
	end
end)

function GetItemas(model)
	for z,c in pairs(Config.Animal) do
		if c.model == model then
			return c.item
		end
	end
end


function GetPrice(model, quality)
    for k, v in pairs(Config.Animal) do
        if v.good == quality then
            if k == boost_id then
                return v.reward * 1.15 * 2.0
            else
                return v.reward * 1.15
            end
        end
        if v.perfect == quality then
            if k == boost_id then
                return v.reward * 1.25 * 2.0
            else
                return v.reward * 1.25
            end
        end
        if v.poor == quality then
            if k == boost_id then
                return v.reward * 2.0
            else
                return v.reward
            end
        end
        if v.model == model then
            if k == boost_id then
                return v.reward * 2.0
            else
                return v.reward
            end
        end
    end
end