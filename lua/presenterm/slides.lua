local M = {}

local config = require('presenterm.config')

-- Constants
local SLIDE_PATTERN = '<!%-%- end_slide %-%->'

---Get frontmatter end line
---@return number Line number where frontmatter ends (0 if no frontmatter)
function M.get_frontmatter_end()
  local lines = vim.api.nvim_buf_get_lines(0, 0, math.min(50, vim.fn.line('$')), false)

  if lines[1] and lines[1]:match('^%-%-%-') then
    for i = 2, #lines do
      if lines[i]:match('^%-%-%-') then
        return i
      end
    end
  end

  return 0
end

---Get all slide positions in buffer
---@return table Array of slide boundary line numbers
function M.get_slide_positions()
  local positions = {}
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local frontmatter_end = M.get_frontmatter_end()

  -- Start after frontmatter if it exists
  table.insert(positions, frontmatter_end)

  for i, line in ipairs(lines) do
    if line:match(SLIDE_PATTERN) and i > frontmatter_end then
      table.insert(positions, i)
    end
  end

  -- Add end of buffer as end of last slide
  table.insert(positions, #lines + 1)

  return positions
end

---Get current slide number and positions
---@return number Current slide number
---@return table All slide positions
function M.get_current_slide()
  local cursor_line = vim.fn.line('.')
  local positions = M.get_slide_positions()

  for i = 1, #positions - 1 do
    if cursor_line <= positions[i + 1] then
      return i, positions
    end
  end

  return #positions - 1, positions
end

---Check if file is a presentation
---@return boolean
function M.is_presentation()
  -- Check for slide markers in the file
  local lines = vim.api.nvim_buf_get_lines(0, 0, math.min(100, vim.fn.line('$')), false)
  for _, line in ipairs(lines) do
    if line:match(SLIDE_PATTERN) then
      return true
    end
  end

  -- Check for presenterm front matter
  if lines[1] and lines[1]:match('^%-%-%-') then
    for i = 2, math.min(20, #lines) do
      if lines[i]:match('^%-%-%-') then
        break
      end
      if lines[i]:match('^title:') or lines[i]:match('^author:') then
        return true
      end
    end
  end

  return false
end

---Create new slide after current
function M.new_slide()
  local current, positions = M.get_current_slide()
  local insert_line = positions[current + 1] - 1

  -- If we're at the last slide, insert at the end
  if current == #positions - 1 then
    insert_line = vim.fn.line('$')
  end

  local cfg = config.get()
  -- Insert empty lines and slide marker
  local new_content = { '', '', '', cfg.slide_marker }
  vim.fn.append(insert_line, new_content)

  -- Move cursor to the second empty line (ready to type)
  vim.fn.cursor(insert_line + 2, 1)
  vim.cmd('startinsert')
end

---Split slide at cursor position
function M.split_slide()
  local cursor_line = vim.fn.line('.')
  local cfg = config.get()

  -- Insert slide marker above current line
  vim.fn.append(cursor_line - 1, { '', cfg.slide_marker, '' })

  -- Move cursor to stay in the same relative position
  vim.fn.cursor(cursor_line + 3, 1)
end

---Delete current slide
function M.delete_slide()
  local current, positions = M.get_current_slide()
  local total_slides = #positions - 1
  local frontmatter_end = M.get_frontmatter_end()

  if total_slides == 1 then
    vim.notify('Cannot delete the only slide', vim.log.levels.WARN)
    return
  end

  -- Don't delete frontmatter
  local start_line = positions[current]
  local end_line = positions[current + 1]

  -- If it's the first slide, start after the frontmatter
  if current == 1 then
    start_line = frontmatter_end
  else
    start_line = start_line + 1
  end

  -- Move cursor to the start of the slide
  vim.fn.cursor(start_line + 1, 1)

  -- Calculate number of lines to delete
  local lines_to_delete = end_line - start_line

  -- Delete using dd command (into registers)
  if lines_to_delete > 0 then
    vim.cmd('normal! ' .. lines_to_delete .. 'dd')
  end

  -- Move to appropriate slide
  if current == total_slides then
    require('presenterm.navigation').previous_slide()
  else
    -- Stay on current slide number (which is now the next slide)
    require('presenterm.navigation').go_to_slide(current)
  end
end

---Yank current slide
function M.yank_slide()
  local current, positions = M.get_current_slide()
  local frontmatter_end = M.get_frontmatter_end()
  local total_slides = #positions - 1

  -- Calculate slide boundaries
  local start_line = positions[current] + 1
  local end_line = positions[current + 1] -- Include the slide marker

  -- For first slide, skip content before first header
  if current == 1 and start_line <= frontmatter_end + 1 then
    -- Find first header after frontmatter
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    for i = frontmatter_end + 1, end_line - 1 do
      if i <= #lines and lines[i]:match('^#+ ') then
        start_line = i
        break
      end
    end
  end

  -- For last slide, don't include the final buffer position
  if current == total_slides then
    end_line = positions[current + 1] - 1
  end

  -- Save current cursor position
  local save_cursor = vim.fn.getpos('.')

  -- Move cursor to the start of the slide
  vim.fn.cursor(start_line, 1)

  -- Calculate number of lines to yank (including the marker)
  local lines_to_yank = end_line - start_line + 1

  -- Yank using yy command (into registers)
  if lines_to_yank > 0 then
    vim.cmd('normal! ' .. lines_to_yank .. 'yy')
    vim.notify('Slide yanked (' .. lines_to_yank .. ' lines)', vim.log.levels.INFO)
  end

  -- Return cursor to original position
  vim.fn.setpos('.', save_cursor)
end

---Visually select current slide
function M.select_slide()
  local current, positions = M.get_current_slide()
  local frontmatter_end = M.get_frontmatter_end()
  local total_slides = #positions - 1

  -- Calculate slide boundaries
  local start_line = positions[current] + 1
  local end_line = positions[current + 1]

  -- For first slide, skip content before first header
  if current == 1 and start_line <= frontmatter_end + 1 then
    -- Find first header after frontmatter
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    for i = frontmatter_end + 1, end_line - 1 do
      if i <= #lines and lines[i]:match('^#+ ') then
        start_line = i
        break
      end
    end
  end

  -- For last slide, don't go beyond the file
  if current == total_slides then
    end_line = math.min(positions[current + 1], vim.fn.line('$'))
  end

  -- Move cursor to start of slide
  vim.fn.cursor(start_line, 1)

  -- Enter visual line mode
  vim.cmd('normal! V')

  -- Move to end of slide (including the marker)
  vim.fn.cursor(end_line, 1)
end

---Get slide content
---@param slide_num number Slide number
---@param positions table Slide positions
---@param skip_pre_header boolean Skip content before first header
---@return table Lines of the slide
function M.get_slide_content(slide_num, positions, skip_pre_header)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local frontmatter_end = M.get_frontmatter_end()
  local start_line = positions[slide_num] + 1
  local end_line = positions[slide_num + 1]

  -- For first slide, optionally skip content before first header
  if skip_pre_header and slide_num == 1 and start_line <= frontmatter_end + 1 then
    -- Find first header after frontmatter
    for i = frontmatter_end + 1, end_line - 1 do
      if i <= #lines and lines[i]:match('^#+ ') then
        start_line = i
        break
      end
    end
  end

  local slide_lines = {}
  for i = start_line, end_line - 1 do
    if i <= #lines then
      table.insert(slide_lines, lines[i])
    end
  end

  -- Remove the slide marker from the end if present
  if #slide_lines > 0 and slide_lines[#slide_lines]:match(SLIDE_PATTERN) then
    table.remove(slide_lines)
  end

  -- Trim trailing empty lines
  while #slide_lines > 0 and slide_lines[#slide_lines] == '' do
    table.remove(slide_lines)
  end

  return slide_lines
end

---Move slide up
function M.move_slide_up()
  local current, positions = M.get_current_slide()

  if current == 1 then
    vim.notify('Already at the first slide', vim.log.levels.WARN)
    return
  end

  -- Get content of current and previous slides
  local current_content = M.get_slide_content(current, positions, current == 1)
  local prev_content = M.get_slide_content(current - 1, positions, current - 1 == 1)

  -- Calculate line ranges
  local prev_start = positions[current - 1] + 1
  local current_end = positions[current + 1] - 1

  local cfg = config.get()
  -- Build new content: current, marker, previous
  local new_content = {}
  vim.list_extend(new_content, current_content)
  table.insert(new_content, '')
  table.insert(new_content, cfg.slide_marker)
  table.insert(new_content, '')
  vim.list_extend(new_content, prev_content)

  -- Replace the two slides
  vim.api.nvim_buf_set_lines(0, prev_start - 1, current_end, false, new_content)

  -- Move cursor to the new position of the current slide
  require('presenterm.navigation').previous_slide()
end

---Move slide down
function M.move_slide_down()
  local current, positions = M.get_current_slide()
  local total_slides = #positions - 1

  if current == total_slides then
    vim.notify('Already at the last slide', vim.log.levels.WARN)
    return
  end

  -- Get content of current and next slides
  local current_content = M.get_slide_content(current, positions, current == 1)
  local next_content = M.get_slide_content(current + 1, positions, false)

  -- Calculate line ranges
  local current_start = positions[current] + 1
  local next_end = positions[current + 2] - 1

  local cfg = config.get()
  -- Build new content: next, marker, current
  local new_content = {}
  vim.list_extend(new_content, next_content)
  table.insert(new_content, '')
  table.insert(new_content, cfg.slide_marker)
  table.insert(new_content, '')
  vim.list_extend(new_content, current_content)

  -- Replace the two slides
  vim.api.nvim_buf_set_lines(0, current_start - 1, next_end, false, new_content)

  -- Move cursor to the new position of the current slide
  require('presenterm.navigation').next_slide()
end

---Interactive slide reordering
function M.interactive_reorder()
  local original_buf = vim.api.nvim_get_current_buf()
  local positions = M.get_slide_positions()
  local slides = {}
  local frontmatter_end = M.get_frontmatter_end()
  local cfg = config.get()

  -- Get all slides content
  for i = 1, #positions - 1 do
    local slide_content = M.get_slide_content(i, positions, false)
    local title = string.format('Slide %d', i)

    -- Find title in slide content
    for _, line in ipairs(slide_content) do
      if line:match('^#+ ') then
        title = line:gsub('^#+ ', '')
        break
      end
    end

    table.insert(slides, {
      index = i,
      title = title,
      content = slide_content,
    })
  end

  -- Create reorder buffer
  vim.cmd('new')
  local reorder_buf = vim.api.nvim_get_current_buf()
  vim.bo[reorder_buf].filetype = 'presenterm-reorder'
  vim.bo[reorder_buf].buftype = 'nofile'
  vim.bo[reorder_buf].bufhidden = 'wipe'
  vim.bo[reorder_buf].modifiable = true

  -- Display slides
  local display_lines = {
    '# Slide Reordering Mode',
    '# Use dd/p to move slides, Enter or :Apply to save, :q to cancel',
    '',
  }

  for _, slide in ipairs(slides) do
    table.insert(display_lines, string.format('%d. %s', slide.index, slide.title))
  end

  vim.api.nvim_buf_set_lines(reorder_buf, 0, -1, false, display_lines)

  -- Store original data
  vim.b[reorder_buf].original_buf = original_buf
  vim.b[reorder_buf].slides = slides
  vim.b[reorder_buf].frontmatter_end = frontmatter_end

  -- Apply reordering function
  local function apply_reorder()
    local lines = vim.api.nvim_buf_get_lines(reorder_buf, 0, -1, false)
    local new_order = {}

    -- Parse the new order
    for _, line in ipairs(lines) do
      local num = line:match('^(%d+)%.')
      if num then
        table.insert(new_order, tonumber(num))
      end
    end

    if #new_order ~= #slides then
      vim.notify('Error: Slide count mismatch', vim.log.levels.ERROR)
      return
    end

    -- Rebuild the presentation
    local all_lines = vim.api.nvim_buf_get_lines(original_buf, 0, -1, false)
    local new_lines = {}

    -- Add frontmatter if exists
    if frontmatter_end > 0 then
      for i = 1, frontmatter_end do
        table.insert(new_lines, all_lines[i])
      end
      table.insert(new_lines, '')
    end

    -- Add slides in new order
    for i, slide_idx in ipairs(new_order) do
      local slide = slides[slide_idx]
      vim.list_extend(new_lines, slide.content)

      -- Add slide marker if not the last slide
      if i < #new_order then
        table.insert(new_lines, '')
        table.insert(new_lines, cfg.slide_marker)
        table.insert(new_lines, '')
      end
    end

    -- Apply changes
    vim.api.nvim_buf_set_lines(original_buf, 0, -1, false, new_lines)
    vim.notify('Slides reordered successfully', vim.log.levels.INFO)
    vim.cmd('close')
  end

  -- Create custom commands for this buffer
  vim.api.nvim_buf_create_user_command(reorder_buf, 'Apply', function()
    apply_reorder()
  end, { desc = 'Apply slide reordering' })

  -- Keybindings
  vim.keymap.set('n', '<CR>', function()
    apply_reorder()
  end, { buffer = reorder_buf, desc = 'Apply reordering' })

  vim.keymap.set('n', '?', function()
    vim.notify(
      'Slide Reordering:\n'
        .. '• dd       - cut slide\n'
        .. '• p        - paste slide below\n'
        .. '• P        - paste slide above\n'
        .. '• Enter    - apply changes\n'
        .. '• :Apply   - apply changes\n'
        .. '• :q       - cancel',
      vim.log.levels.INFO
    )
  end, { buffer = reorder_buf, desc = 'Show help' })
end

return M
