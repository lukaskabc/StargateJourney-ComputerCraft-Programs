local Pager = {}

function Pager:new(monitor, addressTable)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.monitor = monitor
    return o
end

return Pager