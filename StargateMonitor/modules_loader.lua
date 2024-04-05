local DEBUG = false

local modules = {}
local modules_config = {}


if fileExists(MODULES_CONFIG_FILE) then
    modules_config = loadFile(MODULES_CONFIG_FILE)
    try(function()
        modules_config = textutils.unserialiseJSON(modules_config)
    end, function(err)
        modules_config = {}
    end)
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

    if type(module.init) ~= "function" and DEBUG then
        printError("Module", module_name, "does not contain init function! Skipping...")
    end

    if type(module.run) ~= "function" and DEBUG then
        printError("Module", module_name ,"does not contain run function! Skipping...")
    end

    modules[module_name] = module
    modules_count = modules_count + 1
    print("Loaded module", module_name)

    -- now load module configuration
    if modules_config[module_name] == nil then
        break -- continue
    end

    local config = modules_config[module_name]
    for option_name, option_obj in pairs(module.configuration) do
        if config[option_name] ~= nil then
            option_obj.value = config[option_name]
        end
    end
    
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
if not fileExists(MONITOR_CONFIG_FILE) then
    printError("Monitor configuration not found!")
    recommendReinstall()
    return 1
end

local monitor_config = loadFile(MONITOR_CONFIG_FILE)
try(function()
    monitor_config = textutils.unserialiseJSON(monitor_config)
end, function(err)
    monitor_config = nil
    printError(err)
    print()
end)

if monitor_config == nil then
    printError("Failed to load monitor configuration!")
    recommendReinstall()
    return 1
end

-- now wrap all monitors
local windows = {}
for i, record in pairs(monitor_config) do
    local monitor_name = record.monitor
    local type = record.type
    local monitor = peripheral.wrap(monitor_name)

    if monitor == nil then
        printError("Monitor", monitor_name, "not found!")
        printError("This monitor was type of", type)
        printError("You probably disconnected that monitor from computer, you can either update config/monitor_config.json with new monitor name or reinstall the script.")
        recommendReinstall()
        return 1
    end

    if peripheral.getType(monitor) == "Create_DisplayLink" then
        monitor = create_link_wrapper(monitor)
    else
        monitor.update = function() end
        monitor.isCreateLink = function() return false end
    end

    if not monitor.isColor() and not ALLOW_NON_ADVANCED_MONITORS and not monitor.isCreateLink() then
        printError("Monitor with name", peripheral.getName(monitor), "is not an advanced monitor!")
        return 1
    end

    monitor.setTextScale(0.5)
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.white)
    monitor.clear()
    if record.textScale ~= nil then
        monitor.setTextScale(record.textScale)
    end

    if record.windows == nil then
        printError("Invalid monitor configuration for monitor", monitor_name, "no window configuration!")
        recommendReinstall()
        return 1
    end

    for j, win in pairs(record.windows) do
        if win.module == nil then
            printError("Invalid monitor configuration for monitor", monitor_name, "no module name for window", j)
            recommendReinstall()
            return 1
        end

        if monitor.isCreateLink() and not modules[win.module].textOnly then
            printError("Module", win.module, "does not support Create Link monitors!")
            recommendReinstall()
            return 1
        end

        local width = win.width
        local height = win.height

        if width == nil then width = -1 end
        if height == nil then height = -1 end

        if width < 1 then
            width, _ = monitor.getSize()
            width = width - win.x + 1
        end
        
        if height < 1 then
            _, height = monitor.getSize()
            height = height - win.y + 1
        end

        local w = window.create(monitor, win.x, win.y, width, height, true)

        local redraw = w.redraw
        w.redraw = function()
            monitor.update()
            redraw()
        end

        w.clear()
        w.redraw()

        w.module = win.module
        w.monitor = monitor
        windows[w.module] = w
    end
end


return {modules, windows}