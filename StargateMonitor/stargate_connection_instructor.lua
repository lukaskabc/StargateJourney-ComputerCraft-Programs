local INTERFACE = nil

local WIRELESS_MODEM = {"wireless_modem"}
local WIRED_NOT_ACTIVE = {"wired_not_active"}
local SOME_WIRED_NOT_ACTIVE = {"some_wired_not_active"}
local SCHEME_END = {"scheme_end"}

-- returns true if there is any interface connected to a stargate
local function isStargateConnected()
    if INTERFACE == nil then
        return false
    end

    return INTERFACE.disconnectStargate ~= nil
end

-- returns true if interface is not null
local function isInterfaceConnected()
    return INTERFACE ~= nil
end

-- returns true if there is a wired modem connected
-- throws WIRELESS_MODEM error if modem is wireless
local function isWiredModemConnected()
    local modem = {peripheral.find("modem")}
    if #modem == 0 then
        return false
    end

    local wirelessFound = false
    local connectedWiredFound = false
    local unconnectedWiredFound = false
    
    for _, m in pairs(modem) do
        if m.isWireless() then
            wirelessFound = true
        elseif m.getNameLocal() == nil then
            unconnectedWiredFound = true
        else
            connectedWiredFound = true
        end
    end

    if connectedWiredFound and unconnectedWiredFound then
        error(SOME_WIRED_NOT_ACTIVE)
    end

    if unconnectedWiredFound then
        error(WIRED_NOT_ACTIVE)
    end

    if connectedWiredFound then
        return true
    end

    if wirelessFound then
        error(WIRELESS_MODEM)
    end

    return false -- unknown error
end

local function isCorrectInterface()
    if INTERFACE == nil then
        return false
    end

    return INTERFACE.engageSymbol or INTERFACE.rotateClockwise
end

local function colorWrite(text, textColor, bgColor)
    local t, b = term.getTextColor(), term.getBackgroundColor()
    term.setTextColor(textColor)
    term.setBackgroundColor(bgColor)
    term.write(text)
    term.setTextColor(t)
    term.setBackgroundColor(b)
end

local function countInterfaces()
    local count = 0
    local names = {"basic_interface", "crystal_interface", "advanced_crystal_interface"}
    for _, name in pairs(names) do
        local i = {peripheral.find(name)}
        count = count + #i
    end
    return count
end

local function printScheme()
    local text, bg = colors.white, colors.black
    local x, y = term.getCursorPos()
    local errorDescription = nil
    local warningDescription = nil

    -- yes this is ugly af, but I am too lazy
    local function checkError()
        term.setCursorPos(x, y)
        if errorDescription == nil then
            return
        end
    
        colorWrite(string.char(127), colors.gray, bg)
    
        error(SCHEME_END)
    end

    local function schemeErrDescription()
        term.setCursorPos(x, y)

        local texts = {}

        if errorDescription ~= nil then
            texts = errorDescription
        elseif warningDescription ~= nil then
            texts = warningDescription
        end

        for i = 1, #texts do
            local line = texts[i]
            colorWrite(string.char(149), colors.gray, bg)
            write("^ "..line)
            y = y + 1
            term.setCursorPos(x, y)
        end
    end

    colorWrite(string.char(156).."[Computer", colors.gray, bg)
    y = y + 1
    term.setCursorPos(x, y)

    -- ======================================== WIRED MODEM
    try(function()
        if isWiredModemConnected() then
            colorWrite(string.char(157).."[", colors.gray, bg)
            term.setTextColor(colors.green)
            term.write("Wired modem")
            y = y + 1
        end
    end, function(err)
        if err == WIRELESS_MODEM then
            errorDescription = {"No Stargate interface or wired modem found!", "Did you by any chance used a wireless", "modem instead of a wired one?"}
        elseif err == WIRED_NOT_ACTIVE then
            errorDescription = {"Wired modem is not connected!", "Connect modems with cable, right click them", "and check that they are lit", "The modem must be red (active)"}
        elseif err == SOME_WIRED_NOT_ACTIVE then
            warningDescription = {"Found unconnected wired modem!", "Connect modems with cable, right click them", "and check that they are lit", "The modem must be red (active)"}
        else
            error(err)
        end
    end)
    if errorDescription ~= nil or warningDescription ~= nil then
        colorWrite(string.char(157).."[", colors.gray, bg)
        local c = colors.white
        if errorDescription ~= nil then
            c = colors.red
        else
            c = colors.yellow
        end
        term.setTextColor(c)
        term.write("Wired modem")
        y = y + 1
        schemeErrDescription()
    end
    checkError()

    -- ======================================== INTERFACE
    colorWrite(string.char(157).."[", colors.gray, bg)
    if not isInterfaceConnected() then
        term.setTextColor(colors.red)
        errorDescription = {"No Stargate interface found!", "Place a Stargate interface next to the computer", "Or use wired modems to connect", "an interface and this computer"}
    elseif countInterfaces() > 1 then
        term.setTextColor(colors.red)
        errorDescription = {"Multiple interfaces found!", "Only one stargate interface can be connected", "to the computer at a time"}
    elseif not isStargateConnected() then
        term.setTextColor(colors.red)
        errorDescription = {"No Stargate connected!", "Check that the interface", "is facing the Stargate:", "Interface has one black side", "that must face AWAY from the gate"}
    elseif not isCorrectInterface() then
        term.setTextColor(colors.red)
        errorDescription = {"Incorrect interface used!", "Used interface is not smart enough", "to work with connected Stargate", "Better interface is required, use", "Crystal interface or Advanced crystal interface"}
    else
        term.setTextColor(colors.green)
    end
    term.write("Interface")
    y = y + 1
    schemeErrDescription()
    checkError()

    -- ======================================== STARGATE
    colorWrite(string.char(141).."[", colors.gray, bg)
    term.setTextColor(colors.green)
    term.write("Stargate")
end

local function performChecks()
    local allGood = true
    INTERFACE = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")

    term.clear()
    -- local width, height = term.getSize()
    -- term.setCursorPos(2, math.floor(height / 3))
    term.setCursorPos(1,1)

    try(printScheme, function(err)
        allGood = false
        if err == SCHEME_END then
            return
        end
        error(err)
    end)

    return allGood
end

local function printErrorToAll()
    local monitors = {peripheral.find("monitor")}
    local terminal = term.current()
    for _, monitor in pairs(monitors) do repeat
        if not monitor then break end -- continue
        try(function()
            term.redirect(monitor)
            term.clear()
            term.setCursorPos(1, 1)
            if term.isColor() then
                term.setTextColor(colors.red)
                term.setBackgroundColor(colors.black)
            end
            print("Error occured, check computer for further instructions")
        end, function(e) end)
    until true
    end
    term.redirect(terminal)

    local links = {peripheral.find("Create_DisplayLink")}
    for _, link in pairs(links) do
        try(function()
            link.clear()
            link.setCursorPos(1, 1)
            link.write("Error occured")
            link.setCursorPos(1,2)
            link.write("check computer for further instructions")
            link.update()
        end, function(e) end)
    end
end

local function clearAll(devices)
    for _, device in pairs(devices) do
        try(function()
            device.clear()
            if device.update then
                device.update()
            end
        end, function(e) end)
    end
end

return function(handOnEnd)
    local timer = nil
    term.clear()
    term.setCursorPos(1, 1)

    while not performChecks() do
        if not timer then
            timer = os.startTimer(5)
        end
        
        print("\n\n")
        term.setTextColor(colors.lightGray)
        term.setBackgroundColor(colors.black)
        print("Press any key to rerun checks")
        print("(if not updated automatically)")

        printErrorToAll()

        local ev = {os.pullEvent()}
        if ev[1] == "timer" then
            if timer == ev[2] then
                timer = nil
            end
        end
    end

    local monitors = {peripheral.find("monitor")}
    local links = {peripheral.find("Create_DisplayLink")}
    clearAll(monitors)
    clearAll(links)

    if handOnEnd then
        print()
        print()
        term.setTextColor(colors.green)
        print("All checks passed and Stargate is successfully connected!")
        term.setTextColor(colors.white)
        print()
        print("Press any key to continue...")
        os.pullEvent("key")
    end
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1, 1)
end
