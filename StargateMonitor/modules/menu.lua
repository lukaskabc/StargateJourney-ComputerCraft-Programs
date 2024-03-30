



local Module = {
    configuration = {
        text_color = {type="color", value="white", description="Button text color"},
        background_color = {type="color", value="lightGray", description="Button background color"},
        active_text_color = {type="color", value="white", description="Active button text color"},
        active_background_color = {type="color", value="gray", description="Active button background color"},
    }
}

local dummy_window = window.create(term.current(), 1, 1, 1, 1, false)
local function hide_window(win)
    win.setVisible(false)

    local x, y = win.getPosition()
    local w, h = win.getSize()
    dummy_window.reposition(x, y, w, h, win.monitor)

    dummy_window.setVisible(true)
    dummy_window.clear()
    dummy_window.redraw()
    dummy_window.setVisible(false)
end

local function show_window(win)
    win.setVisible(true)
    win.redraw()
end

-- module_names: {"button name", "module_name"}
-- windows: table with windows of all modules from modules_loader
-- window: window for this module
function Module:new(module_names, windows, window)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.window = window
    o.windows = {}
    o.buttons = {}
    o.active_window = nil

    -- init module names and their windows
    for i, m in pairs(module_names) do
        local name = m[1]
        local module_name = m[2]
        local win = windows[module_name]
        if win == nil then
            printError("Error during Menu buidling")
            printError("Failed to find window for module: " .. module_name)
            return 1
        end

        if o.active_window == nil then
            o.active_window = win
        else
            hide_window(win)
        end

        table.insert(o.windows, {name = name, window = win})
    end

    local w,h = o.window.getSize()

    o.menu_lines = {}
    o.menu_lines[1] = {}
    local line_width = 0
    local line = 1
    for i, m in pairs(o.windows) do
        if line_width + #m.name + 3 <= w then
            line_width = line_width + #m.name + 3
            table.insert(o.menu_lines[line], m)
        elseif line_width == 0 then
            printError("Error during Menu buidling")
            printError("Name: " .. m.name)
            printError("Is too long for given menu window width")
            printError("Max name length for current window width is " .. w - 1)
        else
            line_width = 0
            line = line + 4
            o.menu_lines[line] = {m}
        end
    end

    return o
end

function Module:renderButtons()
    self.window.setBackgroundColor(colors.black)
    self.window.clear()

    local ww, wh = self.window.getSize()

    for line, menu_line in pairs(self.menu_lines) do
        local lineLength = 0
        for _, btn in pairs(menu_line) do
            lineLength = lineLength + #btn.name
        end

        local space = math.floor((ww - lineLength) / (#menu_line + 1))
        local position = space

        for _, btn in pairs(menu_line) do
            if self.active_window == btn.window then
                self.window.setTextColor(colors[self.configuration.active_text_color.value])
                self.window.setBackgroundColor(colors[self.configuration.active_background_color.value])
            else
                self.window.setTextColor(colors[self.configuration.text_color.value])
                self.window.setBackgroundColor(colors[self.configuration.background_color.value])
            end

            local txt = " " .. btn.name .. " "
            self.window.setCursorPos(position, line)
            self.window.write(string.rep(" ", #txt))
            self.window.setCursorPos(position, line + 1)
            self.window.write(txt)
            self.window.setCursorPos(position, line + 2)
            self.window.write(string.rep(" ", #txt))

            table.insert(self.buttons, {window = btn.window, x = position, y = line, length = #txt})

            position = position + #txt + space
        end
    end
end

function Module:handle_click(x, y)
    local wx, wy = self.window.getPosition()
    local ww, wh = self.window.getSize()

    if x < wx or x >= wx + ww or y < wy or y >= wy + wh then
        return
    end

    local button = nil

    for _, btn in pairs(self.buttons) do
        if x >= wx + btn.x - 1 and x < wx + btn.x + btn.length - 1 and y >= wy + btn.y - 1 and y < wy + btn.y + 2 then
            button = btn
            break
        end
    end

    if button == nil then return end

    if self.active_window ~= nil then
        hide_window(self.active_window)
    end

    self.active_window = button.window
    show_window(self.active_window)

    self:renderButtons()
end


return Module