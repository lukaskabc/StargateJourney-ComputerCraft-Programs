--
--      Y.A.S.C. Yet Another Stargate Computer
--             Hallowed is Povstalec !
--
--             Created by lukaskabc
--
--
-- https://github.com/lukaskabc/StargateJourney-ComputerCraft-Programs/tree/main/StargateMonitor
--

require("constants")
require("utils")
require("run_later")
local try = require("try")
local universal_interface = require("universal_interface")
universal_interface.checkInterfaceConnected()

local modules, windows = table.unpack(require("modules_loader"))
modules["universal_interface"] = universal_interface

local parallelMethods = {later_exec}

-- verify advanced computer
if not term.isColor() then
    printError("This program requires an advanced computer!")
    return 1
end

-- Initialize all modules
for module_name, module in pairs(modules) do
    if module.init then
        print("Initializing module", module_name, "...")
        local r = module.init(modules, windows)
        if r ~= nil and r ~= 0 then
            print()
            printError("Failed to initialize module", module_name, "("..r..")")
            return 1
        end
    end
end

-- Collect all run methods from modules to be run in parallel
for module_name, module in pairs(modules) do
    if module.run then
        table.insert(parallelMethods, function()
            try(module.run, function(err)
                printError(err)
                print()
                printError("Script experienced an unexpected error in module", module_name)
            end)
        end)
    end
end


parallel.waitForAny(table.unpack(parallelMethods))