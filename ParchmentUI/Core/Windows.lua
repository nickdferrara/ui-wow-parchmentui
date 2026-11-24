local ADDON_NAME, ns = ...

local Windows = {}
ns.Windows = Windows

local descriptors = {}
local order = {}
local states = {}
local started = false

-- Theme and Layout load after Core and hand their context in through these, so Core never
-- reaches into a later module.
local GetTheme = function() end
local GetDock = function() end

function Windows.SetThemeProvider(provider)
    GetTheme = provider
end

function Windows.SetDockProvider(provider)
    GetDock = provider
end

function Windows.Register(descriptor)
    assert(type(descriptor) == "table", "descriptor must be a table")
    local id = descriptor.id
    assert(type(id) == "string" and id ~= "", "descriptor.id must be a string")
    assert(descriptors[id] == nil, "window registered twice: " .. id)
    assert(type(descriptor.frameName) == "string", "descriptor.frameName must be a string")
    assert(type(descriptor.Skin) == "function", "descriptor.Skin must be a function")
    assert(
        descriptor.Layout == nil or type(descriptor.Layout) == "function",
        "descriptor.Layout must be a function"
    )
    descriptors[id] = descriptor
    order[#order + 1] = id
    states[id] = { skinned = false, failed = false }
end

function Windows.IsRegistered(id)
    return descriptors[id] ~= nil
end

-- A failing window is switched off for the session so its stock frame keeps working.
local function Fail(id, err)
    local state = states[id]
    state.failed = true
    state.error = tostring(err)
    ns.Print(ns.L.SKIN_FAILED:format(id), "skin:" .. id)
end

local function Guarded(id, fn)
    local ok, err = xpcall(fn, function(message)
        return message
    end)
    if not ok then
        Fail(id, err)
    end
    return ok
end

function Windows.RequestLayout(id)
    local descriptor, state = descriptors[id], states[id]
    if not descriptor or not descriptor.Layout or not state.skinned or state.failed then
        return
    end
    ns.Combat.RunWhenSafe(function()
        local frame = _G[descriptor.frameName]
        if frame and not state.failed then
            Guarded(id, function()
                descriptor.Layout(frame, GetDock())
            end)
        end
    end, "layout:" .. id)
end

local function Apply(id)
    local descriptor, state = descriptors[id], states[id]
    if state.skinned or state.failed or not ns.DB.IsWindowEnabled(id) then
        return
    end
    -- A frame missing on this client build leaves the stock window alone instead of erroring.
    local frame = _G[descriptor.frameName]
    if not frame then
        return
    end
    local ok = Guarded(id, function()
        descriptor.Skin(frame, GetTheme())
    end)
    if not ok then
        return
    end
    state.skinned = true
    if descriptor.Layout then
        frame:HookScript("OnShow", function()
            Windows.RequestLayout(id)
        end)
        if frame:IsShown() then
            Windows.RequestLayout(id)
        end
    end
end

local function IsAddOnLoaded(name)
    if not (C_AddOns and C_AddOns.IsAddOnLoaded) then
        return false
    end
    local _, finished = C_AddOns.IsAddOnLoaded(name)
    return finished == true
end

-- Called at login. Load-on-demand windows whose addon is not loaded yet wait for
-- Windows.OnAddonLoaded.
function Windows.Start()
    started = true
    for index = 1, #order do
        local descriptor = descriptors[order[index]]
        if not descriptor.loadOnDemand or IsAddOnLoaded(descriptor.loadOnDemand) then
            Apply(descriptor.id)
        end
    end
end

function Windows.OnAddonLoaded(addonName)
    if not started then
        return
    end
    for index = 1, #order do
        local descriptor = descriptors[order[index]]
        if descriptor.loadOnDemand == addonName then
            Apply(descriptor.id)
        end
    end
end

function Windows.Status()
    local report = {}
    for index = 1, #order do
        local id = order[index]
        local state = states[id]
        local status = "waiting"
        if state.failed then
            status = "failed"
        elseif state.skinned then
            status = "skinned"
        elseif not ns.DB.IsWindowEnabled(id) then
            status = "disabled"
        end
        report[index] = { id = id, status = status, error = state.error }
    end
    return report
end
