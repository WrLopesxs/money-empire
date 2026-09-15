local Blueprint = require(script.Parent.BusinessBlueprint)
local Visual = {}
function Visual.build(parent,id,level)
    local plan = Blueprint.build(id,level)
    local model = Instance.new("Model"); model.Name=id
    for _,item in ipairs(plan.Parts) do
        local p=Instance.new("Part"); p.Name=item.Name
        p.Size=Vector3.new(unpack(item.Size)); p.CFrame=CFrame.new(unpack(item.Position))
        p.Color=Color3.fromRGB(unpack(item.Color)); p.Material=Enum.Material[item.Material]; p.Shape=Enum.PartType[item.Shape]
        p.Anchored=true; p.CanTouch=false; p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
        p.Parent=model
    end
    -- Explicit origin: PivotTo must not use the bounding-box center of a tall tower.
    model.WorldPivot=CFrame.new(); model.Parent=parent
    return model,plan.Height
end
return Visual
