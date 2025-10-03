local M = {}

---List of default keybindings
M.default_keys = {
  { mode = 'n', lhs = ']s' },
  { mode = 'n', lhs = '[s' },
  { mode = 'n', lhs = '<leader>sn' },
  { mode = 'n', lhs = '<leader>ss' },
  { mode = 'n', lhs = '<leader>sd' },
  { mode = 'n', lhs = '<leader>sy' },
  { mode = 'n', lhs = '<leader>sv' },
  { mode = 'n', lhs = '<leader>sk' },
  { mode = 'n', lhs = '<leader>sj' },
  { mode = 'n', lhs = '<leader>sR' },
  { mode = 'n', lhs = '<leader>sl' },
  { mode = 'n', lhs = '<leader>sL' },
  { mode = 'n', lhs = '<leader>sp' },
  { mode = 'n', lhs = '<C-e>' },
  { mode = 'i', lhs = '<C-e>' },
  { mode = 'n', lhs = '<leader>sr' },
  { mode = 'n', lhs = '<leader>sP' },
  { mode = 'n', lhs = '<leader>sc' },
}

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

  -- Picker integration
  vim.keymap.set('n', '<leader>sl', function()
    require('presenterm.pickers').slide_picker()
  end, { buffer = bufnr, desc = 'List slides' })
  vim.keymap.set('n', '<leader>sL', function()
    require('presenterm.layout').layout_picker()
  end, { buffer = bufnr, desc = 'Select layout' })
  vim.keymap.set('n', '<leader>sp', function()
    require('presenterm.pickers').partial_picker()
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

  -- Mark that default keybindings were set
  vim.b[bufnr].presenterm_default_keybindings = true
end

---Remove default keybindings from a buffer
---@param bufnr number Buffer number
function M.remove_default(bufnr)
  for _, key in ipairs(M.default_keys) do
    pcall(vim.keymap.del, key.mode, key.lhs, { buffer = bufnr })
  end
  vim.b[bufnr].presenterm_default_keybindings = nil
end

return M
