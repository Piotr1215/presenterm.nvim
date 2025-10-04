describe('snacks', function()
  local snacks_pickers

  before_each(function()
    -- Clear module cache
    package.loaded['presenterm.pickers.snacks'] = nil
    package.loaded['presenterm.navigation'] = nil
    package.loaded['presenterm.slides'] = nil
    package.loaded['presenterm.partials'] = nil
    package.loaded['presenterm.layout'] = nil
    package.loaded['snacks'] = nil

    -- Initialize vim globals
    vim.fn = vim.fn or {}
    vim.api = vim.api or {}
    vim.log = vim.log or { levels = { ERROR = 4, WARN = 3, INFO = 2 } }
    vim.schedule = function(fn)
      fn()
    end

    -- Mock snacks picker
    local picker_mock = {
      close = function(self) end,
      current = function(self)
        -- Return the first item
        return self._items and self._items[1] or nil
      end,
      _items = nil,
    }

    local snacks_mock = {
      picker = {
        pick = function(opts)
          -- Store items for testing
          picker_mock._items = opts.items or {}

          -- Test confirm function
          if opts.confirm and #picker_mock._items > 0 then
            local item = picker_mock._items[1]
            opts.confirm(picker_mock, item)
          end

          -- Test format function
          if opts.format and #picker_mock._items > 0 then
            local formatted = opts.format(picker_mock._items[1])
            assert.is_table(formatted)
            assert.is_table(formatted[1])
          end

          -- Test custom actions and keybindings
          if opts.actions and opts.win and opts.win.input and opts.win.input.keys then
            for key, keyspec in pairs(opts.win.input.keys) do
              local action_name = type(keyspec) == 'table' and keyspec[1] or keyspec
              if opts.actions[action_name] and #picker_mock._items > 0 then
                opts.actions[action_name](picker_mock)
              end
            end
          end
        end,
        preview = {
          preview = function(ctx) end,
          file = function(ctx) end,
        },
      },
    }
    package.loaded['snacks'] = snacks_mock

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
      open_partial_at_cursor = function() end,
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

    -- Mock vim.api functions for partial editing test
    vim.api.nvim_buf_get_lines = function(bufnr, start_line, end_line, strict)
      return { '<!-- include: intro.md -->' }
    end

    vim.fn.cursor = function(line, col) end
    vim.fn.readfile = function(path)
      return { 'File content' }
    end

    snacks_pickers = require('presenterm.pickers.snacks')
  end)

  describe('slide_picker', function()
    it('creates picker with correct items', function()
      local go_to_slide_called = false
      package.loaded['presenterm.navigation'].go_to_slide = function(index)
        go_to_slide_called = true
        assert.equals(1, index)
      end

      snacks_pickers.slide_picker()
      assert.is_true(go_to_slide_called)
    end)

    it('formats items correctly', function()
      local format_result = nil
      package.loaded['snacks'].picker.pick = function(opts)
        if opts.items and #opts.items > 0 and opts.format then
          format_result = opts.format(opts.items[1])
        end
      end

      snacks_pickers.slide_picker()
      assert.is_not_nil(format_result)
      assert.is_table(format_result)
      assert.is_table(format_result[1])
    end)

    it('sets preview field on items for snacks native preview', function()
      local items_with_preview = false
      package.loaded['snacks'].picker.pick = function(opts)
        if opts.items and #opts.items > 0 then
          local item = opts.items[1]
          if item.preview and type(item.preview) == 'table' then
            items_with_preview = true
          end
        end
      end

      snacks_pickers.slide_picker()
      assert.is_true(items_with_preview)
    end)

    it('has ctrl-e keybinding for editing partials', function()
      local partial_opened = false
      package.loaded['presenterm.partials'].open_partial_at_cursor = function()
        partial_opened = true
      end

      local keybinding_exists = false
      package.loaded['snacks'].picker.pick = function(opts)
        if opts.win and opts.win.input and opts.win.input.keys then
          keybinding_exists = opts.win.input.keys['<C-e>'] ~= nil
          if keybinding_exists and type(opts.win.input.keys['<C-e>']) == 'function' then
            -- Simulate picker with selected item
            local picker_mock = {
              norm = function(self, fn)
                fn()
              end,
              close = function() end,
              current = function()
                return { slide = { index = 2 } }
              end,
            }
            opts.win.input.keys['<C-e>'](picker_mock)
          end
        end
      end

      snacks_pickers.slide_picker()
      assert.is_true(keybinding_exists)
    end)

    it('shows correct prompt', function()
      local prompt = nil
      package.loaded['snacks'].picker.pick = function(opts)
        prompt = opts.prompt
      end

      snacks_pickers.slide_picker()
      assert.equals('Presenterm Slides (C-e: edit partial)', prompt)
    end)
  end)

  describe('partial_picker', function()
    it('creates picker with correct items in include mode', function()
      local insert_called = false
      package.loaded['presenterm.partials'].insert_partial_include = function(path)
        insert_called = true
        assert.equals('intro.md', path)
      end

      snacks_pickers.partial_picker({ edit_mode = false })
      assert.is_true(insert_called)
    end)

    it('creates picker with correct items in edit mode', function()
      local edit_called = false
      package.loaded['presenterm.partials'].edit_partial = function(path)
        edit_called = true
        assert.equals('/path/to/intro.md', path)
      end

      snacks_pickers.partial_picker({ edit_mode = true })
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

      snacks_pickers.partial_picker()
      assert.equals('No partial files found', notify_msg)
    end)

    it('has ctrl-e keybinding in include mode', function()
      local keybinding_exists = false
      package.loaded['snacks'].picker.pick = function(opts)
        if opts.win and opts.win.input and opts.win.input.keys then
          keybinding_exists = opts.win.input.keys['<C-e>'] ~= nil
        end
      end

      snacks_pickers.partial_picker({ edit_mode = false })
      assert.is_true(keybinding_exists)
    end)

    it('has ctrl-i keybinding in edit mode', function()
      local keybinding_exists = false
      package.loaded['snacks'].picker.pick = function(opts)
        if opts.win and opts.win.input and opts.win.input.keys then
          keybinding_exists = opts.win.input.keys['<C-i>'] ~= nil
        end
      end

      snacks_pickers.partial_picker({ edit_mode = true })
      assert.is_true(keybinding_exists)
    end)

    it('shows correct prompt for include mode', function()
      local prompt = nil
      package.loaded['snacks'].picker.pick = function(opts)
        prompt = opts.prompt
      end

      snacks_pickers.partial_picker({ edit_mode = false })
      assert.equals('Include Partial (C-e: edit file)', prompt)
    end)

    it('shows correct prompt for edit mode', function()
      local prompt = nil
      package.loaded['snacks'].picker.pick = function(opts)
        prompt = opts.prompt
      end

      snacks_pickers.partial_picker({ edit_mode = true })
      assert.equals('Edit Partial (C-i: insert include)', prompt)
    end)

    it('sets preview field on items with partial file content', function()
      local items_with_preview = false
      package.loaded['snacks'].picker.pick = function(opts)
        if opts.items and #opts.items > 0 then
          local item = opts.items[1]
          if item.preview and type(item.preview) == 'table' and item.preview.text then
            items_with_preview = true
          end
        end
      end

      snacks_pickers.partial_picker({ edit_mode = false })
      assert.is_true(items_with_preview)
    end)
  end)

  describe('layout_picker', function()
    it('creates picker with sorted items', function()
      local insert_called = false
      package.loaded['presenterm.layout'].insert_layout = function(dimensions)
        insert_called = true
        assert.is_table(dimensions)
      end

      snacks_pickers.layout_picker()
      assert.is_true(insert_called)
    end)

    it('formats items correctly', function()
      local format_result = nil
      package.loaded['snacks'].picker.pick = function(opts)
        if opts.items and #opts.items > 0 and opts.format then
          format_result = opts.format(opts.items[1])
        end
      end

      snacks_pickers.layout_picker()
      assert.is_not_nil(format_result)
      assert.is_table(format_result)
      assert.is_table(format_result[1])
    end)

    it('sets preview field on items for layout syntax preview', function()
      local items_with_preview = false
      package.loaded['snacks'].picker.pick = function(opts)
        if opts.items and #opts.items > 0 then
          local item = opts.items[1]
          if item.preview and type(item.preview) == 'table' and item.preview.text then
            items_with_preview = true
          end
        end
      end

      snacks_pickers.layout_picker()
      assert.is_true(items_with_preview)
    end)

    it('shows correct prompt', function()
      local prompt = nil
      package.loaded['snacks'].picker.pick = function(opts)
        prompt = opts.prompt
      end

      snacks_pickers.layout_picker()
      assert.equals('Select Column Layout', prompt)
    end)
  end)
end)
