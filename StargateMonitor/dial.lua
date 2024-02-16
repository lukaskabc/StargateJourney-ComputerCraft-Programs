--        part of
--   Stargate Monitor
-- created by lukaskabc
--
-- Dial page (displays and handles cratouche)

local CARTOUCHE = require("1_cartouche") 
local universal_dial = require("universal_dialer")

-- binded via init function
local canPrint
local monitor
local gateInterface
local coords
local monitorSize
local startY = 1
local listStartY = startY + 5
local spacing = 1
local selected = 0
local navigate
local fastDial = false
local dialingAddressHolder
local dialingSignal
 
local function validateCartouche()
    for _, value in ipairs(CARTOUCHE) do
        if value.name == " " and #value.address == 0 then
            goto continue
        end

        value.name = string.gsub(value.name, "%s+$", "")

        if #value.address < 6 or #value.address > 8 or value.address[#value.address] == 0 then
            printError("Address of "..value.name.." is invalid")
            printError(table.concat(value.address, "-"))
            error("Address must be 6, 7 or 8 symbols long and do not end with 0")
        end

        if #value.name > monitorSize[1] then
            printError("Name of "..value.name.." is too long")
            error("Name must be shorter than "..monitorSize[1].." characters")
        end

        if value.name == "" then
            value.name = "-"..table.concat(value.address, "-") .. "-"
        end

        ::continue::
    end
end

local function init(_canPrint, _monitor, _gateInterface, _coords, _navigate, _fastDial, _dialingAddressHolder, _dialingSignal)
    canPrint = _canPrint
    monitor = _monitor
    gateInterface = _gateInterface
    coords = _coords
    navigate = _navigate
    fastDial = _fastDial
    dialingAddressHolder = _dialingAddressHolder
    dialingSignal = _dialingSignal
    monitorSize = {monitor.getSize()}

    validateCartouche()
end

local function printCenterLine(y, text, colors)
    if not canPrint() then
        return
    end

    if colors ~= nil then
        monitor.setBackgroundColor(colors[2])
        monitor.setTextColor(colors[1])
    end


    local x = math.floor((monitorSize[1] - #text) / 2)

    monitor.setCursorPos(0, y)
    monitor.write(string.rep(" ", monitorSize[1]))

    monitor.setCursorPos(x, y)
    monitor.write(text)
end

local function printCartouche()
    if not canPrint() then
        return
    end

    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.white)

    local y = listStartY
    for _, value in pairs(CARTOUCHE) do
        printCenterLine(y, value.name)
        y = y + 1 + spacing
    end
end

local function getClickedId(y)
    local id = 1
    local yy = listStartY
    while yy < y and id < #CARTOUCHE do
        id = id + 1
        yy = yy + 1 + spacing
    end

    if yy ~= y then
        return 0
    end

    return id
end

local function run()
    while true do
        local event, side, x, y = os.pullEvent("monitor_touch")

        if not canPrint() then
            goto continue
        end

        local id = getClickedId(y)

        if id < 1 or id > #CARTOUCHE then
            selected = 0
            -- yes printing the single selected line would be better
            printCartouche()
            goto continue
        end

        if selected ~= id then
            selected = id

            printCartouche()

            printCenterLine(y, CARTOUCHE[id].name, {colors.black, colors.white})

        elseif dialingSignal.canDial() then
            dialingSignal.start()
            navigate(1)
            dialingAddressHolder.set(CARTOUCHE[id].address)
            universal_dial(gateInterface, CARTOUCHE[id].address, fastDial, dialingSignal)
        else 
            printError("Dialing sequence blocked by active connection")
        end
        
        ::continue::
    end
end

local function pagePrint()
    selected = 0

    monitor.setCursorPos(1, startY)
    monitor.setTextColor(colors.white)
    monitor.setBackgroundColor(colors.black)
    local text = "[ CARTOUCHE ]="

    local width = math.floor((monitorSize[1] - #text) / 2)

    monitor.write(string.rep("=", width))
    monitor.write(text)
    monitor.write(string.rep("=", width))
    monitor.setCursorPos(1, startY + 2)
    monitor.setTextColor(colors.gray)
    monitor.write("Select destination")
    monitor.setCursorPos(1, startY + 3)
    monitor.write("to initiate dialing sequence:")

    monitor.setTextColor(colors.white)
    monitor.setBackgroundColor(colors.black)

    printCartouche()
end


return {
    init = init,
    run = run,
    page = {
        name = "CARTOUCHE",
        print = pagePrint
    }
}
