local mainTerminal = term.current()
local strings = require("cc.strings")
local universal_dial = require("./universal_dialer")

local wait, table_contains = table.unpack(require("./utils"))

local MAIN_TERM_SIZE = {mainTerminal.getSize()}

local TERMINAL_WIDTH = MAIN_TERM_SIZE[1]

local DIAL_WINDOW_HEIGHT = 5
local MAX_SYMBOLS_IN_ADDRESS = 8 -- without the point of origin
local LOG_WINDOW_HEIGHT = MAIN_TERM_SIZE[2] - DIAL_WINDOW_HEIGHT - 1 -- make 1 line space between windows

local MAX_SYMBOL_VALUE = 38 -- inclusive

local BACKGROUND_COLOR = colors.white
local TEXT_COLOR = colors.black
local SYMBOL_BACKGROUND = colors.white
local SYMBOL_TEXT = colors.blue
local SYMBOL_INVALID_TEXT = colors.red

local logWindow = window.create(mainTerminal, 1, 1, TERMINAL_WIDTH, LOG_WINDOW_HEIGHT, true)
local dialWindow = window.create(mainTerminal, 1, LOG_WINDOW_HEIGHT + 2, TERMINAL_WIDTH, DIAL_WINDOW_HEIGHT, true)
term.redirect(logWindow)


-- binded by init function
local gateInterface
local allowFastDial
local dialingAddressHolder
local dialingSignal

local DialGUI = { address = {""}, currentSymbol = 1 }

local space = " - "
-- each symbol are two digits + space chars (-space after last symbol)
local addressWidth = (MAX_SYMBOLS_IN_ADDRESS * (2 + #space)) - #space

local addressX = math.floor(TERMINAL_WIDTH / 2) - math.floor(addressWidth / 2) - #space

local addressY = 4

function DialGUI.render()
    dialWindow.setBackgroundColor(BACKGROUND_COLOR)
    dialWindow.setTextColor(TEXT_COLOR)
    dialWindow.clear()

    local headline = "Enter address to dial:"
    local headlineX = 2

    dialWindow.setCursorPos(headlineX, 2)
    dialWindow.write(headline)
    
    DialGUI.printAddress()

end

function DialGUI.updateCursorPos()
    local x = addressX - #space + 1

    for i = 1, DialGUI.currentSymbol do
        x = x + 2 + #space
    end

    if #DialGUI.address[DialGUI.currentSymbol] > 0 then
        x = x + 1
    end

    dialWindow.setCursorPos(x, addressY)
    dialWindow.setBackgroundColor(SYMBOL_BACKGROUND)
    dialWindow.setTextColor(SYMBOL_TEXT)
    dialWindow.restoreCursor()
end

local function isAboveMaxSymbolValue(symbol)
    return (tonumber(symbol) or 0) > MAX_SYMBOL_VALUE
end

local function formatAddress(address)
    local result = "-"
    for _, v in pairs(address) do
        result = result .. v .. "-"
    end

    return result
end

function DialGUI.isSymbolPresentTwice(symbol)
    local count = 0
    for _,v in pairs(DialGUI.address) do
        if tonumber(v) == tonumber(symbol) then
            count = count + 1
            if count > 1 then
                return true
            end
        end
    end
    return false
end

function DialGUI.printAddress()

    dialWindow.setCursorPos(addressX, addressY)

    for i = 1, MAX_SYMBOLS_IN_ADDRESS do

        local symbol = strings.ensure_width(tostring(DialGUI.address[i] or ""), 2)

        dialWindow.setBackgroundColor(BACKGROUND_COLOR)
        dialWindow.setTextColor(TEXT_COLOR)
        dialWindow.write(space)

        dialWindow.setBackgroundColor(SYMBOL_BACKGROUND)
        if isAboveMaxSymbolValue(symbol) or DialGUI.isSymbolPresentTwice(symbol) then
            dialWindow.setBackgroundColor(SYMBOL_INVALID_TEXT)
        else
            dialWindow.setTextColor(SYMBOL_TEXT)
        end
        dialWindow.write(symbol)
    end

    dialWindow.setBackgroundColor(BACKGROUND_COLOR)
    dialWindow.setTextColor(TEXT_COLOR)
    dialWindow.write(space)

    DialGUI.updateCursorPos()
end

function DialGUI.pushNumber(character)
    local current = DialGUI.address[DialGUI.currentSymbol] or ""
    if #current == 2 and DialGUI.currentSymbol == MAX_SYMBOLS_IN_ADDRESS then
        DialGUI.printAddress()
        return
    end

    DialGUI.address[DialGUI.currentSymbol] = current .. character

    dialWindow.setBackgroundColor(BACKGROUND_COLOR)
    dialWindow.setTextColor(SYMBOL_TEXT)
    dialWindow.write(character)

    if #DialGUI.address[DialGUI.currentSymbol] == 2 then
        DialGUI.space()
    end
end

function DialGUI.backspace()
    local current = DialGUI.address[DialGUI.currentSymbol] or ""

    if #current == 0 and DialGUI.currentSymbol > 1 then
        table.remove(DialGUI.address) -- removes last
        DialGUI.currentSymbol = DialGUI.currentSymbol - 1
    end

    current = DialGUI.address[DialGUI.currentSymbol]
    DialGUI.address[DialGUI.currentSymbol] = current:sub(0, #current - 1)

    DialGUI.printAddress()
end

function DialGUI.space()
    if DialGUI.address[DialGUI.currentSymbol] == "" then
        return
    end
    if DialGUI.currentSymbol == MAX_SYMBOLS_IN_ADDRESS then
        DialGUI.printAddress()
        return
    end

    DialGUI.currentSymbol = DialGUI.currentSymbol + 1
    table.insert(DialGUI.address, "")
    DialGUI.printAddress()
end

function DialGUI.reset()
    DialGUI.address = {""}
    DialGUI.currentSymbol = 1
    DialGUI.printAddress()
end

local function isNumeric(char)
    return tonumber(char) ~= nil
end

local function handleSpecialKey(key)
    if key == keys.backspace then
        DialGUI.backspace()
    elseif table_contains({keys.space, keys.tab, keys.minus, keys.comma, keys.period, keys.slash, keys.right}, key) then
        DialGUI.space()
    elseif key == keys.enter or key == keys.numPadEnter then
        if dialingSignal.isDialing() or not dialingSignal.canDial() then
            print("Unable to initiate dialing (dialing blocked)")
            return
        end

        if #DialGUI.address < 6 then
            print("Address is too short (at least 6 symbols required)")
        else
            local addr = {}
            for _,v in pairs(DialGUI.address) do
                table.insert(addr, tonumber(v))
            end

            dialingAddressHolder.set(addr)
            dialingSignal.start()

            print("Dialing " .. formatAddress(addr))
            DialGUI.printAddress()

            universal_dial(gateInterface, addr, allowFastDial, dialingSignal)

            DialGUI.reset()
        end
    end
end

local function handleKeys()
    while true do
        local event, data = os.pullEvent()
        if event == "char" and isNumeric(data) then
            DialGUI.pushNumber(data)
        elseif event == "key" then
            handleSpecialKey(data)
        elseif event == "paste" then
            for char in string.gmatch(data, ".") do
                if isNumeric(char) then
                    DialGUI.pushNumber(char)
                elseif table_contains({"-", ".", ",", " ", "/", "	"}, char) then
                    DialGUI.space()
                end
            end
        end
    end
end



local function init(_gateInterface, _allowFastDial, _dialingAddressHolder, _dialingSignal)
    gateInterface = _gateInterface
    allowFastDial = _allowFastDial
    dialingAddressHolder = _dialingAddressHolder
    dialingSignal = _dialingSignal

    dialWindow.setCursorBlink(true)

    logWindow.setBackgroundColor(colors.black)
    logWindow.setTextColor(colors.gray)
    logWindow.clear()

    DialGUI.render()
    DialGUI.updateCursorPos()

    print("You can enter custom address and initiate dialing by pressing Enter")
end

return {
    init = init,
    run = handleKeys
}