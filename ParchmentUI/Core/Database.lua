local ADDON_NAME, ns = ...

local Database = {}
ns.DB = Database

local store = {}

local function SplitPath(path)
    local keys = {}
    for key in path:gmatch("[^%.]+") do
        keys[#keys + 1] = key
    end
    return keys
end

local function Lookup(root, keys)
    local node = root
    for index = 1, #keys do
        if type(node) ~= "table" then
            return nil
        end
        node = node[keys[index]]
    end
    return node
end

local function DefaultFor(keys)
    local value = Lookup(ns.Defaults, keys)
    if value == nil and keys[1] == "windows" and #keys == 3 then
        value = ns.WindowDefaults[keys[3]]
    end
    return value
end

local function RunMigrations(data, migrations)
    local version = data.schemaVersion
    if type(version) ~= "number" then
        -- Data with content but no version predates versioning; an empty table is a new install.
        version = next(data) == nil and ns.SCHEMA_VERSION or 0
    end
    for target = version + 1, ns.SCHEMA_VERSION do
        local migrate = migrations and migrations[target]
        if migrate then
            migrate(data)
        end
    end
    -- Data written by a newer release keeps its version so that release can still read it.
    data.schemaVersion = math.max(version, ns.SCHEMA_VERSION)
end

function Database.Init(saved, migrations)
    store = type(saved) == "table" and saved or {}
    RunMigrations(store, migrations)
    return store
end

function Database.Get(path)
    local keys = SplitPath(path)
    local value = Lookup(store, keys)
    if value == nil then
        value = DefaultFor(keys)
    end
    return value
end

local function Prune(node, keys, depth)
    if depth > #keys then
        return
    end
    local child = node[keys[depth]]
    if type(child) ~= "table" then
        return
    end
    Prune(child, keys, depth + 1)
    if next(child) == nil then
        node[keys[depth]] = nil
    end
end

-- Only values that differ from the defaults are stored, so changing a default later reaches
-- every player who never touched that option.
function Database.Set(path, value)
    local keys = SplitPath(path)
    if value == DefaultFor(keys) then
        value = nil
    end
    local node = store
    for index = 1, #keys - 1 do
        local key = keys[index]
        if type(node[key]) ~= "table" then
            if value == nil then
                return
            end
            node[key] = {}
        end
        node = node[key]
    end
    node[keys[#keys]] = value
    if value == nil then
        Prune(store, keys, 1)
    end
end

function Database.IsWindowEnabled(id)
    return Database.Get("windows." .. id .. ".enabled") == true
end

function Database.Reset()
    for key in pairs(store) do
        store[key] = nil
    end
    store.schemaVersion = ns.SCHEMA_VERSION
end
