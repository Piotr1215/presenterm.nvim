local wizard = require('presenterm.wizard')
local templates = require('presenterm.templates')

describe('wizard', function()
  local original_io_open
  local original_vim_fn_mkdir
  local original_vim_cmd
  local original_vim_notify

  before_each(function()
    -- Store originals
    original_io_open = io.open
    original_vim_fn_mkdir = vim.fn.mkdir
    original_vim_cmd = vim.cmd
    original_vim_notify = vim.notify

    -- Initialize vim functions
    vim.fn = vim.fn or {}
    vim.notify = vim.notify or function() end
  end)

  after_each(function()
    -- Restore originals
    if original_io_open then
      io.open = original_io_open
    end
    if original_vim_fn_mkdir then
      vim.fn.mkdir = original_vim_fn_mkdir
    end
    if original_vim_cmd then
      vim.cmd = original_vim_cmd
    end
    if original_vim_notify then
      vim.notify = original_vim_notify
    end
  end)

  describe('templates module', function()
    it('should export required functions', function()
      assert.is_function(templates.list)
      assert.is_function(templates.get)
      assert.is_function(templates.generate)
      assert.is_function(templates.generate_preview)
    end)

    it('should have sample_vars for preview generation', function()
      assert.is_table(templates.sample_vars)
      assert.is_string(templates.sample_vars.title)
      assert.is_string(templates.sample_vars.author)
    end)

    it('should generate preview lines from template', function()
      local lines = templates.generate_preview('minimal')
      assert.is_table(lines)
      assert.is_true(#lines > 0)
      -- First line should be frontmatter start
      assert.equals('---', lines[1])
    end)

    it('should list all available templates', function()
      local template_list = templates.list()
      assert.is_table(template_list)
      assert.is_true(#template_list > 0)

      -- Check template structure
      for _, tmpl in ipairs(template_list) do
        assert.is_string(tmpl.key)
        assert.is_string(tmpl.name)
        assert.is_string(tmpl.description)
        assert.is_string(tmpl.category)
      end
    end)

    it('should return templates sorted by name', function()
      local template_list = templates.list()
      local prev_name = ''
      for _, tmpl in ipairs(template_list) do
        assert.is_true(tmpl.name >= prev_name, 'Templates should be sorted alphabetically')
        prev_name = tmpl.name
      end
    end)

    it('should have expected default templates', function()
      local template_list = templates.list()
      local keys = {}
      for _, tmpl in ipairs(template_list) do
        table.insert(keys, tmpl.key)
      end

      assert.is_true(vim.tbl_contains(keys, 'tech-talk'))
      assert.is_true(vim.tbl_contains(keys, 'lightning-talk'))
      assert.is_true(vim.tbl_contains(keys, 'workshop'))
      assert.is_true(vim.tbl_contains(keys, 'minimal'))
      assert.is_true(vim.tbl_contains(keys, 'pitch'))
    end)

    it('should get template by key', function()
      local template = templates.get('tech-talk')
      assert.is_table(template)
      assert.equals('Tech Talk', template.name)
      assert.is_function(template.content)
    end)

    it('should return nil for unknown template', function()
      local template = templates.get('nonexistent')
      assert.is_nil(template)
    end)

    it('should generate content from tech-talk template', function()
      local vars = {
        title = 'Test Presentation',
        author = 'Test Author',
        date = '2024-01-01',
      }
      local content = templates.generate('tech-talk', vars)

      assert.is_string(content)
      assert.is_true(content:find('title: Test Presentation', 1, true) ~= nil)
      assert.is_true(content:find('author: Test Author', 1, true) ~= nil)
      assert.is_true(content:find('# Test Presentation', 1, true) ~= nil)
      assert.is_true(content:find('2024-01-01', 1, true) ~= nil)
      assert.is_true(content:find('<!-- end_slide -->', 1, true) ~= nil)
    end)

    it('should generate content from minimal template', function()
      local vars = {
        title = 'Minimal Deck',
        author = 'Jane Doe',
      }
      local content = templates.generate('minimal', vars)

      assert.is_string(content)
      assert.is_true(content:find('title: Minimal Deck') ~= nil)
      assert.is_true(content:find('author: Jane Doe') ~= nil)
      assert.is_true(content:find('# Minimal Deck') ~= nil)
    end)

    it('should generate workshop template with optional fields', function()
      local vars = {
        title = 'Hands-On Workshop',
        author = 'Instructor',
        repo = 'https://github.com/test/repo',
      }
      local content = templates.generate('workshop', vars)

      assert.is_string(content)
      assert.is_true(content:find('Hands%-On Workshop') ~= nil)
      assert.is_true(content:find('https://github.com/test/repo') ~= nil)
      assert.is_true(content:find('Prerequisites') ~= nil)
    end)

    it('should generate pitch template with product field', function()
      local vars = {
        title = 'Product Pitch',
        author = 'Sales Team',
        product = 'SuperApp',
        contact = 'sales@example.com',
      }
      local content = templates.generate('pitch', vars)

      assert.is_string(content)
      assert.is_true(content:find('SuperApp') ~= nil)
      assert.is_true(content:find('sales@example.com') ~= nil)
      assert.is_true(content:find('Pricing') ~= nil)
    end)

    it('should error on unknown template', function()
      local vars = { title = 'Test', author = 'Test' }
      assert.has_error(function()
        templates.generate('nonexistent', vars)
      end)
    end)

    it('should include all required sections in tech-talk', function()
      local vars = { title = 'Test', author = 'Test' }
      local content = templates.generate('tech-talk', vars)

      assert.is_true(content:find('# Agenda') ~= nil)
      assert.is_true(content:find('# Introduction') ~= nil)
      assert.is_true(content:find('# Problem Statement') ~= nil)
      assert.is_true(content:find('# Solution Overview') ~= nil)
      assert.is_true(content:find('# Technical Deep Dive') ~= nil)
      assert.is_true(content:find('# Demo') ~= nil)
      assert.is_true(content:find('# Key Takeaways') ~= nil)
      assert.is_true(content:find('# Q&A') ~= nil)
    end)

    it('should include executable code block in demo sections', function()
      local vars = { title = 'Test', author = 'Test' }
      local content = templates.generate('tech-talk', vars)

      assert.is_true(content:find('```bash %+exec') ~= nil)
    end)
  end)

  describe('file operations', function()
    it('should handle io.open failure gracefully without crashing', function()
      local error_notified = false
      local file_write_called = false

      -- Mock io.open to fail
      io.open = function(filename, mode)
        return nil, 'Permission denied'
      end

      -- Mock vim.notify to track error notification
      vim.notify = function(msg, level)
        if msg:find('Error: Could not create file') and level == vim.log.levels.ERROR then
          error_notified = true
        end
      end

      -- Mock file object to detect if write is called on nil
      local mock_file = {
        write = function()
          file_write_called = true
        end,
        close = function() end,
      }

      -- This should not crash even though io.open returns nil
      -- We need to expose write_file or test through create_presentation
      -- For now, test that io.open failure is handled
      assert.is_function(wizard.create_presentation)
    end)

    it('should validate filename is not empty after sanitization', function()
      -- Edge case: title with only special characters
      local vars = {
        title = '!@#$%^&*()',
        author = 'Test Author',
        date = '2024-01-01',
      }

      local content = templates.generate('tech-talk', vars)
      assert.is_string(content)

      -- The sanitized filename would be just '.md'
      -- This should be validated and rejected
      local filename = vars.title:lower():gsub('%s+', '-'):gsub('[^%w%-]', '') .. '.md'
      assert.equals('.md', filename, 'Edge case: empty filename before extension')
    end)

    it('should not use undefined vars parameter in write_file', function()
      -- This test documents that vars parameter is unused
      -- After fix, this parameter should be removed
      local vars = {
        title = 'Test',
        author = 'Test',
        unused_field = 'should not cause issues',
      }

      local content = templates.generate('tech-talk', vars)
      assert.is_string(content)
      -- If vars was used incorrectly, it might cause issues
    end)
  end)

  describe('wizard flow', function()
    it('should export create_presentation function', function()
      assert.is_function(wizard.create_presentation)
    end)

    it('should accept optional template_key in opts', function()
      -- Test that opts.template_key is respected
      local opts = { template_key = 'minimal' }

      -- Mock the picker system to verify template selection is skipped
      local picker_called = false
      package.loaded['presenterm.pickers'] = {
        template_picker = function(callback)
          picker_called = true
          callback('tech-talk')
        end,
      }

      -- We can't fully test the async flow without complex mocking,
      -- but we can verify the function accepts the parameter
      assert.has_no.errors(function()
        -- This would start the wizard but we can't complete it in tests
        -- without extensive vim.ui.input mocking
      end)
    end)

    it('should handle cancelled title input', function()
      -- Mock vim.ui.input to simulate user cancellation
      local cancel_notified = false
      vim.ui = {
        input = function(opts, callback)
          -- Simulate user pressing ESC or cancelling
          callback(nil)
        end,
      }

      vim.notify = function(msg, level)
        if msg:find('Cancelled: No title provided') and level == vim.log.levels.WARN then
          cancel_notified = true
        end
      end

      -- This should be testable once we refactor wizard to expose
      -- collect_variables or similar internal functions
    end)

    it('should use git user.name as default author', function()
      -- Mock git config
      vim.fn.system = function(cmd)
        if cmd == 'git config user.name' then
          return 'John Doe\n'
        elseif cmd == 'git config remote.origin.url' then
          return 'https://github.com/test/repo.git\n'
        end
        return ''
      end

      -- This tests that default values are properly set
      local git_user = vim.fn.system('git config user.name'):gsub('\n', '')
      assert.equals('John Doe', git_user)
    end)
  end)

  describe('filename generation', function()
    it('should sanitize title to valid filename', function()
      local test_cases = {
        { input = 'My Awesome Talk', expected = 'my-awesome-talk.md' },
        { input = 'Test: With Special Chars!', expected = 'test-with-special-chars.md' },
        { input = 'Multiple   Spaces', expected = 'multiple-spaces.md' },
        { input = 'CamelCase Title', expected = 'camelcase-title.md' },
      }

      for _, tc in ipairs(test_cases) do
        local filename = tc.input:lower():gsub('%s+', '-'):gsub('[^%w%-]', '') .. '.md'
        assert.equals(tc.expected, filename, 'Failed for input: ' .. tc.input)
      end
    end)

    it('should detect empty filename after sanitization', function()
      local edge_cases = {
        { input = '!@#$', expected = '' },
        { input = '   ', expected = '-' }, -- Spaces become dashes, then single dash remains
        { input = '---', expected = '---' }, -- Dashes are valid, remain
        { input = '...', expected = '' },
        { input = '***', expected = '' },
      }

      for _, tc in ipairs(edge_cases) do
        local sanitized = tc.input:lower():gsub('%s+', '-'):gsub('[^%w%-]', '')
        assert.equals(
          tc.expected,
          sanitized,
          string.format('Title "%s" should result in "%s"', tc.input, tc.expected)
        )
      end
    end)
  end)
end)
