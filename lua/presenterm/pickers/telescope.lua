local M = {}

local navigation = require('presenterm.navigation')
local partials = require('presenterm.partials')
local slides = require('presenterm.slides')

---Telescope slide picker
---@param opts table|nil Options
function M.slide_picker(opts)
  opts = opts or {}

  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')

  local slide_list = navigation.get_slide_titles()

  -- Reverse the slide list so first slide appears at top
  local reversed_slides = {}
  for i = #slide_list, 1, -1 do
    table.insert(reversed_slides, slide_list[i])
  end

  pickers
    .new(opts, {
      prompt_title = 'Presenterm Slides (C-e: edit partial)',
      finder = finders.new_table({
        results = reversed_slides,
        entry_maker = function(entry)
          local indicator = entry.has_partial and ' [P]' or ''
          return {
            value = entry,
            display = string.format('%2d. %s%s', entry.index, entry.title, indicator),
            ordinal = entry.index .. ' ' .. entry.title .. ' ' .. entry.preview,
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            navigation.go_to_slide(selection.value.index)
          end
        end)

        -- Add mapping to edit partial if slide contains partials
        map('i', '<C-e>', function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            -- Go to the slide first
            navigation.go_to_slide(selection.value.index)
            -- Find and open first partial in this slide
            vim.schedule(function()
              local positions = slides.get_slide_positions()
              local start_line = positions[selection.value.index] + 1
              local end_line = positions[selection.value.index + 1] - 1

              -- Search for partial includes in the slide
              local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
              for i, line in ipairs(lines) do
                if line:match('<!%-%- include: (.+) %-%->') then
                  -- Move cursor to the partial include line
                  vim.fn.cursor(start_line + i - 1, 1)
                  partials.open_partial_at_cursor()
                  return
                end
              end
              vim.notify('No partial includes in this slide', vim.log.levels.INFO)
            end)
          end
        end)

        return true
      end,
    })
    :find()
end

---Telescope partial picker with edit mode
---@param opts table|nil Options (edit_mode: boolean)
function M.partial_picker(opts)
  opts = opts or {}
  local edit_mode = opts.edit_mode or false

  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  local previewers = require('telescope.previewers')

  local partial_files = partials.find_partials()

  if #partial_files == 0 then
    vim.notify('No partial files found', vim.log.levels.WARN)
    return
  end

  pickers
    .new(opts, {
      prompt_title = edit_mode and 'Edit Partial (C-i: insert include)'
        or 'Include Partial (C-e: edit file)',
      finder = finders.new_table({
        results = partial_files,
        entry_maker = function(entry)
          return {
            value = entry,
            display = string.format('%s - %s', entry.name, entry.title),
            ordinal = entry.name .. ' ' .. entry.title .. ' ' .. entry.preview,
            path = entry.path, -- For previewer
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
      previewer = previewers.new_buffer_previewer({
        title = 'Partial Content',
        define_preview = function(self, entry, _)
          local content = vim.fn.readfile(entry.value.path)
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, content)
          vim.bo[self.state.bufnr].filetype = 'markdown'
        end,
      }),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            if edit_mode then
              partials.edit_partial(selection.value.path)
            else
              partials.insert_partial_include(selection.value.relative_path)
              vim.notify(
                'Inserted: <!-- include: ' .. selection.value.relative_path .. ' -->',
                vim.log.levels.INFO
              )
            end
          end
        end)

        -- Add secondary action (opposite of default)
        local secondary_action = edit_mode and 'i' or 'n'
        local secondary_key = edit_mode and '<C-i>' or '<C-e>'

        map(secondary_action, secondary_key, function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            if edit_mode then
              partials.insert_partial_include(selection.value.relative_path)
              vim.notify(
                'Inserted: <!-- include: ' .. selection.value.relative_path .. ' -->',
                vim.log.levels.INFO
              )
            else
              partials.edit_partial(selection.value.path)
            end
          end
        end)

        return true
      end,
    })
    :find()
end

---Telescope layout picker
---@param opts table|nil Options
function M.layout_picker(opts)
  opts = opts or {}

  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  local layout = require('presenterm.layout')

  local templates = layout.get_templates()

  -- Convert templates to picker entries
  local entries = {}
  for _, template in pairs(templates) do
    table.insert(entries, {
      value = template,
      display = template.name,
      ordinal = template.name,
    })
  end

  -- Sort by name
  table.sort(entries, function(a, b)
    return a.display < b.display
  end)

  pickers
    .new(opts, {
      prompt_title = 'Select Column Layout',
      finder = finders.new_table({
        results = entries,
        entry_maker = function(entry)
          return entry
        end,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          if selection then
            layout.insert_layout(selection.value.dimensions)
          end
        end)
        return true
      end,
    })
    :find()
end

return M
