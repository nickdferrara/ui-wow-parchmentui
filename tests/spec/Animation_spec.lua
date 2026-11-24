local Stub = require("tests.stub.WowApi")

describe("animation", function()
    local state, ns, Animation, target, frames

    local function Record(alpha, reveal)
        frames[#frames + 1] = { alpha = alpha, reveal = reveal }
    end

    before_each(function()
        frames = {}
        target = {}
        state = Stub.Install()
        ns = state.Login()
        Animation = ns.Animation
    end)

    after_each(function()
        Stub.Uninstall(state)
    end)

    it("runs no per-frame handler while idle", function()
        assert.equal(0, state.OnUpdateCount())
    end)

    it("unrolls from closed to open over the configured duration", function()
        local done = 0
        assert.is_true(Animation.Play(target, true, Record, function()
            done = done + 1
        end))
        assert.same({ alpha = 0, reveal = 0 }, frames[1])
        assert.equal(1, state.OnUpdateCount())

        state.Tick(0.1)
        assert.is_true(frames[2].reveal > 0 and frames[2].reveal < 1)
        assert.equal(0, done)

        state.Tick(0.2)
        assert.same({ alpha = 1, reveal = 1 }, frames[#frames])
        assert.equal(1, done)
        assert.is_false(Animation.IsPlaying(target))
        assert.equal(0, state.OnUpdateCount())
    end)

    it("is fully opaque before the unroll completes", function()
        local alpha, reveal = Animation.Evaluate({ opening = true, duration = 1 }, 0.5)
        assert.equal(1, alpha)
        assert.is_true(reveal < 1)
    end)

    it("closes as the reverse of opening", function()
        local opening = { opening = true, duration = 0.4 }
        local closing = { opening = false, duration = 0.4 }
        local alpha, reveal = Animation.Evaluate(closing, 0.1)
        local openAlpha, openReveal = Animation.Evaluate(opening, 0.3)
        assert.is_true(math.abs(alpha - openAlpha) < 1e-9)
        assert.is_true(math.abs(reveal - openReveal) < 1e-9)
        assert.same({ 0, 0 }, { Animation.Evaluate(closing, 5) })
    end)

    it("applies the final state at once when animation is switched off", function()
        ns.Options.Set("animation", false)
        local done = false
        assert.is_false(Animation.Play(target, true, Record, function()
            done = true
        end))
        assert.same({ { alpha = 1, reveal = 1 } }, frames)
        assert.is_true(done)
        assert.equal(0, state.OnUpdateCount())
    end)

    it("applies the final state at once in combat", function()
        state.inCombat = true
        assert.is_false(Animation.Play(target, false, Record))
        assert.same({ { alpha = 0, reveal = 0 } }, frames)
    end)

    it("completes a running animation when combat starts", function()
        Animation.Play(target, true, Record)
        state.Tick(0.05)
        state.Fire("PLAYER_REGEN_DISABLED")
        assert.same({ alpha = 1, reveal = 1 }, frames[#frames])
        assert.equal(0, state.OnUpdateCount())
    end)

    it("follows the speed option", function()
        ns.Options.Set("speed", 1)
        Animation.Play(target, true, Record)
        state.Tick(0.5)
        assert.is_true(Animation.IsPlaying(target))
        state.Tick(0.5)
        assert.is_false(Animation.IsPlaying(target))
    end)

    it("replaces an animation in progress without finishing the old one", function()
        local firstDone = false
        Animation.Play(target, true, Record, function()
            firstDone = true
        end)
        state.Tick(0.1)
        Animation.Play(target, false, Record)
        state.Tick(1)
        assert.is_false(firstDone)
        assert.same({ alpha = 0, reveal = 0 }, frames[#frames])
        assert.equal(0, state.OnUpdateCount())
    end)

    it("animates two targets independently and lets a callback start another", function()
        local other, chained = {}, {}
        Animation.Play(target, true, Record, function()
            Animation.Play(chained, true, Record)
        end)
        Animation.Play(other, true, Record)
        state.Tick(1)
        assert.is_false(Animation.IsPlaying(target))
        assert.is_false(Animation.IsPlaying(other))
        assert.is_true(Animation.IsPlaying(chained))
        assert.equal(1, state.OnUpdateCount())
    end)

    it("drops an animation whose apply function fails", function()
        local calls = 0
        Animation.Play(target, true, function()
            calls = calls + 1
            if calls == 2 then
                error("region missing")
            end
        end)
        state.Tick(0.05)
        assert.is_false(Animation.IsPlaying(target))
        assert.equal(1, #state.errors)
        state.Tick(0.05)
        assert.equal(3, calls)
    end)
end)
