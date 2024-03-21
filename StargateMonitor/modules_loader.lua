local utils = require("utils")
local modules = {}

local function recommendReinstall()
    printError("Did you installed program correctly?")
    printError("Please reinstall the program with installer:")
    printError("pastebin run hXCYLwmF")
end

-- now lets load all modules
local abs_modules_folder = shell.resolve(MODULES_FOLDER)
if not fs.exists(abs_modules_folder) or not fs.isDir(abs_modules_folder) then
    printError("Modules folder not found!")
    recommendReinstall()
    return 1
end

-- load modules
-- required structure of module (returned object):
--     init() - function called when program starts
--     run()  - function executed in parallel with other modules
--
local modules_count = 0
for _,file in pairs(fs.list(abs_modules_folder)) do repeat
    local module_name = file:sub(1, #file - 4) -- remove .lua extension
    local module_path = MODULES_FOLDER .. "." .. module_name
    -- MODULES_FOLDER is already resolved as absolute path
    local module = require(module_path)

    if type(module) ~= "table" then
        printError("Value returned from module", module_name, "is not a table! Skipping...")
        break -- continue
    end

    if type(module.init) ~= "function" then
        printError("Module", module_name, "does not contain init function! Skipping...")
        break -- continue
    end

    if type(module.run) ~= "function" then
        printError("Module", module_name ,"does not contain run function! Skipping...")
        break -- continue
    end

    modules[module_name] = module
    modules_count = modules_count + 1
    print("Loaded module", module_name)
    
until true
end

if modules_count == 0 then
    printError("No modules found!")
    recommendReinstall()
    return 1
end

print("Loaded", modules_count, "modules")

-- ==================================================================================================================

-- load monitor configuration
if not utils.fileExists(MONITOR_CONFIG_FILE) then
    printError("Monitor configuration not found!")
    recommendReinstall()
    return 1
end

local monitor_config = utils.loadFile(MONITOR_CONFIG_FILE)
monitor_config = textutils.unserialiseJSON(monitor_config)



return {modules, monitor_config}