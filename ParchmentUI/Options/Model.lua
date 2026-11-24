local ADDON_NAME, ns = ...

local Options = {}
ns.Options = Options

-- Options are addressed by a short name, which is also the slash command word. Numbers marked
-- percent are stored as a fraction and shown to the player as a percentage.
local DEFINITIONS = {
    theme = { path = "theme", kind = "choice", choices = { "light", "dark", "match" } },
    side = { path = "dockSide", kind = "choice", choices = { "right", "left" } },
    offset = { path = "dockOffset", kind = "number", min = 0, max = 400 },
    scale = { path = "scale", kind = "number", min = 0.5, max = 1.5, percent = true },
    font = { path = "fontScale", kind = "number", min = 1, max = 1.5, percent = true },
    animation = { path = "animation.enabled", kind = "toggle" },
    speed = { path = "animation.duration", kind = "number", min = 0.1, max = 1 },
}

Options.ORDER = { "theme", "side", "offset", "scale", "font", "animation", "speed" }

Options.ERROR_UNKNOWN = "unknown"
Options.ERROR_INVALID = "invalid"
Options.ERROR_UNAVAILABLE = "unavailable"

local TOGGLE_WORDS = { on = true, off = false }
local listeners = {}

-- Matching Dialogue UI is only offered while that addon is loaded.
local function IsChoiceAvailable(name, choice)
    return not (name == "theme" and choice == ns.Theme.MATCH_DIALOGUE_UI)
        or ns.Compat.IsDialogueUILoaded()
end

local function Contains(list, value)
    for index = 1, #list do
        if list[index] == value then
            return true
        end
    end
    return false
end

function Options.Has(name)
    return DEFINITIONS[name] ~= nil
end

function Options.Choices(name)
    local definition = DEFINITIONS[name]
    local available = {}
    if definition and definition.kind == "choice" then
        for index = 1, #definition.choices do
            if IsChoiceAvailable(name, definition.choices[index]) then
                available[#available + 1] = definition.choices[index]
            end
        end
    end
    return available
end

function Options.Get(name)
    local definition = DEFINITIONS[name]
    return definition and ns.DB.Get(definition.path)
end

local function Normalize(name, definition, value)
    if definition.kind == "choice" then
        if not Contains(definition.choices, value) then
            return nil, Options.ERROR_INVALID
        elseif not IsChoiceAvailable(name, value) then
            return nil, Options.ERROR_UNAVAILABLE
        end
        return value
    elseif definition.kind == "toggle" then
        if type(value) ~= "boolean" then
            return nil, Options.ERROR_INVALID
        end
        return value
    end
    -- value ~= value is true only for NaN, which would otherwise slip through the clamp.
    if type(value) ~= "number" or value ~= value then
        return nil, Options.ERROR_INVALID
    end
    value = math.max(definition.min, math.min(definition.max, value))
    if definition.percent then
        value = math.floor(value * 100 + 0.5) / 100
    end
    return value
end

-- Returns true and the stored value, or false and one of the Options.ERROR_ codes. Numbers
-- outside their range are clamped rather than rejected.
function Options.Set(name, value)
    local definition = DEFINITIONS[name]
    if not definition then
        return false, Options.ERROR_UNKNOWN
    end
    local normalized, err = Normalize(name, definition, value)
    if normalized == nil then
        return false, err
    end
    if normalized ~= ns.DB.Get(definition.path) then
        ns.DB.Set(definition.path, normalized)
        for index = 1, #listeners do
            ns.SafeCall(listeners[index], name, normalized)
        end
    end
    return true, normalized
end

-- Turns text typed by the player into a value for Options.Set, or nil when it cannot be read.
function Options.Parse(name, text)
    local definition = DEFINITIONS[name]
    if not definition or type(text) ~= "string" then
        return nil
    end
    text = text:lower():match("^%s*(.-)%s*$")
    if definition.kind == "choice" then
        return text ~= "" and text or nil
    elseif definition.kind == "toggle" then
        return TOGGLE_WORDS[text]
    end
    local number = tonumber((text:gsub("%%$", "")))
    if number and definition.percent then
        number = number / 100
    end
    return number
end

function Options.ParseToggle(text)
    if type(text) ~= "string" then
        return nil
    end
    return TOGGLE_WORDS[text:lower()]
end

local function FormatValue(definition, value)
    if definition.kind == "toggle" then
        return value and "on" or "off"
    elseif definition.kind == "number" then
        if definition.percent then
            return ("%d%%"):format(math.floor(value * 100 + 0.5))
        end
        return ("%g"):format(value)
    end
    return tostring(value)
end

function Options.Describe(name)
    local definition = DEFINITIONS[name]
    return definition and FormatValue(definition, ns.DB.Get(definition.path))
end

-- The values a player may type for an option, for help and error messages.
function Options.Usage(name)
    local definition = DEFINITIONS[name]
    if not definition then
        return nil
    elseif definition.kind == "choice" then
        return table.concat(Options.Choices(name), " | ")
    elseif definition.kind == "toggle" then
        return "on | off"
    end
    return ns.L.OPTION_RANGE:format(
        FormatValue(definition, definition.min),
        FormatValue(definition, definition.max)
    )
end

-- Window skins are applied once at load, so a change takes effect after a reload. Returns
-- false when no window with that id is registered.
function Options.SetWindowEnabled(id, enabled)
    if type(enabled) ~= "boolean" or not ns.Windows.IsRegistered(id) then
        return false
    end
    ns.DB.Set("windows." .. id .. ".enabled", enabled)
    return true
end

-- Listeners are called with the option name and its new value after a change is stored.
function Options.Subscribe(listener)
    listeners[#listeners + 1] = listener
end
