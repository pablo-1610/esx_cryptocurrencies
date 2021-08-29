ESX, isMenuActive, canInteractWithZone, interactWithServer = nil, false, true, false

cryptoValues = {}

local function countTable(table)
    local i = 0
    for _,_ in pairs(table) do
        i = i + 1
    end
    return i
end

local function customGroupDigits(value)
	local left,num,right = string.match(value,'^([^%d]*%d)(%d*)(.-)$')

	return left..(num:reverse():gsub('(%d%d%d)','%1' .. "."):reverse())..right
end

local function showbox(TextEntry, ExampleText, MaxStringLenght, isValueInt)
    AddTextEntry('FMMC_KEY_TIP1', TextEntry)
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", ExampleText, "", "", "", MaxStringLenght)
    local blockinput = true
    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
        Wait(0)
    end
    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult()
        Wait(500)
        blockinput = false
        if isValueInt then
            local isNumber = tonumber(result)
            if isNumber and tonumber(result) > 0 then
                return result
            else
                return nil
            end
        end

        return result
    else
        Wait(500)
        blockinput = false
        return nil
    end
end

local function generateCryptoValue(value, isPositive)
    if isPositive == nil then
        return "~o~"..customGroupDigits(value).."$ ~s~[~o~=~s~]"
    end
    return (isPositive and "~g~" or "~r~")..customGroupDigits(value).."$ ~s~["..(isPositive and "~g~↑" or "~r~↓").."~s~]"
end

local function sub(subName)
    return "crypto_"..subName
end

local function generateCryptoSelectTitle(ammount)
    if ammount > 0 then
        return "~s~: ~y~x"..customGroupDigits(ammount)..""
    else 
        return "~s~: ~b~Définir"
    end
end

local function createMenuPanes()
    local title, desc = "Cryptomonnaies", "~g~Gérez vos cryptomonnaies"
    RMenu.Add("crypto", sub("main"), RageUI.CreateMenu(title, desc, nil, nil, "pablo", "black"))
    RMenu:Get("crypto", sub("main")).Closed = function()
    end

    RMenu.Add("crypto", sub("sell"), RageUI.CreateSubMenu(RMenu:Get("crypto", sub("main")), title, desc, nil, nil, "pablo", "black"))
    RMenu:Get("crypto", sub("sell")).Closed = function()
    end

    RMenu.Add("crypto", sub("buy"), RageUI.CreateSubMenu(RMenu:Get("crypto", sub("main")), title, desc, nil, nil, "pablo", "black"))
    RMenu:Get("crypto", sub("buy")).Closed = function()
    end
end

Citizen.CreateThread(function()
    TriggerEvent(Config.esxGetter, function(obj)
        ESX = obj
    end)

    createMenuPanes()

    local interactZone = Config.position
    if Config.blip then 
        local blip = AddBlipForCoord(interactZone)
        SetBlipAsShortRange(blip, true)
        SetBlipScale(blip, 0.9)
        SetBlipSprite(blip, 58)
        SetBlipColour(blip, 28)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Cryptomonnaies")
        EndTextCommandSetBlipName(blip)
    end

    while true do
        local interval = 250
        local playerPos = GetEntityCoords(PlayerPedId())
        local dst = #(interactZone-playerPos)
        if dst <= 30.0 and canInteractWithZone then
            interval = 0
            DrawMarker(22, interactZone, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.45, 0.45, 0.45, 255, 0, 0, 255, 55555, false, true, 2, false, false, false, false)
            if dst <= 1.0 then
                ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour gérer vos cryptomonnaies")
                if IsControlJustPressed(0, 51) and not isMenuActive then
                    canInteractWithZone = false
                    TriggerServerEvent("crypto:openCryptoMenu")
                end
            end
        end
        Wait(interval)
    end
end)

RegisterNetEvent("cryptos:cbMoney")
RegisterNetEvent("cryptos:cbWallet")
RegisterNetEvent("crypto:cbOpenMenu")
AddEventHandler("crypto:cbOpenMenu", function(incomingCryptoValues, playerMoney, cryptoWallet)
    FreezeEntityPosition(PlayerPedId(), true)
    canInteractWithZone = true
    cryptoValues = incomingCryptoValues
    isMenuActive = true
    RageUI.Visible(RMenu:Get("crypto", sub("main")), true)
    Citizen.CreateThread(function()
        AddEventHandler("cryptos:cbWallet", function(newWallet)
            cryptoWallet = newWallet
        end)
        AddEventHandler("cryptos:cbMoney", function(newMoney)
            playerMoney = newMoney
        end)
        local cryptoSelectedAmmount = {}
        local function resetCryptoSelectedAmmount()
            for k,v in pairs(cryptoValues) do
                cryptoSelectedAmmount[k] = 0
            end
        end
        resetCryptoSelectedAmmount()
        while isMenuActive do
            local shouldStayOpened = false
            local function tick()
                shouldStayOpened = true
            end
            RageUI.IsVisible(RMenu:Get("crypto", sub("main")), true, true, true, function()
                RageUI.Separator("Liquide: ~g~"..ESX.Math.GroupDigits(playerMoney[1]).."$ ~s~| Banque: ~b~"..ESX.Math.GroupDigits(playerMoney[2]).."$")
                RageUI.Separator("↓ ~g~Gestion ~s~↓")
                RageUI.ButtonWithStyle("Vendre mes cryptomonnaies", nil, {RightLabel = "→→"}, true, function() resetCryptoSelectedAmmount() end, RMenu:Get("crypto", sub("sell")))
                RageUI.ButtonWithStyle("Acheter des cryptomonnaies", nil, {RightLabel = "→→"}, true, function() resetCryptoSelectedAmmount() end, RMenu:Get("crypto", sub("buy")))
                if countTable(cryptoValues) > 0 then
                    RageUI.Separator("↓ ~y~Les cryptos ~s~↓")
                    for cryptoName,cryptoData in pairs(cryptoValues) do
                        RageUI.ButtonWithStyle(cryptoData.label, nil, {RightLabel = generateCryptoValue(cryptoData.value, cryptoData.positive)}, true)
                    end
                end
                tick()
            end, function()
            end)

            RageUI.IsVisible(RMenu:Get("crypto", sub("sell")), true, true, true, function()
                RageUI.Separator("Liquide: ~g~"..ESX.Math.GroupDigits(playerMoney[1]).."$ ~s~| Banque: ~b~"..ESX.Math.GroupDigits(playerMoney[2]).."$")
                RageUI.Separator("↓ ~g~Vente de cryptos ~s~↓")
                for cryptoName,cryptoData in pairs(cryptoValues) do
                    if (cryptoWallet[cryptoName] or 0) > 0 then
                        RageUI.ButtonWithStyle(cryptoData.label.." [~b~x"..cryptoWallet[cryptoName].."~s~]", "~y~Nom: ~s~"..cryptoData.label.."~n~~o~Valeur: ~s~"..customGroupDigits(cryptoData.value).."~g~$~n~~r~Total: ~s~"..(customGroupDigits(cryptoData.value*cryptoWallet[cryptoName])).."~g~$", {RightLabel = generateCryptoValue(cryptoData.value, cryptoData.positive)}, not interactWithServer, function(_,_,s)
                            if s then
                                local qty = showbox("Quantité", "", 50, true)
                                if qty == nil then
                                    ESX.ShowNotification("~r~Quantité invalide")
                                else
                                    interactWithServer = true
                                    TriggerServerEvent("crypto:sellCryptos", cryptoName, qty)
                                end
                            end
                        end)
                    end
                end
                tick()
            end, function()
            end)

            RageUI.IsVisible(RMenu:Get("crypto", sub("buy")), true, true, true, function()
                RageUI.Separator("Liquide: ~g~"..ESX.Math.GroupDigits(playerMoney[1]).."$ ~s~| Banque: ~b~"..ESX.Math.GroupDigits(playerMoney[2]).."$")
                RageUI.Separator("↓ ~g~Achat de cryptos ~s~↓")
                for cryptoName,cryptoData in pairs(cryptoValues) do
                    RageUI.ButtonWithStyle(cryptoData.label.." [~b~x"..(cryptoWallet[cryptoName] or 0).."~s~]", "~y~Nom: ~s~"..cryptoData.label.."~n~~o~Valeur: ~s~"..customGroupDigits(cryptoData.value).."~g~$", {RightLabel = generateCryptoValue(cryptoData.value, cryptoData.positive)}, not interactWithServer, function(_,_,s)
                        if s then
                            local qty = showbox("Quantité", "", 50, true)
                            if qty == nil then
                                ESX.ShowNotification("~r~Quantité invalide")
                            else
                                interactWithServer = true
                                TriggerServerEvent("crypto:buyCryptos", cryptoName, qty)
                            end
                        end
                    end)
                end
                tick()
            end, function()
            end)

            if not shouldStayOpened and isMenuActive then
                TriggerServerEvent("crypto:closeCryptoMenu")
                FreezeEntityPosition(PlayerPedId(), false)
                isMenuActive = false
            end
            Wait(0)
        end
    end)
end)

RegisterNetEvent("crypto:updateCryptoValue")
AddEventHandler("crypto:updateCryptoValue", function(incomingCryptoValues)
    cryptoValues = incomingCryptoValues
end)

RegisterNetEvent("crypto:cbServer")
AddEventHandler("crypto:cbServer", function(message)
    interactWithServer = false
    if message ~= nil then ESX.ShowNotification(message) end
end)