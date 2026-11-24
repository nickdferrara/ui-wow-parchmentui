local Stub = require("tests.stub.WowApi")

describe("dock", function()
    local state, Dock
    local SCREEN = { width = 1920, height = 1080 }

    local function Options(overrides)
        local options = { side = "right", offset = 40, scale = 1 }
        for key, value in pairs(overrides or {}) do
            options[key] = value
        end
        return options
    end

    before_each(function()
        state = Stub.Install()
        Dock = state.Load().Layout
    end)

    after_each(function()
        Stub.Uninstall(state)
    end)

    describe("stacking", function()
        it("puts a second window beside the first", function()
            assert.same({ "character", "bags" }, Dock.Push({ "character" }, "bags"))
        end)

        it("replaces the second window with a third", function()
            assert.same({ "character", "talents" }, Dock.Push({ "character", "bags" }, "talents"))
        end)

        it("does not move a window that is already docked", function()
            assert.same({ "character", "bags" }, Dock.Push({ "character", "bags" }, "character"))
        end)

        it("moves the second window to the edge when the first closes", function()
            assert.same({ "bags" }, Dock.Remove({ "character", "bags" }, "character"))
        end)
    end)

    describe("slots", function()
        it("anchors a single window to the right edge, vertically centered", function()
            local slots = Dock.Compute(SCREEN, Options(), {
                { id = "character", width = 400, height = 600 },
            })
            assert.same({ id = "character", point = "RIGHT", x = -40, y = 0, scale = 1 }, slots[1])
        end)

        it("mirrors to the left edge", function()
            local slots = Dock.Compute(SCREEN, Options({ side = "left" }), {
                { id = "character", width = 400, height = 600 },
            })
            assert.equal("LEFT", slots[1].point)
            assert.equal(40, slots[1].x)
        end)

        it("places the second window to the left of the first with a gap", function()
            local slots = Dock.Compute(SCREEN, Options(), {
                { id = "character", width = 400, height = 600 },
                { id = "bags", width = 300, height = 500 },
            })
            assert.equal(-(40 + 400 + Dock.GAP), slots[2].x)
        end)

        it("leaves room for a panel another addon has at the edge", function()
            local slots = Dock.Compute(SCREEN, Options({ reserved = 500 }), {
                { id = "character", width = 400, height = 600 },
            })
            assert.equal(-540, slots[1].x)
        end)

        it("scales a window down when it is taller than the screen", function()
            local screen = { width = 1280, height = 720 }
            local slots = Dock.Compute(screen, Options(), {
                { id = "talents", width = 400, height = 1376 },
            })
            assert.equal(0.5, slots[1].scale)
        end)

        it("never scales a window above the player's chosen scale", function()
            local slots = Dock.Compute(SCREEN, Options({ scale = 0.8 }), {
                { id = "character", width = 400, height = 200 },
            })
            assert.equal(0.8, slots[1].scale)
        end)

        it("shrinks windows that would not fit side by side", function()
            local screen = { width = 1280, height = 720 }
            local slots = Dock.Compute(screen, Options(), {
                { id = "character", width = 800, height = 600 },
                { id = "talents", width = 800, height = 600 },
            })
            local farEdge = -slots[2].x + 800 * slots[2].scale
            assert.is_true(slots[1].scale < 1)
            assert.is_true(farEdge <= screen.width - Dock.MARGIN + 1e-6)
        end)
    end)
end)
