local BASE_URL = "https://raw.githubusercontent.com/lukaskabc/StargateJourney-ComputerCraft-Programs/rewrite/StargateMonitor/"
local MODULE_BASE_URL = BASE_URL .. "modules/"
local installer = {}

term.clear()
term.setCursorPos(1, 1)
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
local TERMINAL = term.current()
local W, H = TERMINAL.getSize()
local WIN = window.create(TERMINAL, 1, 1, W, H, false)
print("Initializing installer...")

local REQUIRED_FILES = {
    "configuration_manager.lua",
    "globals.lua",
    "main.lua",
    "modules_loader.lua",
    "run_later.lua",
    "stargate_connection_instructor.lua",
    "stargate_feedbacks.lua",
    "try.lua",
    "universal_interface.lua",
    "utils.lua"
}

local MODULES = {
    {
        name = "Cartouche",
        module_file = "cartouche.lua",
        files = {
            MODULE_BASE_URL .. "address_monitor_pager.lua",
        }
    },
    {
        name = "Stargate Visualization (Status)",
        module_file = "gate_visualization.lua",
        files = {
            BASE_URL .. "assets/chevrons.lua",
            BASE_URL .. "assets/stargate.nfp",
            BASE_URL .. "assets/wormhole.nfp"
        }
    },
    {
        name = "Last feedback",
        module_file = "last_feedback.lua",
        files = {}
    },
    {
        name = "Menu",
        module_file = "menu_module.lua",
        files = {
            MODULE_BASE_URL .. "menu.lua",
        }
    },
    {
        name = "Status button",
        module_file = "status_button.lua",
        files = {}
    }
}

-- saves text to file (replacing file contents)
local function saveFile(filename, text)
    local f = io.open(filename, "w")
    f:write(text)
    f:flush()
    f:close()
end

local function urlToFile(url)
    return string.sub(url, #BASE_URL)
end

function installer.downloadFile(url)
    local target = urlToFile(url)

    WIN.clear()
    term.redirect(WIN)
    local res, msg = http.get(url)
    term.redirect(TERMINAL)
    if not res or res.getResponseCode() ~= 200 then
        term.redirect(WIN)
        WIN.setVisible(true)
        WIN.redraw()
        if res then res.close() end
        printError("Failed to download file " .. target)
        printError(msg)
        print(url)
        error("Failed to download file")
    end

    local content = res.readAll()
    target = shell.resolve("./"..target)
    
    saveFile(target, content)
    res.close()
end

function installer.downloadFileSet(files, prepend)
    if not prepend then prepend = "" end
    term.setTextColor(colors.lightGray)
    local _,y = term.getCursorPos()
    for i, file in pairs(files) do
        term.clearLine()
        term.setCursorPos(1, y)
        write("Downloading files...")
        write(i)
        write("/")
        write(#files)
        installer.downloadFile(prepend .. file)
    end
    print()
    term.setTextColor(colors.white)
end

function installer.print()
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colors.orange)
    print("Choose module you want to install:")
    term.setTextColor(colors.lightGray)
    print("click module to begin installation")
    term.setCursorPos(1, 4)
    term.setTextColor(colors.white)

    for _, m in pairs(MODULES) do
        if m.selected then
            term.setTextColor(colors.green)
            write("[#] ")
        else
            term.setTextColor(colors.red)
            write("[ ] ")
        end
        
        term.setTextColor(colors.white)
        write(m.name)
        print()
    end
end

function installer.installModule(module)
    term.clear()
    print("Installing module " .. module.name)
    installer.downloadFile(MODULE_BASE_URL .. module.module_file)
    installer.downloadFileSet(module.files)


    module.selected = true
end

function installer.run()
    print("Downloading required files...")
    -- installer.downloadFileSet(REQUIRED_FILES, BASE_URL)
    if not fs.isDir("modules") then fs.makeDir("modules") end
    if not fs.isDir("config") then fs.makeDir("config") end
    if not fs.isDir("assets") then fs.makeDir("assets") end

    installer.print()

    while true do repeat
        local ev = {os.pullEvent()}
        if ev[1] == "mouse_click" then

            local _, y = ev[3], ev[4]
            y = y - 3
            if y < 1 or y > #MODULES then
                break -- continue
            end

            installer.installModule(MODULES[y])
        elseif ev[1] == "key" then
            if ev[2] == keys.enter then
                installer.downloadModules()
            end
        end
    until true end
end




installer.run()