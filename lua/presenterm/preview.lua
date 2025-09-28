local M = {}

local config = require('presenterm.config')
local slides = require('presenterm.slides')

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

  -- Launch in neovim terminal (vertical split)
  vim.cmd(string.format('vsplit | terminal %s %s', cfg.preview.command, file))
end

---Count slides and estimate time
function M.presentation_stats()
  local _, positions = slides.get_current_slide()
  local total_slides = #positions - 1
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  local word_count = 0
  local code_blocks = 0
  local exec_blocks = 0
  local partial_includes = 0

  for _, line in ipairs(lines) do
    -- Count code blocks
    if line:match('^```') then
      code_blocks = code_blocks + 1
      if line:match('%+exec') then
        exec_blocks = exec_blocks + 1
      end
    -- Count partial includes
    elseif line:match('<!%-%- include: .+ %-%->') then
      partial_includes = partial_includes + 1
    else
      -- Simple word count
      for _ in line:gmatch('%S+') do
        word_count = word_count + 1
      end
    end
  end

  -- Rough estimates
  local speaking_time = math.ceil(word_count / 150) -- 150 words per minute
  local demo_time = exec_blocks * 0.5 -- 30 seconds per exec block
  local total_time = speaking_time + demo_time

  local stats = {
    string.format('Slides: %d', total_slides),
    string.format('Words: %d', word_count),
    string.format('Code blocks: %d (%d executable)', code_blocks, exec_blocks),
    string.format('Partial includes: %d', partial_includes),
    string.format('Estimated time: %d minutes', total_time),
    '',
    'Time breakdown:',
    string.format('  Speaking: %d min (at 150 wpm)', speaking_time),
    string.format('  Demos: %.1f min (30s per exec block)', demo_time),
  }

  -- Create floating window for stats
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

  -- Close on any key
  vim.keymap.set('n', '<Esc>', ':close<CR>', { buffer = buf, silent = true })
  vim.keymap.set('n', 'q', ':close<CR>', { buffer = buf, silent = true })
end

return M
