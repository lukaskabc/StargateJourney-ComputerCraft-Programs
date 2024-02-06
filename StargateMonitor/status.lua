--        part of
--   Stargate Monitor
-- created by lukaskabc
--
-- Status page
-- handles events from gate and holds some status information

local strings = require("cc.strings")
local wait, table_contains, run_later = table.unpack(require("./utils"))

local activeChevronColor = colors.red
local chevronBlinkColor = colors.yellow
local chevrons = require("chevrons")

local Blink = {
    centerX = 1,
    centerY = 1,
    _shouldClear = true
}

local GateMonitor = {}
local Feedback = { code = 0, description = "" }

 -- binded via init function
local canPrint
local monitor
local gateInterface
local coords
local monitorSize
local dialingAddressHolder
local dialingSignal
local History

local function init(_canPrint, _monitor, _gateInterface, _coords, _dialingAddressHolder, _dialingSignal, _history)
    canPrint = _canPrint
    monitor = _monitor
    gateInterface = _gateInterface
    coords = _coords
    dialingAddressHolder = _dialingAddressHolder
    dialingSignal = _dialingSignal
    History = _history
    monitorSize = {monitor.getSize()}

    Blink.centerX =  coords.offset[1] + 14
    Blink.centerY = coords.offset[2] + 10
end


local GATE_STATUS = {
    IDLE            = {name = " I D L E ", color = colors.green},
    DIALING         = {name = " DIALING ", color = colors.orange},
    INCOMING       = {name = "INCOMING ", color = colors.red},

    OPEN_OUTGOING   = {name = " O P E N ", color = colors.lightBlue},
    OPEN_INCOMING  = {name = "INCOMING ", color = colors.red}
}

local GATE_FEEDBACK = {
    NONE = {code = 0, description = "No feedback"},
    UNKNOWN_ERROR = {code = -1, description = "An unknown error occurred"},

    -- symbols
    SYMBOL_ENCODED = {code = 1, description = "Symbol encoded"},
    SYMBOL_IN_ADDRESS = {code = -2, description = "Symbol in address"},
    SYMBOL_OUT_OF_BOUNDS = {code = -3, description = "Symbol out of bounds"},

    -- connection
    CONNECTION_ESTABLISHED_SYSTEM_WIDE = {code = 2, description = "Connection established system wide"},
    CONNECTION_ESTABLISHED_INTERSTELLAR = {code = 3, description = "Connection established interstellar"},
    CONNECTION_ESTABLISHED_INTERGALACTIC = {code = 4, description = "Connection established intergalactic"},

    -- errors
    INCOMPLETE_ADDRESS = {code = -4, description = "Incomplete address"},
    INVALID_ADDRESS = {code = -5, description = "Invalid address"},
    NOT_ENOUGH_POWER = {code = -6, description = "Not enough power"},
    SELF_OBSTRUCTED = {code = -7, description = "Self obstructed"},
    TARGET_OBSTRUCTED = {code = -8, description = "Target obstructed"},
    SELF_DIAL = {code = -9, description = "Self dial"},
    SAME_SYSTEM_DIAL = {code = -10, description = "Same system dial"},
    ALREADY_CONNECTED = {code = -11, description = "Already connected"},
    NO_GALAXY = {code = -12, description = "No galaxy"},
    NO_DIMENSIONS = {code = -13, description = "No dimensions"},
    NO_STARGATES = {code = -14, description = "No stargates"},
    TARGET_RESTRICTED = {code = -15, description = "Target restricted"},

    -- end of connection
    CONNECTION_ENDED_BY_DISCONNECT = {code = 7, description = "Connection ended by disconnect"},
    CONNECTION_ENDED_BY_POINT_OF_ORIGIN = {code = 8, description = "Connection ended by point of origin"},
    CONNECTION_ENDED_BY_NETWORK = {code = 9, description = "Connection ended by network"},
    CONNECTION_ENDED_BY_AUTOCLOSE = {code = 10, description = "Connection ended by autoclose"},
    EXCEEDED_CONNECTION_TIME = {code = -15, description = "Exceeded connection time"},
    RAN_OUT_OF_POWER = {code = -17, description = "Ran out of power"},
    CONNECTION_REROUTED = {code = -18, description = "Connection rerouted"},
    WRONG_DISCONNECT_SIDE = {code = -18, description = "Wrong disconnect side"},
    CONNECTION_FORMING = {code = -20, description = "Connection forming"},

    STARGATE_DESTROYED = {code = -21, description = "Stargate destroyed"},
    COULD_NOT_REACH_TARGET_STARGATE = {code = -22, description = "Could not reach target stargate"},
    INTERRUPTED_BY_INCOMING_CONNECTION = {code = -23, description = "Interrupted by incoming connection"},

    -- milky way gate specific
    CHEVRON_RAISED = {code = 11, description = "Chevron raised"},
    ROTATING = {code = 12, description = "Rotating"},
    ROTATION_BLOCKED = {code = -24, description = "Rotation blocked"},
    NOT_ROTATING = {code = -25, description = "Not rotating"},
    ROTATION_STOPPED = {code = 13, description = "Rotation stopped"},
    CHEVRON_ALREADY_RAISED = {code = -26, description = "Chevron already raised"},
    CHEVRON_ALREADY_LOWERED = {code = -27, description = "Chevron already lowered"},
    CHEVRON_NOT_RAISED = {code = -28, description = "Chevron not raised"},
    CANNOT_ENCODE_POINT_OF_ORIGIN = {code = -29, description = "Cannot encode point of origin"}
}

local Status = {status = GATE_STATUS.IDLE, lastOpenStatus = false, isOpen = false, lastEncodedChevron = 0, isIncoming = true}
local Address = {address = {}}

local function pagePrint()
    if not canPrint() then
        return
    end

    GateMonitor.print()
    Status.print()
end

-- ====================
--        STATUS
-- ====================

function Status.get()
    return Status.status
end

function Status.text()
    return Status.status.name
end

function Status.color()
    return Status.status.color
end

function Status.reset()
    Status.isOpen = false
    Status.isIncoming = true
    Status.lastEncodedChevron = 0
end

function Status.print(overrideColor)
    if not canPrint() then
        return
    end

    if overrideColor == nil then
        overrideColor = Status.color()
    end
    local space = "           ";
    local text = Status.text()
    local textX = coords.statusTextPos[1] - math.floor(#space / 2)
    local textY = coords.statusTextPos[2]
    monitor.setTextColor(colors.white)
    monitor.setBackgroundColor(overrideColor)
    monitor.setCursorPos(textX, textY - 1);
    monitor.write(space)
    monitor.setCursorPos(textX, textY)
    monitor.write(" "..text.." ")
    monitor.setCursorPos(textX, textY + 1);
    monitor.write(space)

    if Status.isOpen ~= Status.lastOpenStatus then
        Status.lastOpenStatus = Status.isOpen
        GateMonitor.print()
    end

    Feedback:new():print()
    Address.print()
end

function Status._isIncoming()
    local feedback = Feedback:new()
    return (Status.isIncoming or feedback:isIncoming()) and not feedback:isOpenOutgoing()
end

function Status.update()
    local newState = Status.get()
    -- check if there are some chevrons engaged
    if gateInterface.getChevronsEngaged() > 0 then
        newState = GATE_STATUS.DIALING

        if gateInterface.isStargateConnected() then
            if Status.isOpen then
                if Status._isIncoming() then
                    newState = GATE_STATUS.OPEN_INCOMING
                else
                    newState = GATE_STATUS.OPEN_OUTGOING
                end
            elseif Status._isIncoming() then
                newState = GATE_STATUS.INCOMING
            end
        end
    else
        newState = GATE_STATUS.IDLE
    end

    if Status.get() == GATE_STATUS.DIALING then
        local feedback = Feedback:new()
        if feedback.code <= -4 and feedback.code >= -24 then
            newState = GATE_STATUS.IDLE
            Address.reset()
            dialingSignal.stop()
        end
    end

    if newState ~= Status.get() then
        Status.status = newState
        Status.print()

        if newState == GATE_STATUS.IDLE then
            GateMonitor.print()
            dialingSignal.reset()
        end
    end
end

-- ====================
--       ADDRESS
-- ====================

function Address.reset()
    Address.address = {}
    dialingAddressHolder.set({})
    Address.print()
end

function Address.add(symbol)
    if table_contains(Address.address, symbol) then
        return
    end
    table.insert(Address.address, symbol)
    Address.print()
end

function Address.getAddress(possibleAddress)
    local addr = {}

    if #dialingAddressHolder.get() > 0 then
        return dialingAddressHolder.get()
    end

    if gateInterface.getConnectedAddress ~= nil and #gateInterface.getConnectedAddress() > 0 then
        addr = gateInterface.getConnectedAddress()
    elseif gateInterface.getDialedAddress ~= nil and #gateInterface.getDialedAddress() > 0 then
        addr = gateInterface.getDialedAddress()
    elseif possibleAddress ~= nil and #possibleAddress > 0 then
        addr = possibleAddress
    else
        addr = Address.address
    end
    return addr
end

function Address.format(address)
    local output = "-"
    local dif = gateInterface.getChevronsEngaged() - (#address + 1) -- +1 for point of origin

    if dif > 0 then
        for i = 1, gateInterface.getChevronsEngaged() - #address do
            output = output .. "??-"
        end
    end

    for i = 1, #address do
        output = output .. address[i] .. "-"
    end
    return output
end

function Address.print()
    if not canPrint() then
        return
    end

    local address = Address.getAddress()

    local text = "Address:" .. Address.format(address)
    monitor.setTextColor(colors.white)
    monitor.setBackgroundColor(colors.black)
    monitor.setCursorPos(table.unpack(coords.addressTextPos))
    monitor.write(strings.ensure_width(text, monitorSize[1]))
end

-- ====================
--        GATE
-- ====================

function GateMonitor.print()
    if not canPrint() then
        return
    end


    local fileName
    local chevronCount = gateInterface.getChevronsEngaged()

    if Status.isOpen then
        fileName = "wormhole.nfp"
    else
        fileName = "stargate.nfp"
    end

    local gateImg = paintutils.loadImage(fileName)
    local terminal = term.current()
    term.redirect(monitor)
    paintutils.drawImage(gateImg, coords.offset[1], coords.offset[2])
    term.redirect(terminal)
    
    if Status.isOpen then
        GateMonitor.activateChevron(9, activeChevronColor)
        chevronCount = chevronCount - 1
    end

    for ch = 1, chevronCount do
        GateMonitor.activateChevron(ch, activeChevronColor)
    end
    
end

function GateMonitor.activateChevron(chevronID, color)
    if not canPrint() then
        return
    end

    for _, coord in pairs(chevrons[chevronID]) do
        monitor.setBackgroundColor(color)
        monitor.setCursorPos(coord[1] + coords.offset[1] - 1, coord[2] + coords.offset[2] - 1)
        monitor.write(" ")
    end
end

-- activate chevron with blink animation
function GateMonitor.engageChevron(chevronID)
    if not canPrint() then
        return
    end

    GateMonitor.activateChevron(chevronID, chevronBlinkColor)
    run_later(0.5, function()
        GateMonitor.activateChevron(chevronID, activeChevronColor)
    end)
end

-- ====================
--        BLINK
-- ====================

function Blink.blink(color)
    Blink._shouldClear = not Blink._shouldClear
    if Blink._shouldClear then
        color = colors.black
    end

    monitor.setCursorPos(Blink.centerX, Blink.centerY)
    monitor.setBackgroundColor(color)
    monitor.write(" ")
end

function Blink.idle()
    if Status.get() ~= GATE_STATUS.IDLE and Status.get() ~= GATE_STATUS.DIALING then 
        -- not idle nor dialing
        return 
    end
    Blink.blink(colors.blue)
end

function Blink.incoming()
    if Status.get() ~= GATE_STATUS.INCOMING and Status.get() ~= GATE_STATUS.OPEN_INCOMING then
        return
    end

    if Blink._shouldClear then
        Status.print(colors.orange)
    else
        Status.print()
    end

    Blink._shouldClear = not Blink._shouldClear


    -- if not open, do dot blink in the middle of gate (with red color)
    if not Status.isOpen then
        Blink.blink(colors.red)
    end
end

function Blink.run()
    while true do
        Status.update()

        if canPrint() then
            Blink.idle()
            Blink.incoming()
        end

        sleep(1)
    end
end

-- ====================
--       FEEDBACK
-- ====================

function Feedback:new(feedbackCode)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    local recentCode, _ = gateInterface.getRecentFeedback()
    o.code = feedbackCode or recentCode
    o.description = Feedback.findDescription(o.code)
    return o
end

function Feedback.findDescription(feedbackCode)
    for _, feedback in pairs(GATE_FEEDBACK) do
        if feedback.code == feedbackCode then
            return feedback.description
        end
    end

    return "Unknown feedback "..feedbackCode
end

function Feedback:isIncoming()
    return self.code == GATE_FEEDBACK.INTERRUPTED_BY_INCOMING_CONNECTION.code
end

function Feedback:isOpenOutgoing()
    return table_contains({
        GATE_FEEDBACK.CONNECTION_ESTABLISHED_SYSTEM_WIDE.code,
        GATE_FEEDBACK.CONNECTION_ESTABLISHED_INTERSTELLAR.code,
        GATE_FEEDBACK.CONNECTION_ESTABLISHED_INTERGALACTIC.code
    }, self.code)
end

function Feedback:print()
    if not canPrint() then
        return
    end

    local y = coords.feedbackTextPos[2]

    monitor.setBackgroundColor(colors.black)

    monitor.setCursorPos(1, y)
    monitor.write(strings.ensure_width("", monitorSize[1] + 2))

    if self.code < 0 then
        monitor.setTextColor(colors.red)
    else
        monitor.setTextColor(colors.lightGray)
    end

    for num, line in pairs(strings.wrap(self.description, monitorSize[1])) do

        local x = coords.feedbackTextPos[1] - math.floor(#line / 2)

        monitor.setCursorPos(x, y + num - 1)
        monitor.write(line)
    end
end

-- ====================
--        EVENTS
-- ====================

local function event_chevronEncoded(chevronID, isIncoming, symbol )
    Status.isIncoming = isIncoming
    Status.update()

    if isIncoming and dialingSignal.isDialing() then
        dialingSignal.stop()
    end

    if chevronID < Status.lastEncodedChevron then
        -- we missed gate reset
        -- reset gate now as lower chevron than previous was encoded
        GateMonitor.print()
        Address.reset()
    end
    
    if symbol == 0 then
        if not Feedback:new():isOpenOutgoing() then
            Address.reset()
            Status.reset()
            pagePrint()
        else 
            print(Feedback:new().description)
            GateMonitor.engageChevron(9)
            Status.lastEncodedChevron = 9
        end
        return
    end

    if symbol ~= nil then
        Address.add(symbol)
    else 
        print("Unknown symbol encoded")
    end

    GateMonitor.engageChevron(chevronID)

    Status.lastEncodedChevron = chevronID
end

local function event_disconnect(feedback) 
    print("Gate disconnected with code "..tostring(feedback))
    dialingSignal.reset()
    Address.reset()
    Status.reset()
    pagePrint()
end

local function event_gate_open(address)

    --print("Gate openned to address", table.unpack(address))
    local addr = Address.getAddress(address)
    if addr and #addr >= 6 then
        History.addAddress(addr)
        print("Outgoing connection to ".. Address.format(addr) .." active")
    else 
        print("Outgoing connection active")
    end

    dialingSignal.stop()
    Status.isOpen = true
    Status.isIncoming = false
    event_chevronEncoded(9)
    pagePrint()
end

local function event_gate_incoming_open(address)
    local addr = Address.getAddress(address)
    if addr and #addr >= 6 then
        History.addAddress(addr)
        print("Incoming connection from ".. Address.format(addr) .." active")
    else 
        print("Incoming connection from unknwon address active")
    end

    dialingSignal.stop()
    Status.isOpen = true
    Status.isIncoming = true
    pagePrint()
    Status.lastEncodedChevron = 9
end

local function event_monitor_trouch(side, x, y)
    if not canPrint() then
        return
    end

    local buttonLength = 10
    
    local textX = coords.statusTextPos[1] - math.floor(buttonLength / 2)
    local textY = coords.statusTextPos[2] 

    if x > textX + buttonLength or x < textX then
        return
    end

    if y > textY + 1 or y < textY - 1 then
        return
    end

    dialingSignal.stop()
    run_later(1, function() dialingSignal.reset() end)
    gateInterface.disconnectStargate()
    Address.reset()
    Status.reset()
    Status.update()
    pagePrint()

end

local function process_event(eventData)
    local event = eventData[1]

    if event == "stargate_chevron_engaged" then
        event_chevronEncoded(table.unpack(eventData, 2))
    elseif event == "stargate_disconnected" then
        event_disconnect(eventData[2])
    elseif event == "stargate_outgoing_wormhole" then
        event_gate_open(eventData[2])
    elseif event == "stargate_incoming_wormhole" then
        event_gate_incoming_open(eventData[2])
    elseif event == "monitor_touch" then
        event_monitor_trouch(table.unpack(eventData, 2))
    end
end

local function subscribeEvents()
    while true do
        local eventData = {os.pullEvent()}
        
        if eventData[1] ~= "timer" then
            process_event(eventData)
        end
    end
end


local function run()
    Status.isIncoming = Status._isIncoming()
    Status.isOpen = gateInterface.isStargateConnected()

    parallel.waitForAll(Blink.run, subscribeEvents)
end


return {
    init = init,
    run = run,
    page = {
        name = "STATUS",
        print = pagePrint
    },
    reset = event_disconnect
}
