-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

config.enable_tab_bar = false
config.color_scheme = "Tokyo Night"
-- config.color_scheme = 'OneDark (base16)'

config.window_padding = {
	left = 5,
	right = 5,
	top = 5,
	bottom = 5,
}
config.initial_rows = 48
config.initial_cols = 180
config.font_size = 13

config.keys = {
	{
		key = "F11",
		action = wezterm.action.ToggleFullScreen,
	},
}

return config
