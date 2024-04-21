local ccstrings = require("cc.strings")
local module = {lines = {}, scroll = 1, selected = 0, on_selected_cb = function(id) end, on_select_cb = function(id) end}
WIN = nil

-- on select is called when item is highlited, 
-- on selected is called when item is selected (second time)
function module.init(win, lines, onSelectCB, onSelectedCB)
    WIN = win
    module.lines = lines
    if onSelectCB then
        module.on_select_cb = onSelectCB
    end
    if onSelectedCB then
        module.on_selected_cb = onSelectedCB
    end
    module.scroll = 1
    module.selected = 0
end

function module.print()
    local terminal = term.current()
    term.redirect(WIN)

    term.setCursorPos(1, 1)
    local w, h = WIN.getSize()

    for i = module.scroll, module.scroll + h - 2 do
        if i > 0 and i <= #module.lines then
            local text = module.lines[i]
            term.setTextColor(colors.white)
            term.setBackgroundColor(colors.black)

            if i == module.selected then
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

function module.doScroll(direction, h)
    if direction < 0 and module.scroll == 1 then
        return
    elseif direction > 0 and module.scroll >= #module.lines - h + 2 then
        return
    end

    module.scroll = math.max(1, math.min(#module.lines - h + 2, module.scroll + direction))
    module.print()
end

local function isInWindow(x, y)
    local wx, wy = WIN.getPosition()
    local w, h = WIN.getSize()
    return x >= wx and x < wx + w and y >= wy and y < wy + h
end

function module.handle_event(ev)
    if not WIN.isVisible() then
        return false
    end

    local w, h = WIN.getSize()
    local wx, wy = WIN.getPosition()

    if ev[1] == "mouse_scroll" and isInWindow(ev[3], ev[4]) then
        local direction = 1
        if ev[2] < 0 then
            direction = -1
        end
    
        module.doScroll(direction, h)
    elseif ev[1] == "key" then
        if ev[2] == keys.up then
            if module.selected > 1 then
                module.selected = module.selected - 1
                if module.selected < module.scroll then
                    module.doScroll(-1, h)
                end
                module.print()
                module.on_select_cb(id)
                return true
            end
        elseif ev[2] == keys.down then
            if module.selected < 1 then
                module.selected = module.scroll - 1
            end
            if module.selected < #module.lines then
                module.selected = module.selected + 1
                if module.selected >= module.scroll + h - 1 then
                    module.doScroll(1, h)
                end
                module.print()
                module.on_select_cb(id)
                return true
            end
        elseif ev[2] == keys.enter or ev[2] == keys.space then
            if module.selected > 0 and module.selected <= #module.lines then
                module.on_selected_cb(module.selected)
                return true
            end
        end
    elseif ev[1] == "mouse_click" and isInWindow(ev[3], ev[4]) then
        local x, y = ev[3], ev[4]
        
        local id = y - wy + module.scroll -- + 1 - 1
        if module.selected ~= id then
            module.selected = id
            module.print()
            module.on_select_cb(id)
            -- call on highlight callback
            -- which should be used for updating selected description
            return true
        end
        if y >= wy and y <= wy+h and id > 0 then
            -- call selected callback
            module.on_selected_cb(id)
            return true
        end
    end
end


return module