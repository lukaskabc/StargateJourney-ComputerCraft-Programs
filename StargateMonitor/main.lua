--
--      Y.A.S.C. Yet Another Stargate Computer
--             Hallowed is Povstalec !
--
--             Created by lukaskabc
--
--
-- https://github.com/lukaskabc/StargateJourney-ComputerCraft-Programs/tree/main/StargateMonitor
--
ROOT_DIR = shell.dir()
EXIT = {} -- exception used for silent program exit
require("globals")
require("try")
require("utils")
require("run_later")

require("stargate_connection_instructor")(false)

local universal_interface = require("universal_interface")
universal_interface.checkInterfaceConnected()

local modules, windows = table.unpack(require("modules_loader"))
modules["universal_interface"] = universal_interface

local pretty_print = require("cc.pretty").pretty_print

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

local function addParallelMethod(method, module_name)
    table.insert(parallelMethods, function()
        try(method, function(err)
            if err == EXIT then
                return
            end
            print()
            printError("Script experienced an unexpected error in module", module_name)
            error(err)
        end)
    end)
end

-- Collect all run methods from modules to be run in parallel
for module_name, module in pairs(modules) do
    if module.run then
        if type(module.run) == "table" then
            for _, method in pairs(module.run) do
                addParallelMethod(method, module_name)
            end
        elseif type(module.run) == "function" then
            addParallelMethod(module.run, module_name)
        end
    end
end

local function error_handle(err)
    if err == EXIT then
        return
    end

    if type(err) == "table" then
        if err == STARGATE_NOT_CONNECTED_ERROR or
        err == INTERFACE_NOT_CONNECTED_ERROR or
        err == INSUFFICIENT_INTERFACE or
        err == STARGATE_ALREADY_DIALING then
            os.reboot()
            return
        end

        pretty_print(err)
    else
        pretty_print(err)
    end
    print()
    printError("Script experienced an unexpected error")
    printError("Please report this error to the script author")
    printError("Press any key to restart the computer...")
    os.pullEvent("key")
    os.reboot()
    return 1
end

print("Startup completed")

try(function()
    parallel.waitForAny(table.unpack(parallelMethods))
end, error_handle)