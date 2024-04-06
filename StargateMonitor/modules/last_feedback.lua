local universal_interface
local WIN = nil

local Module = {
    last_feedback = nil,
    configuration = {
        line_width = {type = "number", value = 0, description = "Width of the line, 0 for auto (full width)"},
        line_max_height = {type = "number", value = 3, description = "Max number of the lines, 2 should be enough, but you can limit it to 1 if you want"},
        align_center = {type = "boolean", value = true, description = "Align text to center"},

        normal_text_color = {type = "color", value = "white", description = "Text color for normal state"},
        normal_text_background = {type = "color", value = "black", description = "Background color for normal state"},
        error_text_color = {type = "color", value = "red", description = "Text color for error state"},
        error_text_background = {type = "color", value = "black", description = "Background color for error state"},
    }
}

-- module render should be repeatable callable
-- and should render the screen (used for previews)
function Module.init(modules, windows)
    universal_interface = modules["universal_interface"]

    for i, win in pairs(windows) do
        if win.module == "last_feedback" then
            WIN = win
            break
        end
    end

    if WIN == nil then
        printError("Failed to find window configuration for Last Feedback module!")
        recommendReinstall()
        return 1
    end

    -- now setup window size
    local x, y = WIN.getPosition()
    local width = Module.configuration.line_width.value
    if width < 1 then
        width, _ = WIN.monitor.getSize()
    end

    WIN.reposition(x, y, width, Module.configuration.line_max_height.value)

    Module.renderFeedback()
    return 0
end

function Module.run()
    while true do
        os.pullEvent()
        Module.renderFeedback()
    end
end

function Module.renderFeedback()
    local code, message = universal_interface.getRecentFeedback()

    if not code then
        universal_interface.checkInterfaceConnected()
        return
    end

    if code == Module.last_feedback then
        return
    end

    local color = Module.configuration.normal_text_color.value
    local background = Module.configuration.normal_text_background.value

    if code < 0 then
        color = Module.configuration.error_text_color.value
        background = Module.configuration.error_text_background.value
    end

    local x, y = 1, 1

    if Module.configuration.align_center.value then
        local w, _ = WIN.getSize()
        x = math.floor((w - string.len(message)) / 2)
        x = math.max(x + 1, 1)
    end

    Module.last_feedback = code
    WIN.setBackgroundColor(colors[background])
    WIN.clear()
    WIN.setCursorPos(x, y)
    WIN.setTextColor(colors[color])
    
    local terminal = term.current()
    term.redirect(WIN)
    write(message)
    term.redirect(terminal)
    WIN.monitor.update()
end

return {
    init = Module.init,
    run = Module.run,
    configuration = Module.configuration,
    name = "Last Feedback",
    description = "Shows last feedback from stargate as simple text message",
    textOnly = true
}