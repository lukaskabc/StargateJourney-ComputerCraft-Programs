-- 
--   Stargate Monitor
-- created by lukaskabc
--
-- https://github.com/lukaskabc/StargateJourney-ComputerCraft-Programs/tree/main/StargateMonitor
--
-- written with Stargate Journey 0.6.17
--
-- 
-- CONFIGURATION
--
-- Use with advanced computer
-- advanced monitor with size 2x3 (w x h)
-- 
-- should work with any compatible pair of interface and stargate
-- 

local monitor = peripheral.wrap("left")
local gateInterface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")

-- I recommend to do not enable this
-- enabling this will break the status 
-- (in some cases it may get really fast/nearly instant and computer events will be lost)
local allowFastDial = false

--
-- END OF CONFIGURATION
--

if monitor == nil then
    error("No monitor found")
end

if gateInterface == nil then
    error("No gate interface found")
end

-- coord stuff, dont touch
local offset = {5, 2}

-- takes one line above and one line below
local statusTextPos = {offset[1] + 14, offset[2] + 21 + 3}
-- optionaly takes lines below if text is too long
local feedbackTextPos = {offset[1] + 14, offset[2] + 21 + 7}
-- single line
local addressTextPos = {offset[1] - 4, offset[2] + 21 + 9}
-- takes one line above and one line below
local menuButtons = {2, offset[2] + 21 + 12}

local coordsForStatus = { offset = offset, statusTextPos = statusTextPos, feedbackTextPos = feedbackTextPos, addressTextPos = addressTextPos}

-- MODULES / PAGES
local later_exec = require("./utils")[4]
local run_later = require("./utils")[3]

local Menu = require("./menu")
local Status = require("./status")
local Dial = require("./dial")
local History = require("./history")

local dialingSignal = {_canDial = true, _isDialing = false}
function dialingSignal.canDial()
    return dialingSignal._canDial
end

function dialingSignal.isDialing()
    return dialingSignal._isDialing
end

function dialingSignal.stop()
    dialingSignal._canDial = false
    dialingSignal._isDialing = false
    --run_later(0.5, function()
    if gateInterface.endRotation ~= nil then
        gateInterface.endRotation()
    end
end

function dialingSignal.start()
    dialingSignal._isDialing = true
end

function dialingSignal.reset()
    print("")
    dialingSignal.stop()

    dialingSignal._canDial = true
    dialingSignal._isDialing = false

    gateInterface.disconnectStargate()
    if gateInterface.closeChevron ~= nil then
        gateInterface.closeChevron()
    end
    if gateInterface.getChevronsEngaged() > 0 then
        gateInterface.disconnectStargate()
        Status.reset(0)
    end
--end)
end

local dialingAddressHolder = {address = {}}
function dialingAddressHolder.get()
    return dialingAddressHolder.address
end

function dialingAddressHolder.set(address)
    dialingAddressHolder.address = address
end

Status.init(function() return Menu.isPage(1) end, monitor, gateInterface, coordsForStatus, dialingAddressHolder, dialingSignal, History)
Dial.init(function() return Menu.isPage(2) end, monitor, gateInterface, {offset = offset}, Menu.navigate, allowFastDial, dialingAddressHolder, dialingSignal)
History.init(function() return Menu.isPage(3) end, monitor, gateInterface, {offset = offset}, Menu.navigate, allowFastDial, dialingAddressHolder, dialingSignal)
Menu.init({Status.page, Dial.page, History.page}, 1, monitor, menuButtons)


parallel.waitForAll(later_exec, Status.run, Dial.run, History.run, Menu.run)