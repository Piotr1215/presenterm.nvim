describe('telescope', function()
  local telescope_module

  before_each(function()
    -- Clear module cache
    package.loaded['presenterm.telescope'] = nil
    package.loaded['presenterm.navigation'] = nil
    package.loaded['presenterm.slides'] = nil
    package.loaded['presenterm.partials'] = nil
    package.loaded['presenterm.config'] = nil

    -- Set up default config
    vim.g.presenterm = {
      slide_marker = '<!-- end_slide -->',
      partials = {
        directory = '_partials',
        resolve_relative = true,
      },
      telescope = {
        theme = 'dropdown',
        layout_config = { width = 0.8, height = 0.6 },
        enable_preview = true,
      },
    }

    -- Initialize vim globals
    vim.fn = vim.fn or {}
    vim.api = vim.api or {}
    vim.log = vim.log or { levels = { ERROR = 4, WARN = 3, INFO = 2 } }

    -- Mock telescope completely before loading the module
    local telescope_mock = {
      register_extension = function() end,
    }
    package.loaded['telescope'] = telescope_mock

    local pickers_mock = {
      new = function(opts, config)
        return { find = function() end }
      end,
    }
    package.loaded['telescope.pickers'] = pickers_mock

    local finders_mock = {
      new_table = function(opts)
        return {}
      end,
    }
    package.loaded['telescope.finders'] = finders_mock

    local config_mock = {
      values = {
        vimgrep_arguments = { 'rg', '--color=never', '--no-heading' },
        generic_sorter = function()
          return {}
        end,
      },
    }
    package.loaded['telescope.config'] = config_mock

    local sorters_mock = {
      get_generic_fuzzy_sorter = function()
        return {}
      end,
    }
    package.loaded['telescope.sorters'] = sorters_mock

    local actions_mock = {
      select_default = {
        replace = function()
          return function() end
        end,
      },
      close = function() end,
    }
    package.loaded['telescope.actions'] = actions_mock

    local state_mock = {
      get_selected_entry = function()
        return { index = 1, value = {} }
      end,
    }
    package.loaded['telescope.actions.state'] = state_mock

    local previewers_mock = {
      vim_buffer_cat = {
        new = function(opts)
          return {}
        end,
      },
      new_buffer_previewer = function(opts)
        return {}
      end,
    }
    package.loaded['telescope.previewers'] = previewers_mock

    local themes_mock = {
      get_dropdown = function(opts)
        return opts or {}
      end,
    }
    package.loaded['telescope.themes'] = themes_mock

    -- Mock navigation module
    package.loaded['presenterm.navigation'] = {
      get_slide_titles = function()
        return {
          { index = 1, title = 'Slide 1', start_line = 1, preview = 'Content' },
          { index = 2, title = 'Slide 2', start_line = 5, preview = 'More' },
        }
      end,
      go_to_slide = function() end,
    }

    -- Mock partials module
    package.loaded['presenterm.partials'] = {
      find_partials = function()
        return {
          {
            filename = 'intro.md',
            title = 'Introduction',
            path = '/project/_partials/intro.md',
            relative_path = '../_partials/intro.md',
          },
          {
            filename = 'demo.md',
            title = 'Demo',
            path = '/project/_partials/demo.md',
            relative_path = '../_partials/demo.md',
          },
        }
      end,
      get_partial_path = function()
        return nil
      end,
      insert_partial_include = function() end,
      edit_partial = function() end,
    }

    -- Mock slides module
    package.loaded['presenterm.slides'] = {
      get_slides = function()
        return {
          { start_line = 1, end_line = 3 },
          { start_line = 5, end_line = 7 },
        }
      end,
    }

    -- Now we can safely require the telescope module
    telescope_module = require('presenterm.telescope')

    -- Mock vim functions
    vim.api.nvim_buf_get_lines = function()
      return { '# Slide 1', 'Content', '<!-- end_slide -->', '', '# Slide 2' }
    end
    vim.fn.line = function()
      return 5
    end
    vim.fn.cursor = function() end
    vim.fn.setline = function() end
    vim.cmd = function() end
    vim.notify = function() end
  end)

  describe('module loading', function()
    it('should load without errors', function()
      assert.is_not_nil(telescope_module)
      assert.is_table(telescope_module)
    end)

    it('should export slide_picker function', function()
      assert.is_function(telescope_module.slide_picker)
    end)

    it('should export partial_picker function', function()
      assert.is_function(telescope_module.partial_picker)
    end)
  end)

  describe('slide_picker', function()
    it('should create telescope picker', function()
      local picker_created = false
      package.loaded['telescope.pickers'].new = function(opts, config)
        picker_created = true
        assert.is_not_nil(config.finder)
        assert.is_not_nil(config.sorter)
        return { find = function() end }
      end

      telescope_module.slide_picker()
      assert.is_true(picker_created)
    end)
  end)

  describe('partial_picker', function()
    it('should create picker for include mode', function()
      local picker_created = false
      local picker_config = nil
      package.loaded['telescope.pickers'].new = function(opts, config)
        picker_created = true
        picker_config = config
        return { find = function() end }
      end

      telescope_module.partial_picker('include')
      assert.is_true(picker_created)
      assert.is_not_nil(picker_config)
      assert.is_not_nil(picker_config.prompt_title)
    end)

    it('should create picker for edit mode', function()
      local picker_created = false
      local picker_config = nil
      package.loaded['telescope.pickers'].new = function(opts, config)
        picker_created = true
        picker_config = config
        return { find = function() end }
      end

      telescope_module.partial_picker('edit')
      assert.is_true(picker_created)
      assert.is_not_nil(picker_config)
      assert.is_not_nil(picker_config.prompt_title)
    end)
  end)
end)
