local WIN = nil
local Module = {
    configuration = {
        -- each item (table) is one menu:
        --      {button = "Button name", modules = {"module A", "module B"}}
        menu = {type = "custom_menu", value = {}, description = "Menu configuration"}
    }
}

function Module.init(modules, windows)
    for i, win in pairs(windows) do
        if win.module == "menu_module" then
            WIN = win
            break
        end
    end

    if WIN == nil then
        printError("Failed to find window configuration for Menu module!")
        recommendReinstall()
        return 1
    end

    local menu_windows = {}

    for _, menu in pairs(Module.configuration.menu.value) do
        local button_name = menu.button
        local mdls = menu.modules

        local w = nil
        for _, m in pairs(mdls) do
            
            
        end
    end

    Module.menu = modules["menu"]:new({{"Status", "gate_vizualization"}, {"Cartouche", "cartouche"}, {"Status", "status_button"}, {"Status", "last_feedback"}}, windows, WIN)

    Module.menu:renderButtons()

    return 0
end

function Module.run()
    while true do
        local _, id, x, y = os.pullEvent("monitor_touch")
        if not WIN.monitor or id ~= peripheral.getName(WIN.monitor) or not WIN.isVisible() then
            return
        end
        Module.menu:handle_click(x, y)
    end
end

return Module