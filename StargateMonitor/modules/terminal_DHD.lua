local ccstrings = require("cc.strings")
local module = {address = {}, cursor = 1}
local WIN = {}
local universal_interface = {}

module.configuration = {
    title = {type="string", value="Enter address to dial:", description="Title displayed above address field"},
    title_color = {type="color", value="black", description="Color of the title text"},
    background_color = {type="color", value="white", description="Background color of the window"},
    separator_color = {type="color", value="black", description="Color of the separator character"},
    address_color = {type="color", value="blue", description="Color of the address text"},
    error_color = {type="color", value="red", description="Color of the address text if number is invalid"},
    char_separators = {type="string", value=".,- ;+=	/", description="Characters that are considered as separators between symbols when entering address"},
    dial_button_text = {type="string", value="Dial", description="Text displayed on the dial button"},
    dial_button_text_color = {type="color", value="green", description="Color of the dial button text"},
    clear_on_invalid_dial = {type="boolean", value=false, description="Clear address field if dialing failed"}
}

function module.init(modules, windows)
    universal_interface = modules["universal_interface"]
    WIN = window.create(COMPUTER_WINDOW, 1, TERM_HEIGHT - 4, TERM_WIDTH, 5, true)
    WIN.setBackgroundColor(colors[module.configuration.background_color.value])
    WIN.clear()
    WIN.redraw()
    module.resetAddress()
    module.print()
end

function module.resetAddress()
    module.address = {}
    module.cursor = 1
    for i = 1, 8 do
        table.insert(module.address, "  ")
    end
end

local function isAddressValid()
    local length = 0
    for _,v in pairs(module.address) do
        if tonumber(v) == nil or isSymbolPresentTwice(module.address, v) or isAboveMaxSymbolValue(v) then
            break
        end
        length = length + 1
    end
    return length > 5
end

function module.activate()
    if isAddressValid() then
        local addr = {}
        for _,v in pairs(module.address) do
            if tonumber(v) == nil then
                break
            end
            table.insert(addr, tonumber(v))
        end
        try(function()
            module.print()
            module.showAlert("Dialing...", -1)
            universal_interface.dial(addr)
            module.resetAddress()
            module.print()
        end, function(e)
            if e and e.message then
                module.print()
                module.showAlert(e.message, -1)
            end
        end)
        return
    end
    module.print()
    module.showAlert("Invalid address", 3)
end

local function getCursorPosition()
    return 7 + math.floor(module.cursor / 2) + 4 * math.floor((module.cursor - 1) / 2)
end

local function getAddressIndex()
    return math.max(1, math.ceil(module.cursor / 2))
end

local function setCharAtCursor(char)
    local i = getAddressIndex()
    local n = module.address[i]
            
    if module.cursor % 2 == 0 then
        module.address[i] = n:sub(1, 1) .. char
    else
        module.address[i] = char .. n:sub(2, 2)
    end
end

local function addCursor()
    module.cursor = math.min(module.cursor + 1, 16)
end

local function remCursor()
    module.cursor = math.max(module.cursor - 1, 1)
end

local function restoreCursor()
    WIN.setTextColor(colors[module.configuration.address_color.value])
    WIN.restoreCursor()
    WIN.setCursorPos(getCursorPosition(), 4)
    WIN.setCursorBlink(true)
end

local alertSerial = 0
local alertCancelToken = nil

function module.print()
    local terminal = term.current()
    term.redirect(WIN)

    if alertCancelToken ~= nil then
        WIN.clear()
    end

    term.setCursorPos(2, 2)

    term.setTextColor(colors[module.configuration.title_color.value])
    term.setBackgroundColor(colors[module.configuration.background_color.value])
    print(module.configuration.title.value)
    
    term.setCursorPos(TERM_WIDTH - #module.configuration.dial_button_text.value, 5)
    term.setTextColor(colors[module.configuration.dial_button_text_color.value])
    term.write(module.configuration.dial_button_text.value)

    term.setCursorPos(5, 4)
    term.clearLine()

    term.setTextColor(colors[module.configuration.separator_color.value])
    term.write("- ")
    for i=1, 8 do
        term.setTextColor(colors[module.configuration.address_color.value])
        if isAboveMaxSymbolValue(module.address[i]) or isSymbolPresentTwice(module.address, module.address[i]) then
            term.setTextColor(colors[module.configuration.error_color.value])
        end
        term.write(module.address[i])
        term.setTextColor(colors[module.configuration.separator_color.value])
        term.write(" - ")
    end

    restoreCursor()
    term.redirect(terminal)
end

function module.handle_event(ev)
    if ev[1] == "key" then
        if ev[2] == keys.enter or ev[2] == keys.numPadEnter then
            module.activate()
            return
        elseif ev[2] == keys.backspace then
            if module.cursor < 16 or module.address[getAddressIndex()]:sub(2, 2) == " " then
                remCursor()
            end
            setCharAtCursor(" ")
            module.print()
        elseif ev[2] == keys.delete then
            setCharAtCursor(" ")
            module.print()
        elseif ev[2] == keys.left then
            remCursor()
            module.print()
        elseif ev[2] == keys.right and module.address[getAddressIndex()] ~= "  " then
            addCursor()
            module.print()
        end
    elseif ev[1] == "char" then
        if tonumber(ev[2]) ~= nil then
            setCharAtCursor(ev[2])
             
            addCursor()
            
            module.print()
        elseif string.find(module.configuration.char_separators.value, ev[2], 1, true) ~= nil then
            if module.address[getAddressIndex()] ~= "  " then
                addCursor()
                module.print()
            end
        end
    elseif ev[1] == "paste" then
        for c = 1, #ev[2] do
            local char = ev[2]:sub(c, c)
            module.handle_event({"char", char})
        end
        return
    elseif ev[1] == "mouse_click" then
        if ev[4] == TERM_HEIGHT and ev[3] >= TERM_WIDTH - #module.configuration.dial_button_text.value then
            module.activate()
            return
        end
        restoreCursor()
    end
end

function module.showAlert(text, timeout)
    local local_token = alertSerial
    alertSerial = alertSerial + 1
    alertCancelToken = local_token

    text = " " .. text .. " "

    local tc = WIN.getTextColor()
    local bc = WIN.getBackgroundColor()

    local w, h = WIN.getSize()
    local x = math.floor((w - string.len(text)) / 2)
    x = math.max(1, x)
    local y = 3

    WIN.setTextColor(colors.red)
    WIN.setBackgroundColor(colors.lightGray)

    WIN.setCursorPos(x, y-1)
    WIN.write(string.rep(" ", string.len(text)))
    WIN.setCursorPos(x, y+1)
    WIN.write(string.rep(" ", string.len(text)))

    WIN.setCursorPos(x, y)
    WIN.write(text)

    WIN.setTextColor(tc)
    WIN.setBackgroundColor(bc)

    COMPUTER_WINDOW.restoreCursor() -- hides cursor in DHD window
    COMPUTER_WINDOW.setCursorPos(1, 1)
    COMPUTER_WINDOW.setCursorBlink(false)

    if timeout == nil then
        timeout = ALERT_TIMEOUT
    end

    if timeout < 1 then
        return
    end

    run_later(timeout, function()
        if alertCancelToken == local_token then
            WIN.clear()
            module.print()
            restoreCursor()
            alertCancelToken = nil
        end
    end)
end

function module.run()
    module.print()
    while true do
        local ev = {os.pullEvent()}
        if COMPUTER_WINDOW.isVisible() then
            module.handle_event(ev)
        end
    end
end


module.name = "Terminal DHD"
return module
