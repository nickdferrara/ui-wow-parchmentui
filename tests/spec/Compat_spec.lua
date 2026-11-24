local Stub = require("tests.stub.WowApi")

describe("compatibility", function()
    local state, ns, skinned

    local function Register(id)
        ns.Windows.Register({
            id = id,
            frameName = "TestCompatFrame",
            Skin = function()
                skinned[#skinned + 1] = id
            end,
        })
    end

    before_each(function()
        skinned = {}
        state = Stub.Install()
        ns = state.Login()
        _G.TestCompatFrame = Stub.NewFrame()
    end)

    after_each(function()
        _G.TestCompatFrame = nil
        Stub.Uninstall(state)
    end)

    it("detects Dialogue UI only once it has loaded", function()
        assert.is_false(ns.Compat.IsDialogueUILoaded())
        state.loadedAddons.DialogueUI = true
        assert.is_true(ns.Compat.IsDialogueUILoaded())
    end)

    it("reports no addon as loaded when the client lacks the lookup", function()
        state.loadedAddons.DialogueUI = true
        _G.C_AddOns = nil
        assert.is_false(ns.Compat.IsDialogueUILoaded())
    end)

    it("skins normally when no other skinning addon is loaded", function()
        Register("character")
        ns.Windows.Start()
        assert.same({ "character" }, skinned)
    end)

    it(
        "leaves every window to a loaded full-interface skinning addon, saying so once each",
        function()
            state.loadedAddons.ElvUI = true
            Register("character")
            Register("spellbook")
            ns.Windows.Start()
            ns.Windows.Start()

            assert.same({}, skinned)
            assert.equal(2, #state.printed)
            assert.matches("character window is styled by ElvUI", state.printed[1], 1, true)
            local status = ns.Windows.Status()
            assert.equal("skipped", status[1].status)
            assert.equal("ElvUI", status[1].manager)
        end
    )

    it("leaves only the windows a partial skinning addon manages", function()
        state.loadedAddons.MailSkins = true
        ns.Compat.RegisterSkinner("MailSkins", function(id)
            return id == "mail"
        end)
        Register("character")
        Register("mail")
        ns.Windows.Start()
        assert.same({ "character" }, skinned)
        assert.equal("MailSkins", ns.Compat.ManagerOf("mail"))
        assert.is_nil(ns.Compat.ManagerOf("character"))
    end)

    it("ignores a skinning addon that is installed but not loaded", function()
        ns.Compat.RegisterSkinner("MailSkins")
        Register("mail")
        ns.Windows.Start()
        assert.same({ "mail" }, skinned)
    end)

    it("names the managing addon in the status listing", function()
        state.loadedAddons.Aurora = true
        Register("character")
        ns.Windows.Start()
        state.printed = {}
        _G.SlashCmdList.PARCHMENTUI("status")
        local line = "character: left to another addon (Aurora)"
        assert.matches(line, table.concat(state.printed, "\n"), 1, true)
    end)
end)
