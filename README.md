# lualine-lsp-progress
Information provided by active lsp clients from the `$/progress` endpoint as a statusline componenet for [lualine.nvim](https://raw.githubusercontent.com/hoob3rt/lualine.nvim).

## Why?
Some LSP servers take a while to initalize. This provides a nice visual indicator to show which clients are ready to use.

## Screenshot
![example](https://user-images.githubusercontent.com/56053130/115862312-b4b12c80-a3cf-11eb-9a0f-3cd67160d732.PNG)

## Use
Add the componenet `lsp_progress` to one of your lualine sections.
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
