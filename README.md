# lualine-lsp-progress
Information provided by active lsp clients from the `$/progress` endpoint as a statusline component for [lualine.nvim](https://raw.githubusercontent.com/hoob3rt/lualine.nvim).

## Why?
Some LSP servers take a while to initalize. This provides a nice visual indicator to show which clients are ready to use.

## Screenshot
![example](https://user-images.githubusercontent.com/56053130/115862312-b4b12c80-a3cf-11eb-9a0f-3cd67160d732.PNG)

## Use
Add the component `lsp_progress` to one of your lualine sections.
```lua
require'lualine'.setup{
	...
	sections = {
		lualine_c = {
			...,
			'lsp_progress'
		}
	}
}
```

## Installation
### [vim-plug](https://github.com/junegunn/vim-plug)
```vim
Plug 'arkav/lualine-lsp-progress'
```
### [packer.nvim](https://github.com/wbthomason/packer.nvim)
```lua
use 'arkav/lualine-lsp-progress'
```

## Configuration

### Configurable items
* Items to display and order
	* Lsp client name e.g. Rust
	* Spinner
	* Progress (individual actions undertaken by the LSP)
		* Title of action undertaken by LSP e.g. Indexing
		* Message from Lsp
		* Percentage compplete
* pre and post items - before each specific lsp item display text
* Spinner
	* Symbols
	* Time between symbol update
* Color of items
* Last Message delay
	* After we receive a progress message saying an action is complete __delay__ removing it from lualine so we can read that it's finished.
	* After the final progress message is displayed __delay__ before no longer showing the lsp client name.

### Decked out configuration
```lua

-- Color for highlights
local colors = {
  yellow = '#ECBE7B',
  cyan = '#008080',
  darkblue = '#081633',
  green = '#98be65',
  orange = '#FF8800',
  violet = '#a9a1e1',
  magenta = '#c678dd',
  blue = '#51afef',
  red = '#ec5f67'
}

local config = {
  options = {
    icons_enabled = true,
    theme = 'gruvbox',
    component_separators = {'', ''},
    section_separators = {'', ''},
    disabled_filetypes = {}
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'filename'},
    lualine_c = {},
    lualine_x = {},
    lualine_y = {'encoding', 'fileformat', 'filetype'},
    lualine_z = {'branch'},
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {'filename'},
    lualine_x = {'location'},
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  extensions = {}
}


-- Inserts a component in lualine_c at left section
local function ins_left(component)
  table.insert(config.sections.lualine_c, component)
end

-- Inserts a component in lualine_x ot right section
local function ins_right(component)
  table.insert(config.sections.lualine_x, component)
end

ins_left {
	'lsp_progress',
	display_components = { 'lsp_client_name', { 'title', 'percentage', 'message' }},
	-- With spinner
	-- display_components = { 'lsp_client_name', 'spinner', { 'title', 'percentage', 'message' }},
	colors = {
	  percentage  = colors.cyan,
	  title  = colors.cyan,
	  message  = colors.cyan,
	  spinner = colors.cyan,
	  lsp_client_name = colors.magenta,
	  use = true,
	},
	separators = {
		component = ' ',
		progress = ' | ',
		message = { pre = '(', post = ')'},
		percentage = { pre = '', post = '%% ' },
		title = { pre = '', post = ': ' },
		lsp_client_name = { pre = '[', post = ']' },
		spinner = { pre = '', post = '' },
		message = { commenced = 'In Progress', completed = 'Completed' },
	},
	display_components = { 'lsp_client_name', 'spinner', { 'title', 'percentage', 'message' } },
	timer = { progress_enddelay = 500, spinner = 1000, lsp_client_name_enddelay = 1000 },
	spinner_symbols = { '🌑 ', '🌒 ', '🌓 ', '🌔 ', '🌕 ', '🌖 ', '🌗 ', '🌘 ' },
}

```
