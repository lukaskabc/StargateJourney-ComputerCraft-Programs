



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
    o.buttons_filled = false
    o.windows = {}
    o.buttons = {}
    o.active_button = nil

    -- init module names and their windows
    for i, m in pairs(module_names) do
        local name = m[1] -- button name
        local module_name = m[2] -- name of the module
        local win = windows[module_name] -- window of the module
        if win == nil then
            printError("Error during Menu buidling")
            printError("Failed to find window for module: " .. module_name)
            return 1
        end

        if o.active_button == nil then
            o.active_button = name
        end

        if o.windows[name] == nil then o.windows[name] = {} end
        table.insert(o.windows[name], win)
    end

    local w,h = o.window.getSize()

    o.menu_lines = {}
    o.menu_lines[1] = {}
    local btns = {}
    local line_width = 0
    local line = 1
    for name, _ in pairs(o.windows) do repeat
        if btns[name] ~= nil then
            break -- continue
        end
        btns[name] = true
        if line_width + #name + 3 <= w then
            line_width = line_width + #name + 3
            table.insert(o.menu_lines[line], name)
        elseif line_width == 0 then
            printError("Error during Menu buidling")
            printError("Name: " .. name)
            printError("Is too long for given menu window width")
            printError("Max name length for current window width is " .. w - 1)
        else
            line_width = 0
            line = line + 4
            o.menu_lines[line] = {name}
        end
    until true
    end

    for name, wins in pairs(o.windows) do
        if name ~= o.active_button then
            for _, w in pairs(o.windows[name]) do
                hide_window(w)
            end
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
            lineLength = lineLength + #btn
        end

        local space = math.floor((ww - lineLength) / (#menu_line + 1))
        local position = space

        for _, btn in pairs(menu_line) do
            if self.active_button == btn then
                self.window.setTextColor(colors[self.configuration.active_text_color.value])
                self.window.setBackgroundColor(colors[self.configuration.active_background_color.value])
            else
                self.window.setTextColor(colors[self.configuration.text_color.value])
                self.window.setBackgroundColor(colors[self.configuration.background_color.value])
            end

            local txt = " " .. btn .. " "
            self.window.setCursorPos(position, line)
            self.window.write(string.rep(" ", #txt))
            self.window.setCursorPos(position, line + 1)
            self.window.write(txt)
            self.window.setCursorPos(position, line + 2)
            self.window.write(string.rep(" ", #txt))

            if not self.buttons_filled then
                table.insert(self.buttons, {name = btn, x = position, y = line, length = #txt})
            end

            position = position + #txt + space
        end
    end
    self.buttons_filled = true
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

    if self.active_button ~= nil then
        for _, w in pairs(self.windows[self.active_button]) do
            hide_window(w)
        end
    end

    self.active_button = button.name

    for _, w in pairs(self.windows[button.name]) do
        show_window(w)
    end

    self:renderButtons()
end


return Module