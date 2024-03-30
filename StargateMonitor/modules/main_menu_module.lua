local WIN = nil
local Module = {}

function Module.init(modules, windows)
    for i, win in pairs(windows) do
        if win.module == "main_menu_module" then
            WIN = win
            break
        end
    end

    if WIN == nil then
        printError("Failed to find window configuration for Main menu module!")
        recommendReinstall()
        return 1
    end

    Module.menu = modules["menu"]:new({{"Status", "gate_vizualization"}, {"Cartouche", "cartouche"}, {"History", "cartouche"}}, windows, WIN)

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