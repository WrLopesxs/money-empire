local Config = require(if script then script.Parent.GameConfig else "./GameConfig")
local Economy = require(if script then script.Parent.Economy else "./Economy")
local UX = {}
function UX.nextBusiness(profile)
    for _,id in ipairs(Config.BusinessOrder) do if not profile.Businesses[id] then return id end end
    return nil
end
function UX.guide(profile)
    local water = profile.Businesses.Water
    local id,kind,target,title,step
    if not water then
        id="Water"; kind="Buy"; target=Config.Businesses.Water.Price; title="Abra sua primeira barraca"; step=1
    elseif water.Level==1 then
        id="Water"; kind="Upgrade"; target=Economy.upgradeCost(id,water); title="Melhore sua renda automática"; step=2
    elseif not profile.Businesses.FoodCart then
        id="FoodCart"; kind="Buy"; target=Config.Businesses.FoodCart.Price; title="Expanda para o carrinho de comida"; step=3
    else return nil end
    return {Id=id,Kind=kind,Target=target,Title=title,Step=step,Ready=profile.Cash>=target,
        Progress=math.clamp(profile.Cash/target,0,1),Remaining=math.max(0,target-profile.Cash)}
end
function UX.visibleBusiness(profile,id,showAll)
    return showAll or profile.Businesses[id]~=nil or UX.nextBusiness(profile)==id
end
return UX
