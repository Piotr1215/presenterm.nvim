local M = {}

local navigation = require('presenterm.navigation')
local partials = require('presenterm.partials')

---FZF-lua slide picker
---@param opts table|nil Options
function M.slide_picker(opts)
  opts = opts or {}

  local fzf_lua = require('fzf-lua')
  local slide_list = navigation.get_slide_titles()

  -- Build entries with preview
  local entries = {}
  for _, slide in ipairs(slide_list) do
    local indicator = slide.has_partial and ' [P]' or ''
    local entry = string.format('%2d. %s%s', slide.index, slide.title, indicator)
    entries[entry] = slide
  end

  fzf_lua.fzf_exec(vim.tbl_keys(entries), {
    prompt = 'Presenterm Slides> ',
    preview = function(selected)
      local slide = entries[selected[1]]
      if slide and slide.preview then
        return slide.preview
      end
      return ''
    end,
    actions = {
      ['default'] = function(selected)
        if #selected > 0 then
          local slide = entries[selected[1]]
          if slide then
            navigation.go_to_slide(slide.index)
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

  -- Build entries with partial data
  local entries = {}
  for _, partial in ipairs(partial_files) do
    local entry = string.format('%s - %s', partial.name, partial.title)
    entries[entry] = partial
  end

  local prompt_title = edit_mode and 'Edit Partial> ' or 'Include Partial> '

  fzf_lua.fzf_exec(vim.tbl_keys(entries), {
    prompt = prompt_title,
    preview = function(selected)
      local partial = entries[selected[1]]
      if partial and partial.path then
        return vim.fn.readfile(partial.path)
      end
      return ''
    end,
    actions = {
      ['default'] = function(selected)
        if #selected > 0 then
          local partial = entries[selected[1]]
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

  -- Build entries
  local entries = {}
  for _, template in pairs(templates) do
    entries[template.name] = template
  end

  fzf_lua.fzf_exec(vim.tbl_keys(entries), {
    prompt = 'Select Column Layout> ',
    actions = {
      ['default'] = function(selected)
        if #selected > 0 then
          local template = entries[selected[1]]
          if template then
            layout.insert_layout(template.dimensions)
          end
        end
      end,
    },
  })
end

return M
