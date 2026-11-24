local ADDON_NAME, ns = ...

local Compat = {}
ns.Compat = Compat

Compat.DIALOGUE_UI = "DialogueUI"

-- Addons that restyle Blizzard windows themselves. Two addons skinning one window fight over
-- the same textures, so a window one of these manages is left to it.
local skinners = {}

function Compat.IsAddOnLoaded(addonName)
    if not (C_AddOns and C_AddOns.IsAddOnLoaded) then
        return false
    end
    local _, finished = C_AddOns.IsAddOnLoaded(addonName)
    return finished == true
end

function Compat.IsDialogueUILoaded()
    return Compat.IsAddOnLoaded(Compat.DIALOGUE_UI)
end

-- manages is an optional function taking a window id. Without it the addon is treated as
-- managing every window.
function Compat.RegisterSkinner(addonName, manages)
    skinners[#skinners + 1] = { addonName = addonName, manages = manages }
end

-- Returns the name of the loaded addon that manages the window, or nil.
function Compat.ManagerOf(windowId)
    for index = 1, #skinners do
        local skinner = skinners[index]
        if
            Compat.IsAddOnLoaded(skinner.addonName)
            and (not skinner.manages or skinner.manages(windowId))
        then
            return skinner.addonName
        end
    end
    return nil
end

Compat.RegisterSkinner("ElvUI")
Compat.RegisterSkinner("Aurora")
