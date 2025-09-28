local M = {}

local slides = require('presenterm.slides')
local partials = require('presenterm.partials')

---Go to specific slide
---@param slide_num number Slide number to go to
function M.go_to_slide(slide_num)
  local _, positions = slides.get_current_slide()
  local total_slides = #positions - 1

  if slide_num < 1 then
    slide_num = 1
  elseif slide_num > total_slides then
    slide_num = total_slides
  end

  -- Move cursor to first line of the slide
  local target_line = positions[slide_num] + 1
  if target_line > vim.fn.line('$') then
    target_line = vim.fn.line('$')
  end

  -- Look for a header in the first few lines of the slide
  local lines = vim.api.nvim_buf_get_lines(
    0,
    target_line - 1,
    math.min(target_line + 10, vim.fn.line('$')),
    false
  )
  for i, line in ipairs(lines) do
    if line:match('^#+ ') or (i < #lines and lines[i + 1]:match('^=+$')) then
      target_line = target_line + i - 1
      break
    end
  end

  vim.fn.cursor(target_line, 1)
  vim.cmd('normal! zz') -- Center the view
end

---Navigate to next slide
function M.next_slide()
  local current, _ = slides.get_current_slide()
  M.go_to_slide(current + 1)
end

---Navigate to previous slide
function M.previous_slide()
  local current, _ = slides.get_current_slide()
  M.go_to_slide(current - 1)
end

---Show slide count in statusline
---@return string Status string
function M.slide_status()
  local current, positions = slides.get_current_slide()
  local total = #positions - 1
  return string.format('[Slide %d/%d]', current, total)
end

---Extract title from lines
---@param lines table Lines to search
---@param start_idx number|nil Starting index
---@return string|nil Title or nil if not found
local function extract_title_from_lines(lines, start_idx)
  for i = start_idx or 1, math.min(#lines, 10) do
    local line = lines[i]
    if line:match('^#+ ') then
      return line:gsub('^#+ ', '')
    elseif i < #lines and lines[i + 1] and lines[i + 1]:match('^=+$') then
      return line
    end
  end
  return nil
end

---Process partial content for title and preview
---@param partial_content table|nil Partial file lines
---@param title string|nil Current title
---@param preview_lines table Preview lines array
---@return string|nil Updated title
---@return table Updated preview lines
local function process_partial(partial_content, title, preview_lines)
  if not partial_content then
    return title, preview_lines
  end

  -- Try to find title in partial
  if not title then
    title = extract_title_from_lines(partial_content)
  end

  -- Add preview lines from partial
  for _, partial_line in ipairs(partial_content) do
    if partial_line:match('%S') and #preview_lines < 3 then
      table.insert(preview_lines, partial_line)
    end
  end

  return title, preview_lines
end

---Process regular line for title and preview
---@param line string Current line
---@param next_line string|nil Next line (for setext headers)
---@param title string|nil Current title
---@param preview_lines table Preview lines array
---@return string|nil Updated title
---@return table Updated preview lines
local function process_regular_line(line, next_line, title, preview_lines)
  -- Check for title
  if not title then
    if line:match('^#+ ') then
      title = line:gsub('^#+ ', '')
    elseif next_line and next_line:match('^=+$') then
      title = line
    end
  end

  -- Collect preview lines
  if line:match('%S') and #preview_lines < 5 then
    table.insert(preview_lines, line)
  end

  return title, preview_lines
end

---Process slide content for title and preview
---@param lines table Buffer lines
---@param start_line number Start line of slide
---@param end_line number End line of slide
---@return string|nil Title
---@return table Preview lines
local function process_slide_content(lines, start_line, end_line)
  local title = nil
  local preview_lines = {}
  local search_end = math.min(end_line - 1, start_line + 10)

  for j = start_line, search_end do
    if j > #lines then
      break
    end

    local line = lines[j]
    local partial_content = partials.expand_partial_content(line)

    if partial_content then
      title, preview_lines = process_partial(partial_content, title, preview_lines)
    else
      local next_line = (j < #lines) and lines[j + 1] or nil
      title, preview_lines = process_regular_line(line, next_line, title, preview_lines)
    end

    -- Stop if we have both title and enough preview
    if title and #preview_lines >= 3 then
      break
    end
  end

  return title, preview_lines
end

---Get slide titles for all slides (with partial support)
---@return table Array of slide info with titles
function M.get_slide_titles()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local positions = slides.get_slide_positions()
  local slide_list = {}

  for i = 1, #positions - 1 do
    local start_line = positions[i] + 1
    local end_line = positions[i + 1]

    local title, preview_lines = process_slide_content(lines, start_line, end_line)
    title = title or string.format('Slide %d', i)

    table.insert(slide_list, {
      index = i,
      title = title,
      start_line = start_line,
      preview = table.concat(preview_lines, ' '):sub(1, 80) .. '...',
    })
  end

  return slide_list
end

return M
