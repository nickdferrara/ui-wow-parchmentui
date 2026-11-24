local Stub = require("tests.stub.WowApi")

describe("textures", function()
    local state, ns

    -- Reads the fields of an uncompressed TGA header that the asset rules constrain.
    local function ReadHeader(addonPath)
        local relative = addonPath:gsub("^Interface\\AddOns\\", ""):gsub("\\", "/")
        local handle = assert(io.open(relative, "rb"), "missing file: " .. relative)
        local header = handle:read(18)
        local size = handle:seek("end")
        handle:close()
        local function Word(offset)
            return header:byte(offset) + header:byte(offset + 1) * 256
        end
        return {
            imageType = header:byte(3),
            width = Word(13),
            height = Word(15),
            bitsPerPixel = header:byte(17),
            size = size,
        }
    end

    local function IsPowerOfTwo(value)
        while value > 1 and value % 2 == 0 do
            value = value / 2
        end
        return value == 1
    end

    before_each(function()
        state = Stub.Install()
        ns = state.Login()
    end)

    after_each(function()
        Stub.Uninstall(state)
    end)

    it("registers the scroll artwork", function()
        local expected = { "buttonOutline", "divider", "scrollRoll", "scrollSurface" }
        assert.same(expected, ns.Textures.Keys())
    end)

    it("ships every registered file as 32-bit uncompressed TGA with the registered size", function()
        for _, key in ipairs(ns.Textures.Keys()) do
            local header = ReadHeader(ns.Textures.Get(key))
            local width, height = ns.Textures.Info(key)
            assert.equal(2, header.imageType, key)
            assert.equal(32, header.bitsPerPixel, key)
            assert.equal(width, header.width, key)
            assert.equal(height, header.height, key)
            assert.equal(18 + width * height * 4, header.size, key)
        end
    end)

    it("keeps every texture to power-of-two sides no longer than 1024", function()
        for _, key in ipairs(ns.Textures.Keys()) do
            local width, height = ns.Textures.Info(key)
            assert.is_true(IsPowerOfTwo(width) and width <= 1024, key)
            assert.is_true(IsPowerOfTwo(height) and height <= 1024, key)
        end
    end)

    it("leaves a stretchable middle inside every nine-slice margin", function()
        for _, key in ipairs(ns.Textures.Keys()) do
            local width, _, margin = ns.Textures.Info(key)
            if margin then
                assert.is_true(margin * 2 < width, key)
            end
        end
    end)

    it("returns nothing for an unknown key and refuses a duplicate", function()
        assert.is_nil(ns.Textures.Get("portrait"))
        assert.is_nil(ns.Textures.Info("portrait"))
        assert.has_error(function()
            ns.Textures.Register("divider", "Other.tga", { width = 8, height = 8 })
        end)
    end)
end)
