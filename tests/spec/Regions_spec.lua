local Stub = require("tests.stub.WowApi")

describe("skin helpers", function()
    local state, ns, Skin

    local function Region(objectType)
        local region = { alpha = 1 }
        function region:SetAlpha(alpha)
            self.alpha = alpha
        end
        function region.GetObjectType()
            return objectType
        end
        function region:SetTextColor(red, green, blue)
            self.color = { red, green, blue }
        end
        return region
    end

    before_each(function()
        state = Stub.Install()
        ns = state.Login()
        Skin = ns.Skin
    end)

    after_each(function()
        Stub.Uninstall(state)
    end)

    it("reports an object and key as new only once, without marking the object", function()
        local frame, other = {}, {}
        assert.is_true(Skin.Once(frame, "background"))
        assert.is_false(Skin.Once(frame, "background"))
        assert.is_true(Skin.Once(frame, "tabs"))
        assert.is_true(Skin.Once(other, "background"))
        assert.is_nil(next(frame))
    end)

    it("walks child keys and stops quietly at a missing one", function()
        local frame = { Inset = { Bg = "texture" } }
        assert.equal("texture", Skin.Child(frame, "Inset", "Bg"))
        assert.is_nil(Skin.Child(frame, "Inset", "Border"))
        assert.is_nil(Skin.Child(frame, "Missing", "Bg"))
        assert.is_nil(Skin.Child(nil, "Inset"))
        assert.equal(frame, Skin.Child(frame))
    end)

    it("makes a stock region transparent and ignores a missing one", function()
        local texture = Region("Texture")
        assert.is_true(Skin.HideRegion(texture))
        assert.equal(0, texture.alpha)
        assert.is_false(Skin.HideRegion(nil))
        assert.is_false(Skin.HideRegion({}))
    end)

    it("hides named child regions and counts the ones it found", function()
        local frame = { Bg = Region("Texture"), TitleBg = Region("Texture") }
        assert.equal(2, Skin.HideRegions(frame, { "Bg", "TitleBg", "PortraitRing" }))
        assert.equal(0, frame.Bg.alpha)
        assert.equal(0, frame.TitleBg.alpha)
    end)

    it("strips a frame's textures but leaves its text alone", function()
        local background, border, title = Region("Texture"), Region("Texture"), Region("FontString")
        local frame = {
            GetRegions = function()
                return background, title, border
            end,
        }
        assert.equal(2, Skin.StripTextures(frame))
        assert.equal(0, background.alpha)
        assert.equal(0, border.alpha)
        assert.equal(1, title.alpha)
        assert.equal(0, Skin.StripTextures(nil))
        assert.equal(0, Skin.StripTextures({}))
    end)

    it("colors text by theme role", function()
        local text = Region("FontString")
        local theme = ns.Theme.Current()
        assert.is_true(Skin.ColorText(text, theme, "heading"))
        assert.same(theme.colors.heading, text.color)
        assert.is_false(Skin.ColorText(text, theme, "no-such-role"))
        assert.is_false(Skin.ColorText(nil, theme, "body"))
    end)

    it("keeps a game color readable on the current theme", function()
        local text = Region("FontString")
        local theme = ns.Theme.Current()
        assert.is_true(Skin.ColorGameText(text, theme, 0.12, 1.00, 0.00))
        local ratio = ns.Palette.ContrastRatio(text.color, theme.colors.surface)
        assert.is_true(ratio >= ns.Palette.MIN_CONTRAST)
    end)
end)
