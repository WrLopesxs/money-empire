local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Modules = game:GetService("ReplicatedStorage"):WaitForChild("Modules")
local Config = require(Modules.GameConfig)
local Economy = require(Modules.Economy)
local Investments = require(Modules.InvestmentModel)
local Policy = require(script.Parent.SessionPolicy)
local temporary = RunService:IsStudio() and Config.StudioTemporaryData
local store = if temporary then nil else DataStoreService:GetDataStore(if RunService:IsStudio() then Config.StudioStoreName else Config.StoreName)
local Manager = { Sessions = {}, Temporary = temporary }
local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = copy(child) end
    return result
end
local function retry(callback)
    local ok, result
    for attempt = 1, Config.SaveRetries do
        ok, result = pcall(callback)
        if ok then return true, result end
        warn("[MoneyEmpire] DataStore tentativa " .. attempt .. ": " .. tostring(result))
        if attempt < Config.SaveRetries then task.wait(attempt) end
    end
    return false, result
end
function Manager.load(player)
    local session = { Token = HttpService:GenerateGUID(false), Profile = nil, Saving = false, Closing = false, Healthy = true, Status = "Carregando", LastSave = 0 }
    if temporary then
        session.Profile = Economy.newProfile()
        session.Status = "TESTE LOCAL • dados temporários"
    else
        local ok, record = retry(function()
            return store:UpdateAsync("Player_" .. player.UserId, function(old)
                local now = os.time()
                if not Policy.canAcquire(old, session.Token, now) then return nil end
                local profile = if old then old.Data else Economy.newProfile()
                if not Economy.validate(profile) then return nil end
                if not Investments.prepare(profile) then return nil end
                return { Format = 1, Data = profile, Lock = { Token = session.Token, Expires = now + Config.SessionLeaseSeconds } }
            end)
        end)
        if not ok or not Policy.owns(record, session.Token, os.time()) then
            return nil, "Não foi possível carregar seus dados com segurança. Aguarde um pouco e entre novamente."
        end
        session.Profile = record.Data
        session.LeaseExpires = record.Lock.Expires
        session.Status = "Salvamento conectado"
    end
    Manager.Sessions[player] = session
    return session
end
function Manager.save(player, release)
    local session = Manager.Sessions[player]
    if not session then return false end
    if release then session.Closing = true end
    -- Serialize saves so an older snapshot cannot overwrite a newer one.
    while session.Saving do task.wait(0.05) end
    if Manager.Sessions[player] ~= session then return false end
    if temporary then
        if release then Manager.Sessions[player] = nil end
        return true
    end
    if not session.Healthy or not Economy.validate(session.Profile) then return false end
    session.Saving = true
    local snapshot = copy(session.Profile)
    snapshot.Revision += 1
    local ok, record = retry(function()
        return store:UpdateAsync("Player_" .. player.UserId, function(old)
            if not Policy.owns(old, session.Token, os.time()) then return nil end
            return { Format = 1, Data = snapshot, Lock = if release then nil else { Token = session.Token, Expires = os.time() + Config.SessionLeaseSeconds } }
        end)
    end)
    local saved = ok and type(record) == "table" and record.Data.Revision == snapshot.Revision
        and (if release then record.Lock == nil else Policy.owns(record, session.Token, os.time()))
    if saved then
        session.Profile.Revision = snapshot.Revision
        session.LastSave = os.time()
        session.LeaseExpires = if release then 0 else record.Lock.Expires
        session.Status = "Salvo às " .. os.date("!%H:%M:%S", session.LastSave) .. " UTC"
    elseif ok then
        session.Healthy = false
        session.Status = "Sessão expirada"
    else
        session.Status = "Falha ao salvar • nova tentativa automática"
    end
    session.Saving = false
    if release then Manager.Sessions[player] = nil end
    if not session.Healthy and player.Parent then player:Kick("Sua sessão de dados expirou. Entre novamente para proteger seu progresso.") end
    return saved
end
function Manager.usable(session)
    if session.Closing or not session.Healthy then return false end
    if not temporary and os.time() >= session.LeaseExpires then
        session.Healthy = false
        return false
    end
    return true
end
return Manager
