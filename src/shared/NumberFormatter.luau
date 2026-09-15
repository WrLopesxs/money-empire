local suffixes = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }
local Formatter = {}
function Formatter.compact(value)
    if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then return "0" end
    local sign = if value < 0 then "-" else ""
    local n, tier = math.abs(value), 1
    while n >= 1000 and tier < #suffixes do n /= 1000; tier += 1 end
    local decimals = if tier == 1 or n >= 100 then 0 elseif n >= 10 then 1 else 2
    local rounded = math.floor(n * 10 ^ decimals + 0.5) / 10 ^ decimals
    if rounded >= 1000 and tier < #suffixes then rounded /= 1000; tier += 1; decimals = 2 end
    local text = string.format("%." .. decimals .. "f", rounded)
    if string.find(text, ".", 1, true) then text = string.gsub(string.gsub(text, "0+$", ""), "%.$", "") end
    return sign .. text .. suffixes[tier]
end
function Formatter.money(value) return "$" .. Formatter.compact(value) end
return Formatter
