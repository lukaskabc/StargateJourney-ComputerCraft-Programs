-- computer screen menu
local WIN
local module = {name = "Terminal menu"}
local BUTTONS = {}
local cartouche_manager = nil

module.configuration = {
    manage_cartouche = {type="boolean", value=true, description="Enable cartouche management button"},
    show_log = {type="boolean", value=true, description="Enable log display button"},
    edit_config = {type="boolean", value=true, description="Enable reconfigure button"},
    reset_stargate = {type="boolean", value=true, description="Enable stargate reset button"},
    reboot = {type="boolean", value=false, description="Enable reboot button"},
    text_color = {type="color", value="white", description="Button text color"},
    background_color = {type="color", value="gray", description="Button background color"},
}


function module.manageCartouche()
    if cartouche_manager == nil then
        printError("Cartouche manager is not installed!")
        return
    end
    cartouche_manager.execute()
end

function module.init(modules, windows)
    local w, h = COMPUTER_WINDOW.getSize()
    WIN = window.create(COMPUTER_WINDOW, 1, 2, w, 7 --[[2 lines of buttons]], true)
    cartouche_manager = modules["cartouche_manager"]

    if cartouche_manager == nil and module.configuration.manage_cartouche.value then
        printError("Cartouche manager is not installed! Disabling...")
        module.configuration.manage_cartouche.value = false
    end

    BUTTONS = {
        {
            text = "Manage cartouche",
            option = "manage_cartouche",
            action = module.manageCartouche
        },
        {
            text = "Edit config",
            option = "edit_config",
            action = CONFIGURATION_MANAGER
        },
        {
            text = "Reset Stargate",
            option = "reset_stargate",
            action = modules["universal_interface"].reset
        },
        {
            text = "Reboot",
            option = "reboot",
            action = function() os.reboot() end
        },
        {
            text = "Show log",
            option = "show_log",
            action = module.showLog
        }
    }

    local menu_buttons = {}
    local wins = {}
    for _, btn in pairs(BUTTONS) do
        if module.configuration[btn.option].value then
            table.insert(menu_buttons, {btn.text, btn.option})
            wins[btn.option] = window.create(WIN, 1, 1, 1, 1, false)
            wins[btn.option].monitor = COMPUTER_WINDOW.monitor
        end
    end
    module.menu = modules["menu"]:new(menu_buttons, wins, WIN)
    module.wins = wins
    
    for n, v in pairs(module.configuration) do
        if module.menu.configuration[n] then
            module.menu.configuration[n] = v
        end
    end

    module.menu.active_button = nil
    module.menu:renderButtons()
    WIN.setVisible(true)
    WIN.redraw()
end

function module.drawMenu()
    module.menu:renderButtons()
    WIN.redraw()
end

local function click_callback(w)
    local option_name = nil
    for name, o in pairs(module.wins) do
        if o == w then
            option_name = name
            break
        end
    end

    if option_name == nil then
        return
    end

    for _, btn in pairs(BUTTONS) do
        if btn.option == option_name then
            btn.action()
            break
        end
    end
end

function module.showLog()
    COMPUTER_WINDOW.setVisible(false)
    DEBUG_WINDOW_WRAPPER.setVisible(true)
    WIN.setVisible(false)
    module.isLogShowed = true
    DEBUG_WINDOW_WRAPPER.redraw()
end 

local function hide_log()
    COMPUTER_WINDOW.setVisible(true)
    DEBUG_WINDOW_WRAPPER.setVisible(false)
    WIN.setVisible(true)
    COMPUTER_WINDOW.redraw()
    module.isLogShowed = false
    module.drawMenu()
end

function module.run()
    local wx, wy = WIN.getPosition()
    local ww, wh = WIN.getSize()
    while true do
        if module.isLogShowed then
            local ev, key = os.pullEvent("key")
            if key == keys.backspace or key == keys["end"] then
                hide_log()
            end
        elseif COMPUTER_WINDOW.isVisible() then
            module.drawMenu()
            local ev, button, x, y = os.pullEvent("mouse_click")

            if x >= wx and x < wx + ww and y >= wy and y < wy + wh then
                module.menu:handle_click(x, y, click_callback)
            end
        end
    end

end



return module