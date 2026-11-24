std = "lua51"
max_line_length = 100
codes = true

files["ParchmentUI"] = {
    -- Every addon file opens with `local ADDON_NAME, ns = ...`; not all use the name.
    ignore = { "211/ADDON_NAME" },
    globals = {
        "ParchmentUI_DB",
        "SLASH_PARCHMENTUI1",
        "SLASH_PARCHMENTUI2",
        "SlashCmdList",
    },
    read_globals = {
        "C_AddOns",
        "CreateFrame",
        "GameFontNormal",
        "GetBuildInfo",
        "GetLocale",
        "InCombatLockdown",
        "UIPanelWindows",
        "UIParent",
        "WOW_PROJECT_ID",
        "geterrorhandler",
    },
}

files["tests"] = {
    std = "lua51+busted",
}
