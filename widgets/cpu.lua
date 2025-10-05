-- ====================================================
--  CPU Widget - by Dennis Hilk
-- ====================================================

local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")

local cpu_widget = wibox.widget {
    widget = wibox.widget.textbox,
    text = "CPU: ...",
}

local prev_total = 0
local prev_idle = 0

gears.timer {
    timeout = 2,
    autostart = true,
    callback = function()
        awful.spawn.easy_async_with_shell("grep 'cpu ' /proc/stat", function(stdout)
            local user, nice, system, idle, iowait, irq, softirq =
                stdout:match("cpu%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)")
            if user then
                local total = user + nice + system + idle + iowait + irq + softirq
                local diff_idle = idle - prev_idle
                local diff_total = total - prev_total
                local usage = (1 - diff_idle / diff_total) * 100
                prev_total = total
                prev_idle = idle
                cpu_widget.text = string.format("CPU: %.1f%%  ", usage)
            end
        end)
    end
}

return cpu_widget
