local ADDON_NAME, ns = ...

local Events = {}
ns.Events = Events

local handlers = {}
local frame = CreateFrame("Frame")

frame:SetScript("OnEvent", function(_, event, ...)
    local list = handlers[event]
    if not list then
        return
    end
    for index = 1, #list do
        ns.SafeCall(list[index], ...)
    end
end)

function Events.Register(event, handler)
    if not handlers[event] then
        handlers[event] = {}
        frame:RegisterEvent(event)
    end
    table.insert(handlers[event], handler)
end
