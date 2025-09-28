describe('config', function()
  local config

  before_each(function()
    -- Clear module cache
    package.loaded['presenterm.config'] = nil
    -- Reset config before each test
    vim.g.presenterm = nil
    -- Require module fresh
    config = require('presenterm.config')
  end)

  describe('defaults', function()
    it('should have correct default values', function()
      assert.equals('<!-- end_slide -->', config.defaults.slide_marker)
      assert.equals('_partials', config.defaults.partials.directory)
      assert.is_true(config.defaults.partials.resolve_relative)
      assert.equals('presenterm', config.defaults.preview.command)
      assert.equals('dropdown', config.defaults.telescope.theme)
    end)
  end)

  describe('get', function()
    it('should return defaults when not configured', function()
      vim.g.presenterm = nil
      local cfg = config.get()
      assert.equals('<!-- end_slide -->', cfg.slide_marker)
      assert.equals('_partials', cfg.partials.directory)
    end)

    it('should return stored config when available', function()
      vim.g.presenterm = {
        slide_marker = '---',
        partials = { directory = 'custom' },
      }
      local cfg = config.get()
      assert.equals('---', cfg.slide_marker)
      assert.equals('custom', cfg.partials.directory)
    end)

    it('should initialize vim.g.presenterm if not set', function()
      vim.g.presenterm = nil
      config.get()
      assert.is_not_nil(vim.g.presenterm)
    end)
  end)

  describe('setup', function()
    it('should do nothing when opts is nil', function()
      vim.g.presenterm = nil
      config.setup()
      assert.is_nil(vim.g.presenterm)
    end)

    it('should merge options with defaults', function()
      config.setup({
        slide_marker = '~~~',
        partials = { directory = 'parts' },
      })
      assert.equals('~~~', vim.g.presenterm.slide_marker)
      assert.equals('parts', vim.g.presenterm.partials.directory)
      assert.is_true(vim.g.presenterm.partials.resolve_relative) -- default preserved
    end)

    it('should deep extend nested tables', function()
      config.setup({
        telescope = { theme = 'ivy' },
      })
      assert.equals('ivy', vim.g.presenterm.telescope.theme)
      assert.is_not_nil(vim.g.presenterm.telescope.layout_config) -- defaults preserved
    end)
  end)
end)
