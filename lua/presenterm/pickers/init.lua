local M = {}

local navigation = require('presenterm.navigation')
local partials = require('presenterm.partials')

---Auto-detect available picker (priority: telescope > fzf > snacks > builtin)
---@return string Picker name ('telescope', 'fzf', 'snacks', or 'builtin')
function M.detect()
  if pcall(require, 'telescope') then
    return 'telescope'
  end
  if pcall(require, 'fzf-lua') then
    return 'fzf'
  end
  if pcall(require, 'snacks') then
    return 'snacks'
  end
  return 'builtin'
end

---Get the configured or detected picker
---@return string
function M.get_picker()
  ---@type PresenterMConfig
  local config = require('presenterm.config').get()
  if config.picker and config.picker.provider then
    -- Validate configured picker is available
    ---@type string
    local provider = config.picker.provider
    if
      provider ~= 'builtin' and not pcall(require, provider == 'fzf' and 'fzf-lua' or provider)
    then
      vim.notify(
        string.format('Configured picker "%s" not found, falling back to auto-detect', provider),
        vim.log.levels.WARN
      )
      return M.detect()
    end
    return provider
  end
  return M.detect()
end

---Fallback slide picker using vim.ui.select (no preview)
---@param _ table|nil Unused opts
local function slide_picker_fallback(_)
  local slide_list = navigation.get_slide_titles()

  vim.ui.select(slide_list, {
    prompt = 'Select slide:',
    format_item = function(item)
      local indicator = item.has_partial and ' [P]' or ''
      return string.format('%2d. %s%s', item.index, item.title, indicator)
    end,
  }, function(choice)
    if choice then
      navigation.go_to_slide(choice.index)
    end
  end)
end

---Fallback partial picker using vim.ui.select (no preview)
---@param opts table|nil Options (edit_mode: boolean)
local function partial_picker_fallback(opts)
  opts = opts or {}
  local edit_mode = opts.edit_mode or false

  local partial_files = partials.find_partials()

  if #partial_files == 0 then
    vim.notify('No partial files found', vim.log.levels.WARN)
    return
  end

  vim.ui.select(partial_files, {
    prompt = edit_mode and 'Edit partial:' or 'Include partial:',
    format_item = function(item)
      return string.format('%s - %s', item.name, item.title)
    end,
  }, function(choice)
    if choice then
      if edit_mode then
        partials.edit_partial(choice.path)
      else
        partials.insert_partial_include(choice.relative_path)
        vim.notify(
          'Inserted: <!-- include: ' .. choice.relative_path .. ' -->',
          vim.log.levels.INFO
        )
      end
    end
  end)
end

---Fallback layout picker using vim.ui.select (no preview)
---@param _ table|nil Unused opts
local function layout_picker_fallback(_)
  local layout = require('presenterm.layout')
  local templates = layout.get_templates()

  -- Convert to array and sort
  local items = {}
  for _, template in pairs(templates) do
    table.insert(items, template)
  end
  table.sort(items, function(a, b)
    return a.name < b.name
  end)

  vim.ui.select(items, {
    prompt = 'Select column layout:',
    format_item = function(item)
      return item.name
    end,
  }, function(choice)
    if choice then
      layout.insert_layout(choice.dimensions)
    end
  end)
end

---Main slide picker with auto-detection
---@param opts table|nil Options
function M.slide_picker(opts)
  local picker = M.get_picker()

  if picker == 'builtin' then
    slide_picker_fallback(opts)
  else
    require('presenterm.pickers.' .. picker).slide_picker(opts)
  end
end

---Main partial picker with auto-detection
---@param opts table|nil Options (edit_mode: boolean)
function M.partial_picker(opts)
  local picker = M.get_picker()

  if picker == 'builtin' then
    partial_picker_fallback(opts)
  else
    require('presenterm.pickers.' .. picker).partial_picker(opts)
  end
end

---Main layout picker with auto-detection
---@param opts table|nil Options
function M.layout_picker(opts)
  local picker = M.get_picker()

  if picker == 'builtin' then
    layout_picker_fallback(opts)
  else
    require('presenterm.pickers.' .. picker).layout_picker(opts)
  end
end

return M
