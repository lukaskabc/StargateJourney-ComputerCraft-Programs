local term_list_selector = require("term_list_selector")
local FILE = fs.combine(ROOT_DIR, "cartouche.json")
local GALAXIES_FILE = fs.combine(ROOT_DIR, "config/cartouche_galaxies.json")
local GALAXIES = {"Unknown Galaxy"}
local ccstrings = require("cc.strings")
local module = {lines = {}}
local ADDRESS_TABLE = {}
local WIN = nil
local ADDRESS_LIST_WIN = nil
local ADDRESS_EDIT_WIN = nil

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

function module.loadGalaxies()
    if not fileExists(GALAXIES_FILE) then
        saveFile(GALAXIES_FILE, textutils.serialiseJSON(GALAXIES))
        return
    end

    try(function()
        local json = loadFile(GALAXIES_FILE)
        GALAXIES = textutils.unserialiseJSON(json)
    end, function(e)
        printError(e)
        print()
        printError("Failed to load galaxies from file: " .. GALAXIES_FILE)
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

    ADDRESS_LIST_WIN = window.create(WIN, 1, 3, TERM_WIDTH, TERM_HEIGHT, true)
    ADDRESS_EDIT_WIN = window.create(WIN, 1, 3, TERM_WIDTH, TERM_HEIGHT, false)
    module.loadAddressTable()
    module.loadGalaxies()
    for _, addr in pairs(ADDRESS_TABLE) do
        local name = " "
        if addr.name and addr.name ~= "" then
            name = ccstrings.ensure_width(name .. addr.name, TERM_WIDTH - (8*2)-3) .. " "
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
    module.edit_selector = term_list_selector:new(ADDRESS_EDIT_WIN, {}, function() end, function() end)
    module.selector = term_list_selector:new(ADDRESS_LIST_WIN, module.lines, function() end, module.edit_address)
    module.selector:print()
    module.print()
end

function module.print()
    WIN.setCursorPos(1, 1)
    WIN.setBackgroundColor(colors.black)
    WIN.setTextColor(colors.lightGray)
    WIN.write(string.char(171)..string.char(171).." Select address to edit")
    WIN.redraw()
    ADDRESS_LIST_WIN.redraw()
end

function module.edit_name(id)
    
end

function module.edit_address_addr(id)
    
end

function module.edit_address_extragalactic(id)
    
end

function module.edit_address_galaxy(id)
    
end

function module.edit_address(id)
    print("Editting address "..id)
    ADDRESS_LIST_WIN.setVisible(false)
    ADDRESS_EDIT_WIN.setVisible(true)

    WIN.clear()
    WIN.setCursorPos(1, 1)
    WIN.setBackgroundColor(colors.black)
    WIN.setTextColor(colors.lightGray)
    WIN.write(string.char(171)..string.char(171).." Select field to edit")
    WIN.redraw()

    local addr = ADDRESS_TABLE[id]

    local parts = {
        {name = "Name", value = addr.name or "", key = "name", exec = function() module.edit_name(id) end},
        {name = "Address", value = addressToString(addr.address or {}), key = "address", exec = function() module.edit_address_addr(id) end},
        {name = "Extra-Galactic address", value = addressToString(addr.extragalactic_address or {}), key = "extragalactic_address", exec = function() module.edit_address_extragalactic(id) end},
        {name = "Galaxy", value = addr.galaxy, key = "galaxy", exec = function() module.edit_address_galaxy(id) end},
    }

    local options = {}
    for i, part in pairs(parts) do
        table.insert(options, ccstrings.ensure_width(" "..part.name.." ", math.max(#part.name + 3, TERM_WIDTH - 2 - #part.value)) .. ccstrings.ensure_width(part.value, TERM_WIDTH - #part.name - 5) .. " ")
    end
    module.edit_selector.lines = options
    module.edit_selector.on_selected_cb = function(part_id)
        if part_id == nil or part_id < 1 or part_id > #parts then
            return
        end
        print("edit part id " .. part_id)
        parts[part_id].exec()
    end

    ADDRESS_EDIT_WIN.redraw()
    module.edit_selector:print()
end

-- TODO: when switching between cartouche manager and log, menu stops responding

function module.execute()
    COMPUTER_WINDOW.setVisible(false)
    WIN.setVisible(true)
    ADDRESS_EDIT_WIN.setVisible(false)
    ADDRESS_LIST_WIN.setVisible(true)
    ADDRESS_LIST_WIN.redraw()
    WIN.redraw()
    module.print()
    module.selector:print()
    while true do
        local ev = {os.pullEvent()}
        if ev[1] == "key" and (ev[2] == keys.backspace or ev[2] == keys["end"]) then
            -- todo closing edit window
            break
        end
        if ADDRESS_LIST_WIN.isVisible() then
            module.selector:handle_event(ev)
        elseif ADDRESS_EDIT_WIN.isVisible() then
            module.edit_selector:handle_event(ev)
        end
    end

    WIN.setVisible(false)
    COMPUTER_WINDOW.setVisible(true)
    COMPUTER_WINDOW.redraw()
end

return module