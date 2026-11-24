local ADDON_NAME, ns = ...

if not ns.supported then
    return
end

local function PrintLines(lines)
    for index = 1, #lines do
        ns.Print(lines[index])
    end
end

local function PrintStatus()
    local L = ns.L
    local report = ns.Windows.Status()
    if #report == 0 then
        ns.Print(L.STATUS_NONE)
        return
    end
    ns.Print(L.STATUS_HEADER)
    for index = 1, #report do
        local entry = report[index]
        local label = L["STATUS_" .. entry.status:upper()]
        if entry.error then
            ns.Print(L.STATUS_LINE_ERROR:format(entry.id, label, entry.error))
        else
            ns.Print(L.STATUS_LINE:format(entry.id, label))
        end
    end
end

local commands = {
    status = PrintStatus,
    audit = function()
        PrintLines(ns.Audit.Collect())
    end,
    reset = function()
        ns.DB.Reset()
        ns.Print(ns.L.RESET_DONE)
    end,
}

local function PrintHelp()
    local L = ns.L
    PrintLines({ L.HELP_HEADER, L.HELP_STATUS, L.HELP_AUDIT, L.HELP_RESET })
end

SLASH_PARCHMENTUI1 = "/parchment"
SLASH_PARCHMENTUI2 = "/pui"
SlashCmdList.PARCHMENTUI = function(message)
    local command = (message or ""):lower():match("^%s*(%S*)")
    local handler = commands[command] or PrintHelp
    handler()
end
