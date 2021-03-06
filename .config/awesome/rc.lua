-- vim: ft=lua fdm=marker

-- {{{ Standard awesome library
local gears = require("gears")
awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
-- }}}

-- {{{ require library
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
-- bashets library
local bashets = require("bashets")
-- Private library
local vicious = require("vicious")
local menu = require("menu")
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init(awful.util.getdir("config") .. "/theme.lua")

-- Private naughty config
naughty.config.defaults.timeout         = 3
naughty.config.defaults.font            = "sans 14"
naughty.config.defaults.position        = "bottom_right"
naughty.config.defaults.fg              = beautiful.fg_focus
naughty.config.defaults.bg              = beautiful.bg_focus
naughty.config.defaults.border_color    = beautiful.border_focus

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- This is used later as the default terminal and editor to run.
terminal = "xterm"
editor = "vim"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier,
    awful.layout.suit.floating
}
-- }}}

-- {{{ Wallpaper
if beautiful.wallpaper then
    for s = 1, screen.count() do
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, s, layouts[1])
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
local myawesomemenu = {
   { "编辑配置 (&E)", editor_cmd .. " " .. awesome.conffile },
   { "重新加载 (&R)", awesome.restart, '/usr/share/icons/gnome/16x16/actions/stock_refresh.png' },
   { "注销 (&L)", awesome.quit },
}

local mymenu = {
   { "&Nautilus", "nautilus --no-desktop /home/imtxc", '/usr/share/icons/gnome/32x32/apps/system-file-manager.png' },
   { "&Wireshark", "wireshark", '/usr/share/icons/hicolor/32x32/apps/webqq.png'},
   { "&VirtualBox", "VirtualBox", '/usr/share/icons/hicolor/32x32/mimetypes/virtualbox.png' },
   { "文档查看器 (&E)", "evince", '/usr/share/icons/hicolor/16x16/apps/evince.png' },
   { "屏幕键盘", "matchbox-keyboard", '/usr/share/pixmaps/matchbox-keyboard.png' },
}

mymainmenu = awful.menu({ items = { 
    { "Awesome", myawesomemenu, beautiful.awesome_icon },
    { "终端 (&T)", terminal, '/usr/share/icons/gnome/32x32/apps/utilities-terminal.png' },
    { "&Chrome", "google-chrome" },
    { "常用 (&U)", mymenu },
    { "应用程序 (&A)", xdgmenu },
    { "挂起 (&S)", "mysuspend" },
    { "关机 (&H)", "systemctl poweroff", '/usr/share/icons/gnome/16x16/actions/gtk-quit.png' },
}
})

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Vicious(Private)

-- {{{ Net
mynetwidget = wibox.widget.textbox()
function get_netspeed()
    local netspeed = {}
    local deviceinfo = vicious.widgets.net()
    netspeed['{down_kb}'] = deviceinfo['{eth0 down_kb}']
    netspeed['{up_kb}'] = deviceinfo['{eth0 up_kb}'] 
    return netspeed
end
vicious.register(mynetwidget, get_netspeed, "${down_kb}↓ ${up_kb}↑", 2)
-- }}}

-- {{{ CPU
mycpuwidget = wibox.widget.textbox()
vicious.register(mycpuwidget, vicious.widgets.cpu, "$1%")
-- }}}

-- {{{ MEM
mymemwidget = awful.widget.progressbar()
mymemwidget:set_width(8)
mymemwidget:set_height(15)
mymemwidget:set_vertical(true)
mymemwidget:set_background_color("#494B4F")
mymemwidget:set_border_color(nil)
mymemwidget:set_color({ type = "linear", from = { 0, 0 }, to = { 10,0 }, stops = { {0, "#AECF96"}, {0.5, "#88A175"}, 
                    {1, "#FF5656"}}})
vicious.register(mymemwidget, vicious.widgets.mem, "$1", 13)

-- {{{ Volume
myvolwidget = wibox.widget.textbox()
vicious.register(myvolwidget, vicious.widgets.volume, "$2 $1", 2, "Master")
-- }}}

-- {{{ Mails
mailicon = wibox.widget.imagebox()
mailfolders = { '/home/imtxc/Documents/Mails/Gmail/INBOX',}
vicious.register(mailicon, vicious.widgets.mdir, function (widget, args)
        if args[1] > 0 then
            mailicon:set_image(beautiful.wiget_mail)
        else
            mailicon:set_image(beautiful.wiget_nomail)
            --mailicon:set_image(beautiful.wiget_null)
        end
        return nil
end, 10, mailfolders)
-- }}}
-- }}}

-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock(" %a %b %d, %H:%M ", 1)

-- Private decoration
myicon = wibox.widget.imagebox()
myicon:set_image(beautiful.awesome_icon)

myspace = wibox.widget.textbox()
myspace:set_text(" ")


-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "bottom", screen = s })

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(myspace)
    left_layout:add(mylayoutbox[s])
    left_layout:add(mytaglist[s])
    left_layout:add(mypromptbox[s])

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    right_layout:add(myspace)
    right_layout:add(mynetwidget)
    right_layout:add(myspace)
    right_layout:add(mycpuwidget)
    right_layout:add(myspace)
    right_layout:add(mymemwidget)
    right_layout:add(myspace)
    right_layout:add(myvolwidget)
    right_layout:add(myspace)
    right_layout:add(mailicon)
    right_layout:add(myspace)
    if s == 1 then right_layout:add(wibox.widget.systray()) end
    right_layout:add(mytextclock)

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    -- Private global key bindings
    awful.key({ modkey }, "a", function () awful.util.spawn("xterm -e alsamixer") end),
    awful.key({ modkey }, "b", function () awful.util.spawn("google-chrome") end),
    --awful.key({ modkey }, "g", function () awful.util.spawn("goldendict") end),
    awful.key({ modkey }, "g", function () awful.util.spawn("nautilus --no-desktop /home/imtxc/") end),
    awful.key({ modkey }, "i", function () mywibox[mouse.screen].visible = not mywibox[mouse.screen].visible end),
    awful.key({ modkey }, "m", function () awful.util.spawn("amixer -q sset Master toggle") end),
    awful.key({ modkey }, "p", function () awful.util.spawn("pidgin") end),
    awful.key({ modkey }, "s", function () awful.util.spawn_with_shell("xset dpms 0 0 5 ; slock ; xset dpms 0 0 0") end),
    awful.key({ modkey }, "t", function () awful.util.spawn("mpc toggle") end),
    --awful.key({ modkey }, "v", function () awful.util.spawn("virtualbox") end),
    --awful.key({ modkey }, "v", function () awful.util.spawn("urxvt") end),
    awful.key({ modkey }, "x", function () awful.util.spawn("urxvt") end),
    awful.key({ modkey }, "Up", function () awful.util.spawn("amixer -q sset Master 10%+ unmute") end),
    awful.key({ modkey }, "Down", function () awful.util.spawn("amixer -q sset Master 10%- unmute") end),
    awful.key({ "Mod1" }, "F2", function () awful.util.spawn("gmrun") end),
    --awful.key({ modkey, "Control" }, "Print", function () awful.util.spawn("/home/imtxc/pi") end),
    awful.key({ modkey, "Control" }, "Print", function () awful.util.spawn("/usr/bin/import -frame /home/imtxc/scrot.png") end),
    awful.key({ modkey }, "Print",
        function ()
            awful.util.spawn("scrot -e 'mv $f ~/'")
            os.execute("sleep 0.5")
            naughty.notify({ title="Screenshot", text="The full screen captured" })
        end),

    awful.key({ "Mod1" }, "n", naughty.toggle),
    awful.key({ "Mod1" }, "Left", function () awful.util.spawn("mpc prev") end),
    awful.key({ "Mod1" }, "Right", function () awful.util.spawn("mpc next") end),
    awful.key({ "Mod1" }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),
    awful.key({ "Mod1" }, "Print",
        function ()
            awful.util.spawn("scrot -u -e 'mv $f ~/'")
            os.execute("sleep 0.5")
            naughty.notify({ title="Screenshot", text="The focused window captured" })
        end),

    awful.key({ modkey, "Control" }, "m", function () awful.util.spawn("monitor-toggle") end),

    awful.key({}, "XF86AudioPlay", function () awful.util.spawn("mpc toggle") end),
    awful.key({}, "XF86AudioStop", function () awful.util.spawn("mpc stop") end),
    awful.key({}, "XF86AudioPrev", function () awful.util.spawn("mpc prev") end),
    awful.key({}, "XF86AudioNext", function () awful.util.spawn("mpc next") end),
    awful.key({}, "XF86AudioMute", function () awful.util.spawn("amixer -q sset Master toggle") end),
    awful.key({}, "XF86AudioLowerVolume", function () awful.util.spawn("amixer -q sset Master 10%- unmute") end),
    awful.key({}, "XF86AudioRaiseVolume", function () awful.util.spawn("amixer -q sset Master 10%+ unmute") end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),

    -- Private client key bindings
    awful.key({ "Mod1" }, "F3",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end),
    awful.key({ "Mod1" }, "F4", function (c) c:kill() end),
    awful.key({ modkey, "Control" }, "Up",    function () awful.client.moveresize(  0, -20,   0,   0) end),
    awful.key({ modkey, "Control" }, "Down",  function () awful.client.moveresize(  0,  20,   0,   0) end),
    awful.key({ modkey, "Control" }, "Left",  function () awful.client.moveresize(-20,   0,   0,   0) end),
    awful.key({ modkey, "Control" }, "Right", function () awful.client.moveresize( 20,   0,   0,   0) end),
    awful.key({ modkey, "Control" }, "Prior", function () awful.client.moveresize(-20, -20,  40,  40) end),
    awful.key({ modkey, "Control" }, "Next",  function () awful.client.moveresize( 20,  20, -40, -40) end)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      local tag = awful.tag.gettags(client.focus.screen)[i]
                      if client.focus and tag then
                          awful.client.movetotag(tag)
                     end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      local tag = awful.tag.gettags(client.focus.screen)[i]
                      if client.focus and tag then
                          awful.client.toggletag(tag)
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     keys = clientkeys,
                     buttons = clientbuttons } },

    -- Private rules
    { rule = { },
      properties = { size_hints_honor = false } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "Plugin-container"},
      properties = { floating = true } },
    { rule = { instance = "Navigator" },
      properties = { tag = tags[1][2] } },
    { rule = { class = "Gimp" },
      properties = { tag = tags[1][7] } },
    { rule = { class = "Pidgin" },
      properties = { floating = true, tag = tags[1][8] } },
    { rule = { class = "Skype" },
      properties = { floating = true, tag = tags[1][8] } },
    { rule = { class = "VMplayer" },
      properties = { tag = tags[1][9] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- buttons for the titlebar
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                )

        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))
        left_layout:buttons(buttons)

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c):set_widget(layout)
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- {{{ Auto Starts
function run_once(cmd)
    findme = cmd
    firstspace = cmd:find(" ")
    if firstspace then
        findme = cmd:sub(0, firstspace-1)
    end
    awful.util.spawn_with_shell("pgrep -u $USER -x " .. findme .. " > /dev/null || (" .. cmd .. ")")
end

run_once("xmodmap " .. os.getenv("HOME") .. "/.Xmodmap")
run_once("~/bin/ng_background 5 &")
-- }}}
