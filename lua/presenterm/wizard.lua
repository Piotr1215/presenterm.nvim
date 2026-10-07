---@class PresenterMWizardModule
local M = {}

local templates = require('presenterm.templates')

---Prompt for input with default value
---@param prompt string Prompt message
---@param default string|nil Default value
---@param callback fun(input: string|nil) Callback with user input
local function prompt_input(prompt, default, callback)
  vim.ui.input({
    prompt = prompt,
    default = default,
  }, callback)
end

---Interactive wizard to create new presentation
---@param opts table|nil Options (template_key to skip template selection)
function M.create_presentation(opts)
  opts = opts or {}

  local function select_template(callback)
    if opts.template_key then
      callback(opts.template_key)
      return
    end

    -- Use the picker system for template selection
    require('presenterm.pickers').template_picker(callback)
  end

  local function collect_variables(template_key, callback)
    local vars = {}

    -- Collect title
    prompt_input('Presentation Title: ', '', function(title)
      if not title or title == '' then
        vim.notify('Cancelled: No title provided', vim.log.levels.WARN)
        return
      end
      vars.title = title

      -- Collect author (default to git user if available)
      local git_user = vim.fn.system('git config user.name'):gsub('\n', '')
      prompt_input('Author: ', git_user, function(author)
        if not author or author == '' then
          author = 'Anonymous'
        end
        vars.author = author

        -- Collect date
        vars.date = os.date('%Y-%m-%d')

        -- Collect optional contact
        prompt_input('Contact (optional): ', '', function(contact)
          if contact and contact ~= '' then
            vars.contact = contact
          end

          -- Collect optional repository
          local git_remote = vim.fn.system('git config remote.origin.url'):gsub('\n', '')
          prompt_input('Repository URL (optional): ', git_remote, function(repo)
            if repo and repo ~= '' then
              vars.repo = repo
            end

            -- Collect optional product name (for pitch template)
            if template_key == 'pitch' then
              prompt_input('Product Name (optional): ', vars.title, function(product)
                if product and product ~= '' then
                  vars.product = product
                end
                callback(vars)
              end)
            else
              callback(vars)
            end
          end)
        end)
      end)
    end)
  end

  ---Write presentation file to disk
  ---@param filename string File path to write
  ---@param content string File content
  local function write_file(filename, content)
    -- Write file
    local file, err = io.open(filename, 'w')
    if not file then
      vim.notify(
        string.format('Error: Could not create file %s: %s', filename, err or 'unknown error'),
        vim.log.levels.ERROR
      )
      return false
    end
    file:write(content)
    file:close()

    -- Create _partials directory if it doesn't exist
    local partials_dir = '_partials'
    if vim.fn.isdirectory(partials_dir) == 0 then
      vim.fn.mkdir(partials_dir, 'p')
    end

    -- Open the new file
    vim.cmd('edit ' .. vim.fn.fnameescape(filename))
    vim.notify(string.format('Created presentation: %s', filename), vim.log.levels.INFO)

    -- Re-trigger FileType autocmd to activate presenterm mode
    -- (buffer content is now loaded, so is_presentation() will work)
    vim.cmd('doautocmd FileType')

    return true
  end

  local function create_file(template_key, vars)
    -- Generate content
    local content = templates.generate(template_key, vars)

    -- Determine filename with validation
    local sanitized = vars.title:lower():gsub('%s+', '-'):gsub('[^%w%-]', ''):gsub('%-+', '-')

    -- Validate filename is not empty
    if sanitized == '' or sanitized == '-' then
      vim.notify(
        'Error: Title contains no valid characters for filename. Please use alphanumeric characters.',
        vim.log.levels.ERROR
      )
      return
    end

    local filename = sanitized .. '.md'

    -- Ask for confirmation
    prompt_input('Save as: ', filename, function(final_filename)
      if not final_filename or final_filename == '' then
        vim.notify('Cancelled: No filename provided', vim.log.levels.WARN)
        return
      end

      -- Check if file exists
      if vim.fn.filereadable(final_filename) == 1 then
        vim.ui.select({ 'Overwrite', 'Cancel' }, {
          prompt = 'File exists. Overwrite?',
        }, function(choice)
          if choice == 'Overwrite' then
            write_file(final_filename, content)
          end
        end)
      else
        write_file(final_filename, content)
      end
    end)
  end

  -- Start wizard
  select_template(function(template_key)
    collect_variables(template_key, function(vars)
      create_file(template_key, vars)
    end)
  end)
end

return M
