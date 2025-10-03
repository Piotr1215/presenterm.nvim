describe('layout', function()
  local layout

  before_each(function()
    -- Clear module cache
    package.loaded['presenterm.layout'] = nil
    package.loaded['presenterm.config'] = nil

    -- Set up default config
    vim.g.presenterm = {
      layout = {
        templates = {},
      },
    }

    layout = require('presenterm.layout')
  end)

  describe('module structure', function()
    it('should export required functions', function()
      assert.is_function(layout.get_templates)
      assert.is_function(layout.insert_layout)
      assert.is_function(layout.layout_picker)
    end)
  end)

  describe('get_templates', function()
    it('should return default templates', function()
      local templates = layout.get_templates()
      assert.is_table(templates)
      assert.is_not_nil(templates['50/50'])
      assert.is_not_nil(templates['60/40'])
    end)

    it('should include template metadata', function()
      local templates = layout.get_templates()
      assert.equals('Two Column (50/50)', templates['50/50'].name)
      assert.is_table(templates['50/50'].dimensions)
      assert.equals(1, templates['50/50'].dimensions[1])
      assert.equals(1, templates['50/50'].dimensions[2])
    end)
  end)

  describe('insert_layout', function()
    local inserted_lines
    local cursor_pos

    before_each(function()
      inserted_lines = {}
      cursor_pos = { 3, 0 }

      -- Mock buffer functions
      vim.api.nvim_get_current_buf = function()
        return 1
      end

      vim.api.nvim_win_get_cursor = function()
        return cursor_pos
      end

      vim.api.nvim_win_set_cursor = function(_, pos)
        cursor_pos = pos
      end

      vim.api.nvim_buf_set_lines = function(bufnr, start, _end, strict, lines)
        inserted_lines = lines
      end

      vim.api.nvim_buf_get_lines = function(bufnr, start, _end, strict)
        local initial = {
          '# Test Slide',
          '',
          'Some content',
        }
        -- Merge inserted lines at the cursor position
        if #inserted_lines > 0 then
          local result = {}
          for i = 1, cursor_pos[1] do
            table.insert(result, initial[i])
          end
          for _, line in ipairs(inserted_lines) do
            table.insert(result, line)
          end
          return result
        end
        return initial
      end
    end)

    it('should insert column layout scaffolding', function()
      -- Position cursor on line 3
      cursor_pos = { 3, 0 }

      -- Insert a 2-column layout
      layout.insert_layout({ 1, 1 })

      local lines = inserted_lines

      -- Should insert layout comment
      local has_layout = false
      local has_col0 = false
      local has_col1 = false
      local has_reset = false

      for _, line in ipairs(lines) do
        if line == '<!-- column_layout: [1, 1] -->' then
          has_layout = true
        end
        if line == '<!-- column: 0 -->' then
          has_col0 = true
        end
        if line == '<!-- column: 1 -->' then
          has_col1 = true
        end
        if line == '<!-- reset_layout -->' then
          has_reset = true
        end
      end

      assert.is_true(has_layout, 'Should have column_layout comment')
      assert.is_true(has_col0, 'Should have column 0 marker')
      assert.is_true(has_col1, 'Should have column 1 marker')
      assert.is_true(has_reset, 'Should have reset_layout comment')
    end)

    it('should position cursor in first column after insertion', function()
      local initial_cursor = 3
      cursor_pos = { initial_cursor, 0 }
      layout.insert_layout({ 1, 1 })

      local cursor = cursor_pos

      -- Cursor should be positioned at initial_cursor + 4
      -- (layout comment + empty + column 0 + cursor here)
      assert.equals(
        initial_cursor + 4,
        cursor[1],
        'Cursor should be positioned correctly after insertion'
      )
    end)

    it('should handle 3-column layout', function()
      cursor_pos = { 3, 0 }
      layout.insert_layout({ 1, 1, 1 })

      local lines = inserted_lines

      local has_layout = false
      local has_col0 = false
      local has_col1 = false
      local has_col2 = false

      for _, line in ipairs(lines) do
        if line == '<!-- column_layout: [1, 1, 1] -->' then
          has_layout = true
        end
        if line == '<!-- column: 0 -->' then
          has_col0 = true
        end
        if line == '<!-- column: 1 -->' then
          has_col1 = true
        end
        if line == '<!-- column: 2 -->' then
          has_col2 = true
        end
      end

      assert.is_true(has_layout, 'Should have column_layout comment')
      assert.is_true(has_col0, 'Should have column 0 marker')
      assert.is_true(has_col1, 'Should have column 1 marker')
      assert.is_true(has_col2, 'Should have column 2 marker')
    end)
  end)

  describe('layout_picker', function()
    it('should be callable', function()
      -- This will need telescope mocking, but for now just check it exists
      assert.is_function(layout.layout_picker)
    end)
  end)
end)
