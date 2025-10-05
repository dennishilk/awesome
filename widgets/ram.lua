-- ====================================================
--  RAM Widget - by Dennis Hilk
-- ====================================================

local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")

local ram_widget = wibox.widget {
    widget = wibox.widget.textbox,
    text = "RAM: ...",
}

gears.timer {
    timeout = 2,
    autostart = true,
    callback = function()
        awful.spawn.easy_async_with_shell("free -m | awk '/Mem:/ {print $3,$2}'", function(stdout)
            local used, total = stdout:match("(%d+)%s+(%d+)")
            if used and total then
                local percent = math.floor((used / total) * 100)
                ram_widget.text = string.format("RAM: %d%% (%dMB/%dMB)  ", percent, used, total)
            end
        end)
    end
}

return ram_widget

