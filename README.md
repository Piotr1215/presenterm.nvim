# presenterm.nvim

A Neovim plugin for creating and managing [presenterm](https://github.com/mfontanini/presenterm) presentations with enhanced support for slide navigation, partials management, and live preview.

<div align="center">

[![Neovim](https://img.shields.io/badge/Neovim-0.9+-green.svg?style=flat-square&logo=neovim)](https://neovim.io)
[![Lua](https://img.shields.io/badge/Lua-5.1+-blue.svg?style=flat-square&logo=lua)](https://www.lua.org)
[![CI](https://github.com/Piotr1215/presenterm.nvim/actions/workflows/test.yml/badge.svg)](https://github.com/Piotr1215/presenterm.nvim/actions/workflows/test.yml)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)
[![LuaRocks](https://img.shields.io/luarocks/v/piotr1215/presenterm.nvim?logo=lua&color=purple&style=flat-square)](https://luarocks.org/modules/piotr1215/presenterm.nvim)

</div>

## Features

- **Slide Management**      : Navigate, create, delete, reorder slides with ease using vim motions or telescope picker
- **Partial Support**       : Include reusable content from partial files, useful when working with multiple presentations
- **Telescope Integration** : Browse slides and partials with preview, slides with partials marked with [P]
- **Interactive Reordering**: Reorder slides interactively using vim line movements
- **Code Execution**        : Toggle `presenterm` code execution markers (`+exec`, `+exec_replace` etc) 
- **Execute Code Blocks**   : Run code blocks directly from Neovim
- **Live Preview**          : Launch `presenterm` preview in terminal
- **Statistics**            : View presentation stats and time estimates

## Installation

### lazy.nvim

```lua
{
  "Piotr1215/presenterm.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim", -- Optional, for telescope integration
  },
  config = function()
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

### rocks.nvim

```vim
:Rocks install presenterm.nvim
```

### luarocks

```bash
luarocks install presenterm.nvim
```

## Usage

The plugin automatically detects `presenterm` presentations (by looking for slide markers like `<!-- end_slide -->` or frontmatter) and activates when you open a markdown file. You can also manually activate with `:PresenterActivate`.

### Keybindings

**Option 1: Use defaults** (recommended)
```lua
require("presenterm").setup({
  default_keybindings = true,
})
```

**Option 2: Customize with `on_attach`**
```lua
require("presenterm").setup({
  on_attach = function(bufnr)
    vim.keymap.set("n", "]s", require("presenterm").next_slide, { buffer = bufnr, desc = "Next slide" })
    vim.keymap.set("n", "[s", require("presenterm").previous_slide, { buffer = bufnr, desc = "Previous slide" })
  end,
})
```

**Option 3: Map commands manually**
```lua
vim.keymap.set("n", "]s", ":PresenterNext<cr>")
vim.keymap.set("n", "[s", ":PresenterPrev<cr>")
```

<details>
<summary>Default keymaps (when default_keybindings = true)</summary>

- `]s` / `[s` - Next/previous slide
- `<leader>sn` - New slide
- `<leader>ss` - Split slide
- `<leader>sd` - Delete slide
- `<leader>sy` - Yank slide
- `<leader>sv` - Select slide
- `<leader>sk` / `<leader>sj` - Move slide up/down
- `<leader>sR` - Reorder slides
- `<leader>sl` - List slides (telescope)
- `<leader>sp` - Include partial (telescope)
- `<C-e>` - Toggle +exec
- `<leader>sr` - Run code block
- `<leader>sP` - Preview presentation
- `<leader>sc` - Presentation stats

</details>

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
- `:PresenterExec toggle` - Toggle code execution flags (plain → +exec → +exec_replace → +exec +acquire_terminal)
- `:PresenterExec run` - Run current code block

#### Preview
- `:PresenterPreview` - Preview presentation
- `:PresenterStats` - Show presentation statistics

#### Other
- `:PresenterActivate` - Manually activate presenterm mode
- `:PresenterHelp` - Show help

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
  on_attach = nil,               -- Optional callback function(bufnr) for buffer-local keymaps
  default_keybindings = false,   -- Set to true to enable default buffer-local keymaps
}
```

## Presentation Structure

A typical `presenterm` presentation structure:

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

## License

MIT
