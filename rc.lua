-- ====================================================
--  AwesomeWM Config by Dennis Hilk
--  Minimal Nerd Edition
-- ====================================================

-- Standard library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")

-- Theme and widgets
local beautiful = require("beautiful")
local wibox = require("wibox")

-- Load theme
beautiful.init("~/.config/awesome/theme.lua")

-- Default terminal and editor
terminal = "alacritty"
editor = os.getenv("EDITOR") or "nano"

-- Default modkey (Super / Windows)
modkey = "Mod4"

-- Layouts
awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.floating,
    awful.layout.suit.max,
}

-- Wallpaper
if beautiful.wallpaper then
    gears.wallpaper.maximized(beautiful.wallpaper, nil, true)
end

-- Widgets

local cpu_widget = require("widgets.cpu")
local ram_widget = require("widgets.ram")
local gpu_widget = require("widgets.gpu")

awful.screen.connect_for_each_screen(function(s)
    set_wallpaper = function()
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
    set_wallpaper()

    local mytextclock = wibox.widget.textclock("%H:%M  ")

    s.mywibox = awful.wibar({ position = "top", screen = s })

    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- left
            layout = wibox.layout.fixed.horizontal,
            cpu_widget,
            ram_widget,
            gpu_widget,
        },
        mytextclock,
        { layout = wibox.layout.fixed.horizontal },
    }
end)

-- Wibar (top bar)
awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper = function()
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
    set_wallpaper()

    -- Create a textclock widget
    local mytextclock = wibox.widget.textclock("%H:%M  ")

    -- Create wibox
    s.mywibox = awful.wibar({ position = "top", screen = s })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { layout = wibox.layout.fixed.horizontal },
        mytextclock,
        { layout = wibox.layout.fixed.horizontal },
    }
end)

-- Keybindings
globalkeys = gears.table.join(
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "open terminal", group = "launcher"}),
    awful.key({ modkey, "Shift"   }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
              {description = "quit awesome", group = "awesome"})
)

root.keys(globalkeys)

