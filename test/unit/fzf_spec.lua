describe('fzf', function()
  local fzf_pickers

  before_each(function()
    -- Clear module cache
    package.loaded['presenterm.pickers.fzf'] = nil
    package.loaded['presenterm.navigation'] = nil
    package.loaded['presenterm.slides'] = nil
    package.loaded['presenterm.partials'] = nil
    package.loaded['presenterm.layout'] = nil
    package.loaded['fzf-lua'] = nil

    -- Initialize vim globals
    vim.fn = vim.fn or {}
    vim.api = vim.api or {}
    vim.log = vim.log or { levels = { ERROR = 4, WARN = 3, INFO = 2 } }
    vim.tbl_keys = function(t)
      local keys = {}
      for k, _ in pairs(t) do
        table.insert(keys, k)
      end
      return keys
    end

    -- Mock fzf-lua
    local fzf_exec_opts = nil
    local fzf_mock = {
      fzf_exec = function(items, opts)
        fzf_exec_opts = opts

        -- Test preview function
        if opts.preview and #items > 0 then
          opts.preview({ items[1] })
        end

        -- Test default action
        if opts.actions and opts.actions.default and #items > 0 then
          opts.actions.default({ items[1] })
        end
      end,
    }
    package.loaded['fzf-lua'] = fzf_mock

    -- Mock navigation
    package.loaded['presenterm.navigation'] = {
      get_slide_titles = function()
        return {
          { index = 1, title = 'Slide 1', has_partial = false, preview = 'Preview 1' },
          { index = 2, title = 'Slide 2', has_partial = true, preview = 'Preview 2' },
        }
      end,
      go_to_slide = function(index) end,
    }

    -- Mock slides
    package.loaded['presenterm.slides'] = {
      get_slide_positions = function()
        return { 0, 10, 20 }
      end,
    }

    -- Mock vim.api for slide content extraction
    vim.api.nvim_buf_get_lines = function(bufnr, start_line, end_line, strict)
      return {
        '# Slide 1',
        '',
        'Content line 1',
        'Content line 2',
      }
    end

    -- Mock vim.list_slice
    vim.list_slice = function(list, start_idx, end_idx)
      local result = {}
      for i = start_idx, end_idx do
        table.insert(result, list[i])
      end
      return result
    end

    -- Mock partials
    package.loaded['presenterm.partials'] = {
      find_partials = function()
        return {
          {
            name = 'intro',
            title = 'Introduction',
            path = '/path/to/intro.md',
            relative_path = 'intro.md',
          },
        }
      end,
      edit_partial = function(path) end,
      insert_partial_include = function(path) end,
    }

    -- Mock layout
    package.loaded['presenterm.layout'] = {
      get_templates = function()
        return {
          ['50/50'] = { name = 'Two Column (50/50)', dimensions = { 1, 1 } },
        }
      end,
      insert_layout = function(dimensions) end,
    }

    -- Mock vim.notify
    vim.notify = function(msg, level) end

    -- Mock vim.fn.readfile
    vim.fn.readfile = function(path)
      return { 'File content' }
    end

    fzf_pickers = require('presenterm.pickers.fzf')
  end)

  describe('module loading', function()
    it('should load without errors', function()
      assert.is_not_nil(fzf_pickers)
      assert.is_table(fzf_pickers)
    end)

    it('should export slide_picker function', function()
      assert.is_function(fzf_pickers.slide_picker)
    end)

    it('should export partial_picker function', function()
      assert.is_function(fzf_pickers.partial_picker)
    end)

    it('should export layout_picker function', function()
      assert.is_function(fzf_pickers.layout_picker)
    end)
  end)

  describe('slide_picker', function()
    it('creates fzf picker with correct items', function()
      local fzf_called = false
      package.loaded['fzf-lua'].fzf_exec = function(items, opts)
        fzf_called = true
        assert.is_table(items)
        assert.is_true(#items > 0)
        -- Check that items are formatted correctly
        local found_slide = false
        for _, item in ipairs(items) do
          if item:find('Slide 1') then
            found_slide = true
            break
          end
        end
        assert.is_true(found_slide)
      end

      fzf_pickers.slide_picker()
      assert.is_true(fzf_called)
    end)

    it('shows correct prompt', function()
      local prompt = nil
      package.loaded['fzf-lua'].fzf_exec = function(items, opts)
        prompt = opts.prompt
      end

      fzf_pickers.slide_picker()
      assert.equals('Presenterm Slides> ', prompt)
    end)

    it('navigates to slide on selection', function()
      local navigated_to = nil
      package.loaded['presenterm.navigation'].go_to_slide = function(index)
        navigated_to = index
      end

      fzf_pickers.slide_picker()
      assert.is_not_nil(navigated_to)
    end)

    it('shows preview for slides', function()
      local preview_called = false
      package.loaded['fzf-lua'].fzf_exec = function(items, opts)
        if opts.preview and #items > 0 then
          local result = opts.preview({ items[1] })
          preview_called = true
          assert.is_not_nil(result)
        end
      end

      fzf_pickers.slide_picker()
      assert.is_true(preview_called)
    end)

    it('marks slides with partials', function()
      local has_partial_indicator = false
      package.loaded['fzf-lua'].fzf_exec = function(items, opts)
        for _, item in ipairs(items) do
          if item:find('%[P%]') then
            has_partial_indicator = true
            break
          end
        end
      end

      fzf_pickers.slide_picker()
      assert.is_true(has_partial_indicator)
    end)
  end)

  describe('partial_picker', function()
    it('creates picker in include mode', function()
      local insert_called = false
      package.loaded['presenterm.partials'].insert_partial_include = function(path)
        insert_called = true
        assert.equals('intro.md', path)
      end

      fzf_pickers.partial_picker({ edit_mode = false })
      assert.is_true(insert_called)
    end)

    it('creates picker in edit mode', function()
      local edit_called = false
      package.loaded['presenterm.partials'].edit_partial = function(path)
        edit_called = true
        assert.equals('/path/to/intro.md', path)
      end

      fzf_pickers.partial_picker({ edit_mode = true })
      assert.is_true(edit_called)
    end)

    it('shows warning when no partials found', function()
      local notify_msg = nil
      vim.notify = function(msg, level)
        notify_msg = msg
      end

      package.loaded['presenterm.partials'].find_partials = function()
        return {}
      end

      fzf_pickers.partial_picker()
      assert.equals('No partial files found', notify_msg)
    end)

    it('shows correct prompt for include mode', function()
      local prompt = nil
      package.loaded['fzf-lua'].fzf_exec = function(items, opts)
        prompt = opts.prompt
      end

      fzf_pickers.partial_picker({ edit_mode = false })
      assert.equals('Include Partial> ', prompt)
    end)

    it('shows correct prompt for edit mode', function()
      local prompt = nil
      package.loaded['fzf-lua'].fzf_exec = function(items, opts)
        prompt = opts.prompt
      end

      fzf_pickers.partial_picker({ edit_mode = true })
      assert.equals('Edit Partial> ', prompt)
    end)

    it('shows preview for partials', function()
      local preview_called = false
      package.loaded['fzf-lua'].fzf_exec = function(items, opts)
        if opts.preview and #items > 0 then
          local result = opts.preview({ items[1] })
          preview_called = true
          assert.is_not_nil(result)
        end
      end

      fzf_pickers.partial_picker({ edit_mode = false })
      assert.is_true(preview_called)
    end)

    it('notifies on successful include', function()
      local notify_msg = nil
      vim.notify = function(msg, level)
        notify_msg = msg
      end

      fzf_pickers.partial_picker({ edit_mode = false })
      assert.is_not_nil(notify_msg)
      assert.is_true(notify_msg:find('Inserted') ~= nil)
    end)
  end)

  describe('layout_picker', function()
    it('creates picker with templates', function()
      local fzf_called = false
      package.loaded['fzf-lua'].fzf_exec = function(items, opts)
        fzf_called = true
        assert.is_table(items)
        assert.is_true(#items > 0)
      end

      fzf_pickers.layout_picker()
      assert.is_true(fzf_called)
    end)

    it('shows correct prompt', function()
      local prompt = nil
      package.loaded['fzf-lua'].fzf_exec = function(items, opts)
        prompt = opts.prompt
      end

      fzf_pickers.layout_picker()
      assert.equals('Select Column Layout> ', prompt)
    end)

    it('inserts layout on selection', function()
      local insert_called = false
      package.loaded['presenterm.layout'].insert_layout = function(dimensions)
        insert_called = true
        assert.is_table(dimensions)
      end

      fzf_pickers.layout_picker()
      assert.is_true(insert_called)
    end)

    it('handles template selection', function()
      local selected_dimensions = nil
      package.loaded['presenterm.layout'].insert_layout = function(dimensions)
        selected_dimensions = dimensions
      end

      fzf_pickers.layout_picker()
      assert.is_not_nil(selected_dimensions)
      assert.is_table(selected_dimensions)
    end)
  end)
end)
