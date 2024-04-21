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
TERM_WIDTH, TERM_HEIGHT = term.getSize()
COMPUTER_WINDOW = window.create(term.current(), 1, 1, TERM_WIDTH, TERM_HEIGHT, true)
COMPUTER_WINDOW.monitor = term.current()

DEBUG_WINDOW_WRAPPER = window.create(term.current(), 1, 1, TERM_WIDTH, TERM_HEIGHT, false)
DEBUG_WINDOW_WRAPPER.setCursorPos(1, TERM_HEIGHT)
DEBUG_WINDOW_WRAPPER.setBackgroundColor(colors.black)
DEBUG_WINDOW_WRAPPER.setTextColor(colors.gray)
DEBUG_WINDOW_WRAPPER.write("Press END or Backspace to exit log")

DEBUG_WINDOW = window.create(DEBUG_WINDOW_WRAPPER, 1, 1, TERM_WIDTH, TERM_HEIGHT - 1, true)
local CONFIGURATION_WINDOW = window.create(term.current(), 1, 1, TERM_WIDTH, TERM_HEIGHT+1, false)

EXIT = {} -- exception used for silent program exit
require("globals")
require("try")
require("utils")
require("run_later")

COMPUTER_WINDOW.monitor.update = function() COMPUTER_WINDOW.redraw() end
COMPUTER_WINDOW.monitor.isCreateLink = function() return false end

local function exitWithDebug()
    COMPUTER_WINDOW.setVisible(false)
    CONFIGURATION_WINDOW.setVisible(false)

    DEBUG_WINDOW_WRAPPER.setVisible(true)
    DEBUG_WINDOW.setVisible(true)
    DEBUG_WINDOW_WRAPPER.clear()
    DEBUG_WINDOW.redraw()
    DEBUG_WINDOW_WRAPPER.redraw()
    term.redirect(DEBUG_WINDOW)
end

--[[
TODOs: 
Support for create link in text only modules (like last feedback)
and add checks that module is text only and so supports create links

]]
try(function()
    require("stargate_connection_instructor")(false)
end, function (err)
    exitWithDebug()
    printError("Stargate connection instructor execution failed, please report this bug with the following error message:")
    printError(err)
end)

term.redirect(DEBUG_WINDOW)

local universal_interface = require("universal_interface")
universal_interface.checkInterfaceConnected()

local modules, windows
try(function()
    modules, windows = table.unpack(require("modules_loader"))
end, function (err)
    exitWithDebug()
    printError("Modules loader error occured, please report this bug with the following error message:")
    printError(err)
end)

modules["universal_interface"] = universal_interface

local pretty_print = require("cc.pretty").pretty_print
local configuration_manager = require("configuration_manager")

function CONFIGURATION_MANAGER()
    COMPUTER_WINDOW.setVisible(false)
    CONFIGURATION_WINDOW.setVisible(true)
    CONFIGURATION_WINDOW.redraw()
    configuration_manager(modules, CONFIGURATION_WINDOW)
    os.reboot()
end

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
            exitWithDebug()
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
    exitWithDebug()

    if err == EXIT then
        return
    end

    if type(err) == "table" then
        if err == STARGATE_NOT_CONNECTED_ERROR or
        err == INTERFACE_NOT_CONNECTED_ERROR or
        err == INSUFFICIENT_INTERFACE or
        err == STARGATE_IS_ACTIVE or
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
    print()
    printError("Press any key to restart the computer...")
    local f = {}
    table.insert(f, function() os.pullEvent("key") end)

    if AUTO_REBOOT_DELAY > 0 then
        printError("Auto rebooting after", AUTO_REBOOT_DELAY, "seconds...")
        table.insert(f, function() os.sleep(AUTO_REBOOT_DELAY) end)
    end

    parallel.waitForAny(table.unpack(f))
    os.reboot()
    return 1
end

print("Startup completed")

try(function()
    parallel.waitForAny(table.unpack(parallelMethods))
    exitWithDebug()
    print()
    printError("Some module exited")
    print()
end, error_handle)