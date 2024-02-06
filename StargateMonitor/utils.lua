-- ====================
--        UTILS
-- ====================

-- this is probably unsused :D
local function wait ( time )
    local targetTime = os.epoch() + (time * 10000)
    local timer = os.startTimer(time)

    while true do
        os.pullEvent("timer")
        
        if targetTime <= os.epoch() then
            os.cancelTimer(timer)
            break
        end
    end
end

-- checks whether table contains the value
local function table_contains(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end

    return false
end

local delayed = {}

-- queues task for execution
local function run_later( delay, func )
    local targetTime = os.epoch() + (delay * 10000)
    table.insert(delayed, { targetTime = targetTime, func = func, timer = os.startTimer(delay)})
end

-- this should run in parallel 
-- takes tasks from delayed and executes them if time exceeded
local function later_exec()
    while true do
        os.pullEvent("timer")
        if #delayed == 0 then
            goto continue
        end
        local copy = delayed
        delayed = {}

        for _, v in pairs(copy) do
            if v.targetTime <= os.epoch() then
                os.cancelTimer(v.timer)
                v.func()
            else
                table.insert(delayed, v)
            end
        end
        ::continue::
    end
end

return {wait, table_contains, run_later, later_exec}
