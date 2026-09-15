-- Original low-poly architecture. Pure data makes scale and part budgets testable.
local Config = require(if script then script.Parent.GameConfig else "./GameConfig")
local Blueprint = {}
function Blueprint.build(id, level)
    local c = Config.Businesses[id]
    assert(c, "Unknown business")
    level = math.clamp(math.floor(level), 1, c.MaxLevel)
    local parts = {}
    local dark, cream, glass = {31,45,58}, {231,225,203}, {132,201,218}
    local function add(name, size, position, color, material, shape)
        table.insert(parts, {Name=name, Size=size, Position=position, Color=color, Material=material or "SmoothPlastic", Shape=shape or "Block"})
    end
    add("Foundation", {21,0.6,22}, {0,0.3,0}, cream, "Concrete")
    local height
    if c.Model == "Stand" then
        height = 9
        add("Counter",{15,3,8},{0,2.1,1},c.Color)
        add("CounterTop",{16,0.5,9},{0,3.85,1},cream)
        for _,x in ipairs({-7,7}) do add("AwningPost",{0.5,5,0.5},{x,6,4},dark,"Wood") end
        for i=1,4 do add("StripedAwning",{4,0.6,11},{-10+i*4,8.7,0},if i%2==0 then cream else c.Color) end
        if id=="Water" then
            for i=1,3 do add("WaterBottle",{1,2,1},{-4+i*2,5,0},glass,"Glass") end
            add("IceBox",{3,2,3},{5,4.8,1},cream)
        elseif id=="FoodCart" then
            add("Grill",{6,0.6,4},{0,4.4,1},dark,"Metal")
            for _,x in ipairs({-6,6}) do add("CartWheel",{2,2,2},{x,1.7,-3.5},dark,"SmoothPlastic","Ball") end
            add("FoodTray",{3,0.6,2},{5,4.4,0},{235,168,76})
        else
            add("Pitcher",{2,3,2},{0,5.6,1},{245,215,87},"Glass")
            for i=1,3 do add("Lemon",{1,1,1},{-6+i*1.5,4.6,-1},{245,220,81},nil,"Ball") end
        end
    elseif c.Model == "Shop" then
        height = 14 + math.floor((level-1)/3)*2
        add("ShopBody",{18,height,17},{0,height/2+0.6,1},cream,"Concrete")
        add("Storefront",{15,7,0.2},{0,4.4,-7.6},glass,"Glass")
        add("Door",{3,7,0.3},{0,4.2,-7.8},dark,"Glass")
        for _,x in ipairs({-7.5,-2,2,7.5}) do add("Frame",{0.3,7.3,0.3},{x,4.4,-7.9},dark,"Metal") end
        add("BrandBand",{19,2.5,1},{0,9.5,-8},c.Color)
        add("Canopy",{20,0.7,5},{0,8,-7.5},c.Color)
        add("Roof",{20,0.8,20},{0,height+1,1},dark)
        if id=="Coffee" then
            add("CupIcon",{2.5,3,2.5},{0,height+3,1},cream)
            add("CupHandle",{1.5,1.5,1},{1.7,height+3,1},cream)
        elseif id=="Restaurant" then
            for _,x in ipairs({-5,5}) do add("TerracePlanter",{3,1.5,2},{x,1.3,-9.5},c.Color); add("Greenery",{2.5,1.4,1.6},{x,2.6,-9.5},{95,149,107}) end
        else
            add("RoofSign",{12,3,1},{0,height+2.6,-5},c.Color)
            add("StockCrate",{3,2,3},{7,1.6,-9},dark,"Wood")
        end
    elseif id=="Factory" then
        height = 22
        add("Warehouse",{19,12,18},{0,6.6,0},c.Color,"Concrete")
        add("Roof",{21,1,20},{0,13,0},dark,"Metal")
        add("LoadingDoor",{9,8,0.3},{-3,4.6,-9.2},dark,"Metal")
        add("OfficeWindow",{5,3,0.3},{6,7,-9.2},glass,"Glass")
        for _,x in ipairs({-6,6}) do add("Chimney",{2,8,2},{x,17,5},cream,"Metal"); add("ChimneyCap",{3,1,3},{x,21.5,5},dark) end
    else
        local index = table.find(Config.BusinessOrder,id)
        height = 22 + index*2 + math.floor((level-1)/3)*4
        add("Podium",{20,5,20},{0,3.1,0},cream,"Concrete")
        add("Tower",{16,height-5,16},{0,5.6+(height-5)/2,1},dark,"Concrete")
        local floors=math.min(6,math.floor(height/6))
        for floor=1,floors do
            local y = 7 + (floor-1)*(height-8)/floors
            add("FrontGlass",{14,3.5,0.2},{0,y,-7.1},glass,"Glass")
            add("SideGlass",{0.2,3.5,14},{8.1,y,1},glass,"Glass")
        end
        for _,x in ipairs({-7.5,7.5}) do add("FacadeFin",{0.5,height-2,0.5},{x,height/2+1,-7.4},c.Color,"Metal") end
        add("Crown",{18,1,18},{0,height+1.2,1},c.Color,"Metal")
        add("Lobby",{7,4,0.3},{0,2.6,-10.1},glass,"Glass")
        if id=="Space" then
            add("Observatory",{7,7,7},{0,height+5,1},c.Color,"Neon","Ball")
            add("Antenna",{0.6,5,0.6},{0,height+10,1},cream,"Metal")
        elseif id=="Bank" then
            for _,x in ipairs({-8,8}) do add("Column",{1.5,5,1.5},{x,3.1,-9},cream) end
        else
            add("RoofGarden",{10,0.8,8},{0,height+2,1},{80,138,112},"Grass")
            add("RoofCore",{5,3,5},{3,height+3,3},c.Color)
        end
    end
    add("LevelAccent",{level*1.5,0.3,0.3},{0,1,-10.8},c.Color,"Neon")
    return { Parts=parts, Height=height+14, Level=level, Name=c.Name }
end
return Blueprint
