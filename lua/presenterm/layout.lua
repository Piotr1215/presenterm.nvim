local M = {}

local config = require('presenterm.config')

---Default layout templates
---Each template has: name (display name) and dimensions (array of column widths)
local default_templates = {
  ['50/50'] = { name = 'Two Column (50/50)', dimensions = { 1, 1 } },
  ['60/40'] = { name = 'Two Column (60/40)', dimensions = { 3, 2 } },
  ['70/30'] = { name = 'Two Column (70/30)', dimensions = { 7, 3 } },
  ['33/33/33'] = { name = 'Three Column (33/33/33)', dimensions = { 1, 1, 1 } },
  ['50/25/25'] = { name = 'Three Column (50/25/25)', dimensions = { 2, 1, 1 } },
  ['20/60/20'] = { name = 'Centered Content (20/60/20)', dimensions = { 1, 3, 1 } },
  ['25/75'] = { name = 'Sidebar Left (25/75)', dimensions = { 1, 3 } },
  ['75/25'] = { name = 'Sidebar Right (75/25)', dimensions = { 3, 1 } },
}

---Get available layout templates
---@return table<string, table> Templates with their configurations
function M.get_templates()
  ---@type PresenterMConfig
  local cfg = config.get()
  local custom_templates = cfg.layout and cfg.layout.templates or {}
  local templates = vim.tbl_deep_extend('force', default_templates, custom_templates)
  return templates
end

---Format layout array for comment
---@param layout_array table Array of column widths [1, 2, 3]
---@return string Formatted layout string "[1, 2, 3]"
local function format_layout(layout_array)
  local parts = {}
  for _, width in ipairs(layout_array) do
    table.insert(parts, tostring(width))
  end
  return '[' .. table.concat(parts, ', ') .. ']'
end

---Insert column layout scaffolding at current cursor position
---@param layout_array table Array of column widths, e.g., {1, 1} for 50/50
---@param bufnr? number Optional buffer number (defaults to current buffer)
function M.insert_layout(layout_array, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local current_line = cursor[1]

  -- Build the scaffolding
  local lines = {}

  -- Add column_layout comment
  table.insert(lines, '<!-- column_layout: ' .. format_layout(layout_array) .. ' -->')
  table.insert(lines, '')

  -- Add column markers for each column
  for i = 0, #layout_array - 1 do
    table.insert(lines, '<!-- column: ' .. i .. ' -->')
    table.insert(lines, '')
    if i < #layout_array - 1 then
      table.insert(lines, '')
    end
  end

  -- Add reset_layout
  table.insert(lines, '')
  table.insert(lines, '<!-- reset_layout -->')

  -- Insert at current position
  vim.api.nvim_buf_set_lines(bufnr, current_line, current_line, false, lines)

  -- Position cursor on the line after first "<!-- column: 0 -->"
  -- That's at current_line + 4 (layout comment + empty + column 0 + cursor here)
  vim.api.nvim_win_set_cursor(0, { current_line + 4, 0 })
end

---Launch picker for layout selection
function M.layout_picker()
  require('presenterm.pickers').layout_picker()
end

return M
