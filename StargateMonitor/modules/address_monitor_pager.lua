local Pager = {}

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

    o.window = window
    o.addressTable = addressTable
    o.firstLine = firstLine
    o.alignCenter = alignCenter
    o.selectedChars = selectedChars
    o.selectedColors = selectedColors
    o.pageSize = pageSize
    return o
end

-- line number, text and if line is selected
function Pager:printLine(line, text, isSelected)

    if isSelected then
        self.window.setTextColor(self.selectedColors[1])
        self.window.setBackgroundColor(self.selectedColors[2])

        text = self.selectedChars[1] .. " " .. text .. " " .. self.selectedChars[2]
    end

    if self.alignCenter then
        local width = self.window.getSize()
        local textWidth = string.len(text)
        local x = math.floor((width - textWidth) / 2)
        self.window.setCursorPos(x, line)
    end

    self.window.write(text)
end

function Pager:draw(page)
    local w = self.window

    for i, addr in pairs(self.addressTable) do
        if i >= (page + 1) * self.pageSize then
            break
        end
        if i > page * self.pageSize then
            self.printLine(i, addr, false)
        end
    end
end


return Pager