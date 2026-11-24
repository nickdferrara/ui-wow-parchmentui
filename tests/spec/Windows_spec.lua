local Stub = require("tests.stub.WowApi")

describe("window registry", function()
    local state, ns, calls

    local function Descriptor(overrides)
        local descriptor = {
            id = "character",
            frameName = "TestCharacterFrame",
            Skin = function(frame, theme)
                calls.skin[#calls.skin + 1] = { frame = frame, theme = theme }
            end,
            Layout = function(frame, dock)
                calls.layout[#calls.layout + 1] = { frame = frame, dock = dock }
            end,
        }
        for key, value in pairs(overrides or {}) do
            descriptor[key] = value
        end
        return descriptor
    end

    before_each(function()
        calls = { skin = {}, layout = {} }
        state = Stub.Install()
        ns = state.Login()
        _G.TestCharacterFrame = Stub.NewFrame()
    end)

    after_each(function()
        _G.TestCharacterFrame = nil
        Stub.Uninstall(state)
    end)

    it("skins a window once, with the current theme", function()
        ns.Windows.Register(Descriptor())
        ns.Windows.Start()
        ns.Windows.Start()
        assert.equal(1, #calls.skin)
        assert.equal(_G.TestCharacterFrame, calls.skin[1].frame)
        assert.equal("light", calls.skin[1].theme.id)
        assert.equal(1, _G.TestCharacterFrame:HookCount("OnShow"))
    end)

    it("lays a window out each time it is shown, using the dock options", function()
        ns.DB.Set("dockSide", "left")
        ns.Windows.Register(Descriptor())
        ns.Windows.Start()
        assert.equal(0, #calls.layout)

        _G.TestCharacterFrame:Show()
        assert.equal(1, #calls.layout)
        assert.equal("left", calls.layout[1].dock.side)
    end)

    it("defers layout requested in combat until combat ends", function()
        ns.Windows.Register(Descriptor())
        ns.Windows.Start()
        state.inCombat = true
        _G.TestCharacterFrame:Show()
        _G.TestCharacterFrame:Show()
        assert.equal(0, #calls.layout)

        state.inCombat = false
        state.Fire("PLAYER_REGEN_ENABLED")
        assert.equal(1, #calls.layout)
    end)

    it("leaves a disabled window alone", function()
        ns.DB.Set("windows.character.enabled", false)
        ns.Windows.Register(Descriptor())
        ns.Windows.Start()
        assert.equal(0, #calls.skin)
        assert.equal("disabled", ns.Windows.Status()[1].status)
    end)

    it("waits without error when the frame does not exist", function()
        ns.Windows.Register(Descriptor({ frameName = "NoSuchFrame" }))
        ns.Windows.Start()
        assert.equal(0, #calls.skin)
        assert.equal("waiting", ns.Windows.Status()[1].status)
        assert.same({}, state.printed)
    end)

    it("skins a load-on-demand window when its addon loads", function()
        ns.Windows.Register(Descriptor({ loadOnDemand = "Blizzard_Test" }))
        ns.Windows.Start()
        assert.equal(0, #calls.skin)

        state.Fire("ADDON_LOADED", "Blizzard_Other")
        assert.equal(0, #calls.skin)
        state.Fire("ADDON_LOADED", "Blizzard_Test")
        assert.equal(1, #calls.skin)
    end)

    it("skins a load-on-demand window at login when its addon is already loaded", function()
        state.loadedAddons.Blizzard_Test = true
        ns.Windows.Register(Descriptor({ loadOnDemand = "Blizzard_Test" }))
        ns.Windows.Start()
        assert.equal(1, #calls.skin)
    end)

    it("switches off a failing skin, reports it once and keeps other windows", function()
        _G.TestSpellFrame = Stub.NewFrame()
        ns.Windows.Register(Descriptor({
            Skin = function()
                error("missing region")
            end,
        }))
        ns.Windows.Register(Descriptor({ id = "spellbook", frameName = "TestSpellFrame" }))
        ns.Windows.Start()
        ns.Windows.Start()
        _G.TestCharacterFrame:Show()
        _G.TestSpellFrame = nil

        local status = ns.Windows.Status()
        assert.equal("failed", status[1].status)
        assert.matches("missing region", status[1].error)
        assert.equal("skinned", status[2].status)
        assert.equal(1, #state.printed)
        assert.equal(0, #calls.layout)
    end)

    it("switches off a window whose layout fails", function()
        ns.Windows.Register(Descriptor({
            Layout = function()
                error("bad anchor")
            end,
        }))
        ns.Windows.Start()
        _G.TestCharacterFrame:Show()
        _G.TestCharacterFrame:Show()
        assert.equal("failed", ns.Windows.Status()[1].status)
        assert.equal(1, #state.printed)
    end)

    it("rejects a duplicate id and an incomplete descriptor", function()
        ns.Windows.Register(Descriptor())
        assert.has_error(function()
            ns.Windows.Register(Descriptor())
        end)
        assert.has_error(function()
            ns.Windows.Register({ id = "talents", frameName = "TestCharacterFrame" })
        end)
    end)

    it("stays inert on a client outside the Forever interface range", function()
        Stub.Uninstall(state)
        state = Stub.Install({ interface = 120000 })
        ns = state.Login()
        ns.Windows.Register(Descriptor())
        state.Fire("PLAYER_LOGIN")
        assert.equal(0, #calls.skin)
        assert.is_nil(_G.SlashCmdList.PARCHMENTUI)
        assert.is_nil(_G.ParchmentUI_DB)
    end)
end)
