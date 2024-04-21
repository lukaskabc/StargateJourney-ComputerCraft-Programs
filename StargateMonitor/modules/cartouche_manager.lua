local term_list_selector = require("term_list_selector")
local FILE = fs.combine(ROOT_DIR, "cartouche.json")
local ccstrings = require("cc.strings")
local module = {lines = {}}
local ADDRESS_TABLE = {}
local WIN = nil
local ADDRESS_LIST_WIN = nil

function module.saveAddressTable()
    try(function()
        local json = textutils.serialiseJSON(ADDRESS_TABLE)
        saveFile(FILE, json)
    end, function(e)
        printError(e)
        print()
        printError("Failed to save address table to file: " .. FILE)
        error(EXIT)
    end)
end

-- returns false on fail
function module.loadAddressTable()
    if not fileExists(FILE) then
        module.saveAddressTable()
        return
    end

    try(function()
        local json = loadFile(FILE)
        ADDRESS_TABLE = textutils.unserialiseJSON(json)
    end, function(e)
        printError(e)
        print()
        printError("Failed to load address table from file: " .. FILE)
        error(EXIT)
    end)

    for i, addr in pairs(ADDRESS_TABLE) do
        if addr.name == nil and addr.address ~= nil then
            addr.name = addressToString(addr.address)
        end
    end
end

function module.init(modules, windows)
    WIN = window.create(COMPUTER_WINDOW.monitor, 1, 1, TERM_WIDTH, TERM_HEIGHT, false)
    WIN.setCursorPos(1, 1)
    WIN.setBackgroundColor(colors.black)
    WIN.setTextColor(colors.lightGray)
    WIN.write("Select address to edit or press backspace to exit")

    ADDRESS_LIST_WIN = window.create(WIN, 1, 3, TERM_WIDTH, TERM_HEIGHT, true)
    module.loadAddressTable()
    for _, addr in pairs(ADDRESS_TABLE) do
        local name = " "
        if addr.name and addr.name ~= "" then
            name = ccstrings.ensure_width(name .. addr.name, TERM_WIDTH - (8*2)-2)
        end
        if addr.address then
            name = name .. addressToString(addr.address)
        end

        if addr.name == "SCRIPT_LOCAL_ADDRESS" then
            table.insert(module.lines, function()
                term.setTextColor(colors.lightGray)
                print(ccstrings.ensure_width(name))
            end)
        else
            table.insert(module.lines, name)
        end 
    end
    module.selector = term_list_selector:new(ADDRESS_LIST_WIN, module.lines, function() end, module.edit_address)
    module.selector:print()
end

function module.edit_address(id)
    print("edit address "..id)
end

-- TODO: when switching between cartouche manager and log, menu stops responding

function module.execute()
    COMPUTER_WINDOW.setVisible(false)
    WIN.setVisible(true)
    WIN.redraw()
    module.selector:print()
    while true do
        local ev = {os.pullEvent()}
        if ev[1] == "key" and (ev[2] == keys.backspace or ev[2] == keys["end"]) then
            break
        end
        module.selector:handle_event(ev)
    end

    WIN.setVisible(false)
    COMPUTER_WINDOW.setVisible(true)
    COMPUTER_WINDOW.redraw()
end

return module