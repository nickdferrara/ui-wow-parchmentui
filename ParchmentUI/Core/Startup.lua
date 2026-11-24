local ADDON_NAME, ns = ...

-- The TOC already keeps the addon off other clients. This is a second line of defence in case
-- the game type directive is not honored.
ns.supported = ns.IsSupportedClient((select(4, GetBuildInfo())))
if not ns.supported then
    return
end

ns.Events.Register("ADDON_LOADED", function(addonName)
    if addonName == ADDON_NAME then
        ParchmentUI_DB = ns.DB.Init(ParchmentUI_DB, ns.Migrations)
    else
        ns.Windows.OnAddonLoaded(addonName)
    end
end)

ns.Events.Register("PLAYER_LOGIN", function()
    ns.Windows.Start()
end)
