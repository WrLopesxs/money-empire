local Economy = require("../src/shared/Economy")
local Investments = require("../src/shared/InvestmentModel")
local Market = require("../src/shared/MarketModel")
local Config = require("../src/shared/MarketConfig")
local Layout = require("../src/shared/UILayout")
local passed = 0
local function test(name, run)
    local ok, err = pcall(run)
    if not ok then error("FAIL " .. name .. ": " .. tostring(err)) end
    passed += 1; print("PASS " .. name)
end
local function request(market, units) return { Sector = "Food", Units = units or 1, Revision = market.Revision } end
local quote = { Revision = 100, Prices = { Food = 20 } }
test("old saves migrate without losing money or businesses", function()
    local p = Economy.newProfile(); p.Cash = 1000; Economy.buy(p, "Water")
    p.Investments = nil; p.Trades = nil; p.RealizedProfit = nil
    assert(Economy.validate(p)); assert(Investments.prepare(p)); assert(p.Cash == 990 and p.Businesses.Water.Level == 1)
    assert(Economy.validate(p) and #p.Trades == 0)
end)
test("corrupt investment fields never reset into a new wallet", function()
    local p = Economy.newProfile(); p.Investments = "bad"
    assert(not Investments.prepare(p) and p.Investments == "bad")
    p.Investments = { Food = { Shares = 0 / 0, Cost = 10 } }; assert(not Economy.validate(p))
    p.Investments = {}; p.RealizedProfit = math.huge; assert(not Economy.validate(p))
end)
test("buy and sell charge disclosed fees and conserve holdings", function()
    local p = Economy.newProfile(); p.Cash = 1000
    assert(Investments.trade(p, "Buy", request(quote, 10), quote, 100))
    assert(math.abs(p.Cash - 796) < 0.02 and p.Investments.Food.Shares == 10)
    assert(Investments.trade(p, "Sell", request(quote, 10), quote, 101))
    assert(p.Investments.Food == nil and math.abs(p.Cash - 992) < 0.02)
    assert(math.abs(p.RealizedProfit + 8) < 0.02 and #p.Trades == 2 and Economy.validate(p))
end)
test("stale quotes cannot execute a transaction", function()
    local p = Economy.newProfile(); p.Cash = 1000
    local r = request(quote); r.Revision -= 1
    assert(not Investments.trade(p, "Buy", r, quote, 100)); assert(p.Cash == 1000 and next(p.Investments) == nil)
end)
test("remote payload cannot select prices or create free shares", function()
    local p = Economy.newProfile(); p.Cash = 1000
    for _, units in ipairs({ 0, -1, 0.5, 1e30, math.huge, 0/0, "1", {} }) do
        local r = request(quote); r.Units = units
        assert(not Investments.trade(p, "Buy", r, quote, 100))
    end
    assert(not Investments.trade(p, "Buy", "Food", quote, 100))
    local r = request(quote); r.Price = 0
    assert(Investments.trade(p, "Buy", r, quote, 100)); assert(p.Cash < 980)
end)
test("insufficient balance and overselling do not mutate wallet", function()
    local p = Economy.newProfile()
    assert(not Investments.trade(p, "Buy", request(quote), quote, 100))
    assert(not Investments.trade(p, "Sell", request(quote), quote, 100)); assert(p.Cash == 1)
    p.Cash = 1000; assert(Investments.trade(p, "Buy", request(quote), quote, 100))
    local cash = p.Cash; assert(not Investments.trade(p, "Sell", request(quote, 10), quote, 101))
    assert(p.Cash == cash and p.Investments.Food.Shares == 1)
end)
test("partial sale preserves average cost and accounts realized gains", function()
    local p = Economy.newProfile(); p.Cash = 1000
    assert(Investments.trade(p,"Buy",request(quote,10),quote,100))
    local higher = { Revision = 101, Prices = { Food = 30 } }
    assert(Investments.trade(p,"Sell",request(higher),higher,101))
    assert(p.Investments.Food.Shares == 9)
    assert(math.abs(p.Investments.Food.Cost - 183.6) < 0.02)
    assert(math.abs(p.RealizedProfit - 9) < 0.02)
end)
test("net worth reflects current quotes", function()
    local p = Economy.newProfile(); p.Cash = 1000
    assert(Investments.trade(p,"Buy",request(quote),quote,100))
    local low = Economy.netWorth(p,{Food=10}); local high = Economy.netWorth(p,{Food=30})
    assert(math.abs(high-low-20) < 0.001)
end)
test("history is bounded and newest first", function()
    local p = Economy.newProfile(); p.Cash = 10000
    for i=1,40 do assert(Investments.trade(p,if i%2==1 then "Buy" else "Sell",request(quote),quote,i)) end
    assert(#p.Trades==Config.HistoryLimit and p.Trades[1].Time==40 and Economy.validate(p))
end)
test("two servers compute identical quotes and finite histories", function()
    local a,b = Market.snapshot(1789470000),Market.snapshot(1789470000)
    for _,sector in ipairs(Config.SectorOrder) do
        assert(a.Prices[sector]==b.Prices[sector] and a.Prices[sector]>0)
        assert(#a.History[sector]==Config.ChartPoints)
        assert(a.History[sector][Config.ChartPoints]==a.Prices[sector])
    end
end)
test("quotes remain fixed inside the same 15 second window", function()
    for _,sector in ipairs(Config.SectorOrder) do assert(Market.priceAt(sector,1500)==Market.priceAt(sector,1514)) end
end)
test("events end after 180 seconds and do not multiply unrelated sectors", function()
    local active = Market.snapshot(0); local ended = Market.snapshot(180)
    assert(active.Multipliers.Tech==4 and active.Multipliers.Food==1)
    assert(ended.Multipliers.Tech==1 and ended.EndsAt==480)
end)
test("market multipliers reach passive business income", function()
    local p = Economy.newProfile(); p.Cash = 1000; Economy.buy(p,"Water")
    local before = p.Cash; Economy.tick(p,1,{Food=3})
    assert(p.Cash==before+3); assert(Economy.income(p,{Food=0.5})==0.5)
end)
test("menu stays inside phone tablet and desktop safe areas", function()
    for _,size in ipairs({{320,480},{390,750},{844,300},{1024,720},{1920,1080}}) do
        local d = Layout.calculate(size[1],size[2])
        assert(d.HudWidth<=384 and d.PanelWidth<=360)
        assert(d.PanelX+d.PanelWidth<=size[1] and d.PanelY+d.PanelHeight<=size[2])
        assert(d.PanelHeight>188)
    end
end)
print("\n"..passed.." market/layout tests passed.")
