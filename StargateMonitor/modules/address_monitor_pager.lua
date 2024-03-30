local Pager = {}

local PREV_TEXT = " " .. string.char(27) .. " Prev "
local NEXT_TEXT = " Next " .. string.char(26) .. " "
local BUTTON_BACKGROUND = colors.lightGray

-- window: window object
-- addressTable: table with addresses to display
-- firstLine: number of first line
-- alignCenter: boolean
-- selectedChars: string of two characters
-- selectedColors: table with two colors (text, background)
-- pageSize: number of lines per page
function Pager:new(window, addressTable, firstLine, alignCenter, selectedChars, selectedColors, pageSize)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.page = 0
    o.window = window or nil
    o.addressTable = addressTable or {}
    o.firstLine = firstLine or 1
    o.alignCenter = alignCenter or false
    o.selectedChars = selectedChars or {}
    o.selectedColors = selectedColors or {colors.white, colors.black}
    o.pageSize = pageSize or 10
    o.selectedID = -1

    local w,h = window.getSize()
    -- remove bottom 3 lines for buttons
    o.pageSize = math.min(pageSize, h - firstLine - 2)

    if type(selectedChars) == "string" then
        o.selectedChars = {}
        for i = 1,string.len(selectedChars) do
            table.insert(o.selectedChars, string.sub(selectedChars, i, i))
        end
    end

    return o
end

function Pager:drawButtons(normalText, normalBackground)
    local w,h = self.window.getSize()

    for i = 0, 2 do
        self.window.setCursorPos(1, h - i)
        self.window.clearLine()
    end

    self.window.setTextColor(colors.white)
    self.window.setBackgroundColor(BUTTON_BACKGROUND)

    if self.page > 0 then
        self.window.setCursorPos(1, h - 1)
        self.window.write(PREV_TEXT)
        self.window.setCursorPos(1, h - 2)
        self.window.write(string.rep(" ", #PREV_TEXT))
        self.window.setCursorPos(1, h)
        self.window.write(string.rep(" ", #PREV_TEXT))
    end

    if self.page * self.pageSize + self.pageSize < #self.addressTable then
        self.window.setCursorPos(w - #NEXT_TEXT, h - 1)
        self.window.write(NEXT_TEXT)
        self.window.setCursorPos(w - #NEXT_TEXT, h - 2)
        self.window.write(string.rep(" ", #NEXT_TEXT))
        self.window.setCursorPos(w - #NEXT_TEXT, h)
        self.window.write(string.rep(" ", #NEXT_TEXT))
    end

    local totalPages = math.ceil(#self.addressTable / self.pageSize)
    if totalPages > 1 then
        local pageText = self.page + 1 .. "/" .. totalPages
        local c = colors.lightGray
        if c == normalBackground then
            c = normalText
        end
        self.window.setTextColor(c)
        self.window.setBackgroundColor(normalBackground)
        self.window.setCursorPos(math.floor((w - #pageText) / 2), h - 1)
        self.window.write(pageText)
    end

end

function Pager:buttonClick(x, y)
    local w,h = self.window.getSize()
    local wx, wy = self.window.getPosition()

    if y < wy + h - 3 or y >= wy + h then
        return false
    end

    if x < wx + #PREV_TEXT and x > wx -1 and self.page > 0 then
        self.page = self.page - 1
    elseif x >= wx + w - #NEXT_TEXT -1 and x < wx + w -1 and self.page +1 < math.ceil(#self.addressTable / self.pageSize) then
        self.page = self.page + 1
    end

    self:draw(self.page)
    return true
end

-- line number, text and if line is selected
function Pager:printLine(line, text, isSelected)

    if isSelected then
        self.window.setTextColor(self.selectedColors[1])
        self.window.setBackgroundColor(self.selectedColors[2])

        if self.selectedChars ~= nil and #self.selectedChars == 2 then
            text = self.selectedChars[1] .. " " .. text .. " " .. self.selectedChars[2]
        end
    end

    if self.alignCenter then
        local width = self.window.getSize()
        local textWidth = string.len(text)
        local x = math.floor((width - textWidth) / 2)
        self.window.setCursorPos(x, line)
    else
        self.window.setCursorPos(1, line)
    end

    self.window.clearLine()
    self.window.write(text)
end

function Pager:draw(page)
    self.page = page
    local _, height = self.window.getSize()
    -- local height = height - self.firstLine
    local space = self.pageSize < (#self.addressTable - (page * self.pageSize)) * 2
    if space then space = 0 else space = 1 end

    local textColor = self.window.getTextColor()
    local backgroundColor = self.window.getBackgroundColor()

    local line = self.firstLine

    for i = (page * self.pageSize) + 1, (page * self.pageSize) + self.pageSize do
        if i > #self.addressTable then
            break
        end

        local addr = self.addressTable[i]

        if i > (page + 1) * self.pageSize then
            break
        end

        local text

        if addr.name ~= nil then
            text = addr.name
        else
            text = addressToString(addr.address)
        end

        if i > page * self.pageSize then
            self.window.setTextColor(textColor)
            self.window.setBackgroundColor(backgroundColor)
            self:printLine(line, text, self.selectedID == i)
        end

        for s = 1, space do
            self.window.setCursorPos(1, line + s)
            self.window.clearLine()
        end

        line = line + 1 + space
    end

    while line <= height - 3 do
        self.window.setCursorPos(1, line)
        self.window.clearLine()
        line = line + 1
    end

    self:drawButtons(textColor, backgroundColor)

    self.window.setTextColor(textColor)
    self.window.setBackgroundColor(backgroundColor)
end

-- returns id of clicked address and true if it was previously selected
function Pager:touch(x, y)
    if self:buttonClick(x, y) then
        return -1, false
    end

    local space = self.pageSize < (#self.addressTable - (self.page * self.pageSize)) * 2
    if space then space = 0 else space = 1 end

    local wx, wy = self.window.getPosition()
    local ww, wh = self.window.getSize()

    local line = (y - wy - self.firstLine + 1) / (1 + space)
    
    if math.floor(line) ~= line then
        return -1, false
    end

    local id = (self.page * self.pageSize) + line + 1
    local wasSelected = self.selectedID == id and id ~= -1
    
    if x < wx or x >= wx + ww or y < wy + self.firstLine - 1 or y >= wy + wh - 3 then
        id = -1
    end

    if id < self.pageSize * self.page or id > #self.addressTable or id > (self.page + 1) * self.pageSize then
        id = -1
    end

    self.selectedID = id
    if wasSelected then
        self.selectedID = -1
    end

    self:draw(self.page)

    return id, wasSelected
end

local alertCancelToken = nil

function Pager:showAlert(text, timeout)
    local local_token = os.epoch("utc")
    alertCancelToken = local_token

    text = " " .. text .. " "

    local tc = self.window.getTextColor()
    local bc = self.window.getBackgroundColor()

    local w, h = self.window.getSize()
    local x = math.floor((w - string.len(text)) / 2)
    local y = math.floor((h - self.firstLine) / 2)

    self.window.setTextColor(colors.red)
    self.window.setBackgroundColor(colors.lightGray)

    self.window.setCursorPos(x, y-1)
    self.window.write(string.rep(" ", string.len(text)))
    self.window.setCursorPos(x, y+1)
    self.window.write(string.rep(" ", string.len(text)))

    self.window.setCursorPos(x, y)
    self.window.write(text)

    self.window.setTextColor(tc)
    self.window.setBackgroundColor(bc)

    if timeout == nil then
        timeout = ALERT_TIMEOUT
    end

    if timeout < 1 then
        return
    end

    run_later(timeout, function()
        if alertCancelToken == local_token then
            self:draw(self.page)
        end
    end)
end

return Pager