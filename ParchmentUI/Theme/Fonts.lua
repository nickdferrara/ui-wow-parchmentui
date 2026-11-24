local ADDON_NAME, ns = ...

local Fonts = {}
ns.Fonts = Fonts

local FONT_PATH = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Fonts\\"

local FILES = {
    body = "EBGaramond-Regular.ttf",
    heading = "EBGaramond-SemiBold.ttf",
    emphasis = "EBGaramond-Italic.ttf",
}

-- The bundled typeface covers Latin and Cyrillic. In these locales the client's own font is
-- kept, because drawing their text with the bundled font would show missing glyphs.
local CLIENT_FONT_LOCALES = {
    koKR = true,
    zhCN = true,
    zhTW = true,
}

-- Returns the font file for a role ("body", "heading" or "emphasis"), or nil when the client
-- font should be kept.
function Fonts.Path(role)
    local file = FILES[role]
    if not file or CLIENT_FONT_LOCALES[GetLocale()] then
        return nil
    end
    return FONT_PATH .. file
end

-- Scales a base size by the player's font size option.
function Fonts.Size(baseSize, theme)
    return baseSize * (theme.fontScale or 1)
end
