# terminal.nvim

A basic terminal buffer manager for Neovim.

## Features

Lets you create and easily switch between terminal buffers.

## Installation

Should work with most plugin managers.

By default has no configuration.
You can set up the default keybindings by calling `setup_default` in your config.
```lua
require('terminal').setup_default()
```
Which will set up the following keybindings:
- `<leader>tp` Switch to terminal - will prompt you to select a terminal if there are multiple
- `<leader>tn` Create new terminal
- `<leader>t1..9` Goto terminal 1..9
- `<leader>tc` Close terminal

## Requirements

- Neovim 0.11+ (May work with older versions but not tested)
