local ADDON_NAME, ns = ...

local Combat = {}
ns.Combat = Combat

local order = {}
local pending = {}

-- Protected frames cannot be moved, resized, shown or hidden during combat lockdown, so layout
-- work requested in combat waits for PLAYER_REGEN_ENABLED. Requests sharing a key collapse
-- into one, keeping the most recent function. Returns true when fn ran immediately.
function Combat.RunWhenSafe(fn, key)
    if not InCombatLockdown() then
        fn()
        return true
    end
    key = key or fn
    if pending[key] == nil then
        order[#order + 1] = key
    end
    pending[key] = fn
    return false
end

function Combat.PendingCount()
    return #order
end

local function Flush()
    -- Swap the queue out first: a queued function may queue more work.
    local keys, work = order, pending
    order, pending = {}, {}
    for index = 1, #keys do
        ns.SafeCall(work[keys[index]])
    end
end

ns.Events.Register("PLAYER_REGEN_ENABLED", Flush)
