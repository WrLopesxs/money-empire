local Config=require("../src/shared/GameConfig")
local Economy=require("../src/shared/Economy")
local UX=require("../src/shared/UXModel")
local Blueprint=require("../src/shared/BusinessBlueprint")
local Format=require("../src/shared/NumberFormatter")
local count=0
local function test(name,run)
    local ok,err=pcall(run); if not ok then error("FAIL "..name..": "..tostring(err)) end
    count+=1; print("PASS "..name)
end
test("guide starts with an affordable path from one dollar",function()
    local p=Economy.newProfile(); local g=UX.guide(p)
    assert(g.Step==1 and g.Kind=="Buy" and g.Id=="Water" and not g.Ready)
    assert(g.Remaining==9 and g.Progress==0.1)
    for _=1,5 do Economy.work(p) end
    assert(UX.guide(p).Ready and UX.guide(p).Progress==1)
end)
test("guide follows existing progress and retires after the third milestone",function()
    local p=Economy.newProfile(); p.Cash=1000; Economy.buy(p,"Water")
    assert(UX.guide(p).Step==2)
    Economy.upgrade(p,"Water"); assert(UX.guide(p).Step==3)
    Economy.buy(p,"FoodCart"); assert(UX.guide(p)==nil)
end)
test("catalog exposes owned businesses and the next unlock",function()
    local p=Economy.newProfile(); assert(UX.nextBusiness(p)=="Water")
    assert(UX.visibleBusiness(p,"Water",false)); assert(not UX.visibleBusiness(p,"Space",false))
    p.Cash=100; Economy.buy(p,"Water")
    assert(UX.visibleBusiness(p,"Water",false) and UX.visibleBusiness(p,"FoodCart",false))
    assert(UX.visibleBusiness(p,"Space",true))
end)
test("completed catalog has no missing next business",function()
    local p=Economy.newProfile(); p.Cash=1e30
    for _,id in ipairs(Config.BusinessOrder) do assert(Economy.buy(p,id)) end
    assert(UX.nextBusiness(p)==nil)
end)
test("all 150 building levels obey geometry and part budgets",function()
    local materials={SmoothPlastic=true,Concrete=true,Metal=true,Wood=true,Glass=true,Grass=true,Neon=true}
    for _,id in ipairs(Config.BusinessOrder) do
        for level=1,10 do
            local model=Blueprint.build(id,level)
            assert(#model.Parts<=30 and model.Level==level)
            for _,part in ipairs(model.Parts) do
                assert(materials[part.Material] and (part.Shape=="Block" or part.Shape=="Ball"))
                for axis=1,3 do assert(part.Size[axis]>0 and part.Size[axis]<100 and part.Position[axis]==part.Position[axis]) end
                assert(math.abs(part.Position[1])+part.Size[1]/2<=11)
                assert(math.abs(part.Position[3])+part.Size[3]/2<=11)
                assert(part.Position[2]-part.Size[2]/2>=-0.001)
                assert(part.Position[2]+part.Size[2]/2<=model.Height)
            end
        end
    end
end)
test("architecture categories have distinct silhouettes",function()
    local water=Blueprint.build("Water",1); local cafe=Blueprint.build("Coffee",1); local tower=Blueprint.build("Tower",1)
    assert(water.Height<cafe.Height and cafe.Height<tower.Height)
    assert(Blueprint.build("Tower",10).Height>tower.Height)
    assert(Blueprint.build("Water",10).Parts[#water.Parts].Size[1]>water.Parts[#water.Parts].Size[1])
end)
test("money shown in confirmations preserves cents",function()
    assert(Format.preciseMoney(20.4)=="$20.40")
    assert(Format.preciseMoney(2040)=="$2040.00")
    assert(Format.preciseMoney(-1.25)=="-$1.25")
end)
print("\n"..count.." UX/model tests passed.")
