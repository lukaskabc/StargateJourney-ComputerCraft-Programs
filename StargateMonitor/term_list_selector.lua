local ccstrings = require("cc.strings")
local Selector = {}

-- on select is called when item is highlited, 
-- on selected is called when item is selected (second time)
function Selector:new(win, lines, onSelectCB, onSelectedCB)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.lines = lines or {}
    o.scroll = 1
    o.selected = 0
    o.on_select_cb = onSelectCB or function(id) end
    o.on_selected_cb = onSelectedCB or function(id) end

    o.WIN = win
    self.lines = lines
    if onSelectCB then
        self.on_select_cb = onSelectCB
    end
    if onSelectedCB then
        self.on_selected_cb = onSelectedCB
    end
    self.scroll = 1
    self.selected = 0

    return o
end

function Selector:print()
    local terminal = term.current()
    term.redirect(self.WIN)

    term.setCursorPos(1, 1)
    local w, h = self.WIN.getSize()

    for i = self.scroll, self.scroll + h - 2 do
        if i > 0 and i <= #self.lines then
            local text = self.lines[i]
            term.setTextColor(colors.white)
            term.setBackgroundColor(colors.black)

            if i == self.selected then
                term.setTextColor(colors.black)
                term.setBackgroundColor(colors.white)
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

function Selector:doScroll(direction, h)
    if direction < 0 and self.scroll == 1 then
        return
    elseif direction > 0 and self.scroll >= #self.lines - h + 2 then
        return
    end

    self.scroll = math.max(1, math.min(#self.lines - h + 2, self.scroll + direction))
    self:print()
end

function Selector:isInWindow(x, y)
    local wx, wy = self.WIN.getPosition()
    local w, h = self.WIN.getSize()
    return x >= wx and x < wx + w and y >= wy and y < wy + h
end

function Selector:handle_event(ev)
    if not self.WIN.isVisible() then
        return false
    end

    local w, h = self.WIN.getSize()
    local wx, wy = self.WIN.getPosition()

    if ev[1] == "mouse_scroll" and self:isInWindow(ev[3], ev[4]) then
        local direction = 1
        if ev[2] < 0 then
            direction = -1
        end
    
        self:doScroll(direction, h)
    elseif ev[1] == "key" then
        if ev[2] == keys.up then
            if self.selected > 1 then
                self.selected = self.selected - 1
                if self.selected < self.scroll then
                    self.doScroll(-1, h)
                end
                self:print()
                self.on_select_cb(id)
                return true
            end
        elseif ev[2] == keys.down then
            if self.selected < 1 then
                self.selected = self.scroll - 1
            end
            if self.selected < #self.lines then
                self.selected = self.selected + 1
                if self.selected >= self.scroll + h - 1 then
                    self.doScroll(1, h)
                end
                self:print()
                self.on_select_cb(id)
                return true
            end
        elseif ev[2] == keys.enter or ev[2] == keys.space then
            if self.selected > 0 and self.selected <= #self.lines then
                self.on_selected_cb(self.selected)
                return true
            end
        end
    elseif ev[1] == "mouse_click" and self:isInWindow(ev[3], ev[4]) then
        local x, y = ev[3], ev[4]
        
        local id = y - wy + self.scroll -- + 1 - 1
        if self.selected ~= id then
            self.selected = id
            self:print()
            self.on_select_cb(id)
            -- call on highlight callback
            -- which should be used for updating selected description
            return true
        end
        if y >= wy and y <= wy+h and id > 0 then
            -- call selected callback
            self.on_selected_cb(id)
            return true
        end
    end
end


return Selector