local universal_interface
local WIN = nil

local STATUS = {
    IDLE = "idle",
    OUTGOING_DIALING = "outgoing_dialing",
    INCOMING_DIALING = "incoming_dialing",
    OUTGOING_ACTIVE = "outgoing_active",
    INCOMING_ACTIVE = "incoming_active"
}

local Module = {
    blinking = false,
    status = STATUS.IDLE,
    configuration = {
        button_width = {type = "number", value = 10, description = "Width of the button"},
        button_height = {type = "number", value = 3, description = "Height of the button"},
        idle_text = {type = "string", value = "IDLE", description = "Text to display when gate is idle"},
        idle_text_color = {type = "color", value = "white", description = "Text color for idle state"},
        outgoing_dialing_text = {type = "string", value = "DIALING", description = "Text to display when gate is dialing out"},
        outgoing_dialing_text_color = {type = "color", value = "black", description = "Text color for dialing out state"},
        incoming_dialing_text = {type = "string", value = "INCOMING", description = "Text to display when gate is locking for incomming connection"},
        incoming_dialing_text_color = {type = "color", value = "red", description = "Text color for locking of incomming connection state"},
        outgoing_active_text = {type = "string", value = "OPEN", description = "Text to display when gate is open for outgoing connection"},
        outgoing_active_text_color = {type = "color", value = "white", description = "Text color for open outgoing connection state"},
        incoming_active_text = {type = "string", value = "INCOMING", description = "Text to display when gate is open for incomming connection"},
        incoming_active_text_color = {type = "color", value = "red", description = "Text color for open incomming connection state"},
        idle_color = {type = "color", value = "cyan", description = "Color of the button when gate is idle"},
        outgoing_dialing_color = {type = "color", value = "yellow", description = "Color of the button when gate is dialing out"},
        incoming_dialing_color = {type = "color", value = "orange", description = "Color of the button when gate is locking for incomming connection"},
        outgoing_active_color = {type = "color", value = "green", description = "Color of the button when gate is open for outgoing connection"},
        incoming_active_color = {type = "color", value = "orange", description = "Color of the button when gate is open for incomming connection"},
        blink_interval = {type = "number", value = 0.5, description = "Blinking interval, 0 for disable"},
        enable_touch_reset = {type = "boolean", value = true, description = "Enable button touch to reset the gate"}
    }
}

-- module render should be repeatable callable
-- and should render the screen (used for previews)
function Module.init(modules, windows)
    universal_interface = modules["universal_interface"]

    for i, win in pairs(windows) do
        if win.module == "status_button" then
            WIN = win
            break
        end
    end

    if WIN == nil then
        printError("Failed to find window configuration for Status Button module!")
        recommendReinstall()
        return 1
    end

    -- now setup window size
    local x, y = WIN.getPosition()
    WIN.reposition(x, y, Module.configuration.button_width.value, Module.configuration.button_height.value)

    Module.updateState()
    Module.renderButton()
    return 0
end

function Module.run()
    while true do
        local ev = {os.pullEvent()}
        local oldStatus = Module.status
        if ev[1] == "stargate_chevron_engaged" then
            local incoming = true
            if #ev > 3 then
                incoming = ev[4]
            end
            if incoming == true then
                Module.status = STATUS.INCOMING_DIALING
            else
                Module.status = STATUS.OUTGOING_DIALING
            end
        elseif ev[1] == "stargate_reset" or ev[1] == "stargate_disconnected" then
            Module.blinking = false
            Module.status = STATUS.IDLE
        elseif ev[1] == "stargate_incoming_wormhole" then
            Module.status = STATUS.INCOMING_ACTIVE
        elseif ev[1] == "stargate_outgoing_wormhole" then
            Module.status = STATUS.OUTGOING_ACTIVE
        elseif ev[1] == "monitor_touch" then
            Module.monitor_touch(table.unpack(ev, 2))
        end

        if oldStatus ~= Module.status then
            Module.renderButton()
        end

        if not Module.blinking and (Module.status == STATUS.INCOMING_ACTIVE or Module.status == STATUS.INCOMING_DIALING) and Module.configuration.blink_interval.value > 0 then
            run_later(Module.configuration.blink_interval.value, Module.blink)
        end
    end
end

function Module.monitor_touch(id, x, y)
    if not Module.configuration.enable_touch_reset.value or not WIN.monitor or not WIN.isVisible() then
        return
    end

    if id ~= peripheral.getName(WIN.monitor) then
        return
    end

    local wx, wy = WIN.getPosition()
    local width = Module.configuration.button_width.value - 1
    local height = Module.configuration.button_height.value - 1

    if x >= wx and x <= wx + width and y >= wy and y <= wy + height then
        universal_interface.reset()
        Module.updateState()
        Module.renderButton()
    end
end

function Module.blink(invert)
    Module.blinking = true
    if Module.status == STATUS.INCOMING_ACTIVE or Module.status == STATUS.INCOMING_DIALING then
        Module.renderButton(not invert)
        run_later(Module.configuration.blink_interval.value, function() Module.blink(not invert) end)
    else
        Module.blinking = false
    end
end

function Module.updateState()
    if universal_interface.isStargateConnected() then
        if universal_interface.isStargateDialingOut() then
            Module.status = STATUS.OUTGOING_ACTIVE
        else
            Module.status = STATUS.INCOMING_ACTIVE
        end
    elseif universal_interface.getChevronsEngaged() > 0 then
        Module.status = STATUS.OUTGOING_DIALING
    else
        Module.status = STATUS.IDLE
    end

end

function Module.renderButton(invert_colors)
    local color = Module.configuration[Module.status .. "_color"].value
    local text = Module.configuration[Module.status .. "_text"].value
    local textColor = Module.configuration[Module.status .. "_text_color"].value
    local width = Module.configuration.button_width.value
    local height = Module.configuration.button_height.value

    if invert_colors then
        color, textColor = textColor, color
    end
    
    local terminal = term.current()
    term.redirect(WIN)
    paintutils.drawFilledBox(1, 1, width, height, colors[color])
    term.redirect(terminal)

    local y = math.ceil(height / 2)
    local x = math.floor((width - string.len(text)) / 2) + 1
    
    WIN.setBackgroundColor(colors[color])
    WIN.setTextColor(colors[textColor])
    WIN.setCursorPos(x, y)
    WIN.write(text)
end

return {
    init = Module.init,
    run = Module.run,
    configuration = Module.configuration,
    name = "Status button",
    description = "Button that displays the status of the Stargate and allows to reset it"
}