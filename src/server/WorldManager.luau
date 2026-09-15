local Players = game:GetService("Players")
local Modules = game:GetService("ReplicatedStorage"):WaitForChild("Modules")
local Config = require(Modules.GameConfig)
local Economy = require(Modules.Economy)
local Format = require(Modules.NumberFormatter)
local World = { Plots = {} }
local colors = { ground = Color3.fromRGB(37, 56, 64), road = Color3.fromRGB(28, 34, 45), mint = Color3.fromRGB(94, 240, 186), white = Color3.fromRGB(235, 241, 239) }
local function part(parent, name, size, position, color, material)
    local p = Instance.new("Part")
    p.Name = name; p.Size = size; p.Position = position; p.Color = color
    p.Anchored = true; p.Material = material or Enum.Material.SmoothPlastic
    p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end
local function sign(parent, text, position, width)
    local anchor = part(parent, "Sign", Vector3.new(width or 28, 6, 0.5), position, colors.road)
    local gui = Instance.new("SurfaceGui"); gui.Face = Enum.NormalId.Front; gui.CanvasSize = Vector2.new(800, 160); gui.Parent = anchor
    local label = Instance.new("TextLabel"); label.Size = UDim2.fromScale(1, 1); label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold; label.TextColor3 = colors.white; label.TextScaled = true; label.Text = text; label.Parent = gui
    return label
end
function World.init()
    local root = Instance.new("Folder"); root.Name = "MoneyEmpireWorld"; root.Parent = workspace
    World.Root = root
    part(root, "Ground", Vector3.new(740, 2, 430), Vector3.new(0, -2, 0), colors.ground, Enum.Material.Grass)
    part(root, "EmpireAvenue", Vector3.new(720, 0.3, 42), Vector3.new(0, -0.8, 0), colors.road)
    for x = -330, 330, 30 do part(root, "RoadMark", Vector3.new(12, 0.05, 0.7), Vector3.new(x, -0.6, 0), colors.white) end
    local spawn = Instance.new("SpawnLocation"); spawn.Name = "Arrival"; spawn.Size = Vector3.new(10, 1, 10)
    spawn.Position = Vector3.new(0, 1, 0); spawn.Anchored = true; spawn.Neutral = true; spawn.Duration = 0; spawn.Transparency = 1; spawn.Parent = root
    sign(root, "MONEY EMPIRE\nFROM $1 TO BILLIONAIRE", Vector3.new(0, 22, 200), 80)
    for i = 1, Config.PlotCount do
        local side = if i <= 4 then -1 else 1
        local x = ((i - 1) % 4 - 1.5) * Config.PlotSpacing
        local origin = Vector3.new(x, 0, side * 100)
        local model = Instance.new("Model"); model.Name = "Plot_" .. i; model.Parent = root
        part(model, "Foundation", Vector3.new(132, 1, 122), origin, Color3.fromRGB(62, 79, 89), Enum.Material.Concrete)
        part(model, "EntryGlow", Vector3.new(100, 0.2, 1), origin + Vector3.new(0, 0.7, -57), colors.mint, Enum.Material.Neon)
        local label = sign(model, "TERRENO DISPONÍVEL", origin + Vector3.new(0, 7, -58), 65)
        local content = Instance.new("Folder"); content.Name = "Businesses"; content.Parent = model
        World.Plots[i] = { Model = model, Content = content, Origin = origin, Label = label, Owner = nil, Signature = "" }
    end
    -- Low cost skyline: decorative anchored geometry, no free physics objects.
    for i = 1, 18 do
        local height = 18 + (i * 17) % 70
        part(root, "Skyline", Vector3.new(22, height, 18), Vector3.new(-350 + i * 37, height / 2, 190), Color3.fromRGB(48 + i % 3 * 8, 65, 87))
    end
end
function World.assign(player)
    for _, plot in ipairs(World.Plots) do
        if not plot.Owner then
            plot.Owner = player; plot.Model:SetAttribute("OwnerUserId", player.UserId)
            return plot
        end
    end
    return nil
end
function World.find(player)
    for _, plot in ipairs(World.Plots) do if plot.Owner == player then return plot end end
    return nil
end
function World.teleport(player)
    local plot = World.find(player)
    if plot and player.Character then player.Character:PivotTo(CFrame.new(plot.Origin + Vector3.new(0, 5, -44))) end
end
function World.release(player)
    local plot = World.find(player)
    if plot then
        plot.Owner = nil; plot.Signature = ""; plot.Content:ClearAllChildren()
        plot.Model:SetAttribute("OwnerUserId", nil); plot.Label.Text = "TERRENO DISPONÍVEL"
    end
end
function World.refresh(player, profile, prices)
    local plot = World.find(player)
    if not plot then return end
    plot.Label.Text = player.DisplayName .. "  •  " .. Economy.title(profile, prices) .. "\n" .. Format.money(Economy.netWorth(profile, prices))
    local signature = ""
    for _, id in ipairs(Config.BusinessOrder) do
        local owned = profile.Businesses[id]
        if owned then signature ..= id .. owned.Level .. ";" end
    end
    local vaultTier = math.clamp(math.floor(math.log10(math.max(1, profile.Cash))), 0, 12)
    signature ..= vaultTier
    if plot.Signature == signature then return end
    plot.Signature = signature; plot.Content:ClearAllChildren()
    local count = 0
    for index, id in ipairs(Config.BusinessOrder) do
        local owned = profile.Businesses[id]
        if owned then
            count += 1
            local c = Config.Businesses[id]
            local color = Color3.fromRGB(unpack(c.Color))
            local position = plot.Origin + Vector3.new(-48 + ((index - 1) % 5) * 24, 0.7, -18 + math.floor((index - 1) / 5) * 30)
            local model = Instance.new("Model"); model.Name = id; model.Parent = plot.Content
            local height = if c.Model == "Stand" then 5 elseif c.Model == "Shop" then 10 else 16 + index * 2 + owned.Level
            part(model, "Building", Vector3.new(18, height, 20), position + Vector3.new(0, height / 2, 0), color)
            part(model, "Roof", Vector3.new(20, 0.8, 22), position + Vector3.new(0, height + 0.4, 0), colors.road)
            local rows = math.min(6, math.floor(height / 5))
            for row = 1, rows do
                part(model, "Windows", Vector3.new(14, 2, 0.15), position + Vector3.new(0, row * 4 - 1, -10.1), Color3.fromRGB(161, 225, 245), Enum.Material.Glass)
            end
            sign(model, c.Name .. "\nNv. " .. owned.Level, position + Vector3.new(0, height + 3, -10), 20)
            if c.Rarity == "Secret" then part(model, "CosmicCrown", Vector3.new(5, 8, 5), position + Vector3.new(0, height + 5, 0), color, Enum.Material.Neon) end
        end
    end
    local vault = plot.Origin + Vector3.new(46, 2.5, -44)
    part(plot.Content, "Vault", Vector3.new(14, 4, 9), vault, colors.road, Enum.Material.Metal)
    for i = 1, vaultTier do
        part(plot.Content, "Gold", Vector3.new(2.5, 1, 2), vault + Vector3.new(-4 + ((i - 1) % 4) * 2.7, 2.5 + math.floor((i - 1) / 4), 0), Color3.fromRGB(255, 208, 88), Enum.Material.Metal)
    end
end
function World.updateTag(player, profile, prices)
    local head = player.Character and player.Character:FindFirstChild("Head")
    if not head then return end
    local gui = head:FindFirstChild("EmpireTag")
    if not gui then
        gui = Instance.new("BillboardGui"); gui.Name = "EmpireTag"; gui.Size = UDim2.fromOffset(230, 65)
        gui.StudsOffset = Vector3.new(0, 3, 0); gui.MaxDistance = 90; gui.Parent = head
        local label = Instance.new("TextLabel"); label.Name = "Label"; label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1; label.TextColor3 = colors.white; label.TextStrokeTransparency = 0.4
        label.Font = Enum.Font.GothamBold; label.TextSize = 15; label.Parent = gui
    end
    gui.Label.Text = player.DisplayName .. "\n" .. Format.money(Economy.netWorth(profile, prices)) .. " • " .. Economy.title(profile, prices)
end
return World
