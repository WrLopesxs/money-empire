-- Pure Luau domain logic: the same implementation runs in Roblox and in CLI tests.
local Config = require(if script then script.Parent.GameConfig else "./GameConfig")
local Investments = require(if script then script.Parent.InvestmentModel else "./InvestmentModel")
local Economy = {}
local function finite(n, minimum, maximum)
    return type(n) == "number" and n == n and n >= minimum and n <= maximum
end
function Economy.newProfile()
    return { Version = 1, Cash = Config.StartingCash, Businesses = {}, Collection = {}, LifetimeEarned = 0, WorkCount = 0, Settings = { ReducedMotion = false }, Revision = 0, Investments = {}, Trades = {}, RealizedProfit = 0 }
end
function Economy.validate(p)
    if type(p) ~= "table" or p.Version ~= 1 then return false end
    if not finite(p.Cash, 0, Config.MaxCash) or not finite(p.LifetimeEarned, 0, Config.MaxCash) then return false end
    if not finite(p.WorkCount, 0, 1e12) or p.WorkCount % 1 ~= 0 then return false end
    if not finite(p.Revision, 0, 1e15) or p.Revision % 1 ~= 0 then return false end
    if type(p.Businesses) ~= "table" or type(p.Collection) ~= "table" or type(p.Settings) ~= "table" then return false end
    if type(p.Settings.ReducedMotion) ~= "boolean" then return false end
    for id, owned in pairs(p.Businesses) do
        local c = Config.Businesses[id]
        if not c or type(owned) ~= "table" then return false end
        if not finite(owned.Level, 1, c.MaxLevel) or owned.Level % 1 ~= 0 then return false end
        if not Config.Variants[owned.Variant] or not finite(owned.Invested, c.Price, Config.MaxCash) then return false end
    end
    for id, discovered in pairs(p.Collection) do
        if not Config.Businesses[id] or discovered ~= true then return false end
    end
    return Investments.validate(p)
end
function Economy.incomeFor(id, owned, multipliers)
    local category = Config.Businesses[id].Category
    local marketBoost = if multipliers then multipliers[category] or 1 else 1
    return Config.Businesses[id].Income * Config.UpgradeIncomeGrowth ^ (owned.Level - 1) * Config.Variants[owned.Variant] * marketBoost
end
function Economy.income(p, multipliers)
    local total = 0
    for id, owned in pairs(p.Businesses) do total += Economy.incomeFor(id, owned, multipliers) end
    return total
end
function Economy.netWorth(p, prices)
    local total = p.Cash + Investments.value(p, prices)
    for _, owned in pairs(p.Businesses) do total += math.floor(owned.Invested * Config.ResaleRatio) end
    return total
end
function Economy.title(p, prices)
    local result, worth = Config.Titles[1].Name, Economy.netWorth(p, prices)
    for _, entry in ipairs(Config.Titles) do if worth >= entry.Value then result = entry.Name end end
    return result
end
function Economy.unlocked(p, id)
    for i, entry in ipairs(Config.BusinessOrder) do
        if entry == id then return i == 1 or p.Collection[Config.BusinessOrder[i - 1]] == true end
    end
    return false
end
function Economy.upgradeCost(id, owned)
    return math.floor(Config.Businesses[id].Price * 0.65 * Config.UpgradeCostGrowth ^ (owned.Level - 1))
end
function Economy.credit(p, amount)
    if not finite(amount, 0, Config.MaxCash) then return false end
    p.Cash = math.min(Config.MaxCash, p.Cash + amount)
    p.LifetimeEarned = math.min(Config.MaxCash, p.LifetimeEarned + amount)
    return true
end
function Economy.work(p)
    Economy.credit(p, Config.WorkReward)
    p.WorkCount += 1
    return true, "+$" .. Config.WorkReward
end
function Economy.buy(p, id)
    local c = Config.Businesses[id]
    if not c or not Economy.unlocked(p, id) then return false, "Compre o negócio anterior para desbloquear." end
    if p.Businesses[id] then return false, "Você já tem este negócio." end
    if p.Cash < c.Price then return false, "Dinheiro insuficiente." end
    p.Cash -= c.Price
    p.Businesses[id] = { Level = 1, Variant = "Normal", Invested = c.Price }
    p.Collection[id] = true
    return true, c.Name .. " inaugurado!"
end
function Economy.upgrade(p, id)
    local owned, c = p.Businesses[id], Config.Businesses[id]
    if not owned or not c then return false, "Negócio não encontrado." end
    if owned.Level >= c.MaxLevel then return false, "Nível máximo atingido." end
    local cost = Economy.upgradeCost(id, owned)
    if p.Cash < cost then return false, "Dinheiro insuficiente." end
    p.Cash -= cost
    owned.Invested += cost
    owned.Level += 1
    return true, "Upgrade concluído!"
end
function Economy.tick(p, elapsed, multipliers)
    if not finite(elapsed, 0, 10) then return false end
    return Economy.credit(p, Economy.income(p, multipliers) * elapsed)
end
function Economy.count(p)
    local n = 0
    for _ in pairs(p.Businesses) do n += 1 end
    return n
end
return Economy
