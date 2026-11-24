local Stub = require("tests.stub.WowApi")

describe("scroll surface", function()
    local state, ns, frame

    before_each(function()
        state = Stub.Install()
        ns = state.Login()
        frame = Stub.NewFrame({ width = 400, height = 600 })
    end)

    after_each(function()
        Stub.Uninstall(state)
    end)

    it("builds a sheet and two rolls behind the frame's contents", function()
        local handle = ns.Scroll.Apply(frame, ns.Theme.Current())
        assert.equal(3, #frame.textures)
        for _, texture in ipairs(frame.textures) do
            assert.equal("BACKGROUND", texture.layer)
        end
        assert.same({ ns.Textures.Get("scrollSurface") }, handle.surface.last.SetTexture)
        assert.same({ ns.Textures.Get("scrollRoll") }, handle.topRoll.last.SetTexture)
        assert.same({ ns.Textures.Get("scrollRoll") }, handle.bottomRoll.last.SetTexture)
    end)

    it("starts fully unrolled and opaque", function()
        local handle = ns.Scroll.Apply(frame, ns.Theme.Current())
        assert.same({ 600 }, handle.surface.last.SetHeight)
        assert.same({ 1 }, handle.bottomRoll.last.SetAlpha)
    end)

    it("reuses its textures when applied again and follows a theme change", function()
        local first = ns.Scroll.Apply(frame, ns.Theme.Current())
        ns.Options.Set("theme", "dark")
        local second = ns.Scroll.Apply(frame, ns.Theme.Current())
        assert.equal(first, second)
        assert.equal(3, #frame.textures)
        assert.same(ns.Palette.themes.dark.surface, second.surface.last.SetVertexColor)
        assert.same(ns.Palette.themes.dark.surface, second.topRoll.last.SetVertexColor)
    end)

    it("unrolls by growing the sheet from the top, taking the bottom roll with it", function()
        local handle = ns.Scroll.Apply(frame, ns.Theme.Current())
        ns.Scroll.SetReveal(handle, 0.5, 0.25)
        assert.same({ 150 }, handle.surface.last.SetHeight)
        assert.same({ 0.5 }, handle.surface.last.SetAlpha)
        assert.same({ 0.5 }, handle.topRoll.last.SetAlpha)
        assert.equal(handle.surface, handle.bottomRoll.last.SetPoint[2])

        ns.Scroll.SetReveal(handle, 0, 0)
        assert.same({ 1 }, handle.surface.last.SetHeight)
    end)

    it("protects the edges of the artwork from stretching where the client supports it", function()
        local handle = ns.Scroll.Apply(frame, ns.Theme.Current())
        assert.same({ 48, 48, 48, 48 }, handle.surface.last.SetTextureSliceMargins)
        assert.same({ 16, 0, 16, 0 }, handle.topRoll.last.SetTextureSliceMargins)
    end)

    it("still builds the scroll on a client without nine-slice scaling", function()
        frame.missingTextureMethods = { SetTextureSliceMargins = true }
        local handle = ns.Scroll.Apply(frame, ns.Theme.Current())
        assert.is_not_nil(handle)
        assert.is_nil(handle.surface.last.SetTextureSliceMargins)
        assert.same({ 600 }, handle.surface.last.SetHeight)
    end)

    it("drives the unroll from the animation module", function()
        local handle = ns.Scroll.Apply(frame, ns.Theme.Current())
        ns.Animation.Play(frame, true, function(alpha, reveal)
            ns.Scroll.SetReveal(handle, alpha, reveal)
        end)
        assert.same({ 0 }, handle.surface.last.SetAlpha)
        state.Tick(1)
        assert.same({ 600 }, handle.surface.last.SetHeight)
        assert.same({ 1 }, handle.surface.last.SetAlpha)
    end)

    it("returns nothing for something that cannot hold textures", function()
        assert.is_nil(ns.Scroll.Apply(nil, ns.Theme.Current()))
        assert.is_nil(ns.Scroll.Apply({}, ns.Theme.Current()))
    end)
end)
