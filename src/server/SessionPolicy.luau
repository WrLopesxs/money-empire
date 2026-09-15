-- Pure lease policy, shared by persistence and its tests.
local Policy = {}
function Policy.canAcquire(record, token, now)
    if record == nil then return true end
    if type(record) ~= "table" or record.Format ~= 1 or type(record.Data) ~= "table" then return false end
    local lock = record.Lock
    if lock == nil then return true end
    if type(lock) ~= "table" or type(lock.Token) ~= "string" or type(lock.Expires) ~= "number" or lock.Expires ~= lock.Expires then return false end
    return lock.Token == token or lock.Expires <= now
end
function Policy.owns(record, token, now)
    return type(record) == "table" and record.Format == 1 and type(record.Lock) == "table"
        and record.Lock.Token == token and type(record.Lock.Expires) == "number" and record.Lock.Expires > now
end
return Policy
