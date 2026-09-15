local Lighting = game:GetService("Lighting")
local Modules = game:GetService("ReplicatedStorage"):WaitForChild("Modules")
local Config = require(Modules.GameConfig)
local Economy = require(Modules.Economy)
local Format = require(Modules.NumberFormatter)
local Visual = require(Modules.BusinessVisual)
local World = { Plots = {} }
local colors = { ground = Color3.fromRGB(37, 56, 64), road = Color3.fromRGB(28, 34, 45), mint = Color3.fromRGB(94, 240, 186), white = Color3.fromRGB(235, 241, 239) }
local function part(parent, name, size, position, color, material)
    local p = Instance.new("Part")
    p.Name = name; p.Size = size; p.CFrame = if typeof(position)=="CFrame" then position else CFrame.new(position); p.Color = color
    p.Anchored = true; p.CanTouch=false; p.Material = material or Enum.Material.SmoothPlastic
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
    Lighting.ClockTime=16.4; Lighting.Brightness=2
    local atmosphere=Instance.new("Atmosphere"); atmosphere.Name="EmpireAtmosphere"; atmosphere.Density=0.22
    atmosphere.Color=Color3.fromRGB(210,226,238); atmosphere.Decay=Color3.fromRGB(119,141,166); atmosphere.Parent=Lighting
    local grade=Instance.new("ColorCorrectionEffect"); grade.Name="EmpireColor"; grade.Saturation=0.08; grade.Contrast=0.06; grade.Parent=Lighting
    local root = Instance.new("Folder"); root.Name = "MoneyEmpireWorld"; root.Parent = workspace
    World.Root = root
    part(root, "Ground", Vector3.new(740, 2, 430), Vector3.new(0, -2, 0), colors.ground, Enum.Material.Grass)
    part(root, "EmpireAvenue", Vector3.new(720, 0.3, 42), Vector3.new(0, -0.8, 0), colors.road)
    for x = -330, 330, 30 do part(root, "RoadMark", Vector3.new(12, 0.05, 0.7), Vector3.new(x, -0.6, 0), colors.white) end
    for _,z in ipairs({-30,30}) do
        part(root,"Sidewalk",Vector3.new(720,0.8,16),Vector3.new(0,-0.2,z),Color3.fromRGB(185,195,187),Enum.Material.Concrete)
        for x=-300,300,60 do
            part(root,"LampPost",Vector3.new(0.5,12,0.5),Vector3.new(x,6,z),colors.road,Enum.Material.Metal)
            part(root,"Lamp",Vector3.new(3,0.4,3),Vector3.new(x,12,z),Color3.fromRGB(255,220,150),Enum.Material.Neon)
            part(root,"TreeTrunk",Vector3.new(1,5,1),Vector3.new(x+16,2.5,z),Color3.fromRGB(126,94,68),Enum.Material.Wood)
            local crown=part(root,"TreeCrown",Vector3.new(7,7,7),Vector3.new(x+16,7,z),Color3.fromRGB(81,135,107))
            crown.Shape=Enum.PartType.Ball; crown.CanCollide=false
        end
    end
    local spawn = Instance.new("SpawnLocation"); spawn.Name = "Arrival"; spawn.Size = Vector3.new(10, 1, 10)
    spawn.Position = Vector3.new(0, 1, 0); spawn.Anchored = true; spawn.Neutral = true; spawn.Duration = 0; spawn.Transparency = 1; spawn.Parent = root
    sign(root, "MONEY EMPIRE\nFROM $1 TO BILLIONAIRE", Vector3.new(0, 22, 200), 80)
    for i = 1, Config.PlotCount do
        local side = if i <= 4 then -1 else 1
        local x = ((i - 1) % 4 - 1.5) * Config.PlotSpacing
        local origin = Vector3.new(x, 0, side * 100)
        local plotFrame=CFrame.new(origin)*CFrame.Angles(0,if side<0 then math.pi else 0,0)
        local model = Instance.new("Model"); model.Name = "Plot_" .. i; model.Parent = root
        part(model, "Foundation", Vector3.new(132, 1, 122), origin, Color3.fromRGB(62, 79, 89), Enum.Material.Concrete)
        part(model,"EntryGlow",Vector3.new(100,0.2,1),plotFrame*CFrame.new(0,0.7,-57),colors.mint,Enum.Material.Neon)
        part(model,"WelcomePlaza",Vector3.new(128,0.2,28),plotFrame*CFrame.new(0,0.7,-43),Color3.fromRGB(181,194,185),Enum.Material.Concrete)
        local label=sign(model,"TERRENO DISPONÍVEL",plotFrame*CFrame.new(-12,7,-58),50)
        for _,localX in ipairs({-36,-12,12,36}) do
            part(model,"PedestrianPath",Vector3.new(2,0.15,88),plotFrame*CFrame.new(localX,0.75,14),Color3.fromRGB(158,176,169),Enum.Material.Concrete)
        end
        local content = Instance.new("Folder"); content.Name = "Businesses"; content.Parent = model
        local vault=Instance.new("Folder"); vault.Name="Vault"; vault.Parent=model
        local terminal=part(model,"ManagementTerminal",Vector3.new(4,4,3),plotFrame*CFrame.new(-45,2.8,-43),colors.road,Enum.Material.Metal)
        part(model,"TerminalScreen",Vector3.new(3,2,0.2),plotFrame*CFrame.new(-45,3.4,-44.6),colors.mint,Enum.Material.Neon)
        local prompt=Instance.new("ProximityPrompt"); prompt.ActionText="Gerenciar negócios"; prompt.ObjectText="Seu império"
        prompt.KeyboardKeyCode=Enum.KeyCode.F; prompt.MaxActivationDistance=10; prompt.RequiresLineOfSight=false; prompt.Enabled=false; prompt.Parent=terminal
        local plot={Model=model,Content=content,Vault=vault,Origin=origin,Frame=plotFrame,Label=label,Owner=nil,Levels={},VaultTier=-1,Prompt=prompt}
        prompt.Triggered:Connect(function(player)
            local hrp=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if plot.Owner==player and hrp and (hrp.Position-terminal.Position).Magnitude<=12 and World.OnInteract then World.OnInteract(player,"OpenBusinesses") end
        end)
        World.Plots[i]=plot
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
            plot.Prompt.Enabled=true
            plot.Prompt.ObjectText=player.DisplayName.." • negócios"
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
    if plot and player.Character then player.Character:PivotTo(plot.Frame*CFrame.new(0,5,-44)*CFrame.Angles(0,math.pi,0)) end
end
function World.release(player)
    local plot = World.find(player)
    if plot then
        plot.Owner=nil; plot.Levels={}; plot.VaultTier=-1; plot.Content:ClearAllChildren(); plot.Vault:ClearAllChildren(); plot.Prompt.Enabled=false
        plot.Model:SetAttribute("OwnerUserId", nil); plot.Label.Text = "TERRENO DISPONÍVEL"
    end
end
function World.refresh(player, profile, prices)
    local plot = World.find(player)
    if not plot then return end
    plot.Label.Text = player.DisplayName .. "  •  " .. Economy.title(profile, prices) .. "\n" .. Format.money(Economy.netWorth(profile, prices))
    local vaultTier = math.clamp(math.floor(math.log10(math.max(1, profile.Cash))), 0, 12)
    for index, id in ipairs(Config.BusinessOrder) do
        local owned = profile.Businesses[id]
        if owned and plot.Levels[id]~=owned.Level then
            local previous=plot.Content:FindFirstChild(id); if previous then previous:Destroy() end
            local c = Config.Businesses[id]
            local model=Visual.build(plot.Content,id,owned.Level)
            local base=plot.Frame*CFrame.new(-48+((index-1)%5)*24,0.7,-18+math.floor((index-1)/5)*30)
            model:PivotTo(base)
            sign(model,c.Name.."\nNv. "..owned.Level,base*CFrame.new(0,3,-10.5),18)
            plot.Levels[id]=owned.Level
        elseif not owned and plot.Levels[id] then
            local previous=plot.Content:FindFirstChild(id); if previous then previous:Destroy() end
            plot.Levels[id]=nil
        end
    end
    if plot.VaultTier~=vaultTier then
        plot.VaultTier=vaultTier; plot.Vault:ClearAllChildren()
        local vault=plot.Frame*CFrame.new(46,2.5,-44)
        part(plot.Vault,"Safe",Vector3.new(14,4,9),vault,colors.road,Enum.Material.Metal)
        for i=1,vaultTier do
            part(plot.Vault,"Gold",Vector3.new(2.5,1,2),vault*CFrame.new(-4+((i-1)%4)*2.7,2.5+math.floor((i-1)/4),0),Color3.fromRGB(255,208,88),Enum.Material.Metal)
        end
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
