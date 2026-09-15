local Config = require(if script then script.Parent.MarketConfig else "./MarketConfig")
local Market = {}
-- UTC-derived simulation: every server sees identical quotes; hopping cannot reset prices.
function Market.eventAt(now)
    local cycle = math.floor(now / Config.EventSeconds)
    local offset = now % Config.EventSeconds
    if offset >= Config.EventDuration then
        return nil, (cycle + 1) * Config.EventSeconds
    end
    local index = (cycle * 17 + math.floor(cycle / 7)) % #Config.Events + 1
    return Config.Events[index], cycle * Config.EventSeconds + Config.EventDuration
end
function Market.priceAt(sector, now)
    local index = table.find(Config.SectorOrder, sector)
    if not index then return nil end
    local tick = math.floor(now / Config.QuoteSeconds)
    local wave = 1 + 0.12 * math.sin(tick * 0.071 + index * 2.1) + 0.06 * math.sin(tick * 0.023 + index)
    local event = Market.eventAt(tick * Config.QuoteSeconds)
    local boost = if event and (event.Sector == sector or event.Sector == "All") then event.Price else 1
    return math.floor(Config.Sectors[sector].BasePrice * wave * boost * 100 + 0.5) / 100
end
function Market.snapshot(now)
    local revision = math.floor(now / Config.QuoteSeconds)
    local event, endsAt = Market.eventAt(now)
    local result = { Revision = revision, EndsAt = endsAt, Name = if event then event.Name else "MERCADO ESTÁVEL",
        Description = if event then event.Description else "Próximo evento em breve", Prices = {}, History = {}, Multipliers = {} }
    for _, sector in ipairs(Config.SectorOrder) do
        result.Prices[sector] = Market.priceAt(sector, now)
        result.Multipliers[sector] = if event and (event.Sector == sector or event.Sector == "All") then event.Income else 1
        local points = {}
        for i = Config.ChartPoints - 1, 0, -1 do
            table.insert(points, Market.priceAt(sector, (revision - i) * Config.QuoteSeconds))
        end
        result.History[sector] = points
    end
    return result
end
return Market
