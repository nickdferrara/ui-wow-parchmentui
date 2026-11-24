local ADDON_NAME, ns = ...

ns.SCHEMA_VERSION = 1

ns.Defaults = {
    theme = "light",
    dockSide = "right",
    dockOffset = 40,
    scale = 1,
    fontScale = 1,
    animation = {
        enabled = true,
        duration = 0.25,
    },
    windows = {},
}

-- Applies to every window id, so a newly added window needs no entry in Defaults.
ns.WindowDefaults = {
    enabled = true,
}

-- Keyed by the schema version each function migrates to. Released entries are never edited.
ns.Migrations = {}
