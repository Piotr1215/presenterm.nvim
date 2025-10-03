describe('pickers', function()
  local pickers

  before_each(function()
    -- Clear module cache
    package.loaded['presenterm.pickers'] = nil
    package.loaded['presenterm.pickers.init'] = nil
    package.loaded['presenterm.pickers.telescope'] = nil
    package.loaded['presenterm.pickers.fzf'] = nil
    package.loaded['presenterm.pickers.snacks'] = nil
    package.loaded['presenterm.navigation'] = nil
    package.loaded['presenterm.partials'] = nil
    package.loaded['presenterm.config'] = nil
    package.loaded['presenterm.layout'] = nil

    -- Mock vim.ui.select
    vim.ui = vim.ui or {}
    vim.ui.select = function(items, opts, on_choice)
      -- Simulate selecting first item
      if #items > 0 then
        on_choice(items[1], 1)
      end
    end

    -- Mock config
    package.loaded['presenterm.config'] = {
      get = function()
        return {}
      end,
    }

    pickers = require('presenterm.pickers')
  end)

  describe('detect', function()
    it('returns telescope when available', function()
      package.loaded['telescope'] = { setup = function() end }
      package.loaded['presenterm.pickers.init'] = nil
      pickers = require('presenterm.pickers')

      assert.equals('telescope', pickers.detect())
    end)

    it('returns fzf when telescope not available but fzf-lua is', function()
      package.loaded['telescope'] = nil
      package.loaded['fzf-lua'] = { setup = function() end }
      package.loaded['presenterm.pickers.init'] = nil
      pickers = require('presenterm.pickers')

      assert.equals('fzf', pickers.detect())
    end)

    it('returns snacks when only snacks is available', function()
      package.loaded['telescope'] = nil
      package.loaded['fzf-lua'] = nil
      package.loaded['snacks'] = { setup = function() end }
      package.loaded['presenterm.pickers.init'] = nil
      pickers = require('presenterm.pickers')

      assert.equals('snacks', pickers.detect())
    end)

    it('returns builtin when no pickers available', function()
      package.loaded['telescope'] = nil
      package.loaded['fzf-lua'] = nil
      package.loaded['snacks'] = nil
      package.loaded['presenterm.pickers.init'] = nil
      pickers = require('presenterm.pickers')

      assert.equals('builtin', pickers.detect())
    end)
  end)

  describe('get_picker', function()
    it('uses configured picker when available', function()
      package.loaded['presenterm.config'] = {
        get = function()
          return { picker = { provider = 'fzf' } }
        end,
      }
      package.loaded['fzf-lua'] = { setup = function() end }
      package.loaded['presenterm.pickers.init'] = nil
      pickers = require('presenterm.pickers')

      assert.equals('fzf', pickers.get_picker())
    end)

    it('falls back to auto-detect when configured picker not available', function()
      local notify_called = false
      vim.notify = function(msg, level)
        notify_called = true
        assert.is_true(msg:find('not found') ~= nil)
      end

      package.loaded['presenterm.config'] = {
        get = function()
          return { picker = { provider = 'nonexistent' } }
        end,
      }
      package.loaded['telescope'] = { setup = function() end }
      package.loaded['presenterm.pickers.init'] = nil
      pickers = require('presenterm.pickers')

      local result = pickers.get_picker()
      assert.is_true(notify_called)
      assert.equals('telescope', result)
    end)

    it('uses auto-detect when no config provided', function()
      package.loaded['telescope'] = { setup = function() end }
      package.loaded['presenterm.pickers.init'] = nil
      pickers = require('presenterm.pickers')

      assert.equals('telescope', pickers.get_picker())
    end)
  end)

  describe('fallback pickers', function()
    before_each(function()
      -- Ensure no pickers are available for fallback tests
      package.loaded['telescope'] = nil
      package.loaded['fzf-lua'] = nil
      package.loaded['snacks'] = nil

      -- Set up base config first
      package.loaded['presenterm.config'] = {
        get = function()
          return {
            partials = {
              directory = '_partials',
            },
          }
        end,
      }

      -- Mock dependencies
      package.loaded['presenterm.navigation'] = {
        get_slide_titles = function()
          return {
            { index = 1, title = 'Slide 1', has_partial = false, preview = 'Preview 1' },
            { index = 2, title = 'Slide 2', has_partial = true, preview = 'Preview 2' },
          }
        end,
        go_to_slide = function(index) end,
      }

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

      package.loaded['presenterm.layout'] = {
        get_templates = function()
          return {
            ['50/50'] = { name = 'Two Column (50/50)', dimensions = { 1, 1 } },
          }
        end,
        insert_layout = function(dimensions) end,
      }

      package.loaded['presenterm.pickers.init'] = nil
      pickers = require('presenterm.pickers')
    end)

    it('slide_picker uses vim.ui.select fallback', function()
      local select_called = false
      vim.ui.select = function(items, opts, on_choice)
        select_called = true
        assert.is_not_nil(items)
        assert.is_true(#items > 0)
        assert.equals('Select slide:', opts.prompt)
        on_choice(items[1], 1)
      end

      pickers.slide_picker()
      assert.is_true(select_called)
    end)

    it('layout_picker uses vim.ui.select fallback', function()
      local select_called = false
      vim.ui.select = function(items, opts, on_choice)
        select_called = true
        assert.is_true(#items > 0)
        assert.equals('Select column layout:', opts.prompt)
        on_choice(items[1], 1)
      end

      pickers.layout_picker()
      assert.is_true(select_called)
    end)
  end)
end)
