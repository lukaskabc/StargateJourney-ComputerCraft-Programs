--        part of
--   Stargate Monitor
-- created by lukaskabc
--

-- (probably) universal dialing functions
-- main function and entrypoint is dial(interface, address, fastDial, dialingSignal)
-- interface: peripheral
-- address: table with numbers
-- fastDial: boolean (true is not mutch compatible with status - it may get really fast)
-- dialingSignal: defined in main.lua for canceling dialing and stuff like that

local wait, table_contains = table.unpack(require("./utils"))

local function direct_dial(interface, address, fastDial, dialingSignal)
    for i, symbol in pairs(address) do

        if dialingSignal and not dialingSignal.isDialing() then return end

        write("Encoding symbol "..symbol.."...")

        interface.engageSymbol(symbol)

        if not fastDial then
            sleep(1)
            while(interface.getChevronsEngaged() < i) do
                if dialingSignal and not dialingSignal.isDialing() then return end
                coroutine.yield()
            end
        end
        print("ok")
    end
end

-- returns true on success, false on error
local function checkFeedback(feedback, allowedCodes)
    if not table_contains(allowedCodes, feedback) then
        print(" ")
        printError("Failure during stagrate dialing sequence ("..feedback..")")
        return false
    end
    return true
end

local function fast_rotational_dial(interface, address, dialingSignal)
    local feedback
    for i, symbol in pairs(address) do
        local prev = address[i-1] or 0

        if dialingSignal and not dialingSignal.isDialing() then return end

        if symbol - prev % 39 > 19 then
            interface.rotateClockwise(symbol)
        else
            interface.rotateAntiClockwise(symbol)
        end

        while not interface.isCurrentSymbol(symbol) do
            if dialingSignal and not dialingSignal.isDialing() then return end
            sleep(0)
        end

        if dialingSignal and not dialingSignal.isDialing() then return end

        feedback = interface.openChevron()
        checkFeedback(feedback, {11, -26})

        if dialingSignal and not dialingSignal.isDialing() then return end

        --coroutine.yield()
        feedback = interface.closeChevron()
        checkFeedback(feedback, {-2, -27, 2, 3, 4})
        --coroutine.yield()

        if dialingSignal and not dialingSignal.isDialing() then return end
        
    end
end

local function rotational_dial(interface, address, fastDial, dialingSignal)
    if fastDial then
        fast_rotational_dial(interface, address, dialingSignal)
        return
    end

    local feedback
    local delay = 1
    for i, symbol in pairs(address) do
        if dialingSignal and not dialingSignal.isDialing() then return end
        
        write("Encoding symbol "..symbol.."...")

        if i % 2 == 0 then
            interface.rotateClockwise(symbol)
        else
            interface.rotateAntiClockwise(symbol)
        end

        while not interface.isCurrentSymbol(symbol) do
            if dialingSignal and not dialingSignal.isDialing() then return end
            sleep(0)
        end

        if dialingSignal and not dialingSignal.isDialing() then return end

        feedback = interface.openChevron()
        checkFeedback(feedback, {11, -26})

        sleep(delay)

        if dialingSignal and not dialingSignal.isDialing() then return end

        if symbol ~= 0 then
            feedback = interface.encodeChevron()
            checkFeedback(feedback, {1})

            sleep(delay)
        end

        if dialingSignal and not dialingSignal.isDialing() then return end

        feedback = interface.closeChevron()
        checkFeedback(feedback, {-2, -27, 2, 3, 4})
        print("ok")

        sleep(delay)
    end
end

local function addOrigin(address)
    local addr = {}
    for i, symbol in pairs(address) do
        addr[#addr+1] = symbol
    end

    if addr[#addr] ~= 0 then
        addr[#addr+1] = 0
    end
    
    return addr
end

local function dial(interface, address, fastDial, dialingSignal)
    if interface.closeChevron ~= nil then
        interface.closeChevron()
    end

    interface.disconnectStargate()

    if #address == 0 then
        print("empty address")
        return
    end

    local addr = addOrigin(address)

    local forceRotation = interface.openChevron ~= nil and not fastDial

    if interface.engageSymbol ~= nil and not forceRotation then
        direct_dial(interface, addr, fastDial, dialingSignal)
    else
        rotational_dial(interface, addr, fastDial, dialingSignal)
    end
end

return dial