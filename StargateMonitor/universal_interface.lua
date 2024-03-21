local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")

local function checkModemError()
    local modem = peripheral.find("modem")
    if modem == nil then return end

end

local function checkInterfaceConnected(printError)
    if interface and interface.disconnectStargate then
        return true
    end

    if not printError then return false end

    if not interface.disconnectStargate then
        printError("Interface is properly connected to the computer, but it is not connected to the stargate!")
        printError("Ensure that the interface is connected to the stargate!")
    end



    return false
end

local function await_interface_setup()
    print("Waiting for interface setup...")
    while true do
        if checkInterfaceConnected() then
            return
        end

        os.pullEvent()
    end
end

local function reset()
    if interface.disconnectStargate then
        interface.disconnectStargate()
    end
    if interface.closeChevron then
        interface.closeChevron()
    end
end

