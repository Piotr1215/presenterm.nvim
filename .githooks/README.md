# Git Hooks

This directory contains git hooks for the presenterm.nvim project.

## Setup

Run the following command to use these hooks:

```bash
make install-hooks
```

Or manually:

```bash
git config core.hooksPath .githooks
```

## Available Hooks

### pre-commit
- Formats all Lua files with stylua
- Runs tests to ensure nothing is broken
- Automatically stages formatted files

## Requirements

- `stylua` - Install with `cargo install stylua`
- `nvim` - For running tests