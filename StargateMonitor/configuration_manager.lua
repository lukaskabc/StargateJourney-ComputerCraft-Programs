local manager = {modules, window, pageWindow, lines = {}, scroll = 1, selected = 0, page}
local modules_selection_page = {}
local module_configuration_page = {}
local text_edit_page = {override = true}
local boolean_edit_page = {override = true}
local number_edit_page = {override = true}
local color_edit_page = {override = true}
local pretty_print = require("cc.pretty").pretty_print
local ccstrings = require("cc.strings")
local HEADER_COLOR = colors.orange
local COLORS = {"white", "orange", "magenta", "lightBlue", "yellow", "lime", "pink", "gray", "lightGray", "cyan", "purple", "blue", "brown", "green", "red", "black"}

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

local function close_edit_page()
    manager.editWindow.setVisible(false)
    manager.editWindow.setCursorBlink(false)
    manager.window.redraw()
    manager.pageWindow.redraw()
    local old = manager.page
    manager.page = module_configuration_page
    manager.page.init(old.module)
    manager.selected = old.id
    manager.scroll = old.scroll
    manager.page.print()
end

local function saveToModulesConfig(module_name, option)
    local config = {}
    try(function ()
        local txt = loadFile(MODULES_CONFIG_FILE)
        config = textutils.unserialise(txt)
    end, function() end)

    if config == nil then
        config = {}
    end
    
    if config[module_name] == nil then
        config[module_name] = {}
    end

    config[module_name][option.name] = option.value

    try(function()
        if fileExists(MODULES_CONFIG_FILE_backup) then
            fs.delete(MODULES_CONFIG_FILE_backup)
        end
    end, function() end)

    if fileExists(MODULES_CONFIG_FILE) then
        fs.copy(MODULES_CONFIG_FILE, MODULES_CONFIG_FILE_backup)
    end
    saveFile(MODULES_CONFIG_FILE, textutils.serialise(config, {compact = false}))
end

local function edit_page_event_handle(ev)
    if ev[1] == "key" then
        if ev[2] == keys.enter then
            local val = manager.page.value
            if manager.page.option.type == "number" then
                val = tonumber(val)
            end
            manager.page.option.value = val
            saveToModulesConfig(manager.page.module.module_name, manager.page.option)
            
            close_edit_page()
        elseif ev[2] == keys["end"] then
            close_edit_page()
        end
    elseif ev[1] == "mouse_click" then
        local x, y = ev[3], ev[4]
        if x > 0 and x < 3 and y == 1 then
            close_edit_page()
        end
    end
end

local function print_edit_page_footer(h)
    term.setCursorPos(1, h-1)
    term.setTextColor(colors.lightGray)
    term.setBackgroundColor(colors.gray)
    printCentered("Press Enter to save, End to cancel")
    term.setTextColor(colors.white)
end

function text_edit_page.init(option, module)
    manager.page.option = option
    manager.page.module = module
    manager.page.x = tostring(option.value):len() + 3
end

function text_edit_page.print()
    local t = term.current()
    local w, h = manager.editWindow.getSize()
    term.redirect(manager.editWindow)
    printCentered("Enter text value:")
    term.setCursorPos(3, 5)
    local v = ccstrings.ensure_width(manager.page.value, w-4)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.write(v)
    term.setBackgroundColor(colors.gray)

    print_edit_page_footer(h)

    term.redirect(t)

    manager.editWindow.setVisible(true)
    manager.editWindow.setCursorBlink(true)
    manager.editWindow.restoreCursor()
    manager.editWindow.setCursorPos(manager.page.x, 5)
end



function text_edit_page.handle_event(ev)
    if ev[1] == "key" then
        if ev[2] == keys.backspace then
            local x, y = manager.editWindow.getCursorPos()
            if #manager.page.value == 0 then return end
            if x <= 3 then return end
            manager.page.value = manager.page.value:sub(1, x-4)..manager.page.value:sub(x-2)
            manager.page.x = x-1
            manager.page.print()
        elseif ev[2] == keys.delete then
            local x, y = manager.editWindow.getCursorPos()
            if #manager.page.value == 0 then return end
            manager.page.value = manager.page.value:sub(1, x-3)..manager.page.value:sub(x-1)
            manager.page.print()
        elseif ev[2] == keys.left then
            local x, y = manager.editWindow.getCursorPos()
            if x > 3 then
                manager.editWindow.setCursorPos(x - 1, y)
                manager.page.x = x-1
            end
        elseif ev[2] == keys.right then
            local x, y = manager.editWindow.getCursorPos()
            local w, h = manager.editWindow.getSize()
            if x < w-2 and x <= #manager.page.value + 2 then
                manager.page.x = x + 1
                manager.editWindow.setCursorPos(manager.page.x, y)
            end
        end
    elseif ev[1] == "char" then
        manager.page.value = manager.page.value:sub(1, manager.page.x-3)..ev[2]..(manager.page.value:sub(manager.page.x-2) or "")
        manager.page.x = manager.page.x + 1
        manager.page.print()
    end

    edit_page_event_handle(ev)
end

function boolean_edit_page.init(option, module)
    boolean_edit_page.option = option
    boolean_edit_page.module = module
end

function boolean_edit_page.print()
    if manager.page.value == "true" or manager.page.value == true then
        manager.page.value = true
    else
        manager.page.value = false
    end

    local t = term.current()
    local w, h = manager.editWindow.getSize()
    term.redirect(manager.editWindow)
    term.setTextColor(colors.lightGray)
    term.setCursorPos(3, 3)
    printCentered("Click on the value")
    term.setCursorPos(3, 4)
    printCentered("or press space to change it")
    term.setCursorPos(3, 6)

    if manager.page.value then
        term.setBackgroundColor(colors.green)
    else
        term.setBackgroundColor(colors.red)
    end

    term.setTextColor(colors.white)
    printCentered(" "..ccstrings.ensure_width(tostring(manager.page.value), 5).." ")

    print_edit_page_footer(h)

    term.redirect(t)

    manager.editWindow.setVisible(true)
    manager.editWindow.setCursorBlink(false)
end

function boolean_edit_page.handle_event(ev)
    if ev[1] == "mouse_click" then
        local x, y = ev[3], ev[4]
        if x > 22 and x < 29 and y == 10 then
            manager.page.value = not manager.page.value
            manager.page.print()
        end
    elseif ev[1] == "key" and ev[2] == keys.space then
        manager.page.value = not manager.page.value
        manager.page.print()
    end

    edit_page_event_handle(ev)
end

function number_edit_page.init(option, module)
    text_edit_page.init(option, module)
end

function number_edit_page.print()
    text_edit_page.print()
end

function number_edit_page.handle_event(ev)
    if ev[1] == "char" then
        if tonumber(ev[2]) == nil and (ev[2] ~= "-" or manager.page.x ~= 3) then
            return
        end

        if ev[2] == "-" and manager.page.value:sub(1, 1) == "-" then
            return
        end

        manager.page.value = manager.page.value:sub(1, manager.page.x-3)..ev[2]..(manager.page.value:sub(manager.page.x-2) or "")
        manager.page.x = manager.page.x + 1
        manager.page.print()

        return
    end
    text_edit_page.handle_event(ev)
end

function color_edit_page.init(option, module)
    color_edit_page.option = option
    color_edit_page.module = module
    color_edit_page.selected = 1
    for i, name in pairs(COLORS) do
        if name == option.value then
            color_edit_page.selected = i
            break
        end
    end
end

function color_edit_page.print()
    local t = term.current()
    local w, h = manager.editWindow.getSize()
    term.redirect(manager.editWindow)
    term.setCursorPos(1, 3)
    term.setTextColor(colors.lightGray)
    printCentered("Use "..string.char(27).." left and right "..string.char(26).." arrows")
    term.setCursorPos(1, 4)
    printCentered("to change selected color")
    term.setCursorPos(math.floor((w/2)-#COLORS), 6)
    
    for i, name in pairs(COLORS) do
        term.setBackgroundColor(colors[name])
        term.setTextColor(colors.white)
        if name == "white" then
            term.setTextColor(colors.black)
        end
        if i == manager.page.selected then
            term.write(string.char(136)..string.char(132))
        else
            term.write("  ")
        end
    end

    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.gray)

    print_edit_page_footer(h)

    term.redirect(t)

    manager.editWindow.setVisible(true)
    manager.editWindow.setCursorBlink(false)
end

function color_edit_page.handle_event(ev)
    if ev[1] == "key" then
        if ev[2] == keys.left then
            if manager.page.selected > 1 then
                manager.page.selected = manager.page.selected - 1
                manager.page.value = COLORS[manager.page.selected]
                manager.page.print()
            end
        elseif ev[2] == keys.right then
            if manager.page.selected < #COLORS then
                manager.page.selected = manager.page.selected + 1
                manager.page.value = COLORS[manager.page.selected]
                manager.page.print()
            end
        end
    end
    edit_page_event_handle(ev)
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
    term.setTextColor(HEADER_COLOR)
    term.setBackgroundColor(colors.gray)
    term.clearLine()
    write(string.char(171)..string.char(171))
    printCentered("Configuration")
    term.setTextColor(colors.lightGray)
    term.setCursorPos(1,2)
    term.clearLine()
    printCentered("Select module you want to configure:")
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)

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

        if ev[3] > 0 and ev[3] < 3 and ev[4] == 1 then
            manager.terminate = true
            return
        end

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
    elseif ev[1] == "key" and (ev[2] == keys["end"] or ev[2] == keys.backspace) then
        manager.terminate = true
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

    manager.pageWindow.reposition(wx, wy, ww, wh - 4) -- -2 for two lines of header and -2 for two lines of description window

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
    term.setTextColor(HEADER_COLOR)
    term.setBackgroundColor(colors.gray)
    term.clearLine()
    write(string.char(171)..string.char(171))
    printCentered("Configuration "..string.char(187).." "..module_configuration_page.module.name)
    term.setCursorPos(1, 2)
    term.clearLine()
    term.setTextColor(colors.lightGray)
    printCentered("Select option you want to change:")
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.redirect(t)
    manager.print()
    local ww, wh = manager.window.getSize()
    module_configuration_page.description_window.reposition(1, wh - 2, ww, 2)
    module_configuration_page.description_window.redraw()
end

function module_configuration_page.edit_option(id)
    local option, name = nth_value(module_configuration_page.module.configuration, id)
    option.name = name
    name = name:gsub("_", " "):gsub("^%l", string.upper)
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

    manager.page.init(option, module_configuration_page.module)
    manager.page.id = id
    manager.page.scroll = manager.scroll
    manager.page.value = tostring(option.value)
    manager.page.print()
end

function module_configuration_page.update_description()
    module_configuration_page.description_window.setVisible(true)
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
    module_configuration_page.description_window.redraw()
end

function module_configuration_page.handle_event(ev)
    if ev[1] == "key" then
        if ev[2] == keys.backspace or ev[2] == keys["end"] then
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

            local id = y - wy + 1 + manager.scroll - 1
            if manager.selected ~= id then
                manager.selected = id
                manager.print()
                module_configuration_page.update_description()
                return
            end
            if y >= wy and y <= wy+h and id > 0 then
                module_configuration_page.edit_option(id)
                return
            end 
        end
    end

    module_configuration_page.update_description()
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

    while not manager.terminate do repeat
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
    until true end
    term.redirect(terminal)
end


return manager.run