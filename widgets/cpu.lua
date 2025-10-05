local awful = require("awful")
local wibox = require("wibox")

local cpu_widget = wibox.widget {
    widget = wibox.widget.textbox,
    text = "CPU: ...",
}

gears.timer {
    timeout = 2,
    autostart = true,
    callback = function()
        awful.spawn.easy_async_with_shell("grep 'cpu ' /proc/stat", function(stdout)
            local user, nice, system, idle = stdout:match("cpu%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)")
            local total = user + nice + system + idle
            local busy = user + nice + system
            cpu_widget.text = string.format("CPU: %d%% ", (busy * 100 / total))
        end)
    end
}

return cpu_widget

