local M = {}

local navigation = require('presenterm.navigation')
local partials = require('presenterm.partials')

---Telescope slide picker
---@param opts table|nil Options
function M.slide_picker(opts)
  opts = opts or {}
  local ok = pcall(require, 'telescope')
  if not ok then
    vim.notify('Telescope not found', vim.log.levels.ERROR)
    return
  end

  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')

  local slides = navigation.get_slide_titles()

  pickers
    .new(opts, {
      prompt_title = 'Presenterm Slides',
      finder = finders.new_table({
        results = slides,
        entry_maker = function(entry)
          return {
            value = entry,
            display = string.format('%2d. %s', entry.index, entry.title),
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
            require('presenterm.navigation').go_to_slide(selection.value.index)
          end
        end)

        -- Add mapping to edit partial if on a partial include line
        map('i', '<C-e>', function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            -- Go to the slide first
            require('presenterm.navigation').go_to_slide(selection.value.index)
            -- Check if current line is a partial include
            vim.schedule(function()
              if partials.is_partial_include() then
                partials.open_partial_at_cursor()
              else
                vim.notify('Not on a partial include line', vim.log.levels.INFO)
              end
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

  local ok = pcall(require, 'telescope')
  if not ok then
    vim.notify('Telescope not found', vim.log.levels.ERROR)
    return
  end

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
      prompt_title = edit_mode and 'Edit Partial' or 'Include Partial',
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
        define_preview = function(self, entry, status)
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
              -- Edit the partial file
              partials.edit_partial(selection.value.path)
            else
              -- Insert the include directive at cursor position
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
              -- In edit mode, C-i inserts the include
              partials.insert_partial_include(selection.value.relative_path)
              vim.notify(
                'Inserted: <!-- include: ' .. selection.value.relative_path .. ' -->',
                vim.log.levels.INFO
              )
            else
              -- In include mode, C-e edits the partial
              partials.edit_partial(selection.value.path)
            end
          end
        end)

        return true
      end,
    })
    :find()
end

---List all partials in telescope
function M.list_partials()
  M.partial_picker({ edit_mode = false })
end

return M
