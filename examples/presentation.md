---
title: presenterm.nvim Demo
author: Feature Showcase
---



# Slide Operations

**Create and Manage Slides:**

- `<leader>sn` - Create new slide after current
- `<leader>ss` - Split slide at cursor position
- `<leader>sd` - Delete current slide
- `<leader>sy` - Yank slide 
- `<leader>sv` - Visual select slide

**Move Slides:**
- `<leader>sk` - Move slide up
- `<leader>sj` - Move slide down

<!-- end_slide -->



## New Slide

<!-- end_slide -->


# Interactive Reordering

Press `<leader>sR` to enter interactive reorder mode

**How it works:**
1. Opens split window with slide overview
2. Use standard vim line movements:
   - `dd` to cut
   - `p` to paste
   - Visual mode + `d` and `p`
3. Save and close to apply changes

**Perfect for restructuring presentations!**

<!-- end_slide -->


# Partials - Reusable Content

Include reusable content from partial files

<!-- include: ./_partials/intro.md -->

<!-- end_slide -->


# Basic Navigation

Navigate between slides with ease:

**Commands:**
- `:Presenterm next` / `:Presenterm prev`
- `:Presenterm goto N` - Jump to slide N
- `:Presenterm list` - Interactive slide picker

**Default Keybindings:**
- `]s` - Next slide
- `[s` - Previous slide
- `<leader>sl` - List all slides

<!-- end_slide -->


<!-- include: ./_partials/demo.md -->

<!-- end_slide -->


# Working with Partials

**Commands:**
- `:Presenterm partial include` - Include partial (insert directive)
- `:Presenterm partial edit` - Edit partial file
- `:Presenterm partial list` - List all partials

**Picker Actions:**
- `<CR>` - Primary action (include/edit based on mode)
- `<C-e>` - Edit partial (in include mode)
- `<C-i>` - Insert include (in edit mode)

**Benefits:** Share content across multiple presentations!

<!-- end_slide -->


# Code Execution

Execute code blocks directly in presentations

**Example with +exec flag:**
```bash +exec
echo "Hello from presenterm!"
date
uname -s
```

**Toggle exec flags:**
- Press `<C-e>` to cycle: plain → +exec → +exec_replace → +exec +acquire_terminal
- `:Presenterm exec run` - Run current code block in Neovim

<!-- end_slide -->


# Column Layouts

Create multi-column slides with `:Presenterm layout`

<!-- column_layout: [1, 1] -->

<!-- column: 0 -->

**Left Column**

- Feature demos
- Code examples
- Documentation

<!-- column: 1 -->

**Right Column**

- Visual content
- Diagrams
- Screenshots

<!-- reset_layout -->

**Templates:** 50/50, 60/40, 70/30, three-column, sidebars, centered

<!-- end_slide -->


# Preview & Statistics

**Launch Preview:**
- `<leader>sP` - Opens presenterm in terminal split
- `:Presenterm preview`

**View Statistics:**
- `<leader>sc` - Show presentation stats
- `:Presenterm stats`

**Toggle Sync:**
- `:Presenterm toggle-sync` - Enable/disable bi-directional sync

**Preview safely:** Default config doesn't execute code (use `-xX` flag if needed)

<!-- end_slide -->


<!-- include: _partials/conclusion.md -->

<!-- end_slide -->

