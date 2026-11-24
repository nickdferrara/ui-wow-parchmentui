local ADDON_NAME, ns = ...

local Dock = {}
ns.Layout = Dock

Dock.MAX_OPEN = 2
Dock.GAP = 8
Dock.MARGIN = 16

-- Returns the list of docked window ids after opening id. The first window keeps the slot at
-- the screen edge, the second sits beside it, and a third replaces the second.
function Dock.Push(open, id)
    local result = {}
    for index = 1, #open do
        if open[index] == id then
            return open
        end
        result[index] = open[index]
    end
    if #result < Dock.MAX_OPEN then
        result[#result + 1] = id
    else
        result[Dock.MAX_OPEN] = id
    end
    return result
end

function Dock.Remove(open, id)
    local result = {}
    for index = 1, #open do
        if open[index] ~= id then
            result[#result + 1] = open[index]
        end
    end
    return result
end

-- A window taller than the screen is scaled down, never clipped.
function Dock.FitScale(height, screenHeight, userScale)
    local available = screenHeight - 2 * Dock.MARGIN
    if height <= 0 or available <= 0 then
        return userScale
    end
    return math.min(userScale, available / height)
end

-- Computes a slot for each window, in order from the docked edge inward.
--   screen:  { width, height } of the UI parent, in its own units
--   options: { side = "right" | "left", offset, scale, reserved }
--            reserved is width already taken at the docked edge by another addon's panel
--   windows: { { id, width, height }, ... } unscaled sizes
-- Each slot is { id, point, x, y, scale }. x is the distance from the docked screen edge to
-- the window's near edge, in UI parent units, signed for use with the given anchor point.
function Dock.Compute(screen, options, windows)
    local scales, total = {}, 0
    for index = 1, #windows do
        local scale = Dock.FitScale(windows[index].height, screen.height, options.scale)
        scales[index] = scale
        total = total + windows[index].width * scale
    end

    local edge = options.offset + (options.reserved or 0)
    local gaps = Dock.GAP * math.max(#windows - 1, 0)
    local room = screen.width - edge - gaps - Dock.MARGIN
    local shrink = (total > room and room > 0) and room / total or 1

    local onRight = options.side ~= "left"
    local slots, cursor = {}, edge
    for index = 1, #windows do
        local scale = scales[index] * shrink
        slots[index] = {
            id = windows[index].id,
            point = onRight and "RIGHT" or "LEFT",
            x = onRight and -cursor or cursor,
            y = 0,
            scale = scale,
        }
        cursor = cursor + windows[index].width * scale + Dock.GAP
    end
    return slots
end

function Dock.Options()
    return {
        side = ns.DB.Get("dockSide"),
        offset = ns.DB.Get("dockOffset"),
        scale = ns.DB.Get("scale"),
    }
end
