-- try catch statement
-- does not support coroutine yield !
return function (f, catch, finally)
    -- Hey Lua, this is so stupid
    local status, exception = pcall(f)
    if not status and catch then
        catch(exception)
    end
    if finally then
        finally()
    end
end