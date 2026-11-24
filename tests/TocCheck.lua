-- Validates the TOC against the file tree:
--   every file it lists exists, every Lua file under the addon folder is listed, every file
--   is gated to the Forever game type, and the Interface number matches the standards.
local ADDON_ROOT = "ParchmentUI/"
local TOC_PATH = ADDON_ROOT .. "ParchmentUI_Camelot.toc"
local STANDARDS_PATH = "docs/engineering-standards.md"
local GAME_TYPE_GATE = "[AllowLoadGameType camelot]"

local problems = {}

local function Problem(message, ...)
    problems[#problems + 1] = message:format(...)
end

local function ReadFile(path)
    local handle = assert(io.open(path, "r"))
    local content = handle:read("*a")
    handle:close()
    return content
end

local function Exists(path)
    local handle = io.open(path, "r")
    if handle then
        handle:close()
    end
    return handle ~= nil
end

local listed, interface = {}, nil
for line in io.lines(TOC_PATH) do
    line = line:gsub("\r$", "")
    local directive, value = line:match("^##%s*([%w%-]+):%s*(.-)%s*$")
    if directive == "Interface" then
        interface = value
    elseif line ~= "" and not line:match("^#") then
        local file = line:match("^([^%[]-)%s*%[") or line:match("^(.-)%s*$")
        file = file:gsub("\\", "/")
        if listed[file] then
            Problem("listed twice: %s", file)
        end
        listed[file] = true
        if not Exists(ADDON_ROOT .. file) then
            Problem("listed but missing: %s", file)
        end
        if not line:find(GAME_TYPE_GATE, 1, true) then
            Problem("not gated with %s: %s", GAME_TYPE_GATE, file)
        end
    end
end

local finder = assert(io.popen('find "' .. ADDON_ROOT .. '" -type f -name "*.lua" | sort'))
for path in finder:lines() do
    local file = path:sub(#ADDON_ROOT + 1)
    if not listed[file] then
        Problem("not listed in the TOC: %s", file)
    end
end
finder:close()

local expected = ReadFile(STANDARDS_PATH):match("Interface (%d+)")
if not interface then
    Problem("the TOC has no Interface directive")
elseif interface ~= expected then
    Problem("Interface is %s, standards say %s", interface, tostring(expected))
end

if #problems > 0 then
    io.stderr:write("TOC check failed:\n  " .. table.concat(problems, "\n  ") .. "\n")
    os.exit(1)
end
print("TOC check passed")
