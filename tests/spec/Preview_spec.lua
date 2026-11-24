local Stub = require("tests.stub.WowApi")

describe("sample scroll preview", function()
    local state, ns, Preview

    -- The preview's own frame is the one parented to the screen.
    local function PreviewFrame()
        for _, frame in ipairs(state.frames) do
            if frame.parent == _G.UIParent and frame.frameType == "Frame" then
                return frame
            end
        end
    end

    local function Sheet()
        for _, texture in ipairs(PreviewFrame().textures) do
            if texture.last.SetTexture[1] == ns.Textures.Get("scrollSurface") then
                return texture
            end
        end
    end

    before_each(function()
        state = Stub.Install()
        _G.UIParent = Stub.NewFrame({ width = 1920, height = 1080 })
        ns = state.Login()
        Preview = ns.Preview
    end)

    after_each(function()
        Stub.Uninstall(state)
    end)

    it("creates nothing until it is first opened", function()
        assert.is_nil(PreviewFrame())
        assert.is_false(Preview.IsShown())
    end)

    it("opens docked at the right edge and unrolls", function()
        Preview.Show()
        local frame = PreviewFrame()
        assert.is_true(Preview.IsShown())
        assert.same({ "RIGHT", _G.UIParent, "RIGHT", -40, 0 }, frame.last.SetPoint)
        assert.same({ 1 }, frame.last.SetScale)
        assert.is_true(ns.Animation.IsPlaying(frame))

        state.Tick(1)
        assert.is_false(ns.Animation.IsPlaying(frame))
        assert.same({ 512 }, Sheet().last.SetHeight)
    end)

    it("shows its text in the bundled typeface and theme ink", function()
        Preview.Show()
        local title = PreviewFrame().fontStrings[1]
        assert.equal(ns.Fonts.Path("heading"), title.last.SetFont[1])
        assert.same(ns.Palette.themes.light.heading, title.last.SetTextColor)
        assert.same({ ns.L.PREVIEW_TITLE }, title.last.SetText)
    end)

    it("anchors in its own scaled units when it has to shrink to fit", function()
        _G.UIParent.width, _G.UIParent.height = 1280, 288
        Preview.Show()
        local frame = PreviewFrame()
        assert.same({ 0.5 }, frame.last.SetScale)
        assert.equal(-80, frame.last.SetPoint[4])
    end)

    it("rolls up before hiding, and reopens if toggled while rolling up", function()
        Preview.Toggle()
        state.Tick(1)
        Preview.Toggle()
        local frame = PreviewFrame()
        assert.is_true(frame:IsShown())
        assert.is_false(Preview.IsShown())

        Preview.Toggle()
        state.Tick(1)
        assert.is_true(frame:IsShown())
        assert.is_true(Preview.IsShown())

        Preview.Toggle()
        state.Tick(1)
        assert.is_false(frame:IsShown())
    end)

    it("opens and closes at once in combat", function()
        state.inCombat = true
        Preview.Show()
        assert.is_false(ns.Animation.IsPlaying(PreviewFrame()))
        Preview.Hide()
        assert.is_false(PreviewFrame():IsShown())
    end)

    it("follows option changes while open", function()
        Preview.Show()
        local frame = PreviewFrame()
        ns.Options.Set("side", "left")
        ns.Options.Set("theme", "dark")
        assert.same({ "LEFT", _G.UIParent, "LEFT", 40, 0 }, frame.last.SetPoint)
        assert.same(ns.Palette.themes.dark.surface, Sheet().last.SetVertexColor)
    end)

    it("ignores option changes while closed", function()
        Preview.Show()
        state.Tick(1)
        Preview.Hide()
        state.Tick(1)
        ns.Options.Set("side", "left")
        assert.equal("RIGHT", PreviewFrame().last.SetPoint[1])
    end)

    it("closes from its button and toggles from the slash command", function()
        _G.SlashCmdList.PARCHMENTUI("preview")
        local frame = PreviewFrame()
        assert.is_true(Preview.IsShown())
        state.Tick(1)
        for _, candidate in ipairs(state.frames) do
            if candidate.parent == frame then
                candidate:Run("OnClick")
            end
        end
        state.Tick(1)
        assert.is_false(frame:IsShown())
    end)
end)
