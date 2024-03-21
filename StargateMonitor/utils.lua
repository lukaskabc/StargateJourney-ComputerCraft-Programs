-- checks whether table contains the value
local function table_contains(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end

    return false
end

-- returns true if specified path exists and is file, false otherwise
local function fileExists(filename)
    return fs.exists(filename) and not fs.isDir(filename)
end

-- loads file as string, if file does not exist returns empty string
local function loadFile(filename)
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
local function saveFile(filename, text)
    local f = io.open(filename, "w")
    f:write(text)
    f:flush()
    f:close()
end


return {
    table_contains = table_contains,
    fileExists = fileExists,
    loadFile = loadFile,
    saveFile = saveFile
}