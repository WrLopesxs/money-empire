-- Sizes are based on the ScreenGui safe area, not the physical display resolution.
local Layout = {}
function Layout.calculate(width, height)
    local margin = 8
    local hudWidth = math.min(384, math.max(0, width - 2 * margin))
    local panelWidth = math.min(360, math.max(0, width - 2 * margin))
    return {
        Margin = margin, HudWidth = hudWidth, HudHeight = 50,
        PanelX = margin, PanelY = 66, PanelWidth = panelWidth,
        PanelHeight = math.min(500, math.max(0, height - 74)),
        DockY = 94, NewsY = 64, FeedbackY = 140,
        StatTextSize = if width < 360 then 16 else 18,
    }
end
return Layout
