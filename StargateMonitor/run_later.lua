DELAYED = {}
-- queues task for execution
local function run_later( delay, func )
    local targetTime = os.epoch() + (delay * 10000)
    table.insert(DELAYED, { targetTime = targetTime, func = func, timer = os.startTimer(delay)})
end

-- this should run in parallel 
-- takes tasks from delayed and executes them if time exceeded
local function later_exec()
    while true do (function()
        os.pullEvent("timer")
        if #DELAYED == 0 then
            return -- continue
        end
        local copy = DELAYED
        DELAYED = {}

        for _, v in pairs(copy) do
            if v.targetTime <= os.epoch() then
                os.cancelTimer(v.timer)
                v.func()
            else
                table.insert(DELAYED, v)
            end
        end
        
    end)() end
end

return {
    run_later = run_later,
    later_exec = later_exec
}