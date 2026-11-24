local ADDON_NAME, ns = ...

local Theme = {}
ns.Theme = Theme

Theme.MATCH_DIALOGUE_UI = "match"

-- "match" is only meaningful while Dialogue UI is loaded. How to read its active theme has
-- not been confirmed in the client, so for now it resolves to the light theme.
function Theme.Resolve(choice)
    if ns.Palette.themes[choice] then
        return choice
    end
    return "light"
end

function Theme.Current()
    local id = Theme.Resolve(ns.DB.Get("theme"))
    return {
        id = id,
        colors = ns.Palette.themes[id],
        fontScale = ns.DB.Get("fontScale"),
    }
end

ns.Windows.SetThemeProvider(Theme.Current)
