local Pager = {}

function Pager:new(window, addressTable, configuration)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.window = window
    o.configuration = configuration
    return o
end



return Pager