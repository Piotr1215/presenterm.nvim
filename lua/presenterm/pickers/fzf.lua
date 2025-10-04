local M = {}

local navigation = require('presenterm.navigation')
local partials = require('presenterm.partials')

---FZF-lua slide picker
---@param opts table|nil Options
function M.slide_picker(opts)
  opts = opts or {}

  local fzf_lua = require('fzf-lua')
  local slides_mod = require('presenterm.slides')
  local slide_list = navigation.get_slide_titles()
  local positions = slides_mod.get_slide_positions()
  local buf_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  -- Build entries array (preserves order) and lookup table
  local entries = {}
  local lookup = {}
  for _, slide in ipairs(slide_list) do
    local indicator = slide.has_partial and ' [P]' or ''
    local entry = string.format('%2d. %s%s', slide.index, slide.title, indicator)
    table.insert(entries, entry)

    -- Extract actual slide content for preview
    local start_line = positions[slide.index] + 1
    local end_line = positions[slide.index + 1] - 1
    local slide_content = vim.list_slice(buf_lines, start_line, end_line)

    lookup[entry] = {
      slide = slide,
      preview = slide_content,
    }
  end

  fzf_lua.fzf_exec(entries, {
    prompt = 'Presenterm Slides> ',
    preview = function(selected)
      local data = lookup[selected[1]]
      if data and data.preview then
        return data.preview
      end
      return ''
    end,
    actions = {
      ['default'] = function(selected)
        if #selected > 0 then
          local data = lookup[selected[1]]
          if data and data.slide then
            navigation.go_to_slide(data.slide.index)
          end
        end
      end,
      ['ctrl-e'] = function(selected)
        if #selected > 0 then
          local data = lookup[selected[1]]
          if data and data.slide then
            navigation.go_to_slide(data.slide.index)
            vim.schedule(function()
              local slides_mod = require('presenterm.slides')
              local slide_positions = slides_mod.get_slide_positions()
              local start_line = slide_positions[data.slide.index] + 1
              local end_line = slide_positions[data.slide.index + 1] - 1
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
        end
      end,
    },
  })
end

---FZF-lua partial picker
---@param opts table|nil Options (edit_mode: boolean)
function M.partial_picker(opts)
  opts = opts or {}
  local edit_mode = opts.edit_mode or false

  local fzf_lua = require('fzf-lua')
  local partial_files = partials.find_partials()

  if #partial_files == 0 then
    vim.notify('No partial files found', vim.log.levels.WARN)
    return
  end

  -- Build entries array (preserves order) and lookup table
  local entries = {}
  local lookup = {}
  for _, partial in ipairs(partial_files) do
    local entry = string.format('%s - %s', partial.name, partial.title)
    table.insert(entries, entry)
    lookup[entry] = partial
  end

  local prompt_title = edit_mode and 'Edit Partial> ' or 'Include Partial> '

  fzf_lua.fzf_exec(entries, {
    prompt = prompt_title,
    preview = function(selected)
      local partial = lookup[selected[1]]
      if partial and partial.path then
        return vim.fn.readfile(partial.path)
      end
      return ''
    end,
    actions = {
      ['default'] = function(selected)
        if #selected > 0 then
          local partial = lookup[selected[1]]
          if partial then
            if edit_mode then
              partials.edit_partial(partial.path)
            else
              partials.insert_partial_include(partial.relative_path)
              vim.notify(
                'Inserted: <!-- include: ' .. partial.relative_path .. ' -->',
                vim.log.levels.INFO
              )
            end
          end
        end
      end,
      ['ctrl-e'] = function(selected)
        if #selected > 0 then
          local partial = lookup[selected[1]]
          if partial then
            partials.edit_partial(partial.path)
          end
        end
      end,
      ['ctrl-i'] = function(selected)
        if #selected > 0 then
          local partial = lookup[selected[1]]
          if partial then
            partials.insert_partial_include(partial.relative_path)
            vim.notify(
              'Inserted: <!-- include: ' .. partial.relative_path .. ' -->',
              vim.log.levels.INFO
            )
          end
        end
      end,
    },
  })
end

---FZF-lua layout picker
---@param opts table|nil Options
function M.layout_picker(opts)
  opts = opts or {}

  local fzf_lua = require('fzf-lua')
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
    return lines
  end

  -- Build entries array (sorted) and lookup table
  local entries = {}
  local lookup = {}
  for _, template in pairs(templates) do
    table.insert(entries, template.name)
    lookup[template.name] = {
      template = template,
      preview = generate_layout_preview(template.dimensions),
    }
  end

  -- Sort by name
  table.sort(entries)

  fzf_lua.fzf_exec(entries, {
    prompt = 'Select Column Layout> ',
    preview = function(selected)
      local data = lookup[selected[1]]
      if data and data.preview then
        return data.preview
      end
      return ''
    end,
    actions = {
      ['default'] = function(selected)
        if #selected > 0 then
          local data = lookup[selected[1]]
          if data and data.template then
            layout.insert_layout(data.template.dimensions)
          end
        end
      end,
    },
  })
end

return M
