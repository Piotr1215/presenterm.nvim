describe('exec', function()
  local exec

  before_each(function()
    -- Clear module cache
    package.loaded['presenterm.exec'] = nil
    exec = require('presenterm.exec')

    -- Mock vim functions
    vim.fn.line = function()
      return 10 -- Current line
    end

    vim.api.nvim_buf_get_lines = function()
      return {
        '# Test',
        '',
        '```bash +exec',
        'echo "Hello"',
        '```',
        '',
        '```python',
        'print("World")',
        '```',
        '',
        'Some text',
      }
    end

    vim.fn.setline = function() end
    vim.notify = function() end
    vim.fn.tempname = function()
      return '/tmp/test'
    end
    vim.fn.writefile = function() end
    vim.cmd = function() end
  end)

  describe('toggle_exec', function()
    it('should add +exec flag when not present', function()
      local setline_called = false
      local new_line_content

      vim.fn.line = function()
        return 8
      end -- Line within python block
      vim.fn.setline = function(_, content)
        setline_called = true
        new_line_content = content
      end

      exec.toggle_exec()
      assert.is_true(setline_called)
      assert.truthy(new_line_content and new_line_content:match('%+exec'))
    end)

    it('should remove +exec flag when present', function()
      local setline_called = false
      local new_line_content

      vim.fn.line = function()
        return 4
      end -- Line within bash block
      vim.fn.setline = function(_, content)
        setline_called = true
        new_line_content = content
      end

      exec.toggle_exec()
      assert.is_true(setline_called)
      assert.is_falsy(new_line_content and new_line_content:match('%+exec'))
    end)

    it('should notify when not in a code block', function()
      local notify_called = false
      vim.fn.line = function()
        return 1
      end -- Outside code blocks
      vim.notify = function(msg, _)
        notify_called = true
        assert.truthy(msg:match('[Nn]ot'))
      end

      exec.toggle_exec()
      assert.is_true(notify_called)
    end)

    it('should handle unclosed code blocks', function()
      vim.api.nvim_buf_get_lines = function()
        return {
          '```bash',
          'echo test',
          -- No closing backticks
        }
      end
      vim.fn.line = function()
        return 2
      end

      local notify_called = false
      vim.notify = function(msg)
        notify_called = true
        assert.truthy(msg:match('[Nn]ot'))
      end

      exec.toggle_exec()
      assert.is_true(notify_called)
    end)
  end)

  describe('run_code_block', function()
    it('should run bash code block with +exec', function()
      local cmd_called = false
      local commands = {}
      vim.fn.line = function()
        return 4
      end -- Inside bash +exec block
      vim.cmd = function(command)
        cmd_called = true
        table.insert(commands, command)
      end

      exec.run_code_block()
      assert.is_true(cmd_called)
      assert.is_true(#commands >= 1)
      assert.truthy(
        commands[1]:match('split') and commands[1]:match('terminal') and commands[1]:match('bash')
      )
    end)

    it('should not run code block without +exec', function()
      local notify_called = false
      vim.fn.line = function()
        return 8
      end -- Inside python block without +exec
      vim.notify = function(msg, _)
        notify_called = true
        assert.truthy(msg:match("doesn't have"))
      end

      exec.run_code_block()
      assert.is_true(notify_called)
    end)

    it('should handle Python code blocks', function()
      vim.api.nvim_buf_get_lines = function()
        return {
          '```python +exec',
          'print("test")',
          '```',
        }
      end
      vim.fn.line = function()
        return 2
      end

      local cmd_called = false
      local commands = {}
      vim.cmd = function(command)
        cmd_called = true
        table.insert(commands, command)
      end

      exec.run_code_block()
      assert.is_true(cmd_called)
      assert.is_true(#commands >= 1)
      assert.truthy(
        commands[1]:match('split') and commands[1]:match('terminal') and commands[1]:match('python')
      )
    end)

    it('should handle Lua code blocks', function()
      vim.api.nvim_buf_get_lines = function()
        return {
          '```lua +exec',
          'print("test")',
          '```',
        }
      end
      vim.fn.line = function()
        return 2
      end

      local cmd_called = false
      local commands = {}
      vim.cmd = function(command)
        cmd_called = true
        table.insert(commands, command)
      end

      exec.run_code_block()
      assert.is_true(cmd_called)
      assert.is_true(#commands >= 1)
      assert.truthy(
        commands[1]:match('split') and commands[1]:match('terminal') and commands[1]:match('nvim')
      )
    end)

    it('should notify for unsupported languages', function()
      vim.api.nvim_buf_get_lines = function()
        return {
          '```ruby +exec',
          'puts "test"',
          '```',
        }
      end
      vim.fn.line = function()
        return 2
      end

      local notify_called = false
      vim.notify = function(msg, _)
        notify_called = true
        assert.truthy(msg:match('[Nn]ot supported'))
      end

      exec.run_code_block()
      assert.is_true(notify_called)
    end)
  end)
end)
