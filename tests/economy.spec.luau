local Economy = require("../src/shared/Economy")
local Config = require("../src/shared/GameConfig")
local Format = require("../src/shared/NumberFormatter")
local Policy = require("../src/server/SessionPolicy")
local Limiter = require("../src/server/RateLimiter")
local passed = 0
local function test(name, run)
    local ok, err = pcall(run)
    if not ok then error("FAIL " .. name .. ": " .. tostring(err)) end
    passed += 1; print("PASS " .. name)
end
test("initial $1 and valid empty profile", function()
    local p = Economy.newProfile(); assert(p.Cash == 1 and Economy.income(p) == 0 and Economy.validate(p))
end)
test("full first-session progression", function()
    local p = Economy.newProfile()
    assert(not Economy.buy(p, "Water"))
    for _ = 1, 5 do Economy.work(p) end
    assert(p.Cash == 11 and Economy.buy(p, "Water"))
    assert(p.Cash == 1 and Economy.income(p) == 1)
    Economy.tick(p, 10); assert(p.Cash == 11)
    local before = Economy.income(p)
    assert(Economy.upgrade(p, "Water")); assert(Economy.income(p) > before)
    for _ = 1, 10 do Economy.tick(p, 10) end
    assert(Economy.buy(p, "FoodCart")); assert(Economy.count(p) == 2)
    assert(Economy.netWorth(p) > p.Cash and Economy.validate(p))
end)
test("no bypass, duplication or forged business", function()
    local p = Economy.newProfile(); p.Cash = 1e15
    assert(not Economy.buy(p, "Space")); assert(not Economy.buy(p, "Unknown"))
    assert(Economy.buy(p, "Water")); local cash = p.Cash
    assert(not Economy.buy(p, "Water")); assert(p.Cash == cash)
    assert(not Economy.upgrade(p, "FoodCart"))
end)
test("all fifteen businesses reach max without broken balance", function()
    local p = Economy.newProfile(); p.Cash = 1e25
    for _, id in ipairs(Config.BusinessOrder) do
        assert(Economy.buy(p, id))
        for _ = 2, Config.Businesses[id].MaxLevel do assert(Economy.upgrade(p, id)) end
        local cash = p.Cash; assert(not Economy.upgrade(p, id)); assert(p.Cash == cash)
    end
    assert(Economy.count(p) == 15 and Economy.validate(p))
end)
test("invalid persisted data rejected without reset", function()
    local p = Economy.newProfile(); p.Cash = 0 / 0; assert(not Economy.validate(p))
    p.Cash = math.huge; assert(not Economy.validate(p))
    p.Cash = -1; assert(not Economy.validate(p))
    p.Cash = 1; p.Version = 2; assert(not Economy.validate(p))
    p.Version = 1; p.Businesses.Water = { Level = 999, Variant = "Normal", Invested = 10 }; assert(not Economy.validate(p))
end)
test("nonfinite and negative credit never changes balance", function()
    local p = Economy.newProfile()
    for _, amount in ipairs({ -100, math.huge, 0 / 0 }) do assert(not Economy.credit(p, amount)); assert(p.Cash == 1) end
    assert(not Economy.tick(p, -1)); assert(not Economy.tick(p, 1000))
end)
test("save profile deep roundtrip remains valid", function()
    local p = Economy.newProfile(); p.Cash = 1000; Economy.buy(p, "Water"); Economy.upgrade(p, "Water")
    local function copy(t) local r = {}; for k, v in pairs(t) do r[k] = if type(v) == "table" then copy(v) else v end; return r end
    local restored = copy(p); assert(Economy.validate(restored)); assert(Economy.income(restored) == Economy.income(p))
    restored.Businesses.Water.Level += 1; assert(restored.Businesses.Water.Level ~= p.Businesses.Water.Level)
end)
test("lease excludes other servers and allows expiry recovery", function()
    local record = { Format = 1, Data = {}, Lock = { Token = "A", Expires = 180 } }
    assert(Policy.canAcquire(nil, "B", 10)); assert(Policy.canAcquire(record, "A", 10))
    assert(not Policy.canAcquire(record, "B", 10)); assert(Policy.canAcquire(record, "B", 181))
    assert(Policy.owns(record, "A", 10)); assert(not Policy.owns(record, "B", 10)); assert(not Policy.owns(record, "A", 180))
    assert(not Policy.canAcquire({ Format = 2 }, "A", 200)); assert(not Policy.canAcquire("bad", "A", 200))
end)
test("server token bucket bounds remote spam", function()
    local state = {}
    for _ = 1, 12 do assert(Limiter.allow(state, 0, 12, 6)) end
    assert(not Limiter.allow(state, 0, 12, 6)); assert(Limiter.allow(state, 1, 12, 6))
    for _ = 1, 5 do assert(Limiter.allow(state, 1, 12, 6)) end
    assert(not Limiter.allow(state, 1, 12, 6))
end)
test("number formatter boundaries and all suffixes", function()
    assert(Format.compact(1000) == "1K"); assert(Format.compact(1000000) == "1M")
    assert(Format.compact(999999) == "1M"); assert(Format.compact(-1500) == "-1.5K")
    assert(Format.compact(0 / 0) == "0"); assert(Format.money(1) == "$1")
    for i, suffix in ipairs({ "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }) do
        assert(Format.compact(1000 ^ i) == "1" .. suffix)
    end
end)
print("\n" .. passed .. " tests passed.")
