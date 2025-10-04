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

- **Slide Management**      : Navigate, create, delete, reorder slides with ease using vim motions
- **Partial Support**       : Include reusable content from partial files, useful when working with multiple presentations
- **Interactive Reordering**: Reorder slides interactively using vim line movements
- **Code Execution**        : Toggle `presenterm` code execution markers (`+exec`, `+exec_replace` etc)
- **Execute Code Blocks**   : Run code blocks directly from Neovim
- **Live Preview**          : Launch `presenterm` preview in terminal with bi-directional sync
- **Bi-directional Sync**   : Navigate in markdown or presenterm, both stay synchronized
- **Statistics**            : View presentation stats and time estimates

## Installation

### lazy.nvim

> [!NOTE] lazy.nvim [auto-detects rockspec files](https://lazy.folke.io/packages#rockspec) and will try to [build via luarocks](https://lazy.folke.io/developers#building) by default. Since this is a pure Lua plugin that doesn't require compilation, add `build = false` to skip the build step and avoid needing lua5.1/luajit.

**Minimal setup (uses defaults):**
```lua
{
  "Piotr1215/presenterm.nvim",
  build = false,  -- Disable rockspec/luarocks build
  opts = {},  -- Uses all defaults, auto-detects picker
}
```

**With optional picker (one of telescope/fzf-lua/snacks):**
```lua
{
  "Piotr1215/presenterm.nvim",
  build = false,
  dependencies = {
    -- Choose one (or install separately):
    "nvim-telescope/telescope.nvim",  -- Option 1: Telescope
    -- "ibhagwan/fzf-lua",            -- Option 2: fzf-lua
    -- "folke/snacks.nvim",           -- Option 3: Snacks
  },
  opts = {},
}
```

**Custom setup with picker preference:**
```lua
{
  "Piotr1215/presenterm.nvim",
  build = false,
  config = function()
    require("presenterm").setup({
      default_keybindings = true,
      picker = {
        provider = "telescope",  -- Options: "telescope", "fzf", "snacks", "builtin"
      },
      preview = {
        command = "presenterm -xX",
        presentation_preview_sync = true,
      },
    })
  end,
}
```

### packer.nvim

```lua
use "Piotr1215/presenterm.nvim"
```

### rocks.nvim (Optional)

> **Note:** This method may require lua5.1 or luajit installed on your system.

```vim
:Rocks install presenterm.nvim
```

### luarocks (Optional)

> **Note:** This method requires lua5.1 or luajit installed on your system.

```bash
luarocks install presenterm.nvim
```

## Usage

The plugin automatically detects `presenterm` presentations (by looking for slide markers like `<!-- end_slide -->` or frontmatter) and activates when you open a markdown file. You can also manually activate with `:Presenterm activate`.

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
vim.keymap.set("n", "]s", ":Presenterm next<cr>")
vim.keymap.set("n", "[s", ":Presenterm prev<cr>")
-- Note: Use the new :Presenterm command pattern shown below in Commands section
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
- `<leader>sl` - List slides
- `<leader>sL` - Select layout
- `<leader>sp` - Include partial
- `<C-e>` - Toggle +exec
- `<leader>sr` - Run code block
- `<leader>sP` - Preview presentation
- `<leader>sc` - Presentation stats

</details>

### Commands

All commands use the `:Presenterm <command>` pattern for a clean namespace.

#### Navigation
- `:Presenterm next` - Go to next slide
- `:Presenterm prev` - Go to previous slide
- `:Presenterm goto N` - Go to slide N
- `:Presenterm list` - List all slides

#### Slide Management
- `:Presenterm new` - Create new slide after current
- `:Presenterm split` - Split slide at cursor position
- `:Presenterm delete` - Delete current slide
- `:Presenterm yank` - Yank current slide
- `:Presenterm select` - Visually select current slide
- `:Presenterm move-up` - Move slide up
- `:Presenterm move-down` - Move slide down
- `:Presenterm reorder` - Interactive slide reordering

#### Partials
- `:Presenterm partial include` - Include partial file
- `:Presenterm partial edit` - Edit partial file
- `:Presenterm partial list` - List all partials

#### Code Blocks
- `:Presenterm exec toggle` - Toggle code execution flags (plain → +exec → +exec_replace → +exec +acquire_terminal)
- `:Presenterm exec run` - Run current code block

#### Column Layouts
- `:Presenterm layout` - Open picker to select and insert column layout templates

Available templates:
- Two Column layouts: 50/50, 60/40, 70/30
- Three Column layouts: 33/33/33, 50/25/25
- Sidebar layouts: 25/75 (left), 75/25 (right)
- Centered content: 20/60/20

Inserts full scaffolding with `<!-- column_layout: [x, y] -->`, column markers, and `<!-- reset_layout -->`.

#### Preview
- `:Presenterm preview` - Preview presentation in terminal split
- `:Presenterm stats` - Show presentation statistics
- `:Presenterm toggle-sync` - Toggle bi-directional sync (navigate in markdown → presenterm follows, and vice versa)

#### Other
- `:Presenterm activate` - Manually activate presenterm mode
- `:Presenterm deactivate` - Deactivate presenterm mode for current buffer
- `:Presenterm help` - Show help

## Preview Sync

When `presentation_preview_sync = true`, navigation is synchronized bi-directionally:

**Buffer → Terminal**: Navigate in markdown with any motion (`j`, `k`, `gg`, `G`, `/`, etc.) → presenterm jumps to that slide

**Terminal → Presenterm**: Navigate in presenterm (`n`, `p`, `<number>G`) → markdown buffer cursor moves to that slide

**Requirements**:
- Presenterm footer must show slide count (e.g., "1 / 10")
- Works automatically with/without frontmatter (adjusts slide numbering)
- Sync prevents loops with 100ms debounce

**Does NOT work when**:
- Presenterm footer is customized to hide slide numbers
- Using custom footer configuration without "N / M" pattern

## Picker and preview integrating

Auto-detects available pickers (Telescope/fzf-lua/Snacks) or falls back to vim.ui.select

### Slide Picker

The slide picker shows all slides with titles extracted from the content, including from partial files. Slides containing partials are marked with `[P]` indicator.

- `<CR>` - Jump to selected slide
- `<C-e>` - Edit the first partial in the selected slide (if it contains any)

### Partial Picker

The partial picker has two modes:

- **Include mode** (`:Presenterm partial include`):
  - `<CR>` - Insert include directive
  - `<C-e>` - Edit the partial file

- **Edit mode** (`:Presenterm partial edit`):
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

### Default Configuration

```lua
{
  slide_marker = "<!-- end_slide -->",
  partials = {
    directory = "_partials",
    resolve_relative = true,
  },
  preview = {
    command = "presenterm",              -- Safe: commands won't execute
    presentation_preview_sync = false,
    login_shell = true,                  -- Loads PATH, env vars, etc.
  },
  picker = {
    provider = nil,  -- Auto-detect: telescope > fzf > snacks > builtin
  },
  on_attach = nil,
  default_keybindings = false,
}
```

By default:
- Commands in slides display but don't execute (safe for untrusted presentations)
- Shell environment loaded (PATH, nvm, pyenv, env vars available)
- No automatic keybindings (set `default_keybindings = true` or configure manually)

### Common Configurations

**For presentations with live demos (docker, node, etc.):**
```lua
preview = {
  command = "presenterm -xX",  -- Executes +exec code blocks
}
```

**Faster startup (skip environment loading):**
```lua
preview = {
  login_shell = false,  -- ~200-500ms faster, but PATH, env vars unavailable
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

## Troubleshooting

Run `:checkhealth presenterm` to diagnose common issues.

The health check will verify:
- Plugin is loaded and configured correctly
- presenterm CLI is installed and in PATH
- Picker plugins (telescope/fzf-lua/snacks) availability
- Partials directory configuration
- Preview and sync settings

**Common issues:**

- **Preview not working:** Ensure presenterm CLI is installed:
  ```bash
  cargo install presenterm
  # or check https://github.com/mfontanini/presenterm
  ```

- **No picker UI:** Install one of:
  - `telescope.nvim`
  - `fzf-lua`
  - `snacks.nvim`

- **Sync not working:** Check that:
  - `presentation_preview_sync = true` in config
  - presenterm footer shows slide numbers (e.g., "1 / 10")
  - Not using custom footer that hides slide numbers

## License

MIT
