-- Presenterm plugin entry point
if vim.g.loaded_presenterm then
  return
end
vim.g.loaded_presenterm = true

-- Navigation commands
vim.api.nvim_create_user_command('PresenterNext', function()
  require('presenterm').next_slide()
end, { desc = 'Go to next slide' })

vim.api.nvim_create_user_command('PresenterPrev', function()
  require('presenterm').previous_slide()
end, { desc = 'Go to previous slide' })

vim.api.nvim_create_user_command('PresenterGoto', function(opts)
  local slide_num = tonumber(opts.args)
  if slide_num then
    require('presenterm').go_to_slide(slide_num)
  else
    vim.notify('Please provide a slide number', vim.log.levels.ERROR)
  end
end, { nargs = 1, desc = 'Go to specific slide' })

vim.api.nvim_create_user_command('PresenterList', function()
  require('presenterm.telescope').slide_picker()
end, { desc = 'List all slides with telescope' })

-- Slide management commands
vim.api.nvim_create_user_command('PresenterNew', function()
  require('presenterm').new_slide()
end, { desc = 'Create new slide after current' })

vim.api.nvim_create_user_command('PresenterSplit', function()
  require('presenterm').split_slide()
end, { desc = 'Split slide at cursor position' })

vim.api.nvim_create_user_command('PresenterDelete', function()
  require('presenterm').delete_slide()
end, { desc = 'Delete current slide' })

vim.api.nvim_create_user_command('PresenterYank', function()
  require('presenterm').yank_slide()
end, { desc = 'Yank current slide' })

vim.api.nvim_create_user_command('PresenterSelect', function()
  require('presenterm').select_slide()
end, { desc = 'Visually select current slide' })

vim.api.nvim_create_user_command('PresenterMoveUp', function()
  require('presenterm').move_slide_up()
end, { desc = 'Move current slide up' })

vim.api.nvim_create_user_command('PresenterMoveDown', function()
  require('presenterm').move_slide_down()
end, { desc = 'Move current slide down' })

vim.api.nvim_create_user_command('PresenterReorder', function()
  require('presenterm').interactive_reorder()
end, { desc = 'Interactive slide reordering' })

-- Partial commands
vim.api.nvim_create_user_command('PresenterPartial', function(opts)
  local subcommand = opts.fargs[1]
  if subcommand == 'include' then
    require('presenterm.telescope').partial_picker()
  elseif subcommand == 'edit' then
    require('presenterm.telescope').partial_picker({ edit_mode = true })
  elseif subcommand == 'list' then
    require('presenterm.telescope').list_partials()
  else
    vim.notify('Unknown subcommand. Use: include, edit, or list', vim.log.levels.ERROR)
  end
end, {
  nargs = 1,
  complete = function(arg_lead, _, _)
    local completions = { 'include', 'edit', 'list' }
    return vim.tbl_filter(function(c)
      return c:find(arg_lead) == 1
    end, completions)
  end,
  desc = 'Partial file operations',
})

-- Code block commands
vim.api.nvim_create_user_command('PresenterExec', function(opts)
  if opts.args == 'toggle' then
    require('presenterm').toggle_exec()
  elseif opts.args == 'run' then
    require('presenterm').run_code_block()
  else
    vim.notify('Unknown subcommand. Use: toggle or run', vim.log.levels.ERROR)
  end
end, {
  nargs = 1,
  complete = function(arg_lead, _, _)
    local completions = { 'toggle', 'run' }
    return vim.tbl_filter(function(c)
      return c:find(arg_lead) == 1
    end, completions)
  end,
  desc = 'Code block execution',
})

-- Preview and stats
vim.api.nvim_create_user_command('PresenterPreview', function()
  require('presenterm').preview()
end, { desc = 'Preview presentation' })

vim.api.nvim_create_user_command('PresenterStats', function()
  require('presenterm').presentation_stats()
end, { desc = 'Show presentation statistics' })

vim.api.nvim_create_user_command('PresenterToggleSync', function()
  require('presenterm.preview').toggle_sync()
end, { desc = 'Toggle bi-directional sync between terminal and buffer' })

-- Activation
vim.api.nvim_create_user_command('PresenterActivate', function()
  require('presenterm').activate()
end, { desc = 'Manually activate presenterm mode' })

vim.api.nvim_create_user_command('PresenterDeactivate', function()
  require('presenterm').deactivate()
end, { desc = 'Deactivate presenterm mode for current buffer' })

vim.api.nvim_create_user_command('PresenterHelp', function()
  require('presenterm').show_help()
end, { desc = 'Show presenterm help' })

-- Auto-activate presenterm for presentation files
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  callback = function(args)
    vim.schedule(function()
      if not vim.b.presenterm_active and require('presenterm.slides').is_presentation() then
        vim.b.presenterm_active = true
        vim.notify('Presenterm mode activated', vim.log.levels.INFO)

        local config = require('presenterm.config').get()

        -- Setup default keybindings if enabled
        if config.default_keybindings then
          require('presenterm.keybindings').setup_default(args.buf)
        end

        -- Call on_attach callback if configured
        if config.on_attach then
          vim.b[args.buf].presenterm_on_attach_called = true
          config.on_attach(args.buf)
        end
      end
    end)
  end,
  desc = 'Auto-activate presenterm for presentation files',
})
