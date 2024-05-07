-- Here's a good reference config
-- https://github.com/theopn/dotfiles/blob/25b85936ef3e7195a0f029525f854fdb915b9f90/wezterm/wezterm.lua

-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- shortcut variable to action
local act = wezterm.action

-- This table will hold the configuration.
local config = {}

-- use the config_builder which will help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- BEGIN CONFIGURATION

-- Get the desired color scheme and make the necessary overrides.

local OneDark = wezterm.color.get_builtin_schemes()['OneDark (Gogh)']

-- Overrides here
-- Original foreground from OneDark
-- OneDark.foreground = '#5c6370'
-- plus 1
-- OneDark.foreground = '#6D7481'
-- plus 2
OneDark.foreground = '#8F96A3'

-- Add back as a color scheme of our choosing
config.color_schemes = {
  ['OneDark'] = OneDark,
}

-- Select the color_scheme
config.color_scheme = 'OneDark'

-- config.color_scheme = 'One Dark (Gogh)'
-- This one is blacker in the background but drops the grey text
-- config.color_scheme = 'One Half Black (Gogh)'

-- Window config stuff
config.window_background_opacity = 0.98
config.window_close_confirmation = 'AlwaysPrompt'

-- sets font, etc for the main window, tabs, border
config.window_frame = {
  font = wezterm.font_with_fallback({
      -- { family = "Mononoki Nerd Font", scale=1.5 },
      -- { family = "Monofur Nerd Font", scale=1.8 },
      { family = "FantasqueSansM Nerd Font", scale=1.5 },
      { family = "CaskaydiaCove Nerd Font", scale=1.5 },
    }),
  }

config.scrollback_lines = 10000
config.default_workspace = 'Main' -- what does this do exactly?
config.initial_cols = 168
config.initial_rows = 32

config.use_fancy_tab_bar = true
config.status_update_interval = 1000

-- right window status bar
wezterm.on("update-right-status", function(window, pane)
  -- Workspace name
  local stat = window:active_workspace()
  -- It's a little silly to have workspace name all the time
  -- Utilize this to display LDR or current key table name
  if window:active_key_table() then stat = window:active_key_table() end
  if window:leader_is_active() then stat = "LDR" end

  -- Current working directory
  local basename = function(s)
    -- Nothign a little regex can't fix
    print(s)
    return string.gsub(s, "(.*[/\\])(.*)", "%2")
  end

  local cwd = basename(pane:get_current_working_dir())
  -- Current command
  local cmd = basename(pane:get_foreground_process_name())

  -- Time
  local time = wezterm.strftime("%H:%M")

  -- Let's add color to one of the components
  window:set_right_status(wezterm.format({
    -- Wezterm has a built-in nerd fonts
    { Text = " -->  " },
    { Text = wezterm.nerdfonts.oct_table .. " TODO -->   " .. stat },
    { Text = "  |  " },
    { Text = wezterm.nerdfonts.md_folder .. "  " .. cwd },
    { Text = "  |  " },
    { Foreground = { Color = "FFB86C" } },
    { Text = wezterm.nerdfonts.fa_code .. "   " .. cmd },
    "ResetAttributes",
    { Text = "  |  " },
    { Text = wezterm.nerdfonts.md_clock .. "  " .. time },
    { Text = "  |  " },
  }))
end)


-- This function returns the suggested title for a tab.
-- It prefers the title that was set via `tab:set_title()`
-- or `wezterm cli set-tab-title`, but falls back to the
-- title of the active pane in that tab.
function tab_title(tab_info)
  local title = tab_info.tab_title
  -- if the tab title is explicitly set, take that
  if title and #title > 0 then
    return title
  end
  -- Otherwise, use the title from the active pane
  -- in that tab
  return tab_info.active_pane.title
end

wezterm.on(
  'format-tab-title',
  function(tab, tabs, panes, cfg, hover, max_width)
    local title = tab_title(tab)
    if tab.is_active then
      return {
        { Foreground = { Color = 'grey' } },
        { Background = { Color = 'black' } },
        { Text =  '--> ' .. title .. ' <--' },
      }
    end
    return title
  end
)


-- terminal window stuff
config.font = wezterm.font_with_fallback({
  -- { family = "Mononoki Nerd Font", scale=1.5 },
  { family = "Monofur Nerd Font", scale=1.8 },
  { family = "FantasqueSansM Nerd Font", scale=1.7 },
  { family = "CaskaydiaCove Nerd Font", scale=1.5 },
})



config.keys = {

  -- OSX cmd+(arrow) to switch between adjacent tabs, similar to iTerm2
  { key = 'LeftArrow', mods = 'CMD', action = act.ActivateTabRelative(-1) },
  { key = 'RightArrow', mods = 'CMD', action = act.ActivateTabRelative(1) },

}



-- and finally, return the configuration to wezterm
return config
