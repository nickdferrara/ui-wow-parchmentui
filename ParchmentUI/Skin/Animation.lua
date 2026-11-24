local ADDON_NAME, ns = ...

local Animation = {}
ns.Animation = Animation

-- The fade finishes ahead of the unroll so the scroll is fully opaque while it is still opening.
local FADE_PORTION = 0.6

local active = {}
local activeCount = 0
local driver = CreateFrame("Frame")

-- Returns nil when the change should be instant: animation is switched off, or the player is
-- in combat, where an unroll would delay a window the player needs right away.
function Animation.Plan(opening)
    if not ns.DB.Get("animation.enabled") or InCombatLockdown() then
        return nil
    end
    return { opening = opening, duration = ns.DB.Get("animation.duration") }
end

-- Returns alpha and reveal, both from 0 to 1, for a plan at a given elapsed time. Reveal is
-- the fraction of the scroll that is unrolled. Closing is the exact reverse of opening.
function Animation.Evaluate(plan, elapsed)
    local progress = math.max(0, math.min(1, elapsed / plan.duration))
    if not plan.opening then
        progress = 1 - progress
    end
    local reveal = 1 - (1 - progress) ^ 3
    return math.min(1, reveal / FADE_PORTION), reveal
end

local OnUpdate

local function Remove(target)
    if active[target] then
        active[target] = nil
        activeCount = activeCount - 1
        if activeCount == 0 then
            -- The handler only exists while something is animating, so an idle addon costs
            -- nothing per frame.
            driver:SetScript("OnUpdate", nil)
        end
    end
end

local function Finish(target)
    local run = active[target]
    local final = run.plan.opening and 1 or 0
    Remove(target)
    ns.SafeCall(run.apply, final, final)
    if run.onDone then
        ns.SafeCall(run.onDone)
    end
end

OnUpdate = function(_, elapsed)
    local finished = {}
    for target, run in pairs(active) do
        run.elapsed = run.elapsed + elapsed
        if run.elapsed >= run.plan.duration then
            finished[#finished + 1] = target
        elseif not ns.SafeCall(run.apply, Animation.Evaluate(run.plan, run.elapsed)) then
            -- A failing apply would otherwise raise an error on every frame.
            finished[#finished + 1] = target
        end
    end
    for index = 1, #finished do
        if active[finished[index]] then
            Finish(finished[index])
        end
    end
end

-- Animates target open or closed. apply(alpha, reveal) must only touch alpha and regions the
-- addon created. Starting a new animation on a target replaces the one in progress, whose
-- onDone is then not called. Returns true when an animation started, false when the final
-- state was applied at once.
function Animation.Play(target, opening, apply, onDone)
    Remove(target)
    local plan = Animation.Plan(opening)
    if not plan then
        local final = opening and 1 or 0
        apply(final, final)
        if onDone then
            onDone()
        end
        return false
    end
    apply(Animation.Evaluate(plan, 0))
    active[target] = { plan = plan, elapsed = 0, apply = apply, onDone = onDone }
    activeCount = activeCount + 1
    if activeCount == 1 then
        driver:SetScript("OnUpdate", OnUpdate)
    end
    return true
end

function Animation.IsPlaying(target)
    return active[target] ~= nil
end

-- Entering combat completes every animation at once.
ns.Events.Register("PLAYER_REGEN_DISABLED", function()
    local targets = {}
    for target in pairs(active) do
        targets[#targets + 1] = target
    end
    for index = 1, #targets do
        Finish(targets[index])
    end
end)
