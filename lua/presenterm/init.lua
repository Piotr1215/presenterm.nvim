---@class PresenterMModule
local M = {}

---Setup Presenterm plugin (optional)
---@param opts PresenterMConfig|table|nil User configuration options
function M.setup(opts)
  -- Only setup configuration if provided
  if opts then
    require('presenterm.config').setup(opts)
  end
end

-- Navigation functions
function M.next_slide()
  return require('presenterm.navigation').next_slide()
end

function M.previous_slide()
  return require('presenterm.navigation').previous_slide()
end

function M.go_to_slide(num)
  return require('presenterm.navigation').go_to_slide(num)
end

-- Slide management functions
function M.new_slide()
  return require('presenterm.slides').new_slide()
end

function M.split_slide()
  return require('presenterm.slides').split_slide()
end

function M.delete_slide()
  return require('presenterm.slides').delete_slide()
end

function M.yank_slide()
  return require('presenterm.slides').yank_slide()
end

function M.select_slide()
  return require('presenterm.slides').select_slide()
end

function M.move_slide_up()
  return require('presenterm.slides').move_slide_up()
end

function M.move_slide_down()
  return require('presenterm.slides').move_slide_down()
end

function M.interactive_reorder()
  return require('presenterm.slides').interactive_reorder()
end

-- Code execution functions
function M.toggle_exec()
  return require('presenterm.exec').toggle_exec()
end

function M.run_code_block()
  return require('presenterm.exec').run_code_block()
end

-- Preview functions
function M.preview()
  return require('presenterm.preview').preview()
end

function M.presentation_stats()
  return require('presenterm.preview').presentation_stats()
end

-- Utility functions
function M.activate()
  if require('presenterm.slides').is_presentation() then
    vim.notify('Presenterm mode activated', vim.log.levels.INFO)
    -- Set buffer-local indicator
    vim.b.presenterm_active = true
  else
    vim.notify('Not a presentation file', vim.log.levels.WARN)
  end
end

function M.deactivate()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.b.presenterm_active = false

  -- Remove default keybindings if they were set
  if vim.b.presenterm_default_keybindings then
    require('presenterm.keybindings').remove_default(bufnr)
  end

  -- Mark on_attach state
  if vim.b.presenterm_on_attach_called then
    vim.b.presenterm_on_attach_called = nil
    vim.notify(
      'Presenterm mode deactivated (on_attach keybindings must be removed manually)',
      vim.log.levels.INFO
    )
  else
    vim.notify('Presenterm mode deactivated', vim.log.levels.INFO)
  end
end

function M.show_help()
  local help_lines = {
    'Presenterm Commands:',
    '',
    'Navigation:',
    '  :PresenterNext       - Go to next slide',
    '  :PresenterPrev       - Go to previous slide',
    '  :PresenterGoto N     - Go to slide N',
    '  :PresenterList       - List all slides',
    '',
    'Slide Management:',
    '  :PresenterNew        - Create new slide',
    '  :PresenterSplit      - Split slide at cursor',
    '  :PresenterDelete     - Delete current slide',
    '  :PresenterYank       - Yank current slide',
    '  :PresenterSelect     - Select current slide',
    '  :PresenterMoveUp     - Move slide up',
    '  :PresenterMoveDown   - Move slide down',
    '  :PresenterReorder    - Interactive reordering',
    '',
    'Partials:',
    '  :PresenterPartial include - Include partial',
    '  :PresenterPartial edit    - Edit partial',
    '  :PresenterPartial list    - List partials',
    '',
    'Code Blocks:',
    '  :PresenterExec toggle - Toggle +exec flag',
    '  :PresenterExec run    - Run code block',
    '',
    'Preview:',
    '  :PresenterPreview    - Preview presentation',
    '  :PresenterStats      - Show statistics',
    '',
    'Other:',
    '  :PresenterActivate   - Activate presenterm mode',
    '  :PresenterDeactivate - Deactivate presenterm mode',
    '  :PresenterHelp       - Show this help',
  }

  -- Create floating window
  local width = math.min(60, vim.o.columns - 4)
  local height = math.min(#help_lines + 2, vim.o.lines - 4)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'

  local win_opts = {
    relative = 'editor',
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    border = 'rounded',
    style = 'minimal',
    title = ' Presenterm Help ',
    title_pos = 'center',
  }

  vim.api.nvim_open_win(buf, true, win_opts)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, help_lines)
  vim.bo[buf].modifiable = false

  -- Close on any key
  vim.keymap.set('n', '<Esc>', ':close<CR>', { buffer = buf, silent = true })
  vim.keymap.set('n', 'q', ':close<CR>', { buffer = buf, silent = true })
end

-- Expose slide status for statusline
function M.slide_status()
  if not vim.b.presenterm_active then
    return ''
  end
  return require('presenterm.navigation').slide_status()
end

return M
