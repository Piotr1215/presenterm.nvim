local M = {}

local config = require('presenterm.config')

---Expand partial include directives
---@param line string Line to check for partial include
---@return table|nil Partial file lines or nil if not a partial
function M.expand_partial_content(line)
  local partial_path = line:match('<!%-%- include: (.+) %-%->')
  if not partial_path then
    return nil
  end

  -- Trim whitespace from partial path
  partial_path = partial_path:match('^%s*(.-)%s*$')

  -- Get current file directory
  local current_file = vim.fn.expand('%:p')
  local current_dir = vim.fn.fnamemodify(current_file, ':h')

  -- Resolve the partial path relative to current file
  local full_path = vim.fn.simplify(current_dir .. '/' .. partial_path)

  -- Check if file exists
  if vim.fn.filereadable(full_path) ~= 1 then
    return nil
  end

  -- Read the partial file
  local partial_lines = vim.fn.readfile(full_path)
  return partial_lines
end

---Get path to partial file from include directive
---@param line string Line containing the include directive
---@return string|nil Full path to partial file
function M.get_partial_path(line)
  local partial_path = line:match('<!%-%- include: (.+) %-%->')
  if not partial_path then
    return nil
  end

  -- Trim whitespace
  partial_path = partial_path:match('^%s*(.-)%s*$')

  -- Get current file directory
  local current_file = vim.fn.expand('%:p')
  local current_dir = vim.fn.fnamemodify(current_file, ':h')

  -- Resolve the partial path
  local full_path = vim.fn.simplify(current_dir .. '/' .. partial_path)

  if vim.fn.filereadable(full_path) == 1 then
    return full_path
  end

  return nil
end

---Find all partial files in the configured directory
---@return table List of partial file info
function M.find_partials()
  local cfg = config.get()

  -- Find _partials directory relative to current file's git root
  local git_root = vim.fn.system('git rev-parse --show-toplevel 2>/dev/null'):gsub('\n', '')
  if git_root == '' then
    return {}
  end

  local partials_dir = git_root .. '/' .. cfg.partials.directory
  if vim.fn.isdirectory(partials_dir) ~= 1 then
    return {}
  end

  -- Get all markdown files in _partials
  local partial_files = vim.fn.glob(partials_dir .. '/*.md', false, true)
  local entries = {}

  for _, filepath in ipairs(partial_files) do
    local filename = vim.fn.fnamemodify(filepath, ':t')
    local name_without_ext = vim.fn.fnamemodify(filename, ':r')

    -- Read first few lines for preview
    local preview_lines = {}
    local file = io.open(filepath, 'r')
    if file then
      local count = 0
      for line in file:lines() do
        if count >= 20 then
          break
        end
        table.insert(preview_lines, line)
        count = count + 1
      end
      file:close()
    end

    -- Extract title from content
    local title = name_without_ext
    for _, line in ipairs(preview_lines) do
      if line:match('^#+ ') then
        title = line:gsub('^#+ ', '')
        break
      end
    end

    table.insert(entries, {
      filename = filename,
      name = name_without_ext,
      title = title,
      path = filepath,
      relative_path = '../' .. cfg.partials.directory .. '/' .. filename,
      preview = table.concat(preview_lines, ' '):sub(1, 100),
      preview_lines = preview_lines,
    })
  end

  return entries
end

---Insert partial include directive at cursor
---@param relative_path string Relative path to the partial
function M.insert_partial_include(relative_path)
  local include_line = '<!-- include: ' .. relative_path .. ' -->'
  vim.api.nvim_put({ include_line }, '', true, true)
end

---Open partial file for editing
---@param path string Full path to the partial file
function M.edit_partial(path)
  if vim.fn.filereadable(path) == 1 then
    vim.cmd('edit ' .. vim.fn.fnameescape(path))
  else
    vim.notify('Partial file not found: ' .. path, vim.log.levels.ERROR)
  end
end

---Check if current line is a partial include
---@return boolean
function M.is_partial_include()
  local line = vim.api.nvim_get_current_line()
  return line:match('<!%-%- include: .+ %-%->') ~= nil
end

---Open partial from current line
function M.open_partial_at_cursor()
  local line = vim.api.nvim_get_current_line()
  local path = M.get_partial_path(line)
  if path then
    M.edit_partial(path)
  else
    vim.notify('Not on a partial include line', vim.log.levels.WARN)
  end
end

return M
