local Config = require(if script then script.Parent.MarketConfig else "./MarketConfig")
local GameConfig = require(if script then script.Parent.GameConfig else "./GameConfig")
local Investments = {}
local function finite(n, minimum, maximum)
    return type(n) == "number" and n == n and n >= minimum and n <= maximum
end
function Investments.validate(profile)
    if profile.Investments ~= nil then
        if type(profile.Investments) ~= "table" then return false end
        for sector, holding in pairs(profile.Investments) do
            if not Config.Sectors[sector] or type(holding) ~= "table" then return false end
            if not finite(holding.Shares, 1, Config.MaxShares) or holding.Shares % 1 ~= 0 then return false end
            if not finite(holding.Cost, 0, GameConfig.MaxCash) then return false end
        end
    end
    if profile.RealizedProfit ~= nil and not finite(profile.RealizedProfit, -GameConfig.MaxCash, GameConfig.MaxCash) then return false end
    if profile.Trades ~= nil then
        if type(profile.Trades) ~= "table" or #profile.Trades > Config.HistoryLimit then return false end
        local count = 0
        for index, trade in pairs(profile.Trades) do
            count += 1
            if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > #profile.Trades then return false end
            if type(trade) ~= "table" or not Config.Sectors[trade.Sector] then return false end
            if trade.Side ~= "Buy" and trade.Side ~= "Sell" then return false end
            if not finite(trade.Units, 1, Config.MaxShares) or trade.Units % 1 ~= 0 then return false end
            if not finite(trade.Price, 0.01, 1e9) or not finite(trade.Total, 0, GameConfig.MaxCash) then return false end
            if not finite(trade.Time, 0, 1e12) then return false end
        end
        if count ~= #profile.Trades then return false end
    end
    return true
end
function Investments.prepare(profile)
    -- Additive migration: only missing fields are initialized. Invalid records remain invalid.
    if not Investments.validate(profile) then return false end
    profile.Investments = profile.Investments or {}
    profile.Trades = profile.Trades or {}
    profile.RealizedProfit = profile.RealizedProfit or 0
    return true
end
function Investments.value(profile, prices)
    local total = 0
    for sector, holding in pairs(profile.Investments or {}) do
        total += if prices and prices[sector] then holding.Shares * prices[sector] else holding.Cost
    end
    return total
end
function Investments.trade(profile, side, request, market, now)
    if side ~= "Buy" and side ~= "Sell" then return false, "Operação inválida." end
    if type(request) ~= "table" or type(request.Sector) ~= "string" or not Config.Sectors[request.Sector] then return false, "Setor inválido." end
    if not table.find(Config.Lots, request.Units) then return false, "Quantidade inválida." end
    if request.Revision ~= market.Revision then return false, "A cotação mudou. Confira o preço e tente novamente." end
    if not Investments.prepare(profile) then return false, "Carteira inválida." end
    local sector, units = request.Sector, request.Units
    local price = market.Prices[sector]
    if not finite(price, 0.01, 1e9) then return false, "Cotação indisponível." end
    local holding = profile.Investments[sector]
    local total
    if side == "Buy" then
        total = math.ceil(price * units * (1 + Config.Fee) * 100) / 100
        if profile.Cash < total then return false, "Dinheiro insuficiente para compra e taxa." end
        if holding and holding.Shares + units > Config.MaxShares then return false, "Limite de cotas atingido." end
        holding = holding or { Shares = 0, Cost = 0 }
        holding.Shares += units; holding.Cost += total
        profile.Investments[sector] = holding; profile.Cash -= total
    else
        if not holding or holding.Shares < units then return false, "Você não tem essas cotas para vender." end
        total = math.floor(price * units * (1 - Config.Fee) * 100) / 100
        if profile.Cash + total > GameConfig.MaxCash then return false, "Limite de saldo atingido." end
        local cost = holding.Cost * units / holding.Shares
        holding.Shares -= units; holding.Cost = math.max(0, holding.Cost - cost)
        profile.Cash += total
        profile.RealizedProfit = math.clamp(profile.RealizedProfit + total - cost, -GameConfig.MaxCash, GameConfig.MaxCash)
        if holding.Shares == 0 then profile.Investments[sector] = nil end
    end
    table.insert(profile.Trades, 1, { Sector = sector, Side = side, Units = units, Price = price, Total = total, Time = now })
    while #profile.Trades > Config.HistoryLimit do table.remove(profile.Trades) end
    return true, if side == "Buy" then "Investimento comprado. Taxa de 2% incluída." else "Venda concluída. Taxa de 2% descontada."
end
return Investments
