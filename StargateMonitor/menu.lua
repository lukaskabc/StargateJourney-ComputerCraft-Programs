--        part of
--   Stargate Monitor
-- created by lukaskabc
--

local strings = require "cc.strings"

local Menu = {
    pages = {},
    currentPage = 1,
    monitor = nil,
    buttonCoords = {1, 1}
}

--[[
    pages = {
        {name = "STATUS", print = function() end},
        {name = "DIAL", print = function() end},
        {name = "HISTORY", print = function() end}

        -- field xStart and xEnd will be added to each page
    }
    currentPage = 1 (number)
    monitor = monitor (peripheral)
    offset = {1, 1}
]]
function Menu.init(pages, currentPage, monitor, buttonCoords)
    Menu.pages = pages
    Menu.currentPage = currentPage
    Menu.buttonCoords = buttonCoords
    Menu.monitor = monitor
end

function Menu.isPage(page)
    return Menu.currentPage == page
end

function Menu.print()
    -- clear monitor
    Menu.monitor.setTextScale(0.5)
    Menu.monitor.setBackgroundColor(colors.black)
    Menu.monitor.clear()

    Menu.pages[Menu.currentPage].print()

    Menu.monitor.setTextColor(colors.white)

    local x = Menu.buttonCoords[1]
    local y = Menu.buttonCoords[2]

    for i = 1, #Menu.pages do
        if i == Menu.currentPage then
            Menu.monitor.setBackgroundColor(colors.gray)
        else
            Menu.monitor.setBackgroundColor(colors.lightGray)
        end

        local buttonWidth = #Menu.pages[i].name + 2
        Menu.pages[i].xStart = x    
        Menu.pages[i].xEnd = x + buttonWidth - 1

        Menu.monitor.setCursorPos(x, y + 1)
        Menu.monitor.write(strings.ensure_width("", buttonWidth))
        Menu.monitor.setCursorPos(x, y - 1)
        Menu.monitor.write(strings.ensure_width("", buttonWidth))
        Menu.monitor.setCursorPos(x, y)
        
        Menu.monitor.write(" ")
        Menu.monitor.write(Menu.pages[i].name)
        Menu.monitor.write(" ")

        

        x = x + #Menu.pages[i].name + 5
    end

end

function Menu.run()
    Menu.print()

    while true do
        local event, side, x, y = os.pullEvent("monitor_touch")

        if y > Menu.buttonCoords[2] + 1 or y < Menu.buttonCoords[2] - 1 then
            goto continue
        end

        for clickedPage, page in pairs(Menu.pages) do
            if x >= page.xStart and x <= page.xEnd then
                if clickedPage ~= Menu.currentPage then
                    Menu.navigate(clickedPage)
                end
                break
            end
        end

        ::continue::
    end
end

function Menu.navigate(pageNum)
    Menu.currentPage = pageNum
    Menu.print()
end


return Menu