# presenterm.nvim - Development Guidelines

## Before implementing

Read the existing patterns first (`lua/presenterm/`, including the picker system in `lua/presenterm/pickers/`), then `test/unit/*_spec.lua` for the mocking style. Write the tests first, and use the `/test-writer` skill for the TDD workflow.

## Testing Requirements

Every feature has tests before merging.

- Specs live in `test/unit/*_spec.lua` and run under Busted
- Mock vim functions: `vim.fn.*`, `vim.ui.*`, `vim.notify`, `io.open`
- Test error paths, not just happy paths
- Run the full suite with `make test` (Busted via `test/run_busted.sh`), or `make test-unit` for unit specs only

## Communication Style

**Keep output SUCCINCT:**
- No lengthy summaries - bullet points only
- Key changes, files modified, test results
- User prefers brief, actionable information