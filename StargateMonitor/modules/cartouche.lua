local universal_interface
local pager

local WIN = nil
local ADDRESS_TABLE = {{name="Abydos", address = {26, 6, 14, 31, 11, 29}}, {name="Lantea"}, {name="Jina adresa"}, {name="uz nevim"}, {name="co sem"}, {name="mam psat"}, {name="Abydos"}, {name="Lantea"}, {name="Jina adresa"}, {name="uz nevim"}, {name="co sem"}, {name="mam psat"}, {name="Abydos"}, {name="Lantea"}, {name="Jina adresa"}, {name="uz nevim"}, {name = "uplne neco jineho"}, {name="a jeste jineho"}, {name = "a posledni"}}
local FILE = fs.combine(ROOT_DIR, "cartouche.json")
local TITLE = nil

local Module = {
    page = 0,
    configuration = {
        page_title = {type="string", value="Cartouche", description="Title displayed at the top of the screen"},
        align_center = {type="boolean", value=true, description="Align text (addresses) to the center of the screen"},
        -- this value can actually be replaced with table of two string {"left", "right"}
        selected_chars = {type="string", value= string.char(26) .. string.char(27), description="Exactly two characters to display on the left and right of the selected address"},
        text_color = {type="color", value="white", description="Text color of the address"},
        background_color = {type="color", value="black", description="Background color of the address"},
        header_text_color = {type="color", value="orange", description="Text color of the header"},
        header_background_color = {type="color", value="black", description="Background color of the header"},
        selected_text_color = {type="color", value="orange", description="Text color of the selected address"},
        selected_background_color = {type="color", value="black", description="Background color of the selected address"},
        page_size = {type="number", value=0, description="Number of addresses to display on one page (0 for auto max height)"}
    }
}

function Module.saveAddressTable()
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
function Module.loadAddressTable()
    if not fileExists(FILE) then
        Module.saveAddressTable()
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

function Module.init(modules, windows)
    for i, win in pairs(windows) do
        if win.module == "cartouche" then
            WIN = win
            break
        end
    end

    if WIN == nil then
        printError("Failed to find window configuration for Cartouche module!")
        recommendReinstall()
        return 1
    end

    local start_line = 1
    TITLE = Module.configuration.page_title.value

    if TITLE ~= nil and TITLE ~= "" then
        start_line = 3
    else
        TITLE = nil
    end

    if Module.configuration.page_size.value < 1 then
        local _, height = WIN.getSize()
        Module.configuration.page_size.value = height - start_line - 1
    end

    -- Module.loadAddressTable()

    universal_interface = modules["universal_interface"]
    pager = modules["address_monitor_pager"]:new(WIN, ADDRESS_TABLE, start_line, Module.configuration.align_center.value, Module.configuration.selected_chars.value, {colors[Module.configuration.selected_text_color.value], colors[Module.configuration.selected_background_color.value]}, Module.configuration.page_size.value)

    -- do not resize window as it is already configured from monitor config
    Module.render()
end

function Module.run()
    while true do
        local ev = {os.pullEvent()}
        if ev[1] == "monitor_touch" then
            Module.touch_event(table.unpack(ev, 2))
        end
    end
end

function Module.touch_event(id, x, y)
    if id ~= peripheral.getName(WIN.monitor) then
        return
    end

    local addrID = nil
    local selected = false
    try(function()
        addrID, selected = pager:touch(x, y)
    end, function (e)
        printError("Error during Cartouche click event:")
        printError(e)
        print()
    end)

    if addrID == nil or addrID < 1 or not selected then
        return
    end

    if ADDRESS_TABLE[addrID] == nil then
        return
    end

    if ADDRESS_TABLE[addrID].address == nil then
        if ADDRESS_TABLE[addrID].name == nil then
            return
        end
        pager:showAlert("Missing address!")
        printError("Unable to dial \"" .. ADDRESS_TABLE[addrID].name .. "\" - missing address!")
        return
    end

    pager:showAlert("Dialing " .. ADDRESS_TABLE[addrID].name, -1)
    
    try(function() 
        universal_interface.dial(ADDRESS_TABLE[addrID].address, false, true)
    end, function(e)
        if e == STARGATE_ALREADY_DIALING then
            pager:showAlert("Stargate is already dialing!")
        else
            error(e)
        end
    end)
    
    pager:draw(Module.page)
end

function Module.render()
    local width, _ = WIN.getSize()
    
    if TITLE then
        WIN.setTextColor(colors[Module.configuration.header_text_color.value])
        WIN.setBackgroundColor(colors[Module.configuration.header_background_color.value])
        local title = "[ " .. TITLE .. " ]"
        local fil_width = (width - string.len(title)) / 2
        local fil = string.rep("=", fil_width + 1)
        pager:printLine(1, fil .. title .. fil, false)
    end

    WIN.setTextColor(colors[Module.configuration.text_color.value])
    WIN.setBackgroundColor(colors[Module.configuration.background_color.value])
    pager:draw(Module.page)
end



return {
    init = Module.init,
    run = Module.run,
    configuration = Module.configuration
}