-- Presenterm plugin entry point
if vim.g.loaded_presenterm then
  return
end
vim.g.loaded_presenterm = true

---@class PresenterSubcommand
---@field impl fun(args:string[], opts: table) The command implementation
---@field complete? fun(subcmd_arg_lead: string): string[] (optional) Command completions callback

---@type table<string, PresenterSubcommand>
local subcommand_tbl = {
  -- Navigation commands
  next = {
    impl = function(args, opts)
      require('presenterm').next_slide()
    end,
  },
  prev = {
    impl = function(args, opts)
      require('presenterm').previous_slide()
    end,
  },
  goto = {
    impl = function(args, opts)
      local slide_num = tonumber(args[1])
      if slide_num then
        require('presenterm').go_to_slide(slide_num)
      else
        vim.notify('Please provide a slide number', vim.log.levels.ERROR)
      end
    end,
  },
  list = {
    impl = function(args, opts)
      require('presenterm.telescope').slide_picker()
    end,
  },
  -- Slide management commands
  new = {
    impl = function(args, opts)
      require('presenterm').new_slide()
    end,
  },
  split = {
    impl = function(args, opts)
      require('presenterm').split_slide()
    end,
  },
  delete = {
    impl = function(args, opts)
      require('presenterm').delete_slide()
    end,
  },
  yank = {
    impl = function(args, opts)
      require('presenterm').yank_slide()
    end,
  },
  select = {
    impl = function(args, opts)
      require('presenterm').select_slide()
    end,
  },
  ['move-up'] = {
    impl = function(args, opts)
      require('presenterm').move_slide_up()
    end,
  },
  ['move-down'] = {
    impl = function(args, opts)
      require('presenterm').move_slide_down()
    end,
  },
  reorder = {
    impl = function(args, opts)
      require('presenterm').interactive_reorder()
    end,
  },
  -- Partial commands
  partial = {
    impl = function(args, opts)
      local subcommand = args[1]
      if subcommand == 'include' then
        require('presenterm.telescope').partial_picker()
      elseif subcommand == 'edit' then
        require('presenterm.telescope').partial_picker({ edit_mode = true })
      elseif subcommand == 'list' then
        require('presenterm.telescope').list_partials()
      else
        vim.notify('Unknown partial subcommand. Use: include, edit, or list', vim.log.levels.ERROR)
      end
    end,
    complete = function(subcmd_arg_lead)
      local partial_args = { 'include', 'edit', 'list' }
      return vim.iter(partial_args)
        :filter(function(arg)
          return arg:find(subcmd_arg_lead) ~= nil
        end)
        :totable()
    end,
  },
  -- Code execution commands
  exec = {
    impl = function(args, opts)
      local subcommand = args[1]
      if subcommand == 'toggle' then
        require('presenterm').toggle_exec()
      elseif subcommand == 'run' then
        require('presenterm').run_code_block()
      else
        vim.notify('Unknown exec subcommand. Use: toggle or run', vim.log.levels.ERROR)
      end
    end,
    complete = function(subcmd_arg_lead)
      local exec_args = { 'toggle', 'run' }
      return vim.iter(exec_args)
        :filter(function(arg)
          return arg:find(subcmd_arg_lead) ~= nil
        end)
        :totable()
    end,
  },
  -- Preview and stats
  preview = {
    impl = function(args, opts)
      require('presenterm').preview()
    end,
  },
  stats = {
    impl = function(args, opts)
      require('presenterm').presentation_stats()
    end,
  },
  ['toggle-sync'] = {
    impl = function(args, opts)
      require('presenterm.preview').toggle_sync()
    end,
  },
  -- Activation
  activate = {
    impl = function(args, opts)
      require('presenterm').activate()
    end,
  },
  deactivate = {
    impl = function(args, opts)
      require('presenterm').deactivate()
    end,
  },
  help = {
    impl = function(args, opts)
      require('presenterm').show_help()
    end,
  },
}

---@param opts table :h lua-guide-commands-create
local function presenterm_cmd(opts)
  local fargs = opts.fargs
  local subcommand_key = fargs[1]
  -- Get the subcommand's arguments, if any
  local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
  local subcommand = subcommand_tbl[subcommand_key]
  if not subcommand then
    vim.notify('Presenterm: Unknown command: ' .. subcommand_key, vim.log.levels.ERROR)
    return
  end
  -- Invoke the subcommand
  subcommand.impl(args, opts)
end

-- Register the main Presenterm command
vim.api.nvim_create_user_command('Presenterm', presenterm_cmd, {
  nargs = '+',
  desc = 'Presenterm command with subcommand completions',
  complete = function(arg_lead, cmdline, _)
    -- Get the subcommand
    local subcmd_key, subcmd_arg_lead = cmdline:match("^['<,'>]*Presenterm[!]*%s(%S+)%s(.*)$")
    if
      subcmd_key
      and subcmd_arg_lead
      and subcommand_tbl[subcmd_key]
      and subcommand_tbl[subcmd_key].complete
    then
      -- The subcommand has completions. Return them.
      return subcommand_tbl[subcmd_key].complete(subcmd_arg_lead)
    end
    -- Check if cmdline is a subcommand
    if cmdline:match("^['<,'>]*Presenterm[!]*%s+%w*$") then
      -- Filter subcommands that match
      local subcommand_keys = vim.tbl_keys(subcommand_tbl)
      return vim.iter(subcommand_keys)
        :filter(function(key)
          return key:find(arg_lead) ~= nil
        end)
        :totable()
    end
  end,
  bang = false,
})

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
