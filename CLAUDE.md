# presenterm.nvim - Development Guidelines

## CRITICAL: Pre-Implementation Checklist

**ALWAYS follow 80/20 rule: 80% READING/RESEARCH, 20% WRITING**

Before implementing ANY feature:
1. **Research existing patterns** - Check `lua/presenterm/` for abstractions (e.g., picker system in `lua/presenterm/pickers/`)
2. **Invoke test-writer skill** - Use `/test-writer` for TDD workflow
3. **Write tests FIRST** - Red → Green → Refactor
4. **Read test files** - Check `test/unit/*_spec.lua` for mocking patterns

## Architecture Overview

presenterm.nvim is a well-architected Neovim plugin for creating and managing presenterm presentations. The plugin demonstrates solid software engineering practices with a clean, modular design.

## Strengths

### Architecture & Design
- **Excellent modular structure**: Clear separation of concerns with dedicated modules for navigation, preview, partials, exec, slides, layout, and keybindings
- **Smart picker abstraction**: The picker system (`lua/presenterm/pickers/`) elegantly abstracts different UI providers (telescope, fzf-lua, snacks, builtin) with automatic detection and graceful fallback
- **Progressive enhancement**: Works without dependencies (vim.ui.select fallback) but enhances with optional pickers
- **Well-defined interfaces**: Clean API boundaries between modules (e.g., `navigation.lua` exposing focused functions like `next_slide()`, `go_to_slide()`)

### Code Quality
- **Comprehensive test coverage**: 12 spec files covering all major modules
- **Consistent code style**: Clean, readable Lua with good naming conventions
- **Type annotations**: Uses LuaLS annotations for better IDE support (`@class`, `@field`, `@param`)
- **Defensive programming**: Proper error handling and validation throughout

### Features & UX
- **Bi-directional sync**: Innovative preview sync between Neovim and presenterm terminal
- **Flexible configuration**: Smart defaults with override capability
- **Vim-native operations**: Leverages native vim concepts (text objects, motions, commands)
- **Partial management**: Thoughtful implementation for reusable content across presentations

## Areas of Excellence

1. **The picker system** (init.lua:6-40) is particularly elegant:
   - Auto-detection with clear priority order
   - User override capability
   - Graceful degradation to builtin
   - Validation of configured picker availability

2. **Preview synchronization** (`preview.lua`) shows deep understanding of terminal integration

3. **Test architecture** using plenary.nvim for comprehensive unit testing

## Minor Improvements to Consider

1. **Config type definition**: The `PresenterMConfig` class in `config.lua:3-9` is missing the `picker` field type definition

2. **Documentation**: While README is comprehensive, inline documentation could be expanded in some complex functions

3. **Performance**: Consider lazy-loading some modules (though current ~2650 LOC is reasonable)

## Technical Merit
The codebase demonstrates:
- Strong understanding of Neovim's API and ecosystem
- Clean abstraction patterns
- Production-ready error handling
- Thoughtful user experience design

## Testing Requirements

**All features MUST have tests before merging**

- Use plenary.nvim test framework (`test/unit/*_spec.lua`)
- Mock vim functions: `vim.fn.*`, `vim.ui.*`, `vim.notify`, `io.open`
- Test error paths, not just happy paths
- Run full suite: `nvim --headless -c "PlenaryBustedDirectory test/unit/ {minimal_init = 'test/minimal_init.lua'}" -c "qa!"`

## Communication Style

**Keep output SUCCINCT:**
- No lengthy summaries - bullet points only
- Key changes, files modified, test results
- User prefers brief, actionable information

## Conclusion

This is a high-quality plugin that solves a real problem elegantly. The architecture is extensible, the code is maintainable, and the feature set is well-thought-out. The picker abstraction pattern could serve as a reference implementation for other plugin authors.

Rating: **9/10** - Production-ready with room for minor enhancements