local term_list_selector = require("term_list_selector")
local module = {lines = {}}
WIN = nil

function module.init(modules, windows)
    WIN = window.create(COMPUTER_WINDOW, 1, 1, TERM_WIDTH, TERM_HEIGHT, false)
    module.selector = term_list_selector:new(WIN, module.lines, function() end, module.edit_address)
end

function module.edit_address(id)
    
end

function module.execute()
    
end

return module