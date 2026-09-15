local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage.Modules.GameConfig)
local Economy = require(ReplicatedStorage.Modules.Economy)
local MarketConfig = require(ReplicatedStorage.Modules.MarketConfig)
local MarketModel = require(ReplicatedStorage.Modules.MarketModel)
local Investments = require(ReplicatedStorage.Modules.InvestmentModel)
local market, sentMarket = nil, {}
local function currentMarket()
    if not market or market.Revision ~= math.floor(os.time() / MarketConfig.QuoteSeconds) then
        market = MarketModel.snapshot(os.time())
    end
    return market
end
local Data = require(script.Parent.DataManager)
local World = require(script.Parent.WorldManager)
local Limiter = require(script.Parent.RateLimiter)
local remotes = Instance.new("Folder"); remotes.Name = "Remotes"; remotes.Parent = ReplicatedStorage
local action = Instance.new("RemoteEvent"); action.Name = "EmpireAction"; action.Parent = remotes
local state = Instance.new("RemoteEvent"); state.Name = "EmpireState"; state.Parent = remotes
local feedback = Instance.new("RemoteEvent"); feedback.Name = "EmpireFeedback"; feedback.Parent = remotes
local limits, lastWork, lastHome = {}, {}, {}
local closing, loading = false, 0
World.init()
for _, name in ipairs({ "Purchase", "Cash", "LevelUp", "Event", "Rare", "Prestige", "Error", "Success" }) do
    local sound = Instance.new("Sound"); sound.Name = name; sound.Volume = 0.35
    sound.Parent = game:GetService("SoundService"):WaitForChild("MoneyEmpireSounds")
end
local function ranking()
    local prices = currentMarket().Prices
    local rows = {}
    for player, session in pairs(Data.Sessions) do
        if not session.Closing then
            table.insert(rows, { Name = player.DisplayName, UserId = player.UserId, NetWorth = Economy.netWorth(session.Profile, prices), Cash = session.Profile.Cash, Businesses = Economy.count(session.Profile) })
        end
    end
    table.sort(rows, function(a, b) return a.NetWorth > b.NetWorth end)
    while #rows > 10 do table.remove(rows) end
    return rows
end
local function send(player, ranks)
    local session = Data.Sessions[player]
    if not session or session.Closing then return end
    local p = session.Profile
    local quote = currentMarket()
    local marketUpdate = if sentMarket[player] ~= quote.Revision then quote else nil
    state:FireClient(player, { Cash = p.Cash, NetWorth = Economy.netWorth(p, quote.Prices), Income = Economy.income(p, quote.Multipliers), Businesses = p.Businesses, Collection = p.Collection, Settings = p.Settings, Title = Economy.title(p, quote.Prices), SaveStatus = session.Status, Temporary = Data.Temporary, Ranking = ranks or ranking(), Market = marketUpdate, ServerTime = os.time(), Investments = p.Investments or {}, Trades = p.Trades or {}, RealizedProfit = p.RealizedProfit or 0 })
    sentMarket[player] = quote.Revision
end
local function joined(player)
    if closing then player:Kick("Servidor encerrando. Entre novamente."); return end
    loading += 1
    local session, errorMessage = Data.load(player)
    loading -= 1
    if not session then if player.Parent then player:Kick(errorMessage) end; return end
    if closing or not player.Parent then Data.save(player, true); return end
    local plot = World.assign(player)
    if not plot then Data.save(player, true); player:Kick("Os 8 terrenos estão ocupados. Tente outro servidor."); return end
    local stats = Instance.new("Folder"); stats.Name = "leaderstats"; stats.Parent = player
    for _, name in ipairs({ "Net Worth", "Cash", "Businesses" }) do
        local value = Instance.new("NumberValue"); value.Name = name; value.Parent = stats
    end
    player.CharacterAdded:Connect(function(character)
        character:WaitForChild("HumanoidRootPart", 10)
        if player.Parent then World.teleport(player); World.updateTag(player, session.Profile) end
    end)
    if player.Character then World.teleport(player) end
    World.refresh(player, session.Profile)
    send(player)
end
Players.PlayerAdded:Connect(joined)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(joined, player) end
Players.PlayerRemoving:Connect(function(player)
    sentMarket[player] = nil
    World.release(player); limits[player] = nil; lastWork[player] = nil; lastHome[player] = nil
    Data.save(player, true)
end)
action.OnServerEvent:Connect(function(player, kind, payload)
    limits[player] = limits[player] or {}
    local now = os.clock()
    if not Limiter.allow(limits[player], now, Config.RemoteBurst, Config.RemotePerSecond) then return end
    if type(kind) ~= "string" or #kind > 24 then return end
    local session = Data.Sessions[player]
    if not session or not Data.usable(session) then return end
    local p, ok, message = session.Profile, false, nil
    if kind == "Sync" then sentMarket[player] = nil; send(player); return
    elseif kind == "InvestBuy" or kind == "InvestSell" then
        ok, message = Investments.trade(p, if kind == "InvestBuy" then "Buy" else "Sell", payload, currentMarket(), os.time())
    elseif kind == "Work" then
        if now - (lastWork[player] or -math.huge) < Config.WorkCooldown then return end
        lastWork[player] = now; ok, message = Economy.work(p)
    elseif kind == "Buy" or kind == "Upgrade" then
        if type(payload) ~= "string" or #payload > 32 or not Config.Businesses[payload] then return end
        if kind == "Buy" then ok, message = Economy.buy(p, payload) else ok, message = Economy.upgrade(p, payload) end
    elseif kind == "Home" then
        if now - (lastHome[player] or -math.huge) < 3 then return end
        lastHome[player] = now; World.teleport(player); return
    elseif kind == "ReducedMotion" then
        if type(payload) ~= "boolean" then return end
        p.Settings.ReducedMotion = payload; ok = true; message = "Preferência atualizada."
    else return end
    if message then feedback:FireClient(player, ok, message, kind) end
    if ok then
        if kind == "Buy" or kind == "Upgrade" then World.refresh(player, p) end
        if kind == "Buy" and Config.Businesses[payload].Rarity == "Secret" then
            feedback:FireAllClients(true, player.DisplayName .. " inaugurou Órbita Espacial • SECRET!", "Secret")
        end
        send(player)
    end
end)
local elapsed, snapshotElapsed = 0, 0
RunService.Heartbeat:Connect(function(dt)
    if closing then return end
    elapsed += dt; snapshotElapsed += dt
    if elapsed < Config.TickSeconds then return end
    local step = math.min(elapsed, 10); elapsed = 0
    local quote = currentMarket()
    local shouldSend = snapshotElapsed >= Config.SnapshotSeconds
    if shouldSend then snapshotElapsed = 0 end
    for player, session in pairs(Data.Sessions) do
        if Data.usable(session) then
            Economy.tick(session.Profile, step, quote.Multipliers)
            local stats = player:FindFirstChild("leaderstats")
            if stats then
                stats["Net Worth"].Value = math.floor(Economy.netWorth(session.Profile, quote.Prices))
                stats.Cash.Value = math.floor(session.Profile.Cash)
                stats.Businesses.Value = Economy.count(session.Profile)
            end
            World.refresh(player, session.Profile, quote.Prices); World.updateTag(player, session.Profile, quote.Prices)
        elseif not session.Healthy and player.Parent then
            player:Kick("Conexão de salvamento expirada. Entre novamente para proteger seus dados.")
        end
    end
    if shouldSend then
        local ranks = ranking()
        for player in pairs(Data.Sessions) do send(player, ranks) end
    end
end)
task.spawn(function()
    while not closing do
        task.wait(Config.AutosaveSeconds)
        for player, session in pairs(Data.Sessions) do
            if not closing and not session.Closing and not session.Saving then task.spawn(Data.save, player, false) end
        end
    end
end)
game:BindToClose(function()
    closing = true
    local deadline = os.clock() + 25
    while loading > 0 and os.clock() < deadline do task.wait(0.1) end
    local pending = 0
    for player in pairs(Data.Sessions) do
        pending += 1
        task.spawn(function() Data.save(player, true); pending -= 1 end)
    end
    while pending > 0 and os.clock() < deadline do task.wait(0.1) end
end)
print("[MoneyEmpire] MVP iniciado. Dados temporários:", Data.Temporary)
