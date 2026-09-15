local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Input = game:GetService("UserInputService")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Config = require(Modules.GameConfig)
local MarketConfig = require(Modules.MarketConfig)
local Economy = require(Modules.Economy)
local Format = require(Modules.NumberFormatter)
local UILayout = require(Modules.UILayout)
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local action = remotes:WaitForChild("EmpireAction")
local theme = { bg = Color3.fromRGB(14,23,34), panel = Color3.fromRGB(24,37,50), card = Color3.fromRGB(32,48,62),
    muted = Color3.fromRGB(152,174,189), white = Color3.fromRGB(238,245,248), mint = Color3.fromRGB(107,241,184),
    gold = Color3.fromRGB(255,211,123), error = Color3.fromRGB(255,140,144) }
local gui = Instance.new("ScreenGui"); gui.Name = "MoneyEmpireUI"; gui.ResetOnSpawn = false
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
local function frame(parent, size, position, color)
    local f = Instance.new("Frame"); f.Size = size; f.Position = position; f.BackgroundColor3 = color or theme.panel
    f.BorderSizePixel = 0; f.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = f; return f
end
local function label(parent, text, size, position, font, color)
    local l = Instance.new("TextLabel"); l.Size = size; l.Position = position; l.BackgroundTransparency = 1
    l.Text = text; l.TextColor3 = color or theme.white; l.Font = Enum.Font.GothamMedium; l.TextSize = font or 12
    l.TextXAlignment = Enum.TextXAlignment.Left; l.TextTruncate = Enum.TextTruncate.AtEnd; l.Parent = parent; return l
end
local function button(parent, text, size, position, callback, color)
    local b = Instance.new("TextButton"); b.Size = size; b.Position = position; b.BackgroundColor3 = color or theme.mint
    b.Text = text; b.TextSize = 12; b.Font = Enum.Font.GothamBold; b.TextColor3 = theme.bg; b.BorderSizePixel = 0; b.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = b
    b.Activated:Connect(callback); return b
end
local function enable(b, yes)
    b.Active = yes; b.AutoButtonColor = yes; b.BackgroundColor3 = if yes then theme.mint else theme.panel
    b.TextColor3 = if yes then theme.bg else theme.muted
end
local root = frame(gui, UDim2.fromScale(1,1), UDim2.new()); root.BackgroundTransparency = 1
local header = frame(root, UDim2.fromOffset(384,50), UDim2.fromOffset(8,8), theme.bg)
local stats = {}
for i, name in ipairs({"DINHEIRO", "PATRIMÔNIO", "RENDA / SEG"}) do
    local cell = frame(header, UDim2.new(1/3,-8,1,-8), UDim2.new((i-1)/3,4,0,4))
    label(cell,name,UDim2.new(1,-12,0,13),UDim2.fromOffset(6,3),9,theme.muted)
    stats[i] = label(cell,"—",UDim2.new(1,-12,0,23),UDim2.fromOffset(6,16),18,if i==3 then theme.mint else theme.white)
end
local news = button(root,"MARKET NEWS • conectando",UDim2.fromOffset(384,24),UDim2.fromOffset(8,64),function() end,theme.panel)
news.TextColor3 = theme.gold; news.TextSize = 11
local dock = frame(root,UDim2.fromOffset(384,40),UDim2.fromOffset(8,94),theme.bg)
local panel = frame(root,UDim2.fromOffset(360,460),UDim2.fromOffset(8,66),theme.bg)
panel.Name = "MenuDrawer"; panel.Visible = false; panel.ClipsDescendants = true; panel.Active = true
local title = label(panel,"Seu império",UDim2.new(1,-70,0,28),UDim2.fromOffset(12,8),17)
local hint = label(panel,"",UDim2.new(1,-24,0,20),UDim2.fromOffset(12,37),11,theme.muted)
local tabs = frame(panel,UDim2.new(1,-20,0,80),UDim2.fromOffset(10,62))
local scroll = Instance.new("ScrollingFrame"); scroll.Name = "Content"; scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4; scroll.ScrollBarImageColor3 = theme.mint; scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new(); scroll.Parent = panel
local list = Instance.new("UIListLayout"); list.Padding = UDim.new(0,8); list.SortOrder = Enum.SortOrder.LayoutOrder; list.Parent = scroll
local save = label(panel,"Conectando…",UDim2.new(1,-24,0,26),UDim2.new(0,12,1,-30),10,theme.muted)
local feedback = label(root,"",UDim2.fromOffset(384,32),UDim2.fromOffset(8,140),12,theme.mint)
feedback.TextWrapped = true; feedback.TextTruncate = Enum.TextTruncate.None
local state, tab, signature, lot, history = nil, "Negócios", "", 1, false
local cards, tabButtons, lotButtons = {}, {}, {}
local tabNames = {"Negócios","Mercado","Investir","Coleção","Ranking","Ajustes"}
local render, resize, openMenu, slide
local messageUntil = 0
openMenu = function(open, nextTab)
    if nextTab and nextTab ~= tab then tab = nextTab; signature = "" end
    if slide then slide:Cancel(); slide = nil end
    panel.Visible = open; dock.Visible = not open; news.Visible = not open; feedback.Visible = not open
    if resize then resize() end
    if open and state and state.Market then
        render()
        if not state.Settings.ReducedMotion then
            local target = panel.Position; panel.Position = target - UDim2.fromOffset(8,0)
            slide = TweenService:Create(panel,TweenInfo.new(0.14),{Position=target}); slide:Play()
        end
    end
end
button(panel,"×",UDim2.fromOffset(44,44),UDim2.new(1,-50,0,4),function() openMenu(false) end,theme.gold)
button(dock,"Menu [B]",UDim2.new(0.28,-4,1,-4),UDim2.fromOffset(2,2),function() openMenu(true) end,theme.gold)
button(dock,"+$2  Trabalhar",UDim2.new(0.46,-4,1,-4),UDim2.new(0.28,2,0,2),function() action:FireServer("Work") end)
button(dock,"Terreno",UDim2.new(0.26,-4,1,-4),UDim2.new(0.74,2,0,2),function() action:FireServer("Home") end,theme.muted)
news.Activated:Connect(function() openMenu(true,"Mercado") end)
for _, name in ipairs(tabNames) do
    tabButtons[name] = button(tabs,name,UDim2.new(),UDim2.new(),function()
        if tab ~= name then tab = name; signature = "" end
        if state and state.Market then render() end
    end)
end
local function clear()
    cards = {}; lotButtons = {}; scroll.CanvasPosition = Vector2.zero
    for _, child in ipairs(scroll:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
end
local function card(height,order)
    local row = frame(scroll,UDim2.new(1,-7,0,height),UDim2.new(),theme.card); row.LayoutOrder = order or 0; return row
end
local function details(row)
    return {Row=row, Title=label(row,"",UDim2.new(1,-24,0,24),UDim2.fromOffset(12,6),14),
        Detail=label(row,"",UDim2.new(1,-24,0,22),UDim2.fromOffset(12,32),11,theme.muted)}
end
render = function()
    if not state or not state.Market or not panel.Visible then return end
    for name,b in pairs(tabButtons) do b.BackgroundColor3 = if name==tab then theme.mint else theme.card; b.TextColor3 = if name==tab then theme.bg else theme.white end
    title.Text = tab
    local count = 0; for _ in pairs(state.Collection) do count += 1 end
    hint.Text = if tab=="Coleção" then count.." / "..#Config.BusinessOrder.." descobertos"
        elseif tab=="Investir" then "Moeda fictícia • taxa de 2% por operação"
        elseif tab=="Mercado" then state.Market.Description
        elseif tab=="Ranking" then "Top 10 • inclui o valor atual da carteira"
        elseif tab=="Ajustes" then "MONEY EMPIRE • From $1 to Billionaire"
        elseif not state.Businesses.Water then "Trabalhe 5 vezes e compre Água gelada."
        else "Renda automática gratuita. Continue expandindo!"
    local key = tab..tostring(history)
    if signature ~= key then
        signature = key; clear()
        if tab=="Negócios" or tab=="Coleção" then
            for i,id in ipairs(Config.BusinessOrder) do
                local row = card(if tab=="Negócios" then 112 else 64,i); local c = details(row)
                if tab=="Negócios" then
                    c.Income = label(row,"",UDim2.new(0.4,-10,0,44),UDim2.fromOffset(12,58),12,theme.mint)
                    c.Buy = button(row,"",UDim2.new(0.6,-16,0,44),UDim2.new(0.4,4,0,58),function()
                        action:FireServer(if state.Businesses[id] then "Upgrade" else "Buy",id)
                    end)
                end
                cards[id] = c
            end
        elseif tab=="Mercado" then
            for i,sector in ipairs(MarketConfig.SectorOrder) do
                local row = card(150,i); local c = details(row)
                local chart = frame(row,UDim2.new(1,-24,0,60),UDim2.fromOffset(12,57)); c.Bars = {}
                for j=1,MarketConfig.ChartPoints do
                    local bar = frame(chart,UDim2.new(),UDim2.new((j-1)/MarketConfig.ChartPoints,1,1,0),theme.mint)
                    bar.AnchorPoint = Vector2.new(0,1); c.Bars[j] = bar
                end
                c.Range = label(row,"",UDim2.new(1,-24,0,22),UDim2.fromOffset(12,123),10,theme.muted); cards[sector] = c
            end
        elseif tab=="Investir" then
            local controls = card(88,0)
            for i,amount in ipairs(MarketConfig.Lots) do
                lotButtons[amount] = button(controls,amount.." cota(s)",UDim2.new(1/3,-8,0,36),UDim2.new((i-1)/3,4,0,4),function() lot=amount; render() end)
            end
            button(controls,if history then "Voltar à carteira" else "Histórico de operações",UDim2.new(1,-8,0,36),UDim2.fromOffset(4,47),function() history=not history; signature=""; render() end,theme.gold)
            if history then
                for i=1,MarketConfig.HistoryLimit do cards[i] = details(card(65,i)) end
            else
                for i,sector in ipairs(MarketConfig.SectorOrder) do
                    local row = card(160,i); local c = details(row); c.Detail.Size = UDim2.new(1,-24,0,40)
                    c.Detail.TextWrapped = true; c.Detail.TextTruncate = Enum.TextTruncate.None
                    c.Pnl = label(row,"",UDim2.new(1,-24,0,24),UDim2.fromOffset(12,76),11)
                    local function trade(kind) action:FireServer(kind,{Sector=sector,Units=lot,Revision=state.Market.Revision}) end
                    c.Buy = button(row,"",UDim2.new(0.5,-16,0,44),UDim2.fromOffset(12,108),function() trade("InvestBuy") end)
                    c.Sell = button(row,"",UDim2.new(0.5,-16,0,44),UDim2.new(0.5,4,0,108),function() trade("InvestSell") end)
                    cards[sector] = c
                end
            end
        elseif tab=="Ranking" then
            for i=1,10 do cards[i] = details(card(65,i)) end
        else
            local row = card(102,0); label(row,"Movimento reduzido",UDim2.new(1,-24,0,24),UDim2.fromOffset(12,8),15)
            cards.Motion = button(row,"",UDim2.new(1,-24,0,44),UDim2.fromOffset(12,46),function() action:FireServer("ReducedMotion",not state.Settings.ReducedMotion) end)
            local text = label(card(150,1),"Patrimônio = saldo + 70% do capital dos negócios + valor da carteira.\n\nCotações simuladas a cada 15s. Eventos duram 3 minutos.\n\nE: trabalhar • B: abrir/fechar",UDim2.new(1,-24,1,-16),UDim2.fromOffset(12,8),12,theme.muted)
            text.TextWrapped = true; text.TextTruncate = Enum.TextTruncate.None
        end
    end
    if tab=="Negócios" or tab=="Coleção" then
        for _,id in ipairs(Config.BusinessOrder) do
            local c,row,owned = Config.Businesses[id],cards[id],state.Businesses[id]
            local hidden = tab=="Coleção" and not state.Collection[id]
            row.Title.Text = if hidden then "? ? ? • Não descoberto" else c.Name
            row.Detail.Text = if hidden then "Continue expandindo para revelar." else c.Rarity.." • "..c.Category..(if owned then " • Nv. "..owned.Level.."/"..c.MaxLevel else "")
            if row.Buy then
                local cost = if owned then Economy.upgradeCost(id,owned) else c.Price
                local maxed = owned and owned.Level>=c.MaxLevel; local unlocked = Economy.unlocked(state,id)
                local income = if owned then Economy.incomeFor(id,owned,state.Market.Multipliers) else c.Income*state.Market.Multipliers[c.Category]
                row.Income.Text = "+"..Format.money(income).."/s"
                row.Buy.Text = if maxed then "NÍVEL MÁXIMO" elseif not unlocked then "BLOQUEADO" else (if owned then "Upgrade " else "Comprar ")..Format.money(cost)
                enable(row.Buy,not maxed and unlocked and state.Cash>=cost)
            end
        end
    elseif tab=="Mercado" then
        for _,sector in ipairs(MarketConfig.SectorOrder) do
            local row,quote = cards[sector],state.Market
            row.Title.Text = MarketConfig.Sectors[sector].Name.." • "..Format.money(quote.Prices[sector])
            row.Detail.Text = "Renda dos negócios: x"..quote.Multipliers[sector]
            if row.Revision~=quote.Revision then
                row.Revision = quote.Revision; local low,high = math.huge,-math.huge
                for _,price in ipairs(quote.History[sector]) do low=math.min(low,price); high=math.max(high,price) end
                for i,price in ipairs(quote.History[sector]) do row.Bars[i].Size=UDim2.new(1/MarketConfig.ChartPoints,-2,0.1+0.9*(price-low)/math.max(0.01,high-low),0) end
                row.Range.Text = Format.money(low).." – "..Format.money(high).." • últimas 24 cotações"
            end
        end
    elseif tab=="Investir" then
        for amount,b in pairs(lotButtons) do b.BackgroundColor3=if amount==lot then theme.mint else theme.muted end
        if history then
            hint.Text = "Resultado realizado: "..Format.money(state.RealizedProfit)
            for i,row in ipairs(cards) do
                local trade = state.Trades[i]; row.Row.Visible=trade~=nil or i==1
                row.Title.Text = if trade then (if trade.Side=="Buy" then "Compra" else "Venda").." • "..trade.Sector.." • "..trade.Units.." cota(s)" else "Nenhuma operação ainda."
                row.Detail.Text = if trade then Format.money(trade.Total).." líquido • "..os.date("!%d/%m %H:%M UTC",trade.Time) else "Suas últimas 20 operações aparecem aqui."
            end
        else
            for _,sector in ipairs(MarketConfig.SectorOrder) do
                local row,holding,price = cards[sector],state.Investments[sector],state.Market.Prices[sector]
                local shares = if holding then holding.Shares else 0
                local pnl = shares*price-(if holding then holding.Cost else 0)
                row.Title.Text = MarketConfig.Sectors[sector].Name
                row.Detail.Text = shares.." cota(s) • valor "..Format.money(shares*price).."\nPreço: "..Format.money(price).." por cota"
                row.Pnl.Text = "Resultado aberto: "..(if pnl>=0 then "+" else "")..Format.money(pnl).." (antes da taxa de venda)"
                row.Pnl.TextColor3 = if pnl>=0 then theme.mint else theme.error
                local cost = math.ceil(price*lot*(1+MarketConfig.Fee)*100)/100
                local proceeds = math.floor(price*lot*(1-MarketConfig.Fee)*100)/100
                row.Buy.Text = "Comprar "..Format.money(cost); row.Sell.Text = "Vender "..Format.money(proceeds)
                enable(row.Buy,state.Cash>=cost and shares+lot<=MarketConfig.MaxShares); enable(row.Sell,shares>=lot)
            end
        end
    elseif tab=="Ranking" then
        for i,row in ipairs(cards) do
            local entry = state.Ranking[i]; row.Row.Visible=entry~=nil
            if entry then row.Title.Text="#"..i.."  "..entry.Name; row.Detail.Text=Format.money(entry.NetWorth).." • "..entry.Businesses.." negócios" end
        end
    else cards.Motion.Text=if state.Settings.ReducedMotion then "ATIVADO" else "DESATIVADO" end
end
remotes:WaitForChild("EmpireState").OnClientEvent:Connect(function(data)
    data.Market = data.Market or (state and state.Market); state=data
    stats[1].Text=Format.money(data.Cash); stats[2].Text=Format.money(data.NetWorth); stats[3].Text="+"..Format.money(data.Income)
    if os.clock()>=messageUntil then save.Text=data.SaveStatus; save.TextColor3=if data.Temporary then theme.gold else theme.muted end
    if not data.Market then action:FireServer("Sync"); return end
    news.Text="MARKET NEWS • "..data.Market.Name.." • "..math.max(0,data.Market.EndsAt-data.ServerTime).."s"
    render()
end)
remotes:WaitForChild("EmpireFeedback").OnClientEvent:Connect(function(ok,message,kind)
    messageUntil=os.clock()+3; local deadline=messageUntil
    feedback.Text=message; feedback.TextColor3=if ok then theme.mint else theme.error
    save.Text=message; save.TextColor3=feedback.TextColor3
    local folder=game:GetService("SoundService"):FindFirstChild("MoneyEmpireSounds")
    local sound=folder and folder:FindFirstChild(if not ok then "Error" elseif kind=="Buy" then "Purchase" elseif kind=="Upgrade" then "LevelUp" else "Cash")
    if sound and sound.SoundId~="" then sound:Play() end
    task.delay(3,function() if messageUntil==deadline then feedback.Text="" end end)
end)
Input.InputBegan:Connect(function(input,processed)
    if processed then return end
    if input.KeyCode==Enum.KeyCode.E then action:FireServer("Work") end
    if input.KeyCode==Enum.KeyCode.B then openMenu(not panel.Visible) end
end)
resize = function()
    if slide then slide:Cancel(); slide=nil end
    local d=UILayout.calculate(root.AbsoluteSize.X,root.AbsoluteSize.Y)
    header.Size=UDim2.fromOffset(d.HudWidth,d.HudHeight); dock.Size=UDim2.fromOffset(d.HudWidth,40)
    news.Size=UDim2.fromOffset(d.HudWidth,24); feedback.Size=UDim2.fromOffset(d.HudWidth,32)
    panel.Position=UDim2.fromOffset(d.PanelX,d.PanelY); panel.Size=UDim2.fromOffset(d.PanelWidth,d.PanelHeight)
    local short=d.PanelHeight<340; local h=if short then 30 else 36
    tabs.Size=UDim2.new(1,-20,0,if short then 68 else 80)
    for i,name in ipairs(tabNames) do
        tabButtons[name].Size=UDim2.new(1/3,-4,0,h)
        tabButtons[name].Position=UDim2.new(((i-1)%3)/3,2,0,math.floor((i-1)/3)*(h+4)+2)
    end
    scroll.Position=UDim2.fromOffset(10,if short then 138 else 150)
    scroll.Size=UDim2.new(1,-20,0,math.max(0,d.PanelHeight-(if short then 176 else 188)))
    for _,l in ipairs(stats) do l.TextSize=d.StatTextSize end
end
root:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize); resize()
action:FireServer("Sync")
