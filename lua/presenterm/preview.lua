local M = {}

local config = require('presenterm.config')
local slides = require('presenterm.slides')

-- State tracking
local state = {
  terminal_buf = nil,
  terminal_chan = nil,
  source_buf = nil,
  sync_enabled = false,
  last_terminal_slide = nil, -- What presenterm is showing
  last_buffer_slide = nil, -- What buffer cursor is on
  is_syncing = false, -- Prevent sync loops
}

---Check if source buffer has frontmatter
---@return boolean
local function has_frontmatter()
  if not state.source_buf or not vim.api.nvim_buf_is_valid(state.source_buf) then
    return false
  end

  local lines = vim.api.nvim_buf_get_lines(state.source_buf, 0, 1, false)
  return lines[1] and lines[1]:match('^%-%-%-$') ~= nil
end

---Parse current slide number from terminal buffer
---@param buf number Terminal buffer
---@return number|nil Slide number or nil if not found
local function parse_slide_from_terminal(buf)
  -- Get all lines from terminal buffer
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  -- Presenterm shows slide number at bottom like "1 / 4"
  -- Search from bottom up for the most recent slide indicator
  for i = #lines, math.max(1, #lines - 30), -1 do
    local line = lines[i]
    -- Remove ANSI codes
    local cleaned = line:gsub('\27%[[0-9;]*m', '')
    -- Match patterns like "1 / 4"
    local current = cleaned:match('(%d+)%s*/%s*%d+')
    if current then
      local slide_num = tonumber(current)

      -- Adjust for frontmatter: presenterm generates slide 1 from frontmatter (unnumbered)
      -- and starts numbering at 2, but in markdown it's slide 1
      if has_frontmatter() then
        slide_num = slide_num - 1
        vim.notify(
          'Parsed slide: ' .. (slide_num + 1) .. ' -> adjusted to ' .. slide_num .. ' (frontmatter)',
          vim.log.levels.DEBUG
        )
      else
        vim.notify('Parsed slide: ' .. slide_num .. ' (no frontmatter)', vim.log.levels.DEBUG)
      end

      return slide_num
    end
  end

  return nil
end

---Check if sync should proceed
---@return boolean
local function should_sync()
  if not state.sync_enabled then
    return false
  end
  if not state.terminal_buf or not state.source_buf then
    return false
  end
  if not vim.api.nvim_buf_is_valid(state.terminal_buf) then
    state.sync_enabled = false
    return false
  end
  return true
end

---Navigate source window to slide
---@param slide_num number
local function navigate_to_slide(slide_num)
  local current_win = vim.api.nvim_get_current_win()
  local source_win = vim.fn.bufwinid(state.source_buf)

  if source_win ~= -1 then
    vim.api.nvim_set_current_win(source_win)
    require('presenterm.navigation').go_to_slide(slide_num)
    vim.api.nvim_set_current_win(current_win)
  end
end

---Sync buffer cursor to terminal's current slide (Terminal → Buffer)
local function sync_terminal_to_buffer()
  if not should_sync() or state.is_syncing then
    return
  end

  local current_slide = parse_slide_from_terminal(state.terminal_buf)
  if not current_slide or current_slide == state.last_terminal_slide then
    return
  end

  state.is_syncing = true
  state.last_terminal_slide = current_slide
  state.last_buffer_slide = current_slide

  navigate_to_slide(current_slide)

  vim.defer_fn(function()
    state.is_syncing = false
  end, 100)
end

---Sync buffer navigation to terminal (Buffer → Terminal)
local function sync_buffer_to_terminal()
  if not should_sync() or state.is_syncing then
    return
  end

  if not state.terminal_chan then
    return
  end

  local current_slide, _ = slides.get_current_slide()
  if current_slide == state.last_buffer_slide then
    return
  end

  state.is_syncing = true
  state.last_buffer_slide = current_slide
  state.last_terminal_slide = current_slide

  -- Adjust for frontmatter: presenterm numbers from 2 when frontmatter exists
  local presenterm_slide = current_slide
  if has_frontmatter() then
    presenterm_slide = current_slide + 1
  end

  -- Send direct jump command (e.g., "3G" to go to slide 3)
  vim.api.nvim_chan_send(state.terminal_chan, tostring(presenterm_slide) .. 'G')

  vim.defer_fn(function()
    state.is_syncing = false
  end, 100)
end

---Setup terminal monitoring (Terminal → Buffer)
local function setup_terminal_monitoring()
  if not state.terminal_buf or not vim.api.nvim_buf_is_valid(state.terminal_buf) then
    return
  end

  -- Monitor terminal buffer changes for Terminal → Buffer sync
  vim.api.nvim_buf_attach(state.terminal_buf, false, {
    on_lines = function()
      if state.sync_enabled then
        -- Debounce: schedule sync for next tick
        vim.schedule(function()
          sync_terminal_to_buffer()
        end)
      end
    end,
    on_detach = function()
      -- Clean up when terminal is closed
      state.sync_enabled = false
      state.terminal_buf = nil
      state.terminal_chan = nil
    end,
  })
end

---Setup buffer monitoring (Buffer → Terminal)
local function setup_buffer_monitoring()
  if not state.source_buf or not vim.api.nvim_buf_is_valid(state.source_buf) then
    return
  end

  -- Monitor cursor movement in source buffer for Buffer → Terminal sync
  vim.api.nvim_create_autocmd('CursorMoved', {
    buffer = state.source_buf,
    callback = function()
      if state.sync_enabled then
        sync_buffer_to_terminal()
      end
    end,
    desc = 'Sync presenterm to buffer cursor position',
  })
end

---Launch presenterm preview
function M.preview()
  local file = vim.fn.expand('%:p')
  if not file:match('%.md$') then
    vim.notify('Not a markdown file', vim.log.levels.ERROR)
    return
  end

  -- Save the file first
  vim.cmd('write')

  local cfg = config.get()

  -- Store source buffer
  state.source_buf = vim.api.nvim_get_current_buf()

  -- Launch in neovim terminal (vertical split)
  local shell = vim.o.shell or '/bin/bash'
  local cmd

  if cfg.preview.login_shell then
    -- Use interactive login shell to load full environment (KUBECONFIG, PATH, etc.)
    cmd = string.format('%s -lic "%s %s"', shell, cfg.preview.command, vim.fn.shellescape(file))
  else
    -- Direct execution (faster but env may not be loaded)
    cmd = string.format('%s %s', cfg.preview.command, vim.fn.shellescape(file))
  end

  vim.cmd('vsplit | terminal ' .. cmd)

  -- Store terminal buffer and channel
  state.terminal_buf = vim.api.nvim_get_current_buf()
  state.terminal_chan = vim.bo[state.terminal_buf].channel

  -- Enable sync if configured
  if cfg.preview.presentation_preview_sync then
    state.sync_enabled = true
    state.last_terminal_slide = nil
    state.last_buffer_slide = nil
    setup_terminal_monitoring() -- Terminal → Buffer
    setup_buffer_monitoring() -- Buffer → Terminal
    vim.notify('Bi-directional sync enabled', vim.log.levels.INFO)
  end

  vim.cmd('startinsert')
end

---Toggle bi-directional sync
function M.toggle_sync()
  state.sync_enabled = not state.sync_enabled
  if state.sync_enabled then
    vim.notify('Bi-directional sync enabled', vim.log.levels.INFO)
    setup_terminal_monitoring()
    setup_buffer_monitoring()
  else
    vim.notify('Bi-directional sync disabled', vim.log.levels.INFO)
  end
end

---Get sync state (for debugging)
function M.get_sync_state()
  return {
    enabled = state.sync_enabled,
    terminal_buf = state.terminal_buf,
    source_buf = state.source_buf,
    last_terminal_slide = state.last_terminal_slide,
    last_buffer_slide = state.last_buffer_slide,
    is_syncing = state.is_syncing,
  }
end

---Print terminal buffer lines with slide pattern detection
---@param lines table
local function print_terminal_lines(lines)
  print('\nLast 30 lines (cleaned):')
  for i = math.max(1, #lines - 30), #lines do
    local cleaned = lines[i]:gsub('\27%[[0-9;]*m', '')
    if cleaned:match('%S') then
      print(i .. ': ' .. cleaned)
      local match = cleaned:match('(%d+)%s*/%s*%d+')
      if match then
        print('     ^^^ MATCHES SLIDE PATTERN: ' .. match)
      end
    end
  end
end

---Print debug summary
---@param slide_num number|nil
local function print_debug_summary(slide_num)
  print('\n=== RESULT ===')
  print('Parsed slide number: ' .. (slide_num or 'nil'))
  print('Has frontmatter: ' .. tostring(has_frontmatter()))
  print('Sync enabled: ' .. tostring(state.sync_enabled))
end

---Debug: Print terminal buffer content
function M.debug_terminal_buffer()
  if not state.terminal_buf or not vim.api.nvim_buf_is_valid(state.terminal_buf) then
    vim.notify('No valid terminal buffer', vim.log.levels.ERROR)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(state.terminal_buf, 0, -1, false)
  print('Terminal buffer has ' .. #lines .. ' lines')

  print_terminal_lines(lines)

  local slide_num = parse_slide_from_terminal(state.terminal_buf)
  print_debug_summary(slide_num)
end

---Count presentation content
---@param lines table
---@return table
local function count_presentation_content(lines)
  local counts = {
    words = 0,
    code_blocks = 0,
    exec_blocks = 0,
    partial_includes = 0,
  }

  for _, line in ipairs(lines) do
    if line:match('^```') then
      counts.code_blocks = counts.code_blocks + 1
      if line:match('%+exec') then
        counts.exec_blocks = counts.exec_blocks + 1
      end
    elseif line:match('<!%-%- include: .+ %-%->') then
      counts.partial_includes = counts.partial_includes + 1
    else
      for _ in line:gmatch('%S+') do
        counts.words = counts.words + 1
      end
    end
  end

  return counts
end

---Generate stats text
---@param total_slides number
---@param counts table
---@return table
local function generate_stats_text(total_slides, counts)
  local speaking_time = math.ceil(counts.words / 150)
  local demo_time = counts.exec_blocks * 0.5
  local total_time = speaking_time + demo_time

  return {
    string.format('Slides: %d', total_slides),
    string.format('Words: %d', counts.words),
    string.format('Code blocks: %d (%d executable)', counts.code_blocks, counts.exec_blocks),
    string.format('Partial includes: %d', counts.partial_includes),
    string.format('Estimated time: %d minutes', total_time),
    '',
    'Time breakdown:',
    string.format('  Speaking: %d min (at 150 wpm)', speaking_time),
    string.format('  Demos: %.1f min (30s per exec block)', demo_time),
  }
end

---Create and show stats floating window
---@param stats table
local function show_stats_window(stats)
  local width = math.min(50, vim.o.columns - 4)
  local height = math.min(#stats + 2, vim.o.lines - 4)

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
    title = ' Presentation Statistics ',
    title_pos = 'center',
  }

  vim.api.nvim_open_win(buf, true, win_opts)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, stats)
  vim.bo[buf].modifiable = false

  vim.keymap.set('n', '<Esc>', ':close<CR>', { buffer = buf, silent = true })
  vim.keymap.set('n', 'q', ':close<CR>', { buffer = buf, silent = true })
end

---Count slides and estimate time
function M.presentation_stats()
  local _, positions = slides.get_current_slide()
  local total_slides = #positions - 1
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  local counts = count_presentation_content(lines)
  local stats = generate_stats_text(total_slides, counts)
  show_stats_window(stats)
end

return M
