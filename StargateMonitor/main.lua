require("constants")
local try = require("try")
local pretty = (require "cc.pretty").pretty_print
local universal_interface = require("universal_interface")

local modules, monitor_config = table.unpack(require("modules_loader"))

parallel.waitForAny(function()
    EXCEPTION = {"exception"}
    try(function()
        print(universal_interface.dial({27, 29, 10, 19, 15, 30, 9, 21}))
        print("ok")
        --error(EXCEPTION)
    end, function(exception)
        print("Error during initialization: ")
        pretty(exception)
    end)
end, function()
    while true do
        print(os.pullEvent())
    end
end)
