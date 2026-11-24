local ADDON_NAME, ns = ...

local Palette = {}
ns.Palette = Palette

-- Minimum contrast for body text against the scroll surface, in both themes.
Palette.MIN_CONTRAST = 4.5

Palette.themes = {
    light = {
        surface = { 0.93, 0.87, 0.73 },
        body = { 0.20, 0.13, 0.07 },
        heading = { 0.35, 0.12, 0.06 },
        muted = { 0.36, 0.28, 0.18 },
        border = { 0.45, 0.33, 0.20 },
    },
    dark = {
        surface = { 0.13, 0.11, 0.09 },
        body = { 0.88, 0.83, 0.72 },
        heading = { 0.95, 0.80, 0.50 },
        muted = { 0.66, 0.60, 0.50 },
        border = { 0.50, 0.42, 0.30 },
    },
}

local function Linear(channel)
    if channel <= 0.03928 then
        return channel / 12.92
    end
    return ((channel + 0.055) / 1.055) ^ 2.4
end

function Palette.Luminance(color)
    return 0.2126 * Linear(color[1]) + 0.7152 * Linear(color[2]) + 0.0722 * Linear(color[3])
end

function Palette.ContrastRatio(first, second)
    local a, b = Palette.Luminance(first), Palette.Luminance(second)
    if a < b then
        a, b = b, a
    end
    return (a + 0.05) / (b + 0.05)
end

local function Blend(color, target, amount)
    return {
        color[1] + (target - color[1]) * amount,
        color[2] + (target - color[2]) * amount,
        color[3] + (target - color[3]) * amount,
    }
end

-- Moves a color toward black on a light surface, or toward white on a dark one, by the
-- smallest amount that reaches minRatio. Used for colors the game picks, such as item quality,
-- which should stay recognisable while remaining readable.
function Palette.Legible(color, surface, minRatio)
    minRatio = minRatio or Palette.MIN_CONTRAST
    if Palette.ContrastRatio(color, surface) >= minRatio then
        return { color[1], color[2], color[3] }
    end
    local target = Palette.Luminance(surface) > 0.5 and 0 or 1
    local low, high = 0, 1
    for _ = 1, 12 do
        local middle = (low + high) / 2
        if Palette.ContrastRatio(Blend(color, target, middle), surface) >= minRatio then
            high = middle
        else
            low = middle
        end
    end
    return Blend(color, target, high)
end
