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

local function PrintOptions()
    local L = ns.L
    ns.Print(L.OPTIONS_HEADER)
    for index = 1, #ns.Options.ORDER do
        local name = ns.Options.ORDER[index]
        ns.Print(L.OPTION_LINE:format(name, ns.Options.Describe(name), ns.Options.Usage(name)))
    end
end

local function HandleOption(name, text)
    local L = ns.L
    if text == "" then
        ns.Print(L.OPTION_CURRENT:format(name, ns.Options.Describe(name)))
        return
    end
    local ok, err = ns.Options.Set(name, ns.Options.Parse(name, text))
    if ok then
        ns.Print(L.OPTION_SET:format(name, ns.Options.Describe(name)))
    elseif err == ns.Options.ERROR_UNAVAILABLE then
        ns.Print(L.OPTION_UNAVAILABLE:format(text))
    else
        ns.Print(L.OPTION_INVALID:format(text, name, ns.Options.Usage(name)))
    end
end

local function HandleWindow(text)
    local L = ns.L
    local id, word = text:match("^(%S+)%s+(%S+)$")
    local enabled = ns.Options.ParseToggle(word)
    if not id or enabled == nil then
        ns.Print(L.HELP_WINDOW)
    elseif ns.Options.SetWindowEnabled(id, enabled) then
        ns.Print(L.WINDOW_SET:format(id, word))
    else
        ns.Print(L.WINDOW_UNKNOWN:format(id))
    end
end

local commands = {
    status = PrintStatus,
    options = PrintOptions,
    window = HandleWindow,
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
    PrintLines({
        L.HELP_HEADER,
        L.HELP_OPTIONS,
        L.HELP_OPTION,
        L.HELP_WINDOW,
        L.HELP_STATUS,
        L.HELP_AUDIT,
        L.HELP_RESET,
    })
end

SLASH_PARCHMENTUI1 = "/parchment"
SLASH_PARCHMENTUI2 = "/pui"
SlashCmdList.PARCHMENTUI = function(message)
    local command, rest = (message or ""):lower():match("^%s*(%S*)%s*(.-)%s*$")
    if commands[command] then
        commands[command](rest)
    elseif ns.Options.Has(command) then
        HandleOption(command, rest)
    else
        PrintHelp()
    end
end
