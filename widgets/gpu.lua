-- ====================================================
--  GPU Widget - by Dennis Hilk
-- ====================================================

local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")

local gpu_widget = wibox.widget {
    widget = wibox.widget.textbox,
    text = "GPU: ...",
}

gears.timer {
    timeout = 3,
    autostart = true,
    callback = function()
        awful.spawn.easy_async_with_shell("nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null", function(stdout)
            local usage = stdout:match("(%d+)")
            if usage then
                gpu_widget.text = string.format("GPU: %s%%  ", usage)
            else
                gpu_widget.text = "GPU: N/A  "
            end
        end)
    end
}

return gpu_widget

