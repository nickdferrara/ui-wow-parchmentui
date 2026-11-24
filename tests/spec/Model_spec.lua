local Stub = require("tests.stub.WowApi")

describe("options model", function()
    local state, ns, Options

    before_each(function()
        state = Stub.Install()
        ns = state.Login()
        Options = ns.Options
    end)

    after_each(function()
        Stub.Uninstall(state)
    end)

    local function Printed()
        return table.concat(state.printed, "\n")
    end

    it("stores a valid choice and reads it back", function()
        assert.same({ true, "dark" }, { Options.Set("theme", "dark") })
        assert.equal("dark", Options.Get("theme"))
        assert.equal("dark", ns.Theme.Current().id)
    end)

    it("rejects an unknown option, a wrong choice and a wrong type", function()
        assert.same({ false, Options.ERROR_UNKNOWN }, { Options.Set("colour", "red") })
        assert.same({ false, Options.ERROR_INVALID }, { Options.Set("theme", "sepia") })
        assert.same({ false, Options.ERROR_INVALID }, { Options.Set("offset", "wide") })
        assert.same({ false, Options.ERROR_INVALID }, { Options.Set("offset", 0 / 0) })
        assert.same({ false, Options.ERROR_INVALID }, { Options.Set("animation", "on") })
        assert.same({ false, Options.ERROR_INVALID }, { Options.Set("theme", nil) })
        assert.equal("light", Options.Get("theme"))
    end)

    it("clamps numbers to their range", function()
        assert.same({ true, 400 }, { Options.Set("offset", 9000) })
        assert.same({ true, 0 }, { Options.Set("offset", -5) })
        assert.same({ true, 1.5 }, { Options.Set("font", 2) })
        assert.same({ true, 1 }, { Options.Set("font", 0.5) })
        assert.same({ true, 0.1 }, { Options.Set("speed", 0) })
    end)

    it("offers the Dialogue UI theme only while that addon is loaded", function()
        assert.same({ "light", "dark" }, Options.Choices("theme"))
        assert.same({ false, Options.ERROR_UNAVAILABLE }, { Options.Set("theme", "match") })

        state.loadedAddons.DialogueUI = true
        assert.same({ "light", "dark", "match" }, Options.Choices("theme"))
        assert.is_true(Options.Set("theme", "match"))
    end)

    it("reads what a player types", function()
        assert.equal("dark", Options.Parse("theme", " DARK "))
        assert.equal(1.25, Options.Parse("font", "125"))
        assert.equal(1.25, Options.Parse("font", "125%"))
        assert.equal(60, Options.Parse("offset", "60"))
        assert.equal(0.3, Options.Parse("speed", "0.3"))
        assert.is_true(Options.Parse("animation", "on"))
        assert.is_false(Options.Parse("animation", "off"))
        assert.is_nil(Options.Parse("animation", "maybe"))
        assert.is_nil(Options.Parse("offset", "wide"))
        assert.is_nil(Options.Parse("theme", ""))
    end)

    it("describes values and accepted input the way a player types them", function()
        Options.Set("font", 1.25)
        Options.Set("animation", false)
        assert.equal("125%", Options.Describe("font"))
        assert.equal("off", Options.Describe("animation"))
        assert.equal("40", Options.Describe("offset"))
        assert.equal("100% to 150%", Options.Usage("font"))
        assert.equal("right | left", Options.Usage("side"))
        assert.equal("on | off", Options.Usage("animation"))
    end)

    it("keeps a value equal to the default out of the saved data", function()
        Options.Set("scale", 0.9)
        assert.equal(0.9, _G.ParchmentUI_DB.scale)
        Options.Set("scale", Options.Parse("scale", "100%"))
        assert.is_nil(_G.ParchmentUI_DB.scale)
    end)

    it("tells listeners about a change, once, and survives a failing listener", function()
        local seen = {}
        Options.Subscribe(function()
            error("listener broke")
        end)
        Options.Subscribe(function(name, value)
            seen[#seen + 1] = name .. "=" .. tostring(value)
        end)
        Options.Set("side", "left")
        Options.Set("side", "left")
        Options.Set("side", "up")
        assert.same({ "side=left" }, seen)
    end)

    it("toggles a registered window and refuses an unknown one", function()
        ns.Windows.Register({ id = "character", frameName = "NoFrame", Skin = function() end })
        assert.is_true(Options.SetWindowEnabled("character", false))
        assert.is_false(ns.DB.IsWindowEnabled("character"))
        assert.is_false(Options.SetWindowEnabled("mailbox", false))
        assert.is_false(Options.SetWindowEnabled("character", "off"))
        assert.is_nil(_G.ParchmentUI_DB.windows.mailbox)
    end)

    describe("slash commands", function()
        local function Run(text)
            state.printed = {}
            _G.SlashCmdList.PARCHMENTUI(text)
            return Printed()
        end

        it("change a setting and confirm the stored value", function()
            assert.matches("theme set to dark.", Run("theme dark"), 1, true)
            assert.matches("font set to 150%.", Run("font 400"), 1, true)
            assert.matches("animation set to off.", Run("Animation OFF"), 1, true)
            assert.equal(1.5, Options.Get("font"))
        end)

        it("show the current value when none is given", function()
            assert.matches("side is right.", Run("side"), 1, true)
        end)

        it("explain a value that cannot be used", function()
            local output = Run("side middle")
            assert.matches(
                "middle is not a valid value for side. Use right | left.",
                output,
                1,
                true
            )
            assert.matches("match needs Dialogue UI", Run("theme match"), 1, true)
            assert.matches("Use 0 to 400.", Run("offset wide"), 1, true)
            assert.equal("right", Options.Get("side"))
        end)

        it("list every setting", function()
            local output = Run("options")
            for _, name in ipairs(Options.ORDER) do
                assert.matches(name .. ": ", output, 1, true)
            end
        end)

        it("turn a window skin off and ask for a reload", function()
            ns.Windows.Register({ id = "character", frameName = "NoFrame", Skin = function() end })
            assert.matches("/reload", Run("window character off"), 1, true)
            assert.is_false(ns.DB.IsWindowEnabled("character"))
            assert.matches("no window skin named mailbox", Run("window mailbox off"), 1, true)
            assert.matches("/pui window <name>", Run("window character"), 1, true)
        end)
    end)
end)
