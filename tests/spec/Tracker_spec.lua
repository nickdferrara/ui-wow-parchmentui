local Stub = require("tests.stub.WowApi")

describe("open window tracking", function()
    local state, ns, layouts
    local FRAMES = {
        character = { name = "TestCharacterFrame", width = 400, height = 600 },
        bags = { name = "TestBagFrame", width = 300, height = 500 },
        talents = { name = "TestTalentFrame", width = 500, height = 700 },
    }

    local function Frame(id)
        return _G[FRAMES[id].name]
    end

    local function LastSlot(id)
        local slot
        for _, entry in ipairs(layouts) do
            if entry.id == id then
                slot = entry.slot
            end
        end
        return slot
    end

    before_each(function()
        layouts = {}
        state = Stub.Install()
        ns = state.Login()
        _G.UIParent = Stub.NewFrame({ width = 1920, height = 1080 })
        for id, info in pairs(FRAMES) do
            _G[info.name] = Stub.NewFrame({ width = info.width, height = info.height })
            ns.Windows.Register({
                id = id,
                frameName = info.name,
                Skin = function() end,
                Layout = function(_, dock)
                    layouts[#layouts + 1] = { id = id, slot = dock.slot }
                end,
            })
        end
        ns.Windows.Start()
    end)

    after_each(function()
        for _, info in pairs(FRAMES) do
            _G[info.name] = nil
        end
        Stub.Uninstall(state)
    end)

    it("docks the first window at the screen edge", function()
        Frame("character"):Show()
        assert.same({ "character" }, ns.Layout.Tracker.Open())
        assert.equal(-40, LastSlot("character").x)
    end)

    it("docks a second window beside the first without moving the first", function()
        Frame("character"):Show()
        Frame("bags"):Show()
        assert.equal(-40, LastSlot("character").x)
        assert.equal(-(40 + 400 + ns.Layout.GAP), LastSlot("bags").x)
    end)

    it("moves the second window to the edge when the first closes", function()
        Frame("character"):Show()
        Frame("bags"):Show()
        Frame("character"):Hide()
        assert.same({ "bags" }, ns.Layout.Tracker.Open())
        assert.equal(-40, LastSlot("bags").x)
    end)

    it("gives a third window the second slot and leaves the displaced one undocked", function()
        Frame("character"):Show()
        Frame("bags"):Show()
        Frame("talents"):Show()
        assert.same({ "character", "talents" }, ns.Layout.Tracker.Open())
        assert.equal(-(40 + 400 + ns.Layout.GAP), LastSlot("talents").x)
        assert.is_nil(ns.Layout.Tracker.SlotFor("bags"))

        Frame("bags"):Hide()
        assert.same({ "character", "talents" }, ns.Layout.Tracker.Open())
    end)

    it("follows the dock side and offset options", function()
        ns.Options.Set("side", "left")
        ns.Options.Set("offset", 100)
        Frame("character"):Show()
        local slot = LastSlot("character")
        assert.equal("LEFT", slot.point)
        assert.equal(100, slot.x)
    end)

    it("waits for combat to end before moving a neighbour", function()
        Frame("character"):Show()
        Frame("bags"):Show()
        local before = #layouts
        state.inCombat = true
        Frame("character"):Hide()
        assert.equal(before, #layouts)

        state.inCombat = false
        state.Fire("PLAYER_REGEN_ENABLED")
        assert.equal(-40, LastSlot("bags").x)
    end)

    it("tracks a window that was already open when its skin was applied", function()
        _G.TestMailFrame = Stub.NewFrame({ width = 350, height = 450, shown = true })
        ns.Windows.Register({
            id = "mail",
            frameName = "TestMailFrame",
            loadOnDemand = "Blizzard_Test",
            Skin = function() end,
            Layout = function() end,
        })
        state.Fire("ADDON_LOADED", "Blizzard_Test")
        _G.TestMailFrame = nil
        assert.same({ "mail" }, ns.Layout.Tracker.Open())
    end)

    it("gives no slot when the screen size is unknown", function()
        _G.UIParent = nil
        Frame("character"):Show()
        assert.is_nil(LastSlot("character"))
        assert.equal("skinned", ns.Windows.Status()[1].status)
    end)
end)
