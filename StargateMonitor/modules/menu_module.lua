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

    local menu_entries = {}

    for _, menu in pairs(Module.configuration.menu.value) do
        local button_name = menu.button
        local button_modules = menu.modules

        for _, m in pairs(button_modules) do
            table.insert(menu_entries, {button_name, m})
        end
    end

    Module.menu = modules["menu"]:new(menu_entries, windows, WIN)

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

-- Module.name = "Main menu"
Module.description = "Button menu for switching displayed modules"
return Module