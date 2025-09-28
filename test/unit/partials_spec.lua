describe('partials', function()
  local partials

  before_each(function()
    -- Clear module cache
    package.loaded['presenterm.partials'] = nil
    package.loaded['presenterm.config'] = nil

    -- Set up default config
    vim.g.presenterm = {
      partials = {
        directory = '_partials',
        resolve_relative = true,
      },
    }

    -- Initialize vim.fn and vim.api if they don't exist
    vim.fn = vim.fn or {}
    vim.api = vim.api or {}
    vim.log = vim.log or { levels = { ERROR = 4, WARN = 3, INFO = 2 } }

    partials = require('presenterm.partials')

    -- Mock vim functions
    vim.fn.expand = function(expr)
      if expr == '%:p' then
        return '/home/user/project/presentation.md'
      elseif expr == '%:p:h' then
        return '/home/user/project'
      end
      return ''
    end

    vim.fn.fnamemodify = function(fname, mods)
      if mods == ':h' then
        return '/home/user/project'
      elseif mods == ':t' then
        return fname:match('[^/]+$') or fname
      elseif mods == ':r' then
        return fname:gsub('%.md$', '')
      end
      return fname
    end

    vim.fn.simplify = function(path)
      return path:gsub('//', '/')
    end

    vim.fn.filereadable = function(path)
      if path:match('intro%.md$') or path:match('demo%.md$') or path:match('conclusion%.md$') then
        return 1
      end
      return 0
    end

    vim.fn.readfile = function(path)
      if path:match('intro%.md$') then
        return {
          '# Introduction',
          '',
          'This is the introduction content.',
        }
      elseif path:match('demo%.md$') then
        return {
          '## Demo Section',
          'Demo content here',
        }
      elseif path:match('conclusion%.md$') then
        return {
          'Just text without header',
        }
      end
      return {}
    end

    vim.fn.glob = function(pattern, _, _)
      if pattern:match('_partials') then
        return {
          '/home/user/project/_partials/intro.md',
          '/home/user/project/_partials/demo.md',
          '/home/user/project/_partials/conclusion.md',
        }
      end
      return {}
    end

    vim.fn.system = function(cmd)
      if cmd:match('git rev%-parse') then
        return '/home/user/project\n'
      end
      return ''
    end

    vim.fn.isdirectory = function(dir)
      if dir:match('_partials$') then
        return 1
      end
      return 0
    end

    vim.fn.fnameescape = function(path)
      return path:gsub(' ', '\\ ')
    end

    vim.api.nvim_get_current_line = function()
      return ''
    end

    vim.api.nvim_put = function() end

    vim.cmd = function() end
    vim.notify = function() end

    -- Mock io.open for find_partials
    _G.io = _G.io or {}
    _G.io.open = function(path)
      if path:match('intro%.md$') then
        local lines = { '# Introduction', '', 'This is the introduction content.' }
        local i = 0
        return {
          lines = function()
            return function()
              i = i + 1
              return lines[i]
            end
          end,
          close = function() end,
        }
      elseif path:match('demo%.md$') then
        local lines = { '## Demo Section', 'Demo content here' }
        local i = 0
        return {
          lines = function()
            return function()
              i = i + 1
              return lines[i]
            end
          end,
          close = function() end,
        }
      elseif path:match('conclusion%.md$') then
        local lines = { 'Just text without header' }
        local i = 0
        return {
          lines = function()
            return function()
              i = i + 1
              return lines[i]
            end
          end,
          close = function() end,
        }
      end
      return nil
    end
  end)

  describe('expand_partial_content', function()
    it('should expand partial content when line contains include directive', function()
      local line = '<!-- include: ../_partials/intro.md -->'
      local content = partials.expand_partial_content(line)
      assert.is_not_nil(content)
      assert.equals(3, #content)
      assert.equals('# Introduction', content[1])
    end)

    it('should return nil when line does not contain include directive', function()
      local line = 'This is just regular text'
      local content = partials.expand_partial_content(line)
      assert.is_nil(content)
    end)

    it('should return nil when file does not exist', function()
      vim.fn.filereadable = function()
        return 0
      end
      local line = '<!-- include: nonexistent.md -->'
      local content = partials.expand_partial_content(line)
      assert.is_nil(content)
    end)
  end)

  describe('get_partial_path', function()
    it('should extract path from include directive', function()
      local line = '<!-- include: ../_partials/intro.md -->'
      local path = partials.get_partial_path(line)
      assert.is_not_nil(path)
      assert.truthy(path:match('intro%.md'))
    end)

    it('should return nil for non-include line', function()
      local line = 'Regular text'
      local path = partials.get_partial_path(line)
      assert.is_nil(path)
    end)

    it('should return nil when file does not exist', function()
      vim.fn.filereadable = function()
        return 0
      end
      local line = '<!-- include: missing.md -->'
      local path = partials.get_partial_path(line)
      assert.is_nil(path)
    end)
  end)

  describe('find_partials', function()
    it('should find all partial files', function()
      local entries = partials.find_partials()
      assert.is_table(entries)
      assert.equals(3, #entries)
    end)

    it('should extract titles from headers', function()
      local entries = partials.find_partials()
      local intro_found = false
      for _, entry in ipairs(entries) do
        if entry.filename == 'intro.md' then
          intro_found = true
          assert.equals('Introduction', entry.title)
          break
        end
      end
      assert.is_true(intro_found)
    end)

    it('should handle missing git root', function()
      vim.fn.system = function()
        return ''
      end
      local entries = partials.find_partials()
      assert.is_table(entries)
      assert.equals(0, #entries)
    end)

    it('should handle missing partials directory', function()
      vim.fn.isdirectory = function()
        return 0
      end
      local entries = partials.find_partials()
      assert.is_table(entries)
      assert.equals(0, #entries)
    end)
  end)

  describe('insert_partial_include', function()
    it('should insert include directive', function()
      local put_content
      vim.api.nvim_put = function(lines)
        put_content = lines[1]
      end

      partials.insert_partial_include('../_partials/intro.md')
      assert.is_not_nil(put_content)
      assert.truthy(put_content:match('<!%-%- include:'))
      assert.truthy(put_content:match('intro%.md'))
    end)
  end)

  describe('edit_partial', function()
    it('should open existing file for editing', function()
      local edit_cmd
      vim.cmd = function(cmd)
        if cmd:match('^edit ') then
          edit_cmd = cmd
        end
      end

      partials.edit_partial('/home/user/project/_partials/intro.md')
      assert.is_not_nil(edit_cmd)
      assert.truthy(edit_cmd:match('intro%.md'))
    end)

    it('should notify when file does not exist', function()
      vim.fn.filereadable = function()
        return 0
      end

      local notify_called = false
      vim.notify = function(msg, level)
        notify_called = true
        assert.truthy(msg:match('[Nn]ot found'))
        assert.equals(vim.log.levels.ERROR, level)
      end

      partials.edit_partial('/path/to/missing.md')
      assert.is_true(notify_called)
    end)
  end)

  describe('is_partial_include', function()
    it('should detect include directive', function()
      vim.api.nvim_get_current_line = function()
        return '<!-- include: ../_partials/intro.md -->'
      end
      assert.is_true(partials.is_partial_include())
    end)

    it('should return false for regular line', function()
      vim.api.nvim_get_current_line = function()
        return 'Regular text'
      end
      assert.is_false(partials.is_partial_include())
    end)
  end)

  describe('open_partial_at_cursor', function()
    it('should open partial when on include line', function()
      vim.api.nvim_get_current_line = function()
        return '<!-- include: ../_partials/intro.md -->'
      end

      local edit_cmd
      vim.cmd = function(cmd)
        if cmd:match('^edit ') then
          edit_cmd = cmd
        end
      end

      partials.open_partial_at_cursor()
      assert.is_not_nil(edit_cmd)
      assert.truthy(edit_cmd:match('intro%.md'))
    end)

    it('should notify when not on include line', function()
      vim.api.nvim_get_current_line = function()
        return 'Regular text'
      end

      local notify_called = false
      vim.notify = function(msg, level)
        notify_called = true
        assert.truthy(msg:match('[Nn]ot on'))
        assert.equals(vim.log.levels.WARN, level)
      end

      partials.open_partial_at_cursor()
      assert.is_true(notify_called)
    end)
  end)
end)
