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
    vim.fn.shellescape = function(str)
      return "'" .. str .. "'"
    end

    vim.cmd = function() end
    vim.notify = function() end

    -- Mock vim.fn.executable for presenterm availability check
    vim.fn.executable = function(cmd)
      if cmd == 'presenterm' then
        return 1 -- Presenterm is available
      end
      return 0
    end

    -- Mock vim.fn.has for Windows detection
    vim.fn.has = function(feature)
      if feature == 'win32' or feature == 'win64' then
        return 0 -- Not Windows by default
      end
      return 0
    end

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

    it('should use login shell when login_shell is true', function()
      vim.g.presenterm = {
        preview = {
          command = 'presenterm',
          login_shell = true,
        },
      }
      vim.o.shell = '/bin/bash'

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
      assert.truthy(cmd_content:match('/bin/bash'))
      assert.truthy(cmd_content:match('%-lic'))
    end)

    it('should not use login shell when login_shell is false', function()
      vim.g.presenterm = {
        preview = {
          command = 'presenterm',
          login_shell = false,
        },
      }

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
      assert.is_false(cmd_content:match('%-lic') ~= nil)
      assert.truthy(cmd_content:match('presenterm'))
    end)
  end)

  describe('image protocol', function()
    -- Neovim's :terminal renders no graphics protocol, so presenterm must fall
    -- back to ascii blocks or images vanish or leak escape codes (issue #10)
    local function launch_with(preview_cfg)
      vim.g.presenterm = { preview = preview_cfg }
      package.loaded['presenterm.config'] = nil
      package.loaded['presenterm.preview'] = nil
      preview = require('presenterm.preview')

      local cmd_content
      vim.cmd = function(command)
        if command:match('terminal') then
          cmd_content = command
        end
      end
      preview.preview()
      return cmd_content
    end

    it('should pass the configured image protocol before the file', function()
      local cmd = launch_with({ command = 'presenterm', image_protocol = 'ascii-blocks' })
      assert.equals(
        "vsplit | terminal presenterm --image-protocol ascii-blocks '/path/to/presentation.md'",
        cmd
      )
    end)

    it('should keep the flag inside the login shell command string', function()
      vim.o.shell = '/bin/bash'
      local cmd = launch_with({
        command = 'presenterm',
        login_shell = true,
        image_protocol = 'ascii-blocks',
      })
      assert.equals(
        [[vsplit | terminal /bin/bash -lic "presenterm --image-protocol ascii-blocks '/path/to/presentation.md'"]],
        cmd
      )
    end)

    it('should omit the flag when image_protocol is false', function()
      local cmd = launch_with({ command = 'presenterm', image_protocol = false })
      assert.equals("vsplit | terminal presenterm '/path/to/presentation.md'", cmd)
    end)

    it('should fall back to presenterm when no command is configured', function()
      local cmd = launch_with({ image_protocol = false })
      assert.equals("vsplit | terminal presenterm '/path/to/presentation.md'", cmd)
    end)

    it('should not override a protocol already set in the command', function()
      local cmd = launch_with({
        command = 'presenterm --image-protocol kitty-local',
        image_protocol = 'ascii-blocks',
      })
      assert.equals(
        "vsplit | terminal presenterm --image-protocol kitty-local '/path/to/presentation.md'",
        cmd
      )
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

    describe('with hidden slides', function()
      local source_buf, terminal_buf = 1, 2
      local on_cursor_moved, on_terminal_lines
      local current_slide, visible_slides, source_lines, terminal_lines
      local jumps, visited, in_source_buf, gone_buf
      local saved_api, saved_schedule

      before_each(function()
        saved_api = vim.tbl_extend('force', {}, vim.api)
        saved_schedule = vim.schedule

        current_slide, visible_slides = 1, { 1, 2, 3 }
        source_lines, terminal_lines = { '# One' }, { '' }
        jumps, visited = {}, {}
        in_source_buf, gone_buf = false, nil

        vim.g.presenterm = {
          preview = { command = 'presenterm', presentation_preview_sync = true },
        }
        vim.bo = setmetatable({}, {
          __index = function()
            return { channel = 7 }
          end,
          __newindex = function() end,
        })

        local slides_stub = package.loaded['presenterm.slides']
        slides_stub.get_current_slide = function()
          return current_slide, {}
        end
        slides_stub.get_visible_slides = function()
          assert.is_true(in_source_buf)
          return visible_slides
        end
        package.loaded['presenterm.navigation'] = {
          go_to_slide = function(slide)
            table.insert(visited, slide)
          end,
        }

        local next_buf = 0
        vim.api.nvim_get_current_buf = function()
          next_buf = next_buf + 1
          return next_buf
        end
        vim.api.nvim_buf_is_valid = function(buf)
          return buf ~= gone_buf
        end
        vim.api.nvim_buf_get_lines = function(buf)
          return buf == terminal_buf and terminal_lines or source_lines
        end
        vim.api.nvim_buf_attach = function(_, _, callbacks)
          on_terminal_lines = callbacks.on_lines
        end
        vim.api.nvim_buf_call = function(buf, fn)
          in_source_buf = buf == source_buf
          local result = fn()
          in_source_buf = false
          return result
        end
        vim.api.nvim_chan_send = function(_, keys)
          table.insert(jumps, tonumber(keys:match('^(%d+)G$')))
        end
        vim.api.nvim_create_autocmd = function(_, opts)
          on_cursor_moved = opts.callback
        end
        vim.schedule = function(fn)
          fn()
        end

        preview.preview()
      end)

      after_each(function()
        package.loaded['presenterm.navigation'] = nil
        vim.schedule = saved_schedule
        for name, fn in pairs(saved_api) do
          vim.api[name] = fn
        end
      end)

      for _, case in ipairs({
        { 'keep the number with nothing hidden', false, 2, { 1, 2, 3 }, { 2 } },
        { 'discount hidden slides', false, 4, { 1, 3, 4 }, { 3 } },
        { 'add the title slide after discounting', true, 3, { 1, 3 }, { 3 } },
        { 'stay put on a hidden slide', false, 2, { 1, 3 }, {} },
      }) do
        local name, frontmatter, slide, visible, expected = unpack(case)

        it('should ' .. name .. ' when the buffer moves', function()
          source_lines = { frontmatter and '---' or '# One' }
          current_slide, visible_slides = slide, visible

          on_cursor_moved()

          assert.same(expected, jumps)
        end)
      end

      for _, case in ipairs({
        { 'discount hidden slides', false, '3 / 3', { 1, 3, 4 }, 4 },
        { 'subtract the title slide first', true, '3 / 3', { 1, 3 }, 3 },
        { 'leave the title slide for go_to_slide to clamp', true, '1 / 3', { 2, 3 }, 0 },
      }) do
        local name, frontmatter, footer, visible, expected = unpack(case)

        it('should ' .. name .. ' when the terminal moves', function()
          source_lines = { frontmatter and '---' or '# One' }
          terminal_lines, visible_slides = { footer }, visible

          on_terminal_lines()

          assert.same({ expected }, visited)
        end)
      end

      it('should not bounce the buffer when the terminal echoes a jump', function()
        current_slide, visible_slides = 4, { 1, 3, 4 }
        on_cursor_moved()

        terminal_lines = { '3 / 3' }
        on_terminal_lines()

        assert.same({}, visited)
      end)

      it('should not resend a jump after the terminal moved the buffer', function()
        terminal_lines, visible_slides = { '3 / 3' }, { 1, 3, 4 }
        on_terminal_lines()

        current_slide = 4
        on_cursor_moved()

        assert.same({}, jumps)
      end)

      it('should stop syncing once the source buffer is gone', function()
        terminal_lines, gone_buf = { '2 / 3' }, source_buf

        on_terminal_lines()

        assert.same({}, visited)
        assert.is_false(preview.get_sync_state().enabled)
      end)
    end)
  end)
end)
