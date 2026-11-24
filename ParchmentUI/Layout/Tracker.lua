local ADDON_NAME, ns = ...

local Dock = ns.Layout

local Tracker = {}
Dock.Tracker = Tracker

-- Ids of the docked windows, ordered from the screen edge inward.
local open = {}

function Tracker.Open()
    local copy = {}
    for index = 1, #open do
        copy[index] = open[index]
    end
    return copy
end

local function Measure()
    local windows = {}
    for index = 1, #open do
        local frame = ns.Windows.GetFrame(open[index])
        if frame then
            local width, height = frame:GetSize()
            windows[#windows + 1] = { id = open[index], width = width or 0, height = height or 0 }
        end
    end
    return windows
end

-- Returns the slot for one window, or nil when it is not docked. A window pushed out of the
-- dock by a third one has no slot: what happens to it on screen is left to the panel manager.
function Tracker.SlotFor(id)
    if not UIParent then
        return nil
    end
    local screen = { width = UIParent:GetWidth(), height = UIParent:GetHeight() }
    local slots = Dock.Compute(screen, Dock.Options(), Measure())
    for index = 1, #slots do
        if slots[index].id == id then
            return slots[index]
        end
    end
    return nil
end

local function OnVisibility(id, shown)
    open = shown and Dock.Push(open, id) or Dock.Remove(open, id)
    -- The other docked windows may have gained or lost a neighbour, so their slots moved.
    for index = 1, #open do
        if open[index] ~= id then
            ns.Windows.RequestLayout(open[index])
        end
    end
end

ns.Windows.SetVisibilityListener(OnVisibility)

ns.Windows.SetDockProvider(function(id)
    local dock = Dock.Options()
    dock.slot = Tracker.SlotFor(id)
    return dock
end)
