local STARGATE_NOT_CONNECTED_ERROR = {message = "Interface is not connected to a stargate!"}
local INTERFACE_NOT_CONNECTED_ERROR = {message = "Interface not found!"}
local INSUFFICIENT_INTERFACE = {message = "Crystal interface is required for this gate type!"}
local FEEDBACK = require("stargate_feedbacks")
local try = require("try")
-- dialing milkyway stargate will use three step symbol encoding (open, encode, close)
local THREE_STEP_ENCODE = true
-- delay used between encode steps with milkyway gate
local CHEVRON_ENCODE_DELAY = 0.5
local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")
require("constants")


--[[
    Fires event yasc_engaging_symbol with parameters:
    - symbol index in address
    - symbol
    - None - pending, true - success, false - failed (aborted)
]]

local universal_interface = {
    -- if true, direct engage symbol will be used if available
    direct_engage = false,
    -- disables delayes and tries to dial as fast as possible (if direct_engage is false, rotation will still be used with milkyway gate)
    quick_dial = false,

    dial_in_progress = false
}

-- return true if the interface is connected to the stargate
-- throws error otherwise
function universal_interface.checkInterfaceConnected()
    if interface and (interface.engageSymbol or interface.rotateClockwise) then
        return true
    end

    if not interface.disconnectStargate then
        error(STARGATE_NOT_CONNECTED_ERROR)
    end

    if not interface.engageSymbol and not interface.rotateClockwise then
        error(INSUFFICIENT_INTERFACE)
    end

    error(INTERFACE_NOT_CONNECTED_ERROR)
end

function universal_interface.resetStargate()
    return universal_interface.reset()
end

-- resets the stargate
function universal_interface.reset()
    universal_interface.abortDial()
    universal_interface.checkInterfaceConnected()

    interface.disconnectStargate()

    if interface.closeChevron then
        -- stargate is reseted first
        -- chevron is closed if possible
        interface.closeChevron()
        -- then the symbol engaged by closing chevron is cleared
        interface.disconnectStargate()
    end
    
    return FEEDBACK.NONE
end

function universal_interface.getEnergy()
    if not interface then
        error(INTERFACE_NOT_CONNECTED_ERROR)
    end
    return interface.getEnergy()
end

-- returns current energy target (the amount to which will be interface pushing energy to the stargate)
function universal_interface.getEnergyTarget()
    universal_interface.checkInterfaceConnected()
    return interface.getEnergyTarget()
end

-- sets the energy target (the amount to which will be interface pushing energy to the stargate)
function universal_interface.setEnergyTarget(energy)
    universal_interface.checkInterfaceConnected()
    return interface.setEnergyTarget(energy)
end

-- Returns the registry ID of the Stargate (For example: "sgjourney:milky_way_stargate").
function universal_interface.getStargateType()
    universal_interface.checkInterfaceConnected()
    return interface.getStargateType()
end

-- Returns the energy (in FE) the Stargate has stored.
function universal_interface.getStargateEnergy()
    universal_interface.checkInterfaceConnected()
    return interface.getStargateEnergy()
end

-- If the Stargate is connected, the command disconnects it. If it isn't connected, the Stargate will be reset.
function universal_interface.disconnectStargate()
    universal_interface.checkInterfaceConnected()
    return interface.disconnectStargate()
end

-- Returns the number of chevrons that have been engaged.
function universal_interface.getChevronsEngaged()
    universal_interface.checkInterfaceConnected()
    return interface.getChevronsEngaged()
end

-- Returns the number of Ticks the Stargate has been active for, returns 0 if it's inactive.
function universal_interface.getOpenTime()
    universal_interface.checkInterfaceConnected()
    return interface.getOpenTime()
end

-- Returns true if the Stargate is currently connected, otherwise returns false.
function universal_interface.isStargateConnected()
    universal_interface.checkInterfaceConnected()
    return interface.isStargateConnected()
end

-- Returns true if the Stargate is currently dialing out, otherwise (if Stargate isn't connected or the connection is incoming) returns false.
function universal_interface.isStargateDialingOut()
    universal_interface.checkInterfaceConnected()
    return interface.isStargateDialingOut()
end

function universal_interface.getRecentFeedback()
    universal_interface.checkInterfaceConnected()
    local feedback, message = interface.getRecentFeedback()
    
    if message ~= nil then
        local msg = string.gsub(message, "\.", "_")
        msg = string.upper(message)
        if FEEDBACK[msg] ~= nil then
            return FEEDBACK[msg].code, FEEDBACK[msg].description
        end
    end

    for _, f in pairs(FEEDBACK) do
        if f.code == feedback then
            return feedback, f.description
        end
    end

    return feedback, message
end

-- Returns the currently dialed address (for outgoing connection) or empty table {}.
function universal_interface.getDialedAddress()
    if interface and interface.getDialedAddress then
        return interface.getDialedAddress()
    end

    return {}
end

-- Returns the currently connected address (the address on the other side of the connection) or empty table {}.
function universal_interface.getConnectedAddress()
    if interface and interface.getConnectedAddress then
        return interface.getConnectedAddress()
    end

    return {}
end

-- Returns the 9-chevron address of the Stargate or empty table {}
function universal_interface.getLocalAddress()
    if interface and interface.getLocalAddress then
        return interface.getLocalAddress()
    end

    return {}
end

-- Does not performs null check and returns the peripheral object
function universal_interface.getNativeInterface()
    return interface
end

-- if true, direct engage symbol will be used if available
function universal_interface.setDirectEngage(direct_engage)
    universal_interface.direct_engage = direct_engage
end

-- disables delayes and tries to dial as fast as possible (if direct_engage is false, rotation will still be used with milkyway gate)
function universal_interface.setQuickDial(quick_dial)
    universal_interface.quick_dial = quick_dial
end

-- Returns the current quick_dial setting
function universal_interface.getQuickDial()
    return universal_interface.quick_dial
end

-- Returns the current direct_engage setting
function universal_interface.getDirectEngage()
    return universal_interface.direct_engage
end

local function direct_symbol_engage(i, address, quick_dial)
    local result = interface.engageSymbol(address[i])

    while(universal_interface.getChevronsEngaged() < i) do
        if not universal_interface.dial_in_progress or quick_dial then break end
        sleep(0)
        universal_interface.checkInterfaceConnected()
    end

    return result
end

local function rotational_symbol_engage_impl(symbol, delay, direction)
    local feedback

    if direction then
        feedback = interface.rotateClockwise(symbol)
    else
        feedback = interface.rotateAntiClockwise(symbol)
    end

    if feedback < 0 then
        return feedback
    end

    while not interface.isCurrentSymbol(symbol) do
        if not universal_interface.dial_in_progress then break end
        sleep(0)
    end

    if not universal_interface.dial_in_progress then return FEEDBACK.UNKNOWN_ERROR end

    sleep(delay)
    if not universal_interface.dial_in_progress then return feedback end
    feedback = interface.openChevron()
    if feedback < 0 or not universal_interface.dial_in_progress then return feedback end

    print("opened chevron", feedback)

    if symbol ~= 0 and THREE_STEP_ENCODE then
        sleep(delay)
        if not universal_interface.dial_in_progress then return feedback end
        feedback = interface.encodeChevron()
        print("encoded chevron", feedback)
        if feedback < 0 or not universal_interface.dial_in_progress then return feedback end
    end

    sleep(delay)
    if not universal_interface.dial_in_progress then return feedback end
    feedback = interface.closeChevron()
    print("closed chevron", feedback)
    if THREE_STEP_ENCODE and feedback == FEEDBACK.SYMBOL_IN_ADDRESS.code then
        feedback = FEEDBACK.SYMBOL_ENCODED.code
    end
    if feedback < 0 or not universal_interface.dial_in_progress then return feedback end
    sleep(delay)

    return feedback
end

local function rotational_symbol_engage(i, address, quick_dial)
    local symbol = address[i]
    local direction = i % 2 == 0
    local delay = CHEVRON_ENCODE_DELAY

    if quick_dial then 
        local prev = address[i - 1] or 0
        direction = symbol - prev % 39 > 19
        delay = 0
    end

    return rotational_symbol_engage_impl(symbol, delay, direction)
end

local function dial(address, engage, quick_dial)
    local isPegasus = interface.getStargateType() == "sgjourney:pegasus_stargate"
    for i, symbol in pairs(address) do
        if not universal_interface.dial_in_progress then break end

        os.queueEvent("yasc_engaging_symbol", i, symbol)
        universal_interface.checkInterfaceConnected()
        local feedback = engage(i, address, quick_dial)

        if feedback < 0 then
            os.queueEvent("yasc_engaging_symbol", i, symbol, false)
            return feedback
        end

        os.queueEvent("yasc_engaging_symbol", i, symbol, universal_interface.dial_in_progress)

        -- pegasus is exluded due to its animation
        if not quick_dial and universal_interface.dial_in_progress and not isPegasus then
            os.sleep(0.5)
        end
    end
end

-- Dials specified address
-- params quick_dial and direct_engage are optional and will override global settings when specified
-- returns FEEDBACK.UNKNOWN_ERROR if dial is already in progress
function universal_interface.dial(address, quick_dial, direct_engage)
    universal_interface.checkInterfaceConnected()
    if universal_interface.dial_in_progress then
        return FEEDBACK.UNKNOWN_ERROR
    end

    universal_interface.dial_in_progress = true

    -- if quick dial not specified, use global setting
    if quick_dial == nil then
        quick_dial = universal_interface.quick_dial
    end

    -- if direct engage not specified, use global setting
    if direct_engage == nil then
        direct_engage = universal_interface.direct_engage
    end

    -- if stargate cannot be rotated and direct_engage is not enabled, then enable it (for other gates than milkyway)
    if interface.rotateClockwise == nil and not direct_engage then
        direct_engage = true
    end

    local result = nil

    -- ensure address is ending on 0 (PoO)
    local addr = {table.unpack(address)}
    if addr[#addr] ~= 0 then
        table.insert(addr, 0)
    end

    -- check address length
    if #addr < 7 then
        universal_interface.dial_in_progress = false
        return FEEDBACK.INCOMPLETE_ADDRESS
    end
    if #addr > 9 then
        universal_interface.dial_in_progress = false
        return FEEDBACK.INVALID_ADDRESS
    end

    -- choose a function for engaging symbols
    local engage = nil
    if direct_engage and interface.engageSymbol then
        engage = direct_symbol_engage
    else
        engage = rotational_symbol_engage
    end

    -- call the dialing function
    -- surround with try-catch to handle exceptions and set dial_in_progress to false
    -- then rethrow the exception
    try(function()
        dial(addr, engage, quick_dial)
    end, function(exception)
        universal_interface.dial_in_progress = false
        error(exception)
    end)

    universal_interface.dial_in_progress = false
    return result
end

-- does not resets stargate!
function universal_interface.abortDial()
    universal_interface.dial_in_progress = false
end

function universal_interface.isDialing()
    return universal_interface.dial_in_progress
end


return universal_interface