local M = {}

local navigation = require('presenterm.navigation')
local partials = require('presenterm.partials')

---Snacks slide picker
---@param opts table|nil Options
function M.slide_picker(opts)
  opts = opts or {}

  local snacks = require('snacks')
  local slides_mod = require('presenterm.slides')
  local slide_list = navigation.get_slide_titles()
  local positions = slides_mod.get_slide_positions()
  local buf_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  -- Build items for snacks picker
  local items = {}
  for _, slide in ipairs(slide_list) do
    local indicator = slide.has_partial and ' [P]' or ''

    -- Extract actual slide content for preview
    local start_line = positions[slide.index] + 1
    local end_line = positions[slide.index + 1] - 1
    local slide_content = vim.list_slice(buf_lines, start_line, end_line)
    local preview_text = table.concat(slide_content, '\n')

    table.insert(items, {
      text = string.format('%2d. %s%s', slide.index, slide.title, indicator),
      slide = slide,
      preview = { text = preview_text, ft = 'markdown' },
    })
  end

  snacks.picker.pick({
    prompt = 'Presenterm Slides (C-e: edit partial)',
    items = items,
    format = function(item)
      return { { item.text } }
    end,
    preview = snacks.picker.preview.preview,
    confirm = function(picker, item)
      picker:close()
      if item and item.slide then
        vim.schedule(function()
          navigation.go_to_slide(item.slide.index)
        end)
      end
    end,
    actions = {
      edit_partial = function(picker)
        local item = picker:current()
        picker:close()
        if item and item.slide then
          vim.schedule(function()
            navigation.go_to_slide(item.slide.index)
            local slide_positions = slides_mod.get_slide_positions()
            local start_line = slide_positions[item.slide.index] + 1
            local end_line = slide_positions[item.slide.index + 1] - 1
            local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
            for i, line in ipairs(lines) do
              if line:match('<!%-%- include: (.+) %-%->') then
                vim.fn.cursor(start_line + i - 1, 1)
                partials.open_partial_at_cursor()
                return
              end
            end
            vim.notify('No partial includes in this slide', vim.log.levels.INFO)
          end)
        end
      end,
    },
    win = {
      input = {
        keys = {
          ['<C-e>'] = { 'edit_partial', mode = { 'i', 'n' } },
        },
      },
    },
  })
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
    -- Read partial file content for preview
    local preview_content = vim.fn.readfile(partial.path)
    local preview_text = table.concat(preview_content, '\n')

    table.insert(items, {
      text = string.format('%s - %s', partial.name, partial.title),
      partial = partial,
      preview = { text = preview_text, ft = 'markdown', loc = false },
    })
  end

  local prompt_title = edit_mode and 'Edit Partial (C-i: insert include)'
    or 'Include Partial (C-e: edit file)'

  snacks.picker.pick({
    prompt = prompt_title,
    items = items,
    format = function(item)
      return { { item.text } }
    end,
    preview = snacks.picker.preview.preview,
    confirm = function(picker, item)
      picker:close()
      if item and item.partial then
        vim.schedule(function()
          if edit_mode then
            partials.edit_partial(item.partial.path)
          else
            partials.insert_partial_include(item.partial.relative_path)
            vim.notify(
              'Inserted: <!-- include: ' .. item.partial.relative_path .. ' -->',
              vim.log.levels.INFO
            )
          end
        end)
      end
    end,
    actions = {
      edit_file = function(picker)
        local item = picker:current()
        picker:close()
        if item and item.partial then
          vim.schedule(function()
            partials.edit_partial(item.partial.path)
          end)
        end
      end,
      insert_include = function(picker)
        local item = picker:current()
        picker:close()
        if item and item.partial then
          vim.schedule(function()
            partials.insert_partial_include(item.partial.relative_path)
            vim.notify(
              'Inserted: <!-- include: ' .. item.partial.relative_path .. ' -->',
              vim.log.levels.INFO
            )
          end)
        end
      end,
    },
    win = {
      input = {
        keys = edit_mode and {
          ['<C-i>'] = { 'insert_include', mode = { 'i', 'n' } },
        } or {
          ['<C-e>'] = { 'edit_file', mode = { 'i', 'n' } },
        },
      },
    },
  })
end

---Snacks layout picker
---@param opts table|nil Options
function M.layout_picker(opts)
  opts = opts or {}

  local snacks = require('snacks')
  local layout = require('presenterm.layout')
  local templates = layout.get_templates()

  -- Helper to format layout array for comment
  local function format_layout(layout_array)
    local parts = {}
    for _, width in ipairs(layout_array) do
      table.insert(parts, tostring(width))
    end
    return '[' .. table.concat(parts, ', ') .. ']'
  end

  -- Helper to generate preview text
  local function generate_layout_preview(dimensions)
    local lines = {}
    table.insert(lines, '<!-- column_layout: ' .. format_layout(dimensions) .. ' -->')
    table.insert(lines, '')
    for i = 0, #dimensions - 1 do
      table.insert(lines, '<!-- column: ' .. i .. ' -->')
      table.insert(lines, '')
      if i < #dimensions - 1 then
        table.insert(lines, '')
      end
    end
    table.insert(lines, '')
    table.insert(lines, '<!-- reset_layout -->')
    return table.concat(lines, '\n')
  end

  -- Build items for snacks picker
  local items = {}
  for _, template in pairs(templates) do
    table.insert(items, {
      text = template.name,
      template = template,
      preview = { text = generate_layout_preview(template.dimensions), ft = 'markdown' },
    })
  end

  -- Sort by name
  table.sort(items, function(a, b)
    return a.text < b.text
  end)

  snacks.picker.pick({
    prompt = 'Select Column Layout',
    items = items,
    format = function(item)
      return { { item.text } }
    end,
    preview = snacks.picker.preview.preview,
    confirm = function(picker, item)
      picker:close()
      if item and item.template then
        vim.schedule(function()
          layout.insert_layout(item.template.dimensions)
        end)
      end
    end,
  })
end

return M
