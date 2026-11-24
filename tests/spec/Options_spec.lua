local Stub = require("tests.stub.WowApi")

describe("options", function()
    local state, ns

    before_each(function()
        state = Stub.Install()
        ns = state.Login()
    end)

    after_each(function()
        _G.CharacterFrame = nil
        Stub.Uninstall(state)
    end)

    local function Printed()
        return table.concat(state.printed, "\n")
    end

    it("shows a missing translation as its key", function()
        assert.equal("NO_SUCH_STRING", ns.L.NO_SUCH_STRING)
        assert.not_equal("RESET_DONE", ns.L.RESET_DONE)
    end)

    it("prints a message with a cause only once per session", function()
        assert.is_true(ns.Print("first", "cause"))
        assert.is_false(ns.Print("second", "cause"))
        assert.is_true(ns.Print("no cause"))
        assert.is_true(ns.Print("no cause"))
        assert.equal(3, #state.printed)
    end)

    it("registers both slash commands and prints help for unknown input", function()
        assert.equal("/parchment", _G.SLASH_PARCHMENTUI1)
        assert.equal("/pui", _G.SLASH_PARCHMENTUI2)
        _G.SlashCmdList.PARCHMENTUI("nonsense")
        assert.matches("/pui audit", Printed(), 1, true)
    end)

    it("resets stored settings from the slash command", function()
        ns.DB.Set("theme", "dark")
        _G.SlashCmdList.PARCHMENTUI("  RESET ")
        assert.equal("light", ns.DB.Get("theme"))
    end)

    it("audits which candidate frames exist on the client", function()
        _G.CharacterFrame = Stub.NewFrame({ width = 338, height = 424, protected = true })
        _G.UIPanelWindows = { CharacterFrame = { area = "left" } }
        _G.SlashCmdList.PARCHMENTUI("audit")
        local output = Printed()
        assert.matches("interface 16001", output, 1, true)
        assert.matches("CharacterFrame: Frame, 338x424, protected=yes", output, 1, true)
        assert.matches("panel area=left", output, 1, true)
        assert.matches("MailFrame: missing", output, 1, true)
        assert.matches(
            "PlayerSpellsFrame: missing (Blizzard_PlayerSpells not loaded)",
            output,
            1,
            true
        )
    end)
end)
