-- checks whether table contains the value
function table_contains(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end

    return false
end

-- returns true if specified path exists and is file, false otherwise
function fileExists(filename)
    return fs.exists(filename) and not fs.isDir(filename)
end

-- loads file as string, if file does not exist returns empty string
function loadFile(filename)
    local lines = {}

    if not fileExists(filename) then
        return ""
    end

    local file = io.lines(filename)

    for line in file do
        table.insert(lines, line)
    end

    return table.concat(lines, "\n")
end

-- saves text to file (replacing file contents)
function saveFile(filename, text)
    local f = io.open(filename, "w")
    f:write(text)
    f:flush()
    f:close()
end

function addressToString(addr)
    if #addr == 0 then
        return "-"
    end
    return "-" .. table.concat(addr, "-") .. "-"
end

function isAboveMaxSymbolValue(symbol)
    return (tonumber(symbol) or 0) >= MAX_SYMBOL_VALUE
end

function isSymbolPresentTwice(address, symbol)
    local count = 0
    for _,v in pairs(address) do
        if tonumber(v) == tonumber(symbol) then
            count = count + 1
            if count > 1 then
                return true
            end
        end
    end
    return false
end

function recommendReinstall()
    printError("Did you installed program correctly?")
    printError("Please reinstall the program with installer:")
    printError("pastebin run hXCYLwmF")
end


function create_link_wrapper(link_peripheral)
    CREATE_LINK_WRAPPER = {}

    CREATE_LINK_WRAPPER.link = link_peripheral
    setmetatable(CREATE_LINK_WRAPPER, link_peripheral)
    CREATE_LINK_WRAPPER.__index = CREATE_LINK_WRAPPER

    function CREATE_LINK_WRAPPER.getSize()
        local h, w = link_peripheral.getSize()
        return w, h
    end

    -- this is required as term does not contain update function
    function CREATE_LINK_WRAPPER.update()
        CREATE_LINK_WRAPPER.link.update()
    end

    function CREATE_LINK_WRAPPER.isColor()
        return false
    end
    CREATE_LINK_WRAPPER.isColour = CREATE_LINK_WRAPPER.isColor

    function CREATE_LINK_WRAPPER.getTextColor()
        return colors.white
    end
    CREATE_LINK_WRAPPER.getTextColour = CREATE_LINK_WRAPPER.getTextColor

    function CREATE_LINK_WRAPPER.getBackgroundColor()
        return colors.black
    end
    CREATE_LINK_WRAPPER.getBackgroundColour = CREATE_LINK_WRAPPER.getBackgroundColor

    function CREATE_LINK_WRAPPER.nativePaletteColor(color)
        return 1, 1, 1
    end
    CREATE_LINK_WRAPPER.nativePaletteColour = CREATE_LINK_WRAPPER.nativePaletteColor
    CREATE_LINK_WRAPPER.getPaletteColor = CREATE_LINK_WRAPPER.nativePaletteColor
    CREATE_LINK_WRAPPER.getPaletteColour = CREATE_LINK_WRAPPER.nativePaletteColor

    function CREATE_LINK_WRAPPER.getCursorBlink()
        return false
    end

    function CREATE_LINK_WRAPPER.isCreateLink()
        return true
    end

    function CREATE_LINK_WRAPPER.blit(text)
        CREATE_LINK_WRAPPER.write(text)
    end

    function CREATE_LINK_WRAPPER.setTextScale(scale)
        -- placeholder function
    end
    
    for name, f in pairs(term) do
        if CREATE_LINK_WRAPPER[name] == nil and type(f) == "function" then
            if link_peripheral[name] ~= nil then
                CREATE_LINK_WRAPPER[name] = link_peripheral[name]
            else
                CREATE_LINK_WRAPPER[name] = function(...)
                    -- placeholder function
                end
            end
        end
    end

    return CREATE_LINK_WRAPPER
end