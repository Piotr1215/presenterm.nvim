local M = {}

---Toggle +exec flag on code block
function M.toggle_exec()
  local cursor_line = vim.fn.line('.')
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  -- Find code block boundaries
  local start_line = nil
  local end_line = nil

  -- Search backwards for code block start
  for i = cursor_line, 1, -1 do
    if lines[i]:match('^```') then
      start_line = i
      break
    end
  end

  -- If no start found, not in a code block
  if not start_line then
    vim.notify('Not inside a code block', vim.log.levels.WARN)
    return
  end

  -- Search forwards for code block end
  for i = cursor_line, #lines do
    if i > start_line and lines[i]:match('^```') then
      end_line = i
      break
    end
  end

  -- If no end found, not in a valid code block
  if not end_line then
    vim.notify('Code block not properly closed', vim.log.levels.WARN)
    return
  end

  -- Now we know we're inside a code block, toggle the +exec flag
  local code_fence = lines[start_line]
  if code_fence:match('%+exec') then
    -- Remove +exec flags
    code_fence = code_fence:gsub(' %+exec%w*', '')
  else
    -- Add +exec flag
    code_fence = code_fence .. ' +exec'
  end

  vim.fn.setline(start_line, code_fence)
  vim.notify(
    code_fence:match('%+exec') and 'Added +exec flag' or 'Removed +exec flag',
    vim.log.levels.INFO
  )
end

---Run current code block (if it has +exec)
function M.run_code_block()
  local cursor_line = vim.fn.line('.')
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  -- Find code block boundaries
  local start_line = nil
  local end_line = nil
  local lang = nil

  -- Search backwards for code block start
  for i = cursor_line, 1, -1 do
    if lines[i]:match('^```') then
      start_line = i
      lang = lines[i]:match('^```(%w+)')
      break
    end
  end

  if not start_line then
    vim.notify('Not inside a code block', vim.log.levels.WARN)
    return
  end

  -- Check if it has +exec
  if not lines[start_line]:match('%+exec') then
    vim.notify("Code block doesn't have +exec flag", vim.log.levels.WARN)
    return
  end

  -- Find code block end
  for i = start_line + 1, #lines do
    if lines[i]:match('^```') then
      end_line = i
      break
    end
  end

  if not end_line then
    vim.notify('Code block not properly closed', vim.log.levels.WARN)
    return
  end

  -- Extract code
  local code_lines = {}
  for i = start_line + 1, end_line - 1 do
    table.insert(code_lines, lines[i])
  end

  -- Execute based on language
  if lang == 'bash' or lang == 'sh' then
    -- Create a temporary file
    local tmpfile = vim.fn.tempname() .. '.sh'
    vim.fn.writefile(code_lines, tmpfile)

    -- Execute in a new terminal
    vim.cmd('split | terminal bash ' .. tmpfile)
    vim.cmd('resize 15')
  elseif lang == 'python' then
    -- Create a temporary file
    local tmpfile = vim.fn.tempname() .. '.py'
    vim.fn.writefile(code_lines, tmpfile)

    -- Execute in a new terminal
    vim.cmd('split | terminal python ' .. tmpfile)
    vim.cmd('resize 15')
  elseif lang == 'lua' then
    -- Create a temporary file
    local tmpfile = vim.fn.tempname() .. '.lua'
    vim.fn.writefile(code_lines, tmpfile)

    -- Execute in a new terminal
    vim.cmd('split | terminal nvim -l ' .. tmpfile)
    vim.cmd('resize 15')
  else
    vim.notify('Execution not supported for language: ' .. (lang or 'unknown'), vim.log.levels.WARN)
  end
end

return M
