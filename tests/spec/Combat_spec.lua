local Stub = require("tests.stub.WowApi")

describe("combat queue", function()
    local state, ns

    before_each(function()
        state = Stub.Install()
        ns = state.Load()
    end)

    after_each(function()
        Stub.Uninstall(state)
    end)

    it("runs work immediately out of combat", function()
        local ran = 0
        assert.is_true(ns.Combat.RunWhenSafe(function()
            ran = ran + 1
        end))
        assert.equal(1, ran)
    end)

    it("holds work during combat and runs it in order when combat ends", function()
        local ran = {}
        state.inCombat = true
        for index = 1, 3 do
            assert.is_false(ns.Combat.RunWhenSafe(function()
                ran[#ran + 1] = index
            end))
        end
        assert.same({}, ran)

        state.inCombat = false
        state.Fire("PLAYER_REGEN_ENABLED")
        assert.same({ 1, 2, 3 }, ran)
        assert.equal(0, ns.Combat.PendingCount())
    end)

    it("collapses requests with the same key, keeping the latest", function()
        local ran = {}
        state.inCombat = true
        ns.Combat.RunWhenSafe(function()
            ran[#ran + 1] = "first"
        end, "layout:character")
        ns.Combat.RunWhenSafe(function()
            ran[#ran + 1] = "second"
        end, "layout:character")
        assert.equal(1, ns.Combat.PendingCount())

        state.inCombat = false
        state.Fire("PLAYER_REGEN_ENABLED")
        assert.same({ "second" }, ran)
    end)

    it("keeps running the queue after one entry fails", function()
        local ran = false
        state.inCombat = true
        ns.Combat.RunWhenSafe(function()
            error("broken")
        end)
        ns.Combat.RunWhenSafe(function()
            ran = true
        end)

        state.inCombat = false
        state.Fire("PLAYER_REGEN_ENABLED")
        assert.is_true(ran)
        assert.equal(1, #state.errors)
    end)
end)
