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

  describe('toggle_exec - Happy Path Tests', function()
    it('should toggle plain -> +exec', function()
      local setline_called = false
      local new_line_content

      vim.api.nvim_buf_get_lines = function()
        return {
          '```bash',
          'echo "Hello"',
          '```',
        }
      end
      vim.fn.line = function()
        return 2
      end
      vim.fn.setline = function(_, content)
        setline_called = true
        new_line_content = content
      end

      exec.toggle_exec()
      assert.is_true(setline_called)
      assert.equals('```bash +exec', new_line_content)
    end)

    it('should toggle +exec -> +exec_replace', function()
      local setline_called = false
      local new_line_content

      vim.api.nvim_buf_get_lines = function()
        return {
          '```bash +exec',
          'echo "Hello"',
          '```',
        }
      end
      vim.fn.line = function()
        return 2
      end
      vim.fn.setline = function(_, content)
        setline_called = true
        new_line_content = content
      end

      exec.toggle_exec()
      assert.is_true(setline_called)
      assert.equals('```bash +exec_replace', new_line_content)
    end)

    it('should toggle +exec_replace -> +exec +acquire_terminal', function()
      local setline_called = false
      local new_line_content

      vim.api.nvim_buf_get_lines = function()
        return {
          '```bash +exec_replace',
          'echo "Hello"',
          '```',
        }
      end
      vim.fn.line = function()
        return 2
      end
      vim.fn.setline = function(_, content)
        setline_called = true
        new_line_content = content
      end

      exec.toggle_exec()
      assert.is_true(setline_called)
      assert.equals('```bash +exec +acquire_terminal', new_line_content)
    end)

    it('should toggle +exec +acquire_terminal -> plain', function()
      local setline_called = false
      local new_line_content

      vim.api.nvim_buf_get_lines = function()
        return {
          '```bash +exec +acquire_terminal',
          'echo "Hello"',
          '```',
        }
      end
      vim.fn.line = function()
        return 2
      end
      vim.fn.setline = function(_, content)
        setline_called = true
        new_line_content = content
      end

      exec.toggle_exec()
      assert.is_true(setline_called)
      assert.equals('```bash', new_line_content)
    end)

    it('should preserve +id: when toggling', function()
      local setline_called = false
      local new_line_content

      vim.api.nvim_buf_get_lines = function()
        return {
          '```bash +exec +id:foo',
          'echo "Hello"',
          '```',
        }
      end
      vim.fn.line = function()
        return 2
      end
      vim.fn.setline = function(_, content)
        setline_called = true
        new_line_content = content
      end

      exec.toggle_exec()
      assert.is_true(setline_called)
      assert.truthy(new_line_content:match('%+id:foo'))
      assert.truthy(new_line_content:match('%+exec_replace'))
    end)

    it('should preserve custom executor when toggling', function()
      local setline_called = false
      local new_line_content

      vim.api.nvim_buf_get_lines = function()
        return {
          '```rust +exec:rust-script',
          'fn main() {}',
          '```',
        }
      end
      vim.fn.line = function()
        return 2
      end
      vim.fn.setline = function(_, content)
        setline_called = true
        new_line_content = content
      end

      exec.toggle_exec()
      assert.is_true(setline_called)
      -- Custom executors skip +exec_replace and go directly to +exec:rust-script +acquire_terminal
      assert.truthy(new_line_content:match('%+exec:rust%-script'))
      assert.truthy(new_line_content:match('%+acquire_terminal'))
    end)

    it('should not return to plain when +id: is present', function()
      local new_line_content

      -- Start from +exec +acquire_terminal with +id:
      vim.api.nvim_buf_get_lines = function()
        return {
          '```bash +exec +acquire_terminal +id:foo',
          'echo "Hello"',
          '```',
        }
      end
      vim.fn.line = function()
        return 2
      end
      vim.fn.setline = function(_, content)
        new_line_content = content
      end

      exec.toggle_exec()
      -- Should cycle back to +exec, not plain
      assert.truthy(new_line_content:match('%+exec'))
      assert.truthy(new_line_content:match('%+id:foo'))
      assert.is_falsy(new_line_content:match('%+acquire_terminal'))
    end)

    it('should not return to plain when custom executor is present', function()
      local new_line_content

      -- Start from +exec:rust-script +acquire_terminal with custom executor
      vim.api.nvim_buf_get_lines = function()
        return {
          '```rust +exec:rust-script +acquire_terminal',
          'fn main() {}',
          '```',
        }
      end
      vim.fn.line = function()
        return 2
      end
      vim.fn.setline = function(_, content)
        new_line_content = content
      end

      exec.toggle_exec()
      -- Should NOT have acquire_terminal anymore
      assert.is_falsy(new_line_content:match('%+acquire_terminal'))
      -- Should still have the custom executor
      assert.truthy(new_line_content:match('%+exec:rust%-script'))
      -- Should have cycled back to just +exec:rust-script
      assert.equals('```rust +exec:rust-script', new_line_content)
    end)
  end)

  describe('toggle_exec - Failure Mode Tests', function()
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

    it('should handle cursor at the end of file in unclosed block', function()
      vim.api.nvim_buf_get_lines = function()
        return {
          '```bash +exec',
          'echo test',
        }
      end
      vim.fn.line = function()
        return 2
      end

      local notify_called = false
      vim.notify = function(msg)
        notify_called = true
        assert.truthy(msg:match('[Cc]ode block not properly closed'))
      end

      exec.toggle_exec()
      assert.is_true(notify_called)
    end)

    it('should handle empty buffer', function()
      vim.api.nvim_buf_get_lines = function()
        return {}
      end
      vim.fn.line = function()
        return 1
      end

      local notify_called = false
      vim.notify = function(msg, _)
        notify_called = true
        assert.truthy(msg:match('[Nn]ot'))
      end

      exec.toggle_exec()
      assert.is_true(notify_called)
    end)
  end)

  describe('toggle_exec - Mutation Tests', function()
    it('should not modify other flags when toggling', function()
      local new_line_content

      vim.api.nvim_buf_get_lines = function()
        return {
          '```bash +exec +id:foo +some_other_flag',
          'echo "Hello"',
          '```',
        }
      end
      vim.fn.line = function()
        return 2
      end
      vim.fn.setline = function(_, content)
        new_line_content = content
      end

      exec.toggle_exec()
      -- +id:foo should be preserved
      assert.truthy(new_line_content:match('%+id:foo'))
      -- +some_other_flag should be preserved
      assert.truthy(new_line_content:match('%+some_other_flag'))
    end)

    it('should handle multiple spaces between flags', function()
      local new_line_content

      vim.api.nvim_buf_get_lines = function()
        return {
          '```bash  +exec  +id:foo',
          'echo "Hello"',
          '```',
        }
      end
      vim.fn.line = function()
        return 2
      end
      vim.fn.setline = function(_, content)
        new_line_content = content
      end

      exec.toggle_exec()
      assert.truthy(new_line_content:match('%+id:foo'))
    end)
  end)

  describe('toggle_exec - Property-Based Tests', function()
    it('should always produce valid code fence syntax', function()
      local test_cases = {
        '```bash',
        '```bash +exec',
        '```bash +exec_replace',
        '```bash +exec +acquire_terminal',
        '```bash +exec +id:test',
        '```rust +exec:rust-script',
        '```python +exec:pytest',
      }

      for _, test_case in ipairs(test_cases) do
        local new_line_content

        vim.api.nvim_buf_get_lines = function()
          return {
            test_case,
            'code here',
            '```',
          }
        end
        vim.fn.line = function()
          return 2
        end
        vim.fn.setline = function(_, content)
          new_line_content = content
        end

        exec.toggle_exec()

        -- Should always start with backticks and language
        assert.truthy(new_line_content:match('^```%w+'))
        -- Should not have double spaces (basic sanity check)
        assert.is_falsy(new_line_content:match('  '))
      end
    end)

    it('should be idempotent after 4 cycles (or 3 with special flags)', function()
      local initial = '```bash'
      local current = initial

      for _ = 1, 4 do
        vim.api.nvim_buf_get_lines = function()
          return {
            current,
            'code',
            '```',
          }
        end
        vim.fn.line = function()
          return 2
        end
        vim.fn.setline = function(_, content)
          current = content
        end

        exec.toggle_exec()
      end

      -- After 4 toggles, should be back to plain
      assert.equals(initial, current)
    end)

    it('should maintain cycle for blocks with +id:', function()
      local states = {}
      local current = '```bash +exec +id:test'

      for _ = 1, 6 do
        vim.api.nvim_buf_get_lines = function()
          return {
            current,
            'code',
            '```',
          }
        end
        vim.fn.line = function()
          return 2
        end
        vim.fn.setline = function(_, content)
          current = content
        end

        exec.toggle_exec()
        table.insert(states, current)
      end

      -- With +id:, should never go to plain
      for _, state in ipairs(states) do
        assert.truthy(state:match('%+exec') or state:match('%+id:test'))
        -- Should always have +id:test
        assert.truthy(state:match('%+id:test'))
      end
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
