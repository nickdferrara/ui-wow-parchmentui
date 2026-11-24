local Stub = require("tests.stub.WowApi")

describe("saved variables", function()
    local state, ns

    before_each(function()
        state = Stub.Install()
        ns = state.Load()
    end)

    after_each(function()
        Stub.Uninstall(state)
    end)

    it("starts a new install at the current schema version with nothing else stored", function()
        local data = ns.DB.Init(nil, ns.Migrations)
        assert.same({ schemaVersion = ns.SCHEMA_VERSION }, data)
    end)

    it("falls back to defaults for values the player never changed", function()
        ns.DB.Init({}, ns.Migrations)
        assert.equal("light", ns.DB.Get("theme"))
        assert.equal(0.25, ns.DB.Get("animation.duration"))
    end)

    it("enables a window that has no stored or default entry", function()
        ns.DB.Init({}, ns.Migrations)
        assert.is_true(ns.DB.IsWindowEnabled("character"))
    end)

    it("stores only values that differ from the defaults", function()
        local data = ns.DB.Init({}, ns.Migrations)
        ns.DB.Set("theme", "dark")
        ns.DB.Set("windows.character.enabled", false)
        assert.equal("dark", data.theme)
        assert.is_false(ns.DB.IsWindowEnabled("character"))

        ns.DB.Set("theme", "light")
        ns.DB.Set("windows.character.enabled", true)
        assert.same({ schemaVersion = ns.SCHEMA_VERSION }, data)
    end)

    it("reset removes every stored value", function()
        local data = ns.DB.Init({ theme = "dark", schemaVersion = ns.SCHEMA_VERSION })
        ns.DB.Reset()
        assert.same({ schemaVersion = ns.SCHEMA_VERSION }, data)
        assert.equal("light", ns.DB.Get("theme"))
    end)

    describe("migrations", function()
        it("run in order from the stored version to the current one", function()
            ns.SCHEMA_VERSION = 3
            local ran = {}
            local migrations = {
                [1] = function()
                    ran[#ran + 1] = 1
                end,
                [2] = function(data)
                    ran[#ran + 1] = 2
                    data.dockSide, data.side = data.side, nil
                end,
                [3] = function()
                    ran[#ran + 1] = 3
                end,
            }
            local data = ns.DB.Init({ schemaVersion = 1, side = "left" }, migrations)
            assert.same({ 2, 3 }, ran)
            assert.same({ schemaVersion = 3, dockSide = "left" }, data)
        end)

        it("treat unversioned data with content as older than every migration", function()
            local ran = false
            ns.DB.Init({ theme = "dark" }, {
                [1] = function()
                    ran = true
                end,
            })
            assert.is_true(ran)
        end)

        it("leave data from a newer release at its own version", function()
            local data = ns.DB.Init({ schemaVersion = ns.SCHEMA_VERSION + 4 }, {})
            assert.equal(ns.SCHEMA_VERSION + 4, data.schemaVersion)
        end)
    end)

    it("initialises the saved variable when the addon loads", function()
        _G.ParchmentUI_DB = { theme = "dark" }
        state.Fire("ADDON_LOADED", "ParchmentUI")
        assert.equal(ns.SCHEMA_VERSION, _G.ParchmentUI_DB.schemaVersion)
        assert.equal("dark", ns.DB.Get("theme"))
    end)
end)
