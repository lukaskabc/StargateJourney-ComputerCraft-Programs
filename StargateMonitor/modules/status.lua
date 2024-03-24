local universal_interface
local activeChevronColor = colors.red
local chevronBlinkColor = colors.yellow
local gateColor = colors.gray
local gateBackgroundColor = colors.black
local CHEVRONS_ORDER = {1, 2, 3, 6, 7, 8, 4, 5, 9}
local CHEVRONS_COORDS = require("assets.chevrons")

local pretty = (require "cc.pretty").pretty_print

-- window for gate status
local WIN = nil


local Status = {}
local encodedChevrons = {}

function Status.init(modules, windows)
    universal_interface = modules["universal_interface"]

    for i, win in pairs(windows) do
        if win.module == "status" then
            WIN = win
            break
        end
    end

    if WIN == nil then
        printError("Failed to find window configuration for Status module!")
        recommendReinstall()
        return 1
    end

    -- now setup window size
    local x, y = WIN.getPosition()
    WIN.reposition(x, y, 30, 21)

    Status.renderGate()

    return 0
end

function Status.run()
    -- os.shutdown()
    while true do
        local ev = {os.pullEvent()}
        if ev[1] == "stargate_chevron_engaged" then
            print(table.unpack(ev))
            Status.event_chevron_engaged(table.unpack(ev, 2))
        elseif ev[1] == "stargate_reset" or ev[1] == "stargate_disconnect" then
            encodedChevrons = {}
            print("stargate reset")
        else
            print(table.unpack(ev))
        end
    end
end

function Status.event_chevron_engaged(chevronsEngaged, chevronID, isIncomming, symbol)
    encodedChevrons[tostring(chevronID)] = chevronID

    Status.renderActiveChevron(chevronID, activeChevronColor)

    local chevrons = {}
    for s, i in pairs(encodedChevrons) do
        table.insert(chevrons, i)
    end
    -- table.sort(chevrons)
    -- print(table.unpack(chevrons))

    -- Status.renderGate()
end


--[[
local function writeAt(x, y, text)
    if type(text) ~= "string" then
        text = string.char(text)
    end
    term.setCursorPos(x, y)
    term.write(text)
end

-- http://i.imgur.com/ka5c7iF.png
function Status.renderGateDetails()
    -- left of the top chevron
    term.setBackgroundColor(gateColor)
    term.setTextColor(gateBackgroundColor)
    writeAt(10, 1, 143)
    writeAt(11, 1, 143)

    -- above left 8 chevron
    writeAt(6, 2, 159)
    writeAt(7, 2, 143)

    writeAt(8, 2, 131)
    -- above right 1 chevron
    writeAt(22, 2, 131)
    writeAt(23, 2, 143)
    
    -- right of the top chevron
    writeAt(12, 1, 131)
    writeAt(18, 1, 131)
    
    writeAt(19, 1, 143)
    writeAt(20, 1, 143)

    -- above right 1 chevron
    writeAt(22, 2, 131)
    writeAt(23, 2, 143)

    -- top chevron (9) detail
    term.setTextColor(colors.orange)
    writeAt(15, 3, 131)
    writeAt(16, 2, 133)
    writeAt(14, 2, 138)
    term.setTextColor(gateColor)
    term.setBackgroundColor(colors.orange)
    writeAt(14, 1, 143)
    writeAt(15, 1, 143)
    writeAt(16, 1, 143)

    -- 1 chevron detail
    writeAt(22, 3, 159)

    term.setTextColor(colors.orange)
    term.setBackgroundColor(gateColor)
    -- writeAt(22, 3, 159)
    

    -- above right 1 chevron
    term.setBackgroundColor(gateBackgroundColor)
    term.setTextColor(gateColor)
    writeAt(24, 2, 144)

    -- top inner
    writeAt(11, 4, 131)
    writeAt(12, 4, 131)
    writeAt(13, 4, 131)
    -- writeAt(14, 4, 131)
    -- writeAt(16, 4, 131)
    writeAt(17, 4, 131)
    writeAt(18, 4, 131)
    writeAt(19, 4, 131)

    -- right of 1 chevron
    writeAt(25, 3, 144)
    writeAt(26, 4, 144)
    writeAt(27, 5, 144)
    writeAt(28, 6, 144)

    -- right side of gate
    writeAt(29, 8, 149)
    writeAt(29, 9, 149)
    writeAt(29, 13, 149)
    writeAt(29, 14, 149)

    -- left side of gate
    writeAt(1, 14, 130)

    -- right bottom
    writeAt(28, 16, 129)
    writeAt(27, 17, 129)
    writeAt(26, 18, 129)
    writeAt(25, 19, 129)
    writeAt(24, 20, 129)
    writeAt(23, 20, 131)

    -- left bottom
    writeAt(2, 16, 130)
    writeAt(3, 17, 130)
    writeAt(4, 18, 130)
    writeAt(5, 19, 130)
    writeAt(6, 20, 130)
    writeAt(7, 20, 131)

    -- bottom of the gate (left)
    writeAt(10, 21, 131)
    writeAt(11, 21, 131)
    writeAt(12, 21, 131)

    -- bottom of the gate (right)
    writeAt(18, 21, 131)
    writeAt(19, 21, 131)
    writeAt(20, 21, 131)

    term.setTextColor(gateBackgroundColor)
    term.setBackgroundColor(gateColor)
    -- left of 8 chevron    
    writeAt(5, 3, 159)
    writeAt(4, 4, 159)
    writeAt(3, 5, 159)
    writeAt(2, 6, 159)

    -- left side of gate
    writeAt(1, 8, 149)
    writeAt(1, 9, 149)
    writeAt(1, 13, 149)
    writeAt(1, 14, 149)
    term.setTextColor(gateColor)
end
]]

function Status.renderGate()
    local fileName
    local chevronCount = universal_interface.getChevronsEngaged()

    if universal_interface.isStargateConnected() then
        fileName = "wormhole.nfp"
        if not table_contains(encodedChevrons, 9) then
            table.insert(encodedChevrons, 9)
        end
    else
        fileName = "stargate.nfp"
    end

    local gameImage = paintutils.loadImage(shell.resolve("assets/" .. fileName))
    local terminal = term.current()
    term.redirect(WIN)
    paintutils.drawImage(gameImage, 1, 1)
    -- Status.renderGateDetails()
    term.redirect(terminal)

    if chevronCount > #encodedChevrons then
        encodedChevrons = {table.unpack(CHEVRONS_ORDER, 1, chevronCount)}
    end

    for i, ch in pairs(encodedChevrons) do
        Status.renderActiveChevron(ch, activeChevronColor)
    end
end

function Status.renderActiveChevron(chevronID, color)
    WIN.setBackgroundColor(color)
    WIN.setTextColor(color)
    for i, coord in pairs(CHEVRONS_COORDS[chevronID]) do
        WIN.setCursorPos(coord[1], coord[2])
        WIN.write(" ")
    end
end



return {
    init = Status.init,
    run = Status.run
}