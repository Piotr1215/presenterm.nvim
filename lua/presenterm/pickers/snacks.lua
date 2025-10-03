local M = {}

local navigation = require('presenterm.navigation')
local partials = require('presenterm.partials')

---Snacks slide picker
---@param opts table|nil Options
function M.slide_picker(opts)
  opts = opts or {}

  local snacks = require('snacks')
  local slide_list = navigation.get_slide_titles()

  -- Build items for snacks picker
  local items = {}
  for _, slide in ipairs(slide_list) do
    local indicator = slide.has_partial and ' [P]' or ''
    table.insert(items, {
      text = string.format('%2d. %s%s', slide.index, slide.title, indicator),
      slide = slide,
    })
  end

  snacks.picker.pick({
    items = items,
    format = function(item)
      return item.text
    end,
    preview = function(item)
      if item.slide and item.slide.preview then
        return item.slide.preview
      end
      return ''
    end,
  }, function(selected)
    if selected and selected.slide then
      navigation.go_to_slide(selected.slide.index)
    end
  end)
end

---Snacks partial picker
---@param opts table|nil Options (edit_mode: boolean)
function M.partial_picker(opts)
  opts = opts or {}
  local edit_mode = opts.edit_mode or false

  local snacks = require('snacks')
  local partial_files = partials.find_partials()

  if #partial_files == 0 then
    vim.notify('No partial files found', vim.log.levels.WARN)
    return
  end

  -- Build items for snacks picker
  local items = {}
  for _, partial in ipairs(partial_files) do
    table.insert(items, {
      text = string.format('%s - %s', partial.name, partial.title),
      partial = partial,
    })
  end

  snacks.picker.pick({
    items = items,
    format = function(item)
      return item.text
    end,
    preview = function(item)
      if item.partial and item.partial.path then
        return vim.fn.readfile(item.partial.path)
      end
      return ''
    end,
  }, function(selected)
    if selected and selected.partial then
      if edit_mode then
        partials.edit_partial(selected.partial.path)
      else
        partials.insert_partial_include(selected.partial.relative_path)
        vim.notify(
          'Inserted: <!-- include: ' .. selected.partial.relative_path .. ' -->',
          vim.log.levels.INFO
        )
      end
    end
  end)
end

---Snacks layout picker
---@param opts table|nil Options
function M.layout_picker(opts)
  opts = opts or {}

  local snacks = require('snacks')
  local layout = require('presenterm.layout')
  local templates = layout.get_templates()

  -- Build items for snacks picker
  local items = {}
  for _, template in pairs(templates) do
    table.insert(items, {
      text = template.name,
      template = template,
    })
  end

  -- Sort by name
  table.sort(items, function(a, b)
    return a.text < b.text
  end)

  snacks.picker.pick({
    items = items,
    format = function(item)
      return item.text
    end,
  }, function(selected)
    if selected and selected.template then
      layout.insert_layout(selected.template.dimensions)
    end
  end)
end

return M
