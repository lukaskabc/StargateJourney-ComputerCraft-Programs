local manager = {modules, window, pageWindow, lines = {}, scroll = 1, selected = 0, page}
local modules_selection_page = {}
local module_configuration_page = {}
local text_edit_page = {override = true}
local boolean_edit_page = {override = true}
local number_edit_page = {override = true}
local color_edit_page = {override = true}
local pretty_print = require("cc.pretty").pretty_print
local ccstrings = require("cc.strings")

local function printCentered(text)
    local w, h = term.getSize()
    local x, y = term.getCursorPos()
    term.setCursorPos(math.floor((w - #text) / 2) + 1, y)
    write(text)
end

local function nth_value(table, n)
    local i = 1
    for k, v in pairs(table) do
        if i == n then
            return v, k
        end
        i = i + 1
    end
    return nil
end

function text_edit_page.init(option, module, id)
    text_edit_page.option = option
    text_edit_page.module = module
    text_edit_page.id = id
    text_edit_page.x = option.value:len() + 3
end

function text_edit_page.print()
    local t = term.current()
    local w, h = manager.editWindow.getSize()
    term.redirect(manager.editWindow)
    printCentered("Enter text value:")
    term.setCursorPos(3, 5)
    local v = ccstrings.ensure_width(text_edit_page.option.value, w-4)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.write(v)
    term.setBackgroundColor(colors.gray)

    term.setCursorPos(1, h-1)
    term.setTextColor(colors.lightGray)
    printCentered("Press Enter to save")
    term.setTextColor(colors.white)

    term.redirect(t)

    manager.editWindow.setVisible(true)
    manager.editWindow.setCursorBlink(true)
    manager.editWindow.restoreCursor()
    manager.editWindow.setCursorPos(text_edit_page.x, 5)
end

function text_edit_page.handle_event(ev)
    if ev[1] == "key" then
        if ev[2] == keys.enter then
            manager.editWindow.setVisible(false)
            manager.editWindow.setCursorBlink(false)
            manager.window.redraw()
            manager.pageWindow.redraw()
            manager.page = module_configuration_page
            manager.page.init(text_edit_page.module)
            manager.selected = text_edit_page.id
            manager.page.print()
        elseif ev[2] == keys.backspace then
            local x, y = manager.editWindow.getCursorPos()
            if #text_edit_page.option.value == 0 then return end
            if x <= 3 then return end
            text_edit_page.option.value = text_edit_page.option.value:sub(1, x-4)..text_edit_page.option.value:sub(x-2)
            text_edit_page.x = x-1
            text_edit_page.print()
        elseif ev[2] == keys.delete then
            local x, y = manager.editWindow.getCursorPos()
            if #text_edit_page.option.value == 0 then return end
            text_edit_page.option.value = text_edit_page.option.value:sub(1, x-3)..text_edit_page.option.value:sub(x-1)
            text_edit_page.print()
        elseif ev[2] == keys.left then
            local x, y = manager.editWindow.getCursorPos()
            if x > 3 then
                manager.editWindow.setCursorPos(x - 1, y)
                text_edit_page.x = x-1
            end
        elseif ev[2] == keys.right then
            local x, y = manager.editWindow.getCursorPos()
            local w, h = manager.editWindow.getSize()
            if x < w-2 and x <= #text_edit_page.option.value + 2 then
                text_edit_page.x = x + 1
                manager.editWindow.setCursorPos(text_edit_page.x, y)
            end
        end
    elseif ev[1] == "char" then
        text_edit_page.option.value = text_edit_page.option.value:sub(1, text_edit_page.x-3)..ev[2]..(text_edit_page.option.value:sub(text_edit_page.x-2) or "")
        text_edit_page.x = text_edit_page.x + 1
        text_edit_page.print()
    end
end

function boolean_edit_page.init(option, module, id)
    boolean_edit_page.option = option
    boolean_edit_page.module = module
    boolean_edit_page.id = id
end

function boolean_edit_page.print()
end

function boolean_edit_page.handle_event(ev)
end

function number_edit_page.init(option, module, id)
    number_edit_page.option = option
    number_edit_page.module = module
    number_edit_page.id = id
end

function number_edit_page.print()
end

function number_edit_page.handle_event(ev)
end

function color_edit_page.init(option, module, id)
    color_edit_page.option = option
    color_edit_page.module = module
    color_edit_page.id = id
end

function color_edit_page.print()
end

function color_edit_page.handle_event(ev)
end

function modules_selection_page.init()
    modules_selection_page.modules = {}
    local w, h = manager.window.getSize()
    manager.pageWindow.reposition(1, 3, w, h-2)
    manager.pageWindow.clear()
    manager.pageWindow.redraw()
    manager.lines = {}
    manager.selected = 0
    manager.scroll = 1

    for _, m in pairs(manager.modules) do
        if m.configuration ~= nil and m.name ~= nil then
            table.insert(modules_selection_page.modules, m)
        end
    end
end

function modules_selection_page.print()
    term.clear()
    term.setCursorPos(1, 1)
    printCentered("Configuration")
    term.setTextColor(colors.lightGray)
    printCentered("Select module you want to configure:")

    for _, m in pairs(modules_selection_page.modules) do
        table.insert(manager.lines, " "..m.name)
    end

    manager.print()
end

function modules_selection_page.handle_event(ev)
    if ev[1] == "mouse_click" then
        local x, y = ev[3], ev[4]
        local wx, wy = manager.pageWindow.getPosition()
        local w, h = manager.pageWindow.getSize()

        local id = y - wy + 1
        if manager.selected ~= id then
            manager.selected = id
            manager.print()
            return
        end
        if y >= wy and y <= wy+h and id > 0 and id <= #modules_selection_page.modules then
            manager.page = module_configuration_page
            manager.selectedModule = id
            manager.page.init(modules_selection_page.modules[id])
            manager.page.print()
        end
    elseif ev[1] == "key" and ev[2] == keys.enter then
        if manager.selected > 0 then
            manager.page = module_configuration_page
            manager.selectedModule = manager.selected
            manager.page.init(modules_selection_page.modules[manager.selected])
            manager.page.print()
        end
    end
end

function module_configuration_page.init(module)
    module_configuration_page.module = module
    manager.lines = {}
    manager.selected = 0
    manager.scroll = 1

    local ww, wh = manager.window.getSize()
    local wx, wy = manager.pageWindow.getPosition()
    -- manager.window.setCursorPos(1, 1)
    -- manager.window.write(ww, wh, wx, wy)

    manager.pageWindow.reposition(wx, wy, ww, wh - 2)

    module_configuration_page.description_window.reposition(1, wx + wh - 1, ww, 2)
    module_configuration_page.description_window.setBackgroundColor(colors.gray)
    module_configuration_page.description_window.setTextColor(colors.white)
    module_configuration_page.description_window.clear()
    module_configuration_page.description_window.setVisible(true)
    module_configuration_page.description_window.redraw()

    for option_name, config_option in pairs(module.configuration) do
        local name = option_name:gsub("_", " "):gsub("^%l", string.upper)
        local line = " "..name..": "
        if table_contains({"boolean", "number"}, config_option.type) then
            line = line..tostring(config_option.value)
        elseif config_option.type == "string" then
            line = line.."\""..config_option.value.."\""
        elseif config_option.type == "color" then
            local txt = line
            line = function()
                write(txt)
                local c = term.getTextColor()
                term.setTextColor(colors[config_option.value])
                write(string.char(132))
                print(ccstrings.ensure_width(""))
                term.setTextColor(c)
            end
        end
        table.insert(manager.lines, line)
    end
end

function module_configuration_page.print()
    local t = term.current()
    term.redirect(manager.window)
    term.setCursorPos(1, 1)
    term.clear()
    write(string.char(171)..string.char(171))
    printCentered("Configuration "..string.char(187).." "..module_configuration_page.module.name)
    term.setTextColor(colors.lightGray)
    printCentered("Select option you want to change:")
    term.redirect(t)
    manager.print()
    module_configuration_page.description_window.redraw()
end

function module_configuration_page.edit_option(id)
    local option, name = nth_value(module_configuration_page.module.configuration, id)
    manager.editWindow.clear()
    manager.editWindow.setVisible(true)
    manager.editWindow.redraw()

    manager.editWindow.setCursorPos(1, 2)
    local t = term.current()
    term.redirect(manager.editWindow)
    printCentered("Editing "..name)
    term.redirect(t)

    manager.editWindow.setCursorPos(1, 4)

    if option.type == "string" then
        manager.page = text_edit_page
    elseif option.type == "boolean" then
        manager.page = boolean_edit_page
    elseif option.type == "number" then
        manager.page = number_edit_page
    elseif option.type == "color" then
        manager.page = color_edit_page
    end

    manager.page.init(option, module_configuration_page.module, id)
    manager.page.print()
end

function module_configuration_page.handle_event(ev)
    if ev[1] == "key" then
        if ev[2] == keys.backspace then
            manager.page = modules_selection_page
            manager.page.init()
            manager.selected = manager.selectedModule
            manager.page.print()
            return
        elseif ev[2] == keys.enter then
            module_configuration_page.edit_option(manager.selected)
            return
        end
    elseif ev[1] == "mouse_click" then
        if ev[3] > 0 and ev[3] < 3 and ev[4] == 1 then
            manager.page = modules_selection_page
            manager.page.init()
            manager.selected = manager.selectedModule
            manager.page.print()
            return
        else
            local x, y = ev[3], ev[4]
            local wx, wy = manager.pageWindow.getPosition()
            local w, h = manager.pageWindow.getSize()

            local id = y - wy + 1
            if manager.selected ~= id then
                manager.selected = id
                manager.print()
                return
            end
            if y >= wy and y <= wy+h and id > 0 then
                module_configuration_page.edit_option(id)
                return
            end 
        end
    end

    module_configuration_page.description_window.clear()
    if manager.selected > 0 then
        local i = 1
        module_configuration_page.description_window.setCursorPos(1, 1)
        local w, h = module_configuration_page.description_window.getSize()
        local c = nth_value(module_configuration_page.module.configuration, manager.selected)
        if c ~= nil then
            local lines = ccstrings.wrap(c.description, w)
            for j = 1, math.min(2, #lines) do
                module_configuration_page.description_window.setCursorPos(1, j)
                module_configuration_page.description_window.write(lines[j])
            end
        end
    end
end

function manager.print()
    local terminal = term.current()
    local win = manager.pageWindow
    term.redirect(win)

    term.setCursorPos(1, 1)
    local w, h = win.getSize()

    for i = manager.scroll, manager.scroll + h - 2 do
        if i > 0 and i <= #manager.lines then
            local text = manager.lines[i]
            term.setTextColor(colors.white)
            term.setBackgroundColor(colors.black)

            if i == manager.selected then
                term.setTextColor(colors.black)
                term.setBackgroundColor(colors.lightGray)
            end

            if type(text) == "function" then
                text()
            else
                print(ccstrings.ensure_width(text))
            end
        end
    end

    term.redirect(terminal)
end

-- function manager.loadLines()
--     manager.lines = {}
--     for module_name, module in pairs(manager.modules) do repeat
--         if module.configuration == nil then
--             break -- continue
--         end
        
--         table.insert(manager.lines, string.char(187).." "..module_name)

--         for option_name, config_option in pairs(module.configuration) do
--             table.insert(manager.lines, "  "..option_name..": "..tostring(config_option.value))
--         end
--     until true end
-- end

-- direction: -1 up, 1 down
function manager.doScroll(direction, h)

    if direction < 0 and manager.scroll == 1 then
        return
    elseif direction > 0 and manager.scroll >= #manager.lines - h + 2 then
        return
    end

    manager.scroll = math.max(1, math.min(#manager.lines - h + 2, manager.scroll + direction))
    manager.print()
end

function manager.run(modules, win)
    manager.modules = modules
    manager.window = win
    local ww, wh = win.getSize()
    manager.pageWindow = window.create(win, 1, 1, ww, wh, true)
    manager.page = modules_selection_page
    local terminal = term.current()
    term.redirect(manager.window)

    module_configuration_page.description_window = window.create(win, 1, wh - 1, ww, 2, false)

    manager.editWindow = window.create(win, 5, 5, ww - 7, 9, false)
    manager.editWindow.setBackgroundColor(colors.gray)
    manager.editWindow.setTextColor(colors.white)
    manager.editWindow.clear()

    manager.page.init()
    manager.page.print()

    while true do repeat
        local ev = {os.pullEvent()}
        local w, h = manager.pageWindow.getSize()
        if manager.page.override then
            manager.page.handle_event(ev)
            break -- continue
        end

        if ev[1] == "mouse_scroll" then
            local s = 1
            if ev[2] < 0 then
                s = -1
            end

            manager.doScroll(s, h)
        elseif ev[1] == "key" then
            if ev[2] == keys.up then
                if manager.selected > 1 then
                    manager.selected = manager.selected - 1
                    if manager.selected < manager.scroll then
                        manager.doScroll(-1, h)
                    end
                end
                manager.print()
            elseif ev[2] == keys.down then
                if manager.selected < 1 then
                    manager.selected = manager.scroll - 1
                end
                if manager.selected < #manager.lines then
                    manager.selected = manager.selected + 1
                    if manager.selected >= manager.scroll + h - 1 then
                        manager.doScroll(1, h)
                    end
                end
                manager.print()
            end
        end
        manager.page.handle_event(ev)
        -- manager.editWindow.restoreCursor()
    until true end
    term.redirect(terminal)
end


return manager.run