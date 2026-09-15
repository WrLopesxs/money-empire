local Limiter = {}
function Limiter.allow(state, now, capacity, refill)
    state.Tokens = math.min(capacity, (state.Tokens or capacity) + math.max(0, now - (state.Last or now)) * refill)
    state.Last = now
    if state.Tokens < 1 then return false end
    state.Tokens -= 1
    return true
end
return Limiter
