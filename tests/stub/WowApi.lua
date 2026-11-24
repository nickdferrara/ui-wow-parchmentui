-- A minimal stand-in for the parts of the client API the addon touches at load time and in
-- the logic under test. It is not a client emulator: add to it only when a test needs it.
local Stub = {}

local ADDON_NAME = "ParchmentUI"
local ADDON_ROOT = "ParchmentUI/"
local GLOBALS = {
    "CreateFrame",
    "InCombatLockdown",
    "GetBuildInfo",
    "GetLocale",
    "C_AddOns",
    "geterrorhandler",
    "SlashCmdList",
    "SLASH_PARCHMENTUI1",
    "SLASH_PARCHMENTUI2",
    "ParchmentUI_DB",
    "UIPanelWindows",
    "UIParent",
    "WOW_PROJECT_ID",
}

local Frame = {}
Frame.__index = Frame

function Frame:RegisterEvent(event)
    self.events[event] = true
end

function Frame:SetScript(script, handler)
    self.scripts[script] = { handler }
end

function Frame:HookScript(script, handler)
    self.scripts[script] = self.scripts[script] or {}
    table.insert(self.scripts[script], handler)
end

function Frame:Run(script, ...)
    for _, handler in ipairs(self.scripts[script] or {}) do
        handler(self, ...)
    end
end

function Frame:HookCount(script)
    return #(self.scripts[script] or {})
end

function Frame:IsShown()
    return self.shown
end

function Frame:Show()
    self.shown = true
    self:Run("OnShow")
end

function Frame:Hide()
    self.shown = false
    self:Run("OnHide")
end

function Frame:GetWidth()
    return self.width
end

function Frame:GetHeight()
    return self.height
end

function Frame:IsProtected()
    return self.protected
end

function Frame.GetObjectType()
    return "Frame"
end

function Frame:GetSize()
    return self.width, self.height
end

function Stub.NewFrame(fields)
    local frame = setmetatable({ events = {}, scripts = {}, shown = false }, Frame)
    frame.protected = false
    frame.width, frame.height = 0, 0
    for key, value in pairs(fields or {}) do
        frame[key] = value
    end
    return frame
end

-- Installs the stub globals and returns a control table for the test to drive.
function Stub.Install(options)
    options = options or {}
    local state = {
        inCombat = false,
        interface = options.interface or 16001,
        locale = "enUS",
        loadedAddons = {},
        frames = {},
        errors = {},
        printed = {},
        realPrint = _G.print,
    }

    _G.CreateFrame = function()
        local frame = Stub.NewFrame()
        table.insert(state.frames, frame)
        return frame
    end
    _G.InCombatLockdown = function()
        return state.inCombat
    end
    _G.GetBuildInfo = function()
        return "1.60.1", "99999", "Nov 24 2026", state.interface
    end
    _G.GetLocale = function()
        return state.locale
    end
    _G.C_AddOns = {
        IsAddOnLoaded = function(name)
            local loaded = state.loadedAddons[name] == true
            return loaded, loaded
        end,
    }
    _G.geterrorhandler = function()
        return function(message)
            table.insert(state.errors, message)
            return message
        end
    end
    _G.SlashCmdList = {}
    _G.print = function(message)
        table.insert(state.printed, message)
    end

    function state.Fire(event, ...)
        for _, frame in ipairs(state.frames) do
            if frame.events[event] then
                frame:Run("OnEvent", event, ...)
            end
        end
    end

    -- Advances every running OnUpdate handler by one rendered frame.
    function state.Tick(elapsed)
        for _, frame in ipairs(state.frames) do
            frame:Run("OnUpdate", elapsed)
        end
    end

    function state.OnUpdateCount()
        local count = 0
        for _, frame in ipairs(state.frames) do
            count = count + frame:HookCount("OnUpdate")
        end
        return count
    end

    -- Loads the addon files in TOC order, the way the client does, and returns the namespace.
    function state.Load()
        local ns = {}
        for line in io.lines(ADDON_ROOT .. ADDON_NAME .. "_Camelot.toc") do
            local file = line:match("^([^#%s][^%[]-)%s*%[") or line:match("^([^#%s].-)%s*$")
            if file then
                assert(loadfile(ADDON_ROOT .. file))(ADDON_NAME, ns)
            end
        end
        return ns
    end

    -- Loads the addon and runs it through the login sequence.
    function state.Login()
        local ns = state.Load()
        state.Fire("ADDON_LOADED", ADDON_NAME)
        state.Fire("PLAYER_LOGIN")
        return ns
    end

    return state
end

function Stub.Uninstall(state)
    _G.print = state.realPrint
    for _, name in ipairs(GLOBALS) do
        _G[name] = nil
    end
end

return Stub
