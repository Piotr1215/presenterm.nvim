local M = {}

---Determine the next state in the toggle cycle
---@param code_fence string The code fence line
---@return string The next state in the cycle
local function get_next_exec_state(code_fence)
  -- Preserve +id: and custom executors (e.g., +exec:rust-script)
  local has_id = code_fence:match('%+id:')
  local custom_executor = code_fence:match('%+exec:(%S+)')

  -- If has +id: or custom executor, never return to plain
  local can_return_to_plain = not (has_id or custom_executor)

  -- Detect current state
  local has_exec = code_fence:match('%+exec')
  local has_exec_replace = code_fence:match('%+exec_replace')
  local has_acquire_terminal = code_fence:match('%+acquire_terminal')

  if has_exec_replace then
    -- State: +exec_replace -> +exec +acquire_terminal
    -- Remove +exec_replace, add +exec and +acquire_terminal
    local new_fence = code_fence:gsub(' %+exec_replace', ' +exec +acquire_terminal')
    return new_fence
  elseif has_exec and has_acquire_terminal then
    -- State: +exec +acquire_terminal -> plain (or +exec if can't return to plain)
    if can_return_to_plain then
      -- Remove all exec-related flags
      local new_fence = code_fence
      new_fence = new_fence:gsub(' %+exec[^%s]*', '')
      new_fence = new_fence:gsub(' %+acquire_terminal', '')
      return new_fence
    else
      -- Cycle back to +exec (preserving +id: or custom executor)
      local new_fence = code_fence:gsub(' %+acquire_terminal', '')
      return new_fence
    end
  elseif has_exec then
    -- State: +exec (or +exec:custom) -> +exec_replace
    -- For custom executors, we can't use +exec_replace, so cycle to +exec +acquire_terminal
    if custom_executor then
      -- Custom executors don't support +exec_replace, go directly to +exec +acquire_terminal
      local new_fence = code_fence .. ' +acquire_terminal'
      return new_fence
    else
      -- Regular +exec -> +exec_replace
      local new_fence = code_fence:gsub(' %+exec', ' +exec_replace')
      return new_fence
    end
  else
    -- State: plain -> +exec
    return code_fence .. ' +exec'
  end
end

---Toggle +exec flag on code block following the cycle:
---plain -> +exec -> +exec_replace -> +exec +acquire_terminal -> plain
---If +id: or custom executor is present, cycle stays within exec states
function M.toggle_exec()
  local cursor_line = vim.fn.line('.')
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  -- Find code block boundaries
  local start_line = nil
  local end_line = nil

  -- Search backwards for code block start
  for i = cursor_line, 1, -1 do
    if lines[i] and lines[i]:match('^```') then
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
    if i > start_line and lines[i] and lines[i]:match('^```') then
      end_line = i
      break
    end
  end

  -- If no end found, not in a valid code block
  if not end_line then
    vim.notify('Code block not properly closed', vim.log.levels.WARN)
    return
  end

  -- Get the next state
  local code_fence = lines[start_line]
  local new_fence = get_next_exec_state(code_fence)

  vim.fn.setline(start_line, new_fence)
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
