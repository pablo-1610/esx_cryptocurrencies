Config = {
    esxGetter = "esx:getSharedObject",
    webhook = "put your webhook here",
    webhook_mess_color = 8421504,
    blip = true,
    position = vector3(-64.09, -797.39, 44.23),
    debug = false, -- Console printing

    crypto = {
        maxValue = 1000000,
        minValue = 0,

        noChangeChance = function()
            return (math.random(1, 3) == 1)
        end,

        cryptoVariationCycle = 2, -- In seconds

        positiveMaxVariationValue = 100,
        negativeMaxVariationValue = -100
    }
}

validateCryptoValue = function(cryptoValue)
    return cryptoValue <= Config.crypto.maxValue and cryptoValue >= Config.crypto.minValue
end

alterCryptoValue = function(currentValue)
    value = currentValue
    local variation = math.random(Config.crypto.negativeMaxVariationValue, Config.crypto.positiveMaxVariationValue)
    local fakeValue = value + variation
    while not validateCryptoValue(fakeValue) do
        variation = math.random(Config.crypto.negativeMaxVariationValue, Config.crypto.positiveMaxVariationValue)
        fakeValue = value + variation
    end
    value = fakeValue
    return value, (variation > 0)
end

debug = function(text)
    if Config.debug then print(text) end
end