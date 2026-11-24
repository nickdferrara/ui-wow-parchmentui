local ADDON_NAME, ns = ...

local Scroll = {}
ns.Scroll = Scroll

local ROLL_HEIGHT = 32
-- The rolled ends are a little wider than the sheet, like a real scroll on its rod.
local ROLL_OVERHANG = 12

-- Scroll parts per frame. Kept here instead of on the frame so nothing is written onto a
-- Blizzard frame.
local handles = setmetatable({}, { __mode = "k" })

local function NewTexture(frame, key, sublevel, sliceVertically)
    local texture = frame:CreateTexture(nil, "BACKGROUND", nil, sublevel)
    texture:SetTexture(ns.Textures.Get(key))
    local _, _, margin = ns.Textures.Info(key)
    -- Nine-slice scaling is not available on every client build. Without it the texture is
    -- stretched whole, which is acceptable for artwork this soft.
    if margin and type(texture.SetTextureSliceMargins) == "function" then
        local vertical = sliceVertically and margin or 0
        texture:SetTextureSliceMargins(margin, vertical, margin, vertical)
    end
    return texture
end

local function Build(frame)
    local surface = NewTexture(frame, "scrollSurface", -8, true)
    surface:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    surface:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)

    local topRoll = NewTexture(frame, "scrollRoll", -7, false)
    topRoll:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", -ROLL_OVERHANG, -ROLL_HEIGHT / 2)
    topRoll:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", ROLL_OVERHANG, -ROLL_HEIGHT / 2)
    topRoll:SetHeight(ROLL_HEIGHT)

    -- The bottom roll hangs from the sheet, so it travels down as the scroll unrolls.
    local bottomRoll = NewTexture(frame, "scrollRoll", -7, false)
    bottomRoll:SetPoint("TOPLEFT", surface, "BOTTOMLEFT", -ROLL_OVERHANG, ROLL_HEIGHT / 2)
    bottomRoll:SetPoint("TOPRIGHT", surface, "BOTTOMRIGHT", ROLL_OVERHANG, ROLL_HEIGHT / 2)
    bottomRoll:SetHeight(ROLL_HEIGHT)

    return { frame = frame, surface = surface, topRoll = topRoll, bottomRoll = bottomRoll }
end

local function EachPart(handle, fn)
    fn(handle.surface)
    fn(handle.topRoll)
    fn(handle.bottomRoll)
end

-- Recolors the scroll for a theme. The artwork is near-white, so the tint is the color.
function Scroll.Tint(handle, theme)
    local color = theme.colors.surface
    EachPart(handle, function(texture)
        texture:SetVertexColor(color[1], color[2], color[3])
    end)
end

-- Sets how far the scroll is unrolled (0 to 1) and how opaque it is. Only textures created by
-- the addon are touched, so this is safe to call in combat.
function Scroll.SetReveal(handle, alpha, reveal)
    local height = (handle.frame:GetHeight() or 0) * reveal
    handle.surface:SetHeight(math.max(height, 1))
    EachPart(handle, function(texture)
        texture:SetAlpha(alpha)
    end)
end

-- Puts the scroll behind a frame's contents, fully unrolled, and returns a handle for
-- Scroll.Tint and Scroll.SetReveal. Calling it again on the same frame reuses the textures
-- and only refreshes the tint. Returns nil for something that cannot hold textures.
function Scroll.Apply(frame, theme)
    if type(frame) ~= "table" or type(frame.CreateTexture) ~= "function" then
        return nil
    end
    local handle = handles[frame]
    if not handle then
        handle = Build(frame)
        handles[frame] = handle
        Scroll.SetReveal(handle, 1, 1)
    end
    Scroll.Tint(handle, theme)
    return handle
end
