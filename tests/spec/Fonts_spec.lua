local Stub = require("tests.stub.WowApi")

describe("fonts", function()
    local state, ns

    local function FontString(path, size, flags)
        local text = { font = { path, size, flags } }
        function text:GetFont()
            return self.font[1], self.font[2], self.font[3]
        end
        function text:SetFont(newPath, newSize, newFlags)
            self.font = { newPath, newSize, newFlags }
        end
        return text
    end

    local function Exists(addonPath)
        local relative = addonPath:gsub("^Interface\\AddOns\\", ""):gsub("\\", "/")
        local handle = io.open(relative, "rb")
        if handle then
            handle:close()
        end
        return handle ~= nil
    end

    before_each(function()
        state = Stub.Install()
        ns = state.Login()
    end)

    after_each(function()
        Stub.Uninstall(state)
    end)

    it("points every role at a font file that ships with the addon", function()
        for _, role in ipairs({ "body", "heading", "emphasis" }) do
            local path = ns.Fonts.Path(role)
            assert.is_true(Exists(path), role .. " font is missing: " .. tostring(path))
        end
        assert.is_true(Exists("Interface\\AddOns\\ParchmentUI\\Fonts\\OFL.txt"))
    end)

    it("has no font for an unknown role", function()
        assert.is_nil(ns.Fonts.Path("caption"))
    end)

    it("keeps the client font in locales the bundled typeface does not cover", function()
        for _, locale in ipairs({ "koKR", "zhCN", "zhTW" }) do
            state.locale = locale
            assert.is_nil(ns.Fonts.Path("body"))
        end
        state.locale = "ruRU"
        assert.is_not_nil(ns.Fonts.Path("body"))
    end)

    it("applies the typeface, the player's font size and the existing outline flags", function()
        ns.Options.Set("font", 1.25)
        local text = FontString("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        assert.is_true(ns.Skin.SetFont(text, ns.Theme.Current(), "heading", 16))
        assert.same({ ns.Fonts.Path("heading"), 20, "OUTLINE" }, text.font)
    end)

    it("changes only the size where the client font is kept", function()
        state.locale = "zhCN"
        local text = FontString("Fonts\\ARKai_T.ttf", 12, nil)
        assert.is_true(ns.Skin.SetFont(text, ns.Theme.Current(), "body", 14))
        assert.same({ "Fonts\\ARKai_T.ttf", 14, "" }, text.font)
    end)

    it("ignores a missing font string", function()
        assert.is_false(ns.Skin.SetFont(nil, ns.Theme.Current(), "body", 14))
        assert.is_false(ns.Skin.SetFont({}, ns.Theme.Current(), "body", 14))
    end)
end)
