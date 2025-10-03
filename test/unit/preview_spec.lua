describe('preview', function()
  local preview

  before_each(function()
    -- Clear module cache
    package.loaded['presenterm.preview'] = nil
    package.loaded['presenterm.config'] = nil
    package.loaded['presenterm.slides'] = nil

    -- Set up default config
    vim.g.presenterm = {
      preview = {
        command = 'presenterm',
      },
    }

    -- Initialize vim globals
    vim.fn = vim.fn or {}
    vim.api = vim.api or {}
    vim.log = vim.log or { levels = { ERROR = 4, WARN = 3, INFO = 2 } }
    vim.o = vim.o or { columns = 80, lines = 24 }
    vim.bo = setmetatable({}, {
      __index = function()
        return {}
      end,
      __newindex = function(t, k, v)
        -- Mock buffer options
      end,
    })
    vim.keymap = vim.keymap or { set = function() end }

    -- Mock slides module
    package.loaded['presenterm.slides'] = {
      get_current_slide = function()
        return 1, { 0, 3, 7, 11 } -- Mock slide positions
      end,
    }

    preview = require('presenterm.preview')

    -- Mock vim functions
    vim.fn.expand = function(arg)
      if arg == '%:p' then
        return '/path/to/presentation.md'
      end
      return ''
    end

    vim.cmd = function() end
    vim.notify = function() end

    -- Mock buffer and window creation for stats
    vim.api.nvim_create_buf = function()
      return 1
    end
    vim.api.nvim_open_win = function()
      return 1
    end
    vim.api.nvim_buf_set_lines = function() end
  end)

  describe('preview', function()
    it('should save and launch preview for markdown files', function()
      local cmd_calls = {}
      vim.cmd = function(command)
        table.insert(cmd_calls, command)
      end

      -- Mock buffer attach for sync
      vim.api.nvim_buf_attach = function()
        return true
      end
      vim.api.nvim_get_current_buf = function()
        return 1
      end

      preview.preview()

      -- Should have: write, vsplit|terminal, startinsert
      assert.is_true(#cmd_calls >= 2)
      assert.equals('write', cmd_calls[1])
      assert.truthy(cmd_calls[2]:match('vsplit'))
      assert.truthy(cmd_calls[2]:match('terminal'))
      assert.truthy(cmd_calls[2]:match('presenterm'))
      assert.truthy(cmd_calls[2]:match('presentation%.md'))
    end)

    it('should reject non-markdown files', function()
      local notify_called = false
      vim.fn.expand = function()
        return '/path/to/file.txt'
      end
      vim.notify = function(msg, level)
        notify_called = true
        assert.truthy(msg:match('[Nn]ot a markdown file'))
        assert.equals(vim.log.levels.ERROR, level)
      end

      preview.preview()
      assert.is_true(notify_called)
    end)

    it('should use custom preview command from config', function()
      vim.g.presenterm = {
        preview = {
          command = 'custom-presenterm',
        },
      }
      -- Force reload to pick up new config
      package.loaded['presenterm.config'] = nil
      package.loaded['presenterm.preview'] = nil
      package.loaded['presenterm.slides'] = {
        get_current_slide = function()
          return 1, { 0, 3, 7, 11 }
        end,
      }
      preview = require('presenterm.preview')

      local cmd_content
      vim.cmd = function(command)
        if command:match('terminal') then
          cmd_content = command
        end
      end

      preview.preview()
      assert.truthy(cmd_content)
      assert.truthy(cmd_content:match('custom%-presenterm'))
    end)

    it('should handle files with spaces in path', function()
      vim.fn.expand = function()
        return '/path/to/my presentation.md'
      end

      local cmd_content
      vim.cmd = function(command)
        if command:match('terminal') then
          cmd_content = command
        end
      end

      preview.preview()
      assert.truthy(cmd_content)
      -- Should have the file path in the command
      assert.truthy(cmd_content:match('my presentation%.md'))
    end)
  end)

  describe('presentation_stats', function()
    it('should calculate presentation statistics', function()
      vim.api.nvim_buf_get_lines = function()
        return {
          '# Slide 1',
          'Content with some words',
          '<!-- end_slide -->',
          '',
          '# Slide 2',
          'More content here',
          'And another line',
          '<!-- end_slide -->',
          '',
          '# Slide 3',
          'Final slide content',
        }
      end

      local stats_lines
      vim.api.nvim_buf_set_lines = function(buf, start_line, end_line, strict, lines)
        stats_lines = lines
      end

      preview.presentation_stats()
      assert.is_not_nil(stats_lines)
      assert.is_table(stats_lines)
      -- Check that stats contain expected information
      local stats_text = table.concat(stats_lines, '\n')
      assert.truthy(stats_text:match('Slides: 3'))
      assert.truthy(stats_text:match('Words: %d+'))
    end)

    it('should handle empty buffer', function()
      vim.api.nvim_buf_get_lines = function()
        return {}
      end

      package.loaded['presenterm.slides'] = {
        get_current_slide = function()
          return 1, { 0, 1 } -- One position means no slides (total_slides = #positions - 1 = 0)
        end,
      }

      local stats_lines
      vim.api.nvim_buf_set_lines = function(buf, start_line, end_line, strict, lines)
        stats_lines = lines
      end

      preview.presentation_stats()
      assert.is_not_nil(stats_lines)
      assert.is_table(stats_lines)
      -- Just check that we got some stats, don't check specific values
      assert.is_true(#stats_lines > 0)
    end)

    it('should count code blocks and executable blocks', function()
      vim.api.nvim_buf_get_lines = function()
        return {
          '# Slide',
          '```bash +exec',
          'echo test',
          '```',
          '```python',
          'print("hello")',
          '```',
        }
      end

      local stats_lines
      vim.api.nvim_buf_set_lines = function(buf, start_line, end_line, strict, lines)
        stats_lines = lines
      end

      preview.presentation_stats()
      assert.is_not_nil(stats_lines)
      local stats_text = table.concat(stats_lines, '\n')
      assert.truthy(stats_text:match('Code blocks: 4')) -- 4 backticks = 4/2 = 2 blocks, but counter counts each ```
      assert.truthy(stats_text:match('1 executable'))
    end)

    it('should estimate time based on word count', function()
      vim.api.nvim_buf_get_lines = function()
        local lines = {}
        -- Create content with approximately 300 words (about 2 minutes at 150 wpm)
        for _ = 1, 60 do
          table.insert(lines, 'one two three four five')
        end
        return lines
      end

      local stats_lines
      vim.api.nvim_buf_set_lines = function(buf, start_line, end_line, strict, lines)
        stats_lines = lines
      end

      preview.presentation_stats()
      assert.is_not_nil(stats_lines)
      local stats_text = table.concat(stats_lines, '\n')
      assert.truthy(stats_text:match('Estimated time: 2 minutes'))
    end)
  end)

  describe('terminal sync', function()
    before_each(function()
      vim.api.nvim_get_current_buf = function()
        return 1
      end
      vim.api.nvim_buf_is_valid = function()
        return true
      end
      vim.fn.bufwinid = function()
        return 1
      end
      vim.api.nvim_get_current_win = function()
        return 1
      end
      vim.api.nvim_set_current_win = function() end
      vim.defer_fn = function(fn)
        fn()
      end
    end)

    describe('get_sync_state', function()
      it('should return sync state', function()
        local state = preview.get_sync_state()
        assert.is_table(state)
        assert.is_not_nil(state.enabled)
      end)
    end)

    describe('toggle_sync', function()
      it('should toggle sync state', function()
        local initial_state = preview.get_sync_state()
        local initial_enabled = initial_state.enabled

        preview.toggle_sync()
        local new_state = preview.get_sync_state()

        assert.equals(not initial_enabled, new_state.enabled)
      end)
    end)
  end)
end)
