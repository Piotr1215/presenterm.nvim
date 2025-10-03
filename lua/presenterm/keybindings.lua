local M = {}

---Setup default keybindings for a buffer
---@param bufnr number Buffer number
function M.setup_default(bufnr)
  local presenterm = require('presenterm')

  -- Navigation
  vim.keymap.set('n', ']s', presenterm.next_slide, { buffer = bufnr, desc = 'Next slide' })
  vim.keymap.set('n', '[s', presenterm.previous_slide, { buffer = bufnr, desc = 'Previous slide' })

  -- Slide management
  vim.keymap.set('n', '<leader>sn', presenterm.new_slide, { buffer = bufnr, desc = 'New slide' })
  vim.keymap.set(
    'n',
    '<leader>ss',
    presenterm.split_slide,
    { buffer = bufnr, desc = 'Split slide' }
  )
  vim.keymap.set(
    'n',
    '<leader>sd',
    presenterm.delete_slide,
    { buffer = bufnr, desc = 'Delete slide' }
  )
  vim.keymap.set('n', '<leader>sy', presenterm.yank_slide, { buffer = bufnr, desc = 'Yank slide' })
  vim.keymap.set(
    'n',
    '<leader>sv',
    presenterm.select_slide,
    { buffer = bufnr, desc = 'Select slide' }
  )
  vim.keymap.set(
    'n',
    '<leader>sk',
    presenterm.move_slide_up,
    { buffer = bufnr, desc = 'Move slide up' }
  )
  vim.keymap.set(
    'n',
    '<leader>sj',
    presenterm.move_slide_down,
    { buffer = bufnr, desc = 'Move slide down' }
  )
  vim.keymap.set(
    'n',
    '<leader>sR',
    presenterm.interactive_reorder,
    { buffer = bufnr, desc = 'Reorder slides' }
  )

  -- Telescope integration
  vim.keymap.set('n', '<leader>sl', function()
    require('presenterm.telescope').slide_picker()
  end, { buffer = bufnr, desc = 'List slides' })
  vim.keymap.set('n', '<leader>sp', function()
    require('presenterm.telescope').partial_picker()
  end, { buffer = bufnr, desc = 'Include partial' })

  -- Code execution
  vim.keymap.set('n', '<C-e>', presenterm.toggle_exec, { buffer = bufnr, desc = 'Toggle +exec' })
  vim.keymap.set('i', '<C-e>', presenterm.toggle_exec, { buffer = bufnr, desc = 'Toggle +exec' })
  vim.keymap.set(
    'n',
    '<leader>sr',
    presenterm.run_code_block,
    { buffer = bufnr, desc = 'Run code block' }
  )

  -- Preview
  vim.keymap.set(
    'n',
    '<leader>sP',
    presenterm.preview,
    { buffer = bufnr, desc = 'Preview presentation' }
  )
  vim.keymap.set(
    'n',
    '<leader>sc',
    presenterm.presentation_stats,
    { buffer = bufnr, desc = 'Presentation stats' }
  )
end

return M
