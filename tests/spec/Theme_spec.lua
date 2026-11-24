local Stub = require("tests.stub.WowApi")

describe("theme", function()
    local state, ns

    before_each(function()
        state = Stub.Install()
        ns = state.Login()
    end)

    after_each(function()
        Stub.Uninstall(state)
    end)

    it("computes WCAG contrast ratios", function()
        local ratio = ns.Palette.ContrastRatio({ 0, 0, 0 }, { 1, 1, 1 })
        assert.is_true(math.abs(ratio - 21) < 1e-9)
        assert.equal(1, ns.Palette.ContrastRatio({ 0.5, 0.5, 0.5 }, { 0.5, 0.5, 0.5 }))
    end)

    it("keeps every text color readable on its surface in both themes", function()
        for name, colors in pairs(ns.Palette.themes) do
            for _, role in ipairs({ "body", "heading", "muted" }) do
                local ratio = ns.Palette.ContrastRatio(colors[role], colors.surface)
                assert.is_true(
                    ratio >= ns.Palette.MIN_CONTRAST,
                    ("%s %s contrast is %.2f"):format(name, role, ratio)
                )
            end
        end
    end)

    it("darkens a bright game color on parchment until it is readable", function()
        local surface = ns.Palette.themes.light.surface
        local uncommonGreen = { 0.12, 1.00, 0.00 }
        local adjusted = ns.Palette.Legible(uncommonGreen, surface)
        assert.is_true(ns.Palette.ContrastRatio(adjusted, surface) >= ns.Palette.MIN_CONTRAST)
        assert.is_true(adjusted[2] > adjusted[1] and adjusted[2] > adjusted[3])
        assert.is_true(adjusted[2] < uncommonGreen[2])
    end)

    it("lightens a dim game color on the dark surface", function()
        local surface = ns.Palette.themes.dark.surface
        local adjusted = ns.Palette.Legible({ 0.00, 0.20, 0.60 }, surface)
        assert.is_true(ns.Palette.ContrastRatio(adjusted, surface) >= ns.Palette.MIN_CONTRAST)
    end)

    it("leaves an already readable color unchanged", function()
        local surface = ns.Palette.themes.light.surface
        assert.same({ 0.1, 0.1, 0.1 }, ns.Palette.Legible({ 0.1, 0.1, 0.1 }, surface))
    end)

    it("follows the stored theme choice", function()
        ns.DB.Set("theme", "dark")
        local theme = ns.Theme.Current()
        assert.equal("dark", theme.id)
        assert.equal(ns.Palette.themes.dark, theme.colors)
    end)

    it("falls back to the light theme for an unknown or unresolved choice", function()
        assert.equal("light", ns.Theme.Resolve("sepia"))
        assert.equal("light", ns.Theme.Resolve(ns.Theme.MATCH_DIALOGUE_UI))
    end)
end)
