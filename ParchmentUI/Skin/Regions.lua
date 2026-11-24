local ADDON_NAME, ns = ...

local Skin = {}
ns.Skin = Skin

-- Addon state about Blizzard objects lives here, never as fields on the objects themselves,
-- because writing to a Blizzard frame can taint it. Weak keys let discarded frames go.
local applied = setmetatable({}, { __mode = "k" })

-- Returns true the first time it is called for an object and key, and false after that. Skins
-- use it to stay idempotent: hooks and created textures must not stack on a second run.
function Skin.Once(object, key)
    local keys = applied[object]
    if not keys then
        keys = {}
        applied[object] = keys
    end
    if keys[key] then
        return false
    end
    keys[key] = true
    return true
end

-- Walks a chain of child keys and returns nil as soon as one is missing, so a frame that
-- changed in a patch switches off part of a skin instead of raising an error.
function Skin.Child(frame, ...)
    local node = frame
    for index = 1, select("#", ...) do
        if type(node) ~= "table" then
            return nil
        end
        node = node[(select(index, ...))]
    end
    return node
end

-- Stock art is made transparent rather than hidden: Blizzard code shows regions again when a
-- window updates, but leaves their alpha alone. Returns true when the region was hidden.
function Skin.HideRegion(region)
    if type(region) ~= "table" or type(region.SetAlpha) ~= "function" then
        return false
    end
    region:SetAlpha(0)
    return true
end

-- Hides the named child regions of a frame and returns how many were found.
function Skin.HideRegions(frame, keys)
    local hidden = 0
    for index = 1, #keys do
        if Skin.HideRegion(Skin.Child(frame, keys[index])) then
            hidden = hidden + 1
        end
    end
    return hidden
end

-- Hides every texture attached directly to a frame, leaving text and child frames alone.
-- Returns how many were hidden.
function Skin.StripTextures(frame)
    if type(frame) ~= "table" or type(frame.GetRegions) ~= "function" then
        return 0
    end
    local regions = { frame:GetRegions() }
    local hidden = 0
    for index = 1, #regions do
        local region = regions[index]
        if
            type(region) == "table"
            and type(region.GetObjectType) == "function"
            and region:GetObjectType() == "Texture"
            and Skin.HideRegion(region)
        then
            hidden = hidden + 1
        end
    end
    return hidden
end

local function SetTextColor(fontString, color)
    if type(fontString) ~= "table" or type(fontString.SetTextColor) ~= "function" then
        return false
    end
    fontString:SetTextColor(color[1], color[2], color[3])
    return true
end

-- Colors text with one of the theme's roles: "body", "heading" or "muted".
function Skin.ColorText(fontString, theme, role)
    local color = theme.colors[role]
    if not color then
        return false
    end
    return SetTextColor(fontString, color)
end

-- Colors text with a color the game chose, such as item quality, adjusted only as far as
-- needed to stay readable on the theme's surface.
function Skin.ColorGameText(fontString, theme, red, green, blue)
    local color = ns.Palette.Legible({ red, green, blue }, theme.colors.surface)
    return SetTextColor(fontString, color)
end

-- Sets the typeface and size for a theme role, keeping the outline flags the text already
-- had. Where the client font is kept for the locale, only the size changes.
function Skin.SetFont(fontString, theme, role, baseSize)
    if
        type(fontString) ~= "table"
        or type(fontString.GetFont) ~= "function"
        or type(fontString.SetFont) ~= "function"
    then
        return false
    end
    local currentPath, _, flags = fontString:GetFont()
    local path = ns.Fonts.Path(role) or currentPath
    if not path then
        return false
    end
    fontString:SetFont(path, ns.Fonts.Size(baseSize, theme), flags or "")
    return true
end
