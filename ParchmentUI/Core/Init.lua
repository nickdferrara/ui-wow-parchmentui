local ADDON_NAME, ns = ...

ns.ADDON_NAME = ADDON_NAME

-- Forever is detected by interface range. Its numbers sit far below the retail range, so a
-- "greater than" comparison against a retail interface number would be wrong on this client.
local INTERFACE_MIN = 16000
local INTERFACE_MAX = 16999

-- A missing translation shows its key, which is easier to spot and report than an error.
ns.L = setmetatable({}, {
    __index = function(_, key)
        return key
    end,
})

function ns.IsSupportedClient(interfaceNumber)
    return type(interfaceNumber) == "number"
        and interfaceNumber >= INTERFACE_MIN
        and interfaceNumber <= INTERFACE_MAX
end

local printedCauses = {}

-- A cause limits a message to one per session. Messages without a cause always print.
function ns.Print(message, cause)
    if cause ~= nil then
        if printedCauses[cause] then
            return false
        end
        printedCauses[cause] = true
    end
    print(("|cffc8a064%s|r: %s"):format(ADDON_NAME, tostring(message)))
    return true
end

-- Runs fn so that an error reaches the client's error handler without stopping the caller.
function ns.SafeCall(fn, ...)
    local args, count = { ... }, select("#", ...)
    return xpcall(function()
        return fn(unpack(args, 1, count))
    end, geterrorhandler())
end
