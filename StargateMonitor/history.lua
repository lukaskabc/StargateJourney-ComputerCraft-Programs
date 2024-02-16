--        part of
--   Stargate Monitor
-- created by lukaskabc
--
-- History page - provides method addAddress
-- handles saving (loading) history to (from) FILENAME
-- 

local universal_dial = require("universal_dialer")
local HISTORY_LENGTH = 10
local FILENAME = "/" .. shell.dir() .. "/history.data"
local CARTOUCHE = require("1_cartouche") 

local pretty = require("cc.pretty").pretty_print

local stack = {}

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

local function loadFile(filename)
    local lines = {}
    local file = io.lines(filename)

    for line in file do
        table.insert(lines, line)
    end

    return table.concat(lines, "\n")
end

local function saveFile(filename, text)
    local f = io.open(filename, "w")
    f:write(text)
    f:flush()
    f:close()
end

local function findName(address)
    local addr = address

    for _, value in pairs(CARTOUCHE) do
        if table.concat(value.address) == table.concat(address) then
            if value.name == "" then
                addr = value.address
            else
                return value.name
            end
            break
        end
    end

    return "-" .. table.concat(addr, "-") .. "-"
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

    local text = loadFile(FILENAME)
    stack = textutils.unserialise(text)

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

local function printStack()
    if not canPrint() then
        return
    end

    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.white)

    local y = listStartY
    for _, value in pairs(stack) do
        printCenterLine(y, findName(value))
        y = y + 1 + spacing
    end
end

local function getClickedId(y)
    local id = 1
    local yy = listStartY
    while yy < y and id < #stack do
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

        if id < 1 or id > #stack then
            selected = 0
            -- yes printing the single selected line would be better
            printStack()
            goto continue
        end

        if selected ~= id then
            selected = id

            printStack()

            printCenterLine(y, findName(stack[id]), {colors.black, colors.white})

        elseif dialingSignal.canDial() then
            dialingSignal.start()
            navigate(1)
            dialingAddressHolder.set(stack[id])
            universal_dial(gateInterface, stack[id], fastDial, dialingSignal)
        else 
            printError("Dialing sequence blocked by active connection")
        end
        
        ::continue::
    end
end

local function pagePrint()
    if not canPrint() then
        return
    end
    
    selected = 0

    monitor.setCursorPos(1, startY)
    monitor.setTextColor(colors.orange)
    monitor.setBackgroundColor(colors.black)
    local text = "[ HISTORY ]"

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

    printStack()
end

-- address = {}
local function addAddress(address)
    if not address or #address == 0 then
        return
    end

    table.insert(stack, 1, address)
    if #stack > HISTORY_LENGTH then
        table.remove(stack)
    end

    -- make it unique
    local unique = {}
    for _, value in pairs(stack) do
        local present = false
        local valueStr = table.concat(value)
        for _, u in pairs(unique) do
            if table.concat(u) == valueStr then
                present = true
                break
            end
        end

        if not present then
            table.insert(unique, value)
        end
    end

    stack = unique

    saveFile(FILENAME, textutils.serialise(stack))
    pagePrint()
end

return {
    init = init,
    run = run,
    page = {
        name = "HISTORY",
        print = pagePrint
    },
    addAddress = addAddress
}
