local ADDON_NAME, ns = ...

local Audit = {}
ns.Audit = Audit

-- Frame names collected from community notes. The report from the live client decides which
-- of them exist; nothing here is relied on by the skins.
Audit.CANDIDATES = {
    { frameName = "CharacterFrame" },
    { frameName = "PaperDollFrame" },
    { frameName = "PlayerSpellsFrame", loadOnDemand = "Blizzard_PlayerSpells" },
    { frameName = "LFGParentFrame" },
    { frameName = "LFGListingFrame" },
    { frameName = "LFGBrowseFrame" },
    { frameName = "LFGFrame" },
    { frameName = "LFDFrame" },
    { frameName = "PVEFrame" },
    { frameName = "SkillsFrame" },
    { frameName = "LegacySystemFrame" },
    { frameName = "SocialUIFrame" },
    { frameName = "FriendsFrame" },
    { frameName = "MerchantFrame" },
    { frameName = "BankFrame" },
    { frameName = "MailFrame" },
}

local function YesNo(value)
    return value and ns.L.AUDIT_YES or ns.L.AUDIT_NO
end

local function DescribeFrame(candidate)
    local L = ns.L
    local name = candidate.frameName
    local frame = _G[name]
    if type(frame) ~= "table" or type(frame.GetObjectType) ~= "function" then
        local addon = candidate.loadOnDemand
        local loaded = addon
            and C_AddOns
            and C_AddOns.IsAddOnLoaded
            and C_AddOns.IsAddOnLoaded(addon)
        if addon and not loaded then
            return L.AUDIT_NOT_LOADED:format(name, addon)
        end
        return L.AUDIT_MISSING:format(name)
    end
    local width, height = frame:GetSize()
    local panel = type(UIPanelWindows) == "table" and UIPanelWindows[name]
    local area = type(panel) == "table" and panel.area or L.AUDIT_UNKNOWN
    return L.AUDIT_FRAME:format(
        name,
        frame:GetObjectType(),
        width or 0,
        height or 0,
        YesNo(frame:IsProtected()),
        YesNo(frame:IsShown()),
        tostring(area)
    )
end

function Audit.Collect()
    local L = ns.L
    local version, build, _, interface = GetBuildInfo()
    local lines = {
        L.AUDIT_BUILD:format(
            tostring(version),
            tostring(build),
            tostring(interface),
            tostring(WOW_PROJECT_ID)
        ),
        L.AUDIT_PANEL_MANAGER:format(YesNo(type(UIPanelWindows) == "table")),
    }
    for index = 1, #Audit.CANDIDATES do
        lines[#lines + 1] = DescribeFrame(Audit.CANDIDATES[index])
    end
    return lines
end
