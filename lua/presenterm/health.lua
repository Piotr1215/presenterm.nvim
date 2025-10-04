---@class PresentermHealth
local M = {}

local health = vim.health or require('health')
local start = health.start or health.report_start
local ok = health.ok or health.report_ok
local warn = health.warn or health.report_warn
local error = health.error or health.report_error
local info = health.info or health.report_info

---Check if presenterm.nvim is loaded and configured
---@return boolean success
local function check_plugin_loaded()
  local presenterm_loaded = pcall(require, 'presenterm')
  if not presenterm_loaded then
    error('presenterm.nvim is not loaded')
    return false
  end
  ok('presenterm.nvim is loaded')

  local config = require('presenterm.config')
  if config.get() then
    ok('Configuration loaded')
    return true
  else
    error('Configuration not properly loaded')
    return false
  end
end

---Check if presenterm CLI is available
local function check_presenterm_cli()
  local handle = io.popen('which presenterm 2>/dev/null')
  if not handle then
    warn('Could not check for presenterm CLI')
    return
  end

  local result = handle:read('*a')
  handle:close()

  if result and result ~= '' then
    ok('presenterm CLI found: ' .. vim.trim(result))
  else
    warn('presenterm CLI not found in PATH')
    info('  Install from: https://github.com/mfontanini/presenterm')
    info('  Preview functionality requires presenterm CLI')
  end
end

---Check picker plugin availability
local function check_picker_plugins()
  local config = require('presenterm.config').get()
  local configured_picker = config.picker and config.picker.provider

  local pickers = {
    { name = 'telescope', module = 'telescope', desc = 'telescope.nvim' },
    { name = 'fzf', module = 'fzf-lua', desc = 'fzf-lua' },
    { name = 'snacks', module = 'snacks', desc = 'snacks.nvim' },
  }

  local available = {}
  for _, picker in ipairs(pickers) do
    local loaded = pcall(require, picker.module)
    if loaded then
      table.insert(available, picker.name)
      local is_configured = configured_picker == picker.name
      local prefix = is_configured and '[CONFIGURED] ' or '[AVAILABLE] '
      ok(prefix .. picker.desc .. ' is available')
    end
  end

  if #available == 0 then
    info('No picker plugins found (will use builtin vim.ui.select)')
    info('  For better UX, install one of:')
    info('    - telescope.nvim')
    info('    - fzf-lua')
    info('    - snacks.nvim')
  end

  if configured_picker and not vim.tbl_contains(available, configured_picker) then
    warn(string.format('Configured picker "%s" is not available', configured_picker))
    info('  Will fall back to available pickers or builtin vim.ui.select')
  end
end

---Check partials directory configuration
local function check_partials_directory()
  local config = require('presenterm.config').get()
  local partials_dir = config.partials and config.partials.directory or '_partials'

  info('Partials directory: ' .. partials_dir)

  if config.partials and config.partials.resolve_relative then
    ok('Partials will be resolved relative to current file')
  else
    info('Partials will be resolved from fixed directory')
  end

  -- Try to check if we can create partials directory (in current directory as test)
  local current_file = vim.fn.expand('%:p')
  if current_file and current_file ~= '' then
    local current_dir = vim.fn.fnamemodify(current_file, ':h')
    local test_partials_path = current_dir .. '/' .. partials_dir

    local stat = vim.loop.fs_stat(test_partials_path)
    if stat and stat.type == 'directory' then
      ok('Partials directory exists in current location: ' .. test_partials_path)
    else
      info('Partials directory will be created when needed')
    end
  end
end

---Check preview configuration
local function check_preview_configuration()
  local config = require('presenterm.config').get()
  local preview_config = config.preview or {}
  local command = preview_config.command or 'presenterm'

  info('Preview command: ' .. command)

  if command:match('^presenterm%s*$') then
    info('  Safe mode: Code blocks will display but not execute')
  elseif command:match('%-x') or command:match('%-X') then
    warn('  Execution mode enabled: Code blocks marked with +exec will run')
    info('  This is intended - use only with trusted presentations')
  end

  if preview_config.presentation_preview_sync then
    ok('Bi-directional sync is ENABLED')
    info('  Navigate in markdown → presenterm follows')
    info('  Navigate in presenterm → cursor moves to slide')
  else
    info('Bi-directional sync is DISABLED')
    info('  Enable with: presentation_preview_sync = true')
  end

  if preview_config.login_shell == false then
    info('Login shell is DISABLED (faster startup)')
    warn('  PATH, environment variables may not be available')
  else
    ok('Login shell is ENABLED')
    info('  Full shell environment loaded (PATH, nvm, pyenv, etc.)')
  end
end

---Check configuration validity
local function check_configuration()
  local config = require('presenterm.config').get()

  -- Check slide marker
  if config.slide_marker and type(config.slide_marker) == 'string' then
    ok('Slide marker: ' .. config.slide_marker)
  else
    error('Invalid slide_marker configuration')
  end

  -- Check default_keybindings
  if config.default_keybindings then
    ok('Default keybindings are ENABLED')
  else
    info('Default keybindings are DISABLED')
    info('  Enable with: default_keybindings = true')
    info('  Or use on_attach callback for custom keymaps')
  end

  -- Check on_attach callback
  if config.on_attach and type(config.on_attach) == 'function' then
    ok('on_attach callback is configured')
  elseif config.on_attach then
    error('on_attach must be a function')
  end
end

---Run health checks for presenterm.nvim
---@return nil
function M.check()
  start('presenterm.nvim')

  if not check_plugin_loaded() then
    return
  end

  start('Configuration')
  check_configuration()

  start('External Dependencies')
  check_presenterm_cli()

  start('Picker Plugins')
  check_picker_plugins()

  start('Partials Configuration')
  check_partials_directory()

  start('Preview Configuration')
  check_preview_configuration()
end

return M
