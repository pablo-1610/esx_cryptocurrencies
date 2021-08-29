ESX, cryptos, watchers = nil, {}, {}

wallet = {}

-- DO NOT DESACTIVATE
--[[
RegisterCommand("debugCmd", function(source)
    local _src = source
    local identifier = ESX.GetPlayerFromId(_src).identifier
    MySQL.Async.execute("INSERT INTO cryptos_wallet (identifier,wallet) VALUES(@a,@b)", {
        ['a'] = identifier,
        ['b'] = json.encode({["bitcoin"] = 170})
    })
end, false)
--]]

local function sendToDiscord(name,message,color)
    local DiscordWebHook = Config.webhook
    local embeds = {
        {
            ["title"]=message,
            ["type"]="rich",
            ["color"] =Config.webhook_mess_color,
            ["footer"]=  {
                ["text"]= "zCrypto",
            },
        }
    }
    PerformHttpRequest(DiscordWebHook, function(err, text, headers) end, 'POST', json.encode({ username = name,embeds = embeds}), { ['Content-Type'] = 'application/json' })
end

local function initCryptoVariator()
    debug("Initialisation de la boucle de crypto")
    Citizen.CreateThread(function()
        while true do
            for crypto, cryptoData in pairs(cryptos) do
                if Config.crypto.noChangeChance() then
                    cryptos[crypto].positive = nil
                    print("La valeur de "..crypto.." ne change pas !")
                else
                    local newCryptoValue, isPositive = alterCryptoValue(cryptoData.value)
                    cryptos[crypto].positive = isPositive
                    cryptos[crypto].value = newCryptoValue
                    debug("La valeur de "..crypto.." s'élève désormais à "..newCryptoValue.."$")
                end
            end
            debug("--------------------------------------")
            for source, _ in pairs(watchers) do
                TriggerClientEvent("crypto:updateCryptoValue", source, cryptos)
            end
            Wait(Config.crypto.cryptoVariationCycle*1000)
        end 
    end)
end

local function getCryptoValueFromDb()
    local wait = true
    MySQL.Async.fetchAll("SELECT * FROM cryptos", {}, function(result)
        for _, data in pairs(result) do
            cryptos[data.name] = {value = data.value, label = data.label, positive = true}
        end
        wait = false
    end)
    repeat Wait(0) until not wait

    wait = true
    MySQL.Async.fetchAll("SELECT * FROM cryptos_wallet", {}, function(result)
        for k,v in pairs(result) do
            wallet[v.identifier] = json.decode(v.wallet)
        end
        wait = false
    end)
end

TriggerEvent(Config.esxGetter, function(obj)
    ESX = obj
    getCryptoValueFromDb()
    initCryptoVariator()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end
    debug("Test")
    for k,v in pairs(cryptos) do 
        debug("Loop "..k)
        MySQL.Async.execute("UPDATE cryptos SET value = @a WHERE name = @b", {
            ['a'] = v.value,
            ['b'] = k
        })
    end
end)

RegisterNetEvent("crypto:openCryptoMenu")
AddEventHandler("crypto:openCryptoMenu", function()
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    watchers[_src] = GetPlayerName(_src)
    TriggerClientEvent("crypto:cbOpenMenu", _src, cryptos, {xPlayer.getMoney(), xPlayer.getAccount("bank").money}, wallet[xPlayer.identifier] or {})
end)

RegisterNetEvent("crypto:closeCryptoMenu")
AddEventHandler("crypto:closeCryptoMenu", function()
    local _src = source
    watchers[_src] = nil
end)

RegisterNetEvent("crypto:buyCryptos")
AddEventHandler("crypto:buyCryptos", function(type, qty)
    qty = tonumber(qty)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local identifier = xPlayer.identifier
    local requiered = cryptos[type].value * qty
    if xPlayer.getMoney() >= requiered then
        xPlayer.removeMoney(requiered)
    elseif xPlayer.getAccount("bank").money >= requiered then
        xPlayer.removeAccountMoney("bank", requiered)
    else
        TriggerClientEvent("crypto:cbServer", _src, "~r~Vous n'avez pas assez d'argent pour acheter ~b~"..qty.." "..cryptos[type].label)
        return
    end
    if not wallet[identifier] then
        wallet[identifier] = {}
        MySQL.Async.insert("INSERT INTO cryptos_wallet (identifier, wallet) VALUES(@a,@b)", {
            ["a"] = identifier,
            ["b"] = json.encode({})
        })
    end
    if not wallet[identifier][type] then
        wallet[identifier][type] = 0
    end
    wallet[identifier][type] = wallet[identifier][type] + qty
    MySQL.Async.execute("UPDATE cryptos_wallet SET wallet = @a WHERE identifier = @b", {
        ["a"] = json.encode(wallet[identifier]),
        ["b"] = identifier
    })
    TriggerClientEvent("cryptos:cbWallet", _src, wallet[identifier])
    TriggerClientEvent("cryptos:cbMoney", _src, {xPlayer.getMoney(), xPlayer.getAccount("bank").money})
    TriggerClientEvent("crypto:cbServer", _src, "~g~Achat effectué")
    sendToDiscord("Crypto", "Le joueur **"..GetPlayerName(_src).." ["..identifier.."] a acheté "..qty.." "..type)
end)

RegisterNetEvent("crypto:sellCryptos")
AddEventHandler("crypto:sellCryptos", function(type, qty)
    qty = tonumber(qty)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local identifier = xPlayer.identifier
    if not wallet[identifier] then
        TriggerClientEvent("crypto:cbServer", _src, "~r~Vous n'avez pas de cryptos")
        return
    end
    local cryptoAmmount = (wallet[identifier][type] or 0)
    if cryptoAmmount < qty then
        TriggerClientEvent("crypto:cbServer", _src, "~r~Vous n'avez pas assez de ~b~"..cryptos[type].label)
        return
    end
    local fakeRemainCryptos = (wallet[identifier][type] - qty)
    if (fakeRemainCryptos <= 0) then
        wallet[identifier][type] = nil
    else
        wallet[identifier][type] = fakeRemainCryptos
    end
    MySQL.Async.execute("UPDATE cryptos_wallet SET wallet = @a WHERE identifier = @b", {
        ["a"] = json.encode(wallet[identifier]),
        ["b"] = identifier
    })
    local reward = (cryptos[type].value * qty)
    xPlayer.addMoney(reward)
    TriggerClientEvent("cryptos:cbWallet", _src, wallet[identifier])
    TriggerClientEvent("cryptos:cbMoney", _src, {xPlayer.getMoney(), xPlayer.getAccount("bank").money})
    TriggerClientEvent("crypto:cbServer", _src, "~g~Vente effectuée")
    sendToDiscord("Crypto", "Le joueur **"..GetPlayerName(_src).." ["..identifier.."] a vendu "..qty.." "..type)
end)
  
  