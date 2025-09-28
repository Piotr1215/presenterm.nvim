# presenterm.nvim

A Neovim plugin for creating and managing [presenterm](https://github.com/mfontanini/presenterm) presentations with enhanced support for slide navigation, partials management, and live preview.

<div align="center">

[![Neovim](https://img.shields.io/badge/Neovim-0.9+-green.svg?style=flat-square&logo=neovim)](https://neovim.io)
[![Lua](https://img.shields.io/badge/Lua-5.1+-blue.svg?style=flat-square&logo=lua)](https://www.lua.org)
[![CI](https://github.com/Piotr1215/presenterm.nvim/actions/workflows/test.yml/badge.svg)](https://github.com/Piotr1215/presenterm.nvim/actions/workflows/test.yml)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)
[![LuaRocks](https://img.shields.io/luarocks/v/Piotr1215/presenterm.nvim?logo=lua&color=purple&style=flat-square)](https://luarocks.org/modules/Piotr1215/presenterm.nvim)

</div>

## Features

- **Slide Management**: Navigate, create, delete, reorder slides with ease
- **Partial Support**: Include reusable content from partial files with smart title detection
- **Telescope Integration**: Browse slides and partials with preview, slides with partials marked with [P]
- **Interactive Reordering**: Reorder slides with dd/p vim motions, shows proper titles from partials
- **Code Execution**: Toggle and run executable code blocks
- **Live Preview**: Launch presenterm preview in terminal
- **Statistics**: View presentation stats and time estimates

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "Piotr1215/presenterm.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim", -- Optional, for telescope integration
  },
  config = function()
    -- Optional: override default configuration
    require("presenterm").setup({
      slide_marker = "<!-- end_slide -->",
      partials = {
        directory = "_partials",
        resolve_relative = true,
      },
      preview = {
        command = "presenterm",
      },
    })
  end,
}
```

## Usage

The plugin provides user commands instead of default keymappings, following Neovim best practices. You can map these commands to your preferred keys.

### Commands

#### Navigation
- `:PresenterNext` - Go to next slide
- `:PresenterPrev` - Go to previous slide
- `:PresenterGoto N` - Go to slide N
- `:PresenterList` - List all slides with telescope

#### Slide Management
- `:PresenterNew` - Create new slide after current
- `:PresenterSplit` - Split slide at cursor position
- `:PresenterDelete` - Delete current slide
- `:PresenterYank` - Yank current slide
- `:PresenterSelect` - Visually select current slide
- `:PresenterMoveUp` - Move slide up
- `:PresenterMoveDown` - Move slide down
- `:PresenterReorder` - Interactive slide reordering

#### Partials
- `:PresenterPartial include` - Include partial file
- `:PresenterPartial edit` - Edit partial file
- `:PresenterPartial list` - List all partials

#### Code Blocks
- `:PresenterExec toggle` - Toggle +exec flag on code block
- `:PresenterExec run` - Run current code block

#### Preview
- `:PresenterPreview` - Preview presentation
- `:PresenterStats` - Show presentation statistics

#### Other
- `:PresenterActivate` - Manually activate presenterm mode
- `:PresenterHelp` - Show help

### Example Keybindings

```lua
-- Navigation
vim.keymap.set("n", "]s", ":PresenterNext<cr>", { desc = "Next slide" })
vim.keymap.set("n", "[s", ":PresenterPrev<cr>", { desc = "Previous slide" })
vim.keymap.set("n", "<leader>sl", ":PresenterList<cr>", { desc = "List slides" })

-- Slide management
vim.keymap.set("n", "<leader>sn", ":PresenterNew<cr>", { desc = "New slide" })
vim.keymap.set("n", "<leader>sd", ":PresenterDelete<cr>", { desc = "Delete slide" })
vim.keymap.set("n", "<leader>sy", ":PresenterYank<cr>", { desc = "Yank slide" })

-- Partials
vim.keymap.set("n", "<leader>sp", ":PresenterPartial include<cr>", { desc = "Include partial" })
vim.keymap.set("n", "<leader>spe", ":PresenterPartial edit<cr>", { desc = "Edit partial" })

-- Preview
vim.keymap.set("n", "<leader>sP", ":PresenterPreview<cr>", { desc = "Preview presentation" })
vim.keymap.set("n", "<leader>sc", ":PresenterStats<cr>", { desc = "Show stats" })
```

## Telescope Integration

### Slide Picker

The slide picker shows all slides with titles extracted from the content, including from partial files. Slides containing partials are marked with `[P]` indicator.

- `<CR>` - Jump to selected slide
- `<C-e>` - Edit the first partial in the selected slide (if it contains any)

### Partial Picker

The partial picker has two modes:

- **Include mode** (`:PresenterPartial include`):
  - `<CR>` - Insert include directive
  - `<C-e>` - Edit the partial file

- **Edit mode** (`:PresenterPartial edit`):
  - `<CR>` - Edit the partial file
  - `<C-i>` - Insert include directive

## Statusline Integration

You can add slide information to your statusline:

```lua
-- For lualine
sections = {
  lualine_x = {
    function()
      return require("presenterm").slide_status()
    end,
  },
}
```

## Configuration

Default configuration:

```lua
{
  slide_marker = "<!-- end_slide -->",
  partials = {
    directory = "_partials",     -- Directory name for partials
    resolve_relative = true,     -- Resolve paths relative to current file
  },
  preview = {
    command = "presenterm",      -- Preview command
    use_tmux = true,            -- Use tmux if available
    tmux_direction = "h",       -- Tmux split direction (h/v)
  },
  telescope = {
    theme = "dropdown",
    layout_config = {
      width = 0.8,
      height = 0.6,
    },
    enable_preview = true,
  },
}
```

## Presentation Structure

A typical presenterm presentation structure:

```
project/
├── presentation.md       # Main presentation file
└── _partials/           # Reusable content
    ├── intro.md
    ├── demo.md
    └── conclusion.md
```

Example presentation.md:

```markdown
---
title: My Presentation
author: Your Name
---

# Welcome

First slide content

<!-- end_slide -->

<!-- include: ../_partials/intro.md -->

<!-- end_slide -->

## Demo

```bash +exec
echo "This code can be executed"
```

<!-- end_slide -->
```

## License

MIT