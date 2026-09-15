local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Config = require(Modules.GameConfig)
local Economy = require(Modules.Economy)
local Format = require(Modules.NumberFormatter)
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local action = remotes:WaitForChild("EmpireAction")
local theme = {
    background = Color3.fromRGB(14, 23, 34), panel = Color3.fromRGB(24, 37, 50),
    card = Color3.fromRGB(32, 48, 62), muted = Color3.fromRGB(152, 174, 189),
    white = Color3.fromRGB(238, 245, 248), mint = Color3.fromRGB(107, 241, 184),
    gold = Color3.fromRGB(255, 211, 123), error = Color3.fromRGB(255, 140, 144),
}
local gui = Instance.new("ScreenGui"); gui.Name = "MoneyEmpireUI"; gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.Parent = player:WaitForChild("PlayerGui")
local function rounded(object, radius)
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, radius or 12); corner.Parent = object
end
local function frame(parent, size, position, color)
    local f = Instance.new("Frame"); f.Size = size; f.Position = position; f.BackgroundColor3 = color or theme.panel
    f.BorderSizePixel = 0; f.Parent = parent; rounded(f); return f
end
local function label(parent, text, size, position, fontSize, color)
    local l = Instance.new("TextLabel"); l.Size = size; l.Position = position; l.BackgroundTransparency = 1
    l.Text = text; l.TextColor3 = color or theme.white; l.Font = Enum.Font.GothamMedium
    l.TextSize = fontSize or 14; l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextTruncate = Enum.TextTruncate.AtEnd; l.Parent = parent; return l
end
local function button(parent, text, size, position, callback, color)
    local b = Instance.new("TextButton"); b.Size = size; b.Position = position; b.BackgroundColor3 = color or theme.mint
    b.Text = text; b.TextSize = 14; b.Font = Enum.Font.GothamBold; b.TextColor3 = theme.background
    b.BorderSizePixel = 0; b.AutoButtonColor = true; b.Parent = parent; rounded(b, 10)
    b.Activated:Connect(callback); return b
end
local header = frame(gui, UDim2.new(1, -24, 0, 112), UDim2.fromOffset(12, 8), theme.background)
label(header, "MONEY EMPIRE", UDim2.new(0.65, 0, 0, 27), UDim2.fromOffset(14, 7), 19, theme.mint).Font = Enum.Font.GothamBlack
local edition = label(header, "FROM $1 TO BILLIONAIRE", UDim2.new(0.65, 0, 0, 16), UDim2.fromOffset(14, 34), 10, theme.muted)
local homeButton = button(header, "Meu terreno", UDim2.fromOffset(108, 36), UDim2.new(1, -120, 0, 9), function() action:FireServer("Home") end, theme.gold)
local statLabels = {}
for i, name in ipairs({ "DINHEIRO", "PATRIMÔNIO", "RENDA / SEG" }) do
    local cell = frame(header, UDim2.new(1 / 3, -12, 0, 48), UDim2.new((i - 1) / 3, 8, 0, 56), theme.panel)
    label(cell, name, UDim2.new(1, -12, 0, 15), UDim2.fromOffset(8, 4), 9, theme.muted)
    statLabels[i] = label(cell, "—", UDim2.new(1, -12, 0, 25), UDim2.fromOffset(8, 19), 20, if i == 3 then theme.mint else theme.white)
end
local panel = frame(gui, UDim2.fromOffset(440, 470), UDim2.fromOffset(12, 206), theme.background)
local heading = label(panel, "Seu próximo grande passo", UDim2.new(1, -55, 0, 27), UDim2.fromOffset(14, 10), 18)
button(panel, "×", UDim2.fromOffset(32, 32), UDim2.new(1, -42, 0, 8), function() panel.Visible = false end, theme.gold)
local hint = label(panel, "Trabalhe 5 vezes e inaugure Água gelada.", UDim2.new(1, -28, 0, 23), UDim2.fromOffset(14, 40), 12, theme.muted)
local tabs = frame(panel, UDim2.new(1, -24, 0, 38), UDim2.fromOffset(12, 72), theme.panel)
local scroll = Instance.new("ScrollingFrame"); scroll.Name = "Content"; scroll.Size = UDim2.new(1, -20, 1, -126)
scroll.Position = UDim2.fromOffset(10, 118); scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4; scroll.ScrollBarImageColor3 = theme.mint; scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new(); scroll.Parent = panel
local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 8); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = scroll
local padding = Instance.new("UIPadding"); padding.PaddingBottom = UDim.new(0, 8); padding.Parent = scroll
-- Keep the bottom of the screen free for Roblox's touch joystick and jump button.
local footer = frame(gui, UDim2.new(1, -24, 0, 69), UDim2.fromOffset(12, 126), theme.background)
local menuButton = button(footer, "Negócios", UDim2.new(0.35, -12, 0, 42), UDim2.fromOffset(9, 8), function() panel.Visible = not panel.Visible end, theme.gold)
local workButton = button(footer, "TRABALHAR  +$2", UDim2.new(0.65, -15, 0, 42), UDim2.new(0.35, 4, 0, 8), function() action:FireServer("Work") end)
local saveLabel = label(footer, "Conectando ao servidor…", UDim2.new(1, -20, 0, 14), UDim2.fromOffset(10, 52), 9, theme.muted)
local toast = frame(gui, UDim2.new(0.8, 0, 0, 48), UDim2.new(0.1, 0, 0, 132), theme.mint)
toast.Visible = false; toast.ZIndex = 10
local toastLabel = label(toast, "", UDim2.new(1, -24, 1, 0), UDim2.fromOffset(12, 0), 14, theme.background)
toastLabel.TextWrapped = true; toastLabel.TextTruncate = Enum.TextTruncate.None; toastLabel.ZIndex = 11
local snapshot, activeTab, signature = nil, "Negócios", ""
local cards, tabButtons = {}, {}
local render
for i, name in ipairs({ "Negócios", "Coleção", "Ranking", "Ajustes" }) do
    tabButtons[name] = button(tabs, name, UDim2.new(0.25, -4, 1, -6), UDim2.new((i - 1) * 0.25, 2, 0, 3), function()
        activeTab = name; signature = ""; if snapshot then render() end
    end, theme.card)
    tabButtons[name].TextColor3 = theme.white; tabButtons[name].TextSize = 12
end
local function clear()
    cards = {}
    for _, child in ipairs(scroll:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
end
local function card(height)
    return frame(scroll, UDim2.new(1, -7, 0, height), UDim2.new(), theme.card)
end
render = function()
    if not snapshot then return end
    for name, b in pairs(tabButtons) do
        b.BackgroundColor3 = if name == activeTab then theme.mint else theme.card
        b.TextColor3 = if name == activeTab then theme.background else theme.white
    end
    heading.Text = if activeTab == "Negócios" then "Seu próximo grande passo" else activeTab
    local count = 0
    for _ in pairs(snapshot.Collection) do count += 1 end
    hint.Text = if activeTab == "Coleção" then count .. " / " .. #Config.BusinessOrder .. " negócios descobertos"
        elseif activeTab == "Ranking" then "Top 10 deste servidor • por patrimônio"
        elseif activeTab == "Ajustes" then "Personalize sua experiência."
        elseif not snapshot.Businesses.Water then "Trabalhe 5 vezes e inaugure Água gelada."
        else "A renda cai direto na sua conta. Continue expandindo!"
    if signature ~= activeTab then
        signature = activeTab; clear()
        if activeTab == "Negócios" or activeTab == "Coleção" then
            for index, id in ipairs(Config.BusinessOrder) do
                local c = Config.Businesses[id]
                local row = card(if activeTab == "Negócios" then 122 else 74); row.LayoutOrder = index
                local stripe = frame(row, UDim2.new(0, 4, 1, -16), UDim2.fromOffset(0, 8), Color3.fromRGB(unpack(c.Color)))
                local title = label(row, c.Name, UDim2.new(1, -22, 0, 25), UDim2.fromOffset(14, 7), 16)
                local detail = label(row, "", UDim2.new(1, -24, 0, 23), UDim2.fromOffset(14, 32), 11, theme.muted)
                local info = label(row, "", UDim2.new(0.5, -10, 0, 44), UDim2.fromOffset(14, 65), 13, theme.mint)
                info.TextWrapped = true; info.TextTruncate = Enum.TextTruncate.None
                local buy
                if activeTab == "Negócios" then
                    buy = button(row, "", UDim2.new(0.5, -18, 0, 44), UDim2.new(0.5, 4, 0, 66), function()
                        if snapshot then action:FireServer(if snapshot.Businesses[id] then "Upgrade" else "Buy", id) end
                    end)
                else info.Visible = false end
                cards[id] = { Title = title, Detail = detail, Info = info, Button = buy, Stripe = stripe }
            end
        elseif activeTab == "Ajustes" then
            local row = card(110)
            label(row, "Movimento reduzido", UDim2.new(1, -24, 0, 25), UDim2.fromOffset(12, 8), 16)
            cards.Motion = button(row, "", UDim2.new(1, -24, 0, 44), UDim2.fromOffset(12, 49), function()
                action:FireServer("ReducedMotion", not snapshot.Settings.ReducedMotion)
            end)
            local about = card(122)
            local text = label(about, "MVP • renda automática gratuita\nPatrimônio = saldo + 70% do capital aplicado.\nColeção registra suas descobertas.\nMoeda fictícia. Sem compras com Robux nesta versão.", UDim2.new(1, -24, 1, -16), UDim2.fromOffset(12, 8), 12, theme.muted)
            text.TextWrapped = true; text.TextTruncate = Enum.TextTruncate.None
        end
    end
    if activeTab == "Negócios" or activeTab == "Coleção" then
        for _, id in ipairs(Config.BusinessOrder) do
            local c, row, owned = Config.Businesses[id], cards[id], snapshot.Businesses[id]
            local discovered = snapshot.Collection[id]
            local unlocked = Economy.unlocked(snapshot, id)
            row.Title.Text = if activeTab == "Coleção" and not discovered then "? ? ?   •   Não descoberto" else c.Name
            row.Stripe.BackgroundColor3 = if activeTab == "Coleção" and not discovered then theme.muted else Color3.fromRGB(unpack(c.Color))
            row.Detail.Text = if activeTab == "Coleção" and not discovered then "Explore a sequência de negócios para revelar."
                else c.Rarity .. "  •  " .. c.Category .. (if owned then "  •  Nv. " .. owned.Level .. "/" .. c.MaxLevel else "")
            if row.Button then
                local maxed = owned and owned.Level >= c.MaxLevel
                local cost = if owned then Economy.upgradeCost(id, owned) else c.Price
                row.Info.Text = "+" .. Format.money(if owned then Economy.incomeFor(id, owned) else c.Income) .. "/s"
                row.Button.Text = if maxed then "NÍVEL MÁXIMO" elseif not unlocked then "BLOQUEADO" else (if owned then "Upgrade " else "Comprar ") .. Format.money(cost)
                row.Button.BackgroundColor3 = if maxed or not unlocked or snapshot.Cash < cost then theme.panel else theme.mint
                row.Button.TextColor3 = if maxed or not unlocked or snapshot.Cash < cost then theme.muted else theme.background
                row.Button.Active = not maxed and unlocked
            end
        end
    elseif activeTab == "Ranking" then
        clear()
        for i, entry in ipairs(snapshot.Ranking) do
            local row = card(74); row.LayoutOrder = i
            label(row, "#" .. i .. "  " .. entry.Name, UDim2.new(1, -24, 0, 28), UDim2.fromOffset(12, 7), 15, if i == 1 then theme.gold else theme.white)
            label(row, Format.money(entry.NetWorth) .. "  •  " .. entry.Businesses .. " negócios", UDim2.new(1, -24, 0, 22), UDim2.fromOffset(12, 39), 13, theme.muted)
        end
    elseif activeTab == "Ajustes" then
        cards.Motion.Text = if snapshot.Settings.ReducedMotion then "ATIVADO" else "DESATIVADO"
    end
end
remotes:WaitForChild("EmpireState").OnClientEvent:Connect(function(data)
    snapshot = data
    statLabels[1].Text = Format.money(data.Cash); statLabels[2].Text = Format.money(data.NetWorth)
    statLabels[3].Text = "+" .. Format.money(data.Income)
    saveLabel.Text = data.SaveStatus; saveLabel.TextColor3 = if data.Temporary then theme.gold else theme.muted
    render()
end)
local toastId = 0
remotes:WaitForChild("EmpireFeedback").OnClientEvent:Connect(function(ok, message, kind)
    toastId += 1; local current = toastId
    toast.Visible = true; toast.BackgroundColor3 = if ok then theme.mint else theme.error
    toastLabel.Text = message
    local folder = game:GetService("SoundService"):FindFirstChild("MoneyEmpireSounds")
    local sound = folder and folder:FindFirstChild(if not ok then "Error" elseif kind == "Buy" then "Purchase" elseif kind == "Upgrade" then "LevelUp" else "Cash")
    if sound and sound.SoundId ~= "" then sound:Play() end
    if snapshot and not snapshot.Settings.ReducedMotion then
        toast.Position = UDim2.new(0.1, 0, 0, 140)
        TweenService:Create(toast, TweenInfo.new(0.18), { Position = UDim2.new(0.1, 0, 0, 126) }):Play()
    end
    task.delay(if kind == "Work" then 0.6 else 2.5, function() if toastId == current then toast.Visible = false end end)
end)
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.E then action:FireServer("Work") end
    if not processed and input.KeyCode == Enum.KeyCode.B then panel.Visible = not panel.Visible end
end)
local function resize()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    local small = viewport.X < 700
    local width = if small then viewport.X - 24 else 440
    local height = math.max(150, math.min(490, viewport.Y - 370))
    panel.Size = UDim2.fromOffset(width, height)
    if small and viewport.Y < 520 then panel.Visible = false end
    for _, l in ipairs(statLabels) do l.TextSize = if viewport.X < 380 then 16 else 20 end
    edition.TextSize = if viewport.X < 380 then 8 else 10
end
local cameraConnection
local function bindCamera()
    if cameraConnection then cameraConnection:Disconnect() end
    if workspace.CurrentCamera then cameraConnection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
    resize()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera); bindCamera()
action:FireServer("Sync")
