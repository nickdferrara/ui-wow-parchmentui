local ADDON_NAME, ns = ...

local Textures = {}
ns.Textures = Textures

local ART_PATH = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Art\\"
local files = {}

-- Window modules refer to artwork by key only, so a file can be renamed in one place.
function Textures.Register(key, fileName)
    assert(files[key] == nil, "texture registered twice: " .. tostring(key))
    files[key] = ART_PATH .. fileName
end

function Textures.Get(key)
    return files[key]
end
