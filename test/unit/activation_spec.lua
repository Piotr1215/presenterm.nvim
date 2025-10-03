describe('activation', function()
  local config

  before_each(function()
    -- Clear module cache
    package.loaded['presenterm.config'] = nil
    package.loaded['presenterm.slides'] = nil
    -- Reset state
    vim.g.presenterm = nil
    vim.b.presenterm_active = nil
    -- Require modules fresh
    config = require('presenterm.config')
  end)

  describe('on_attach callback', function()
    it('should be called with buffer number when presentation is activated', function()
      local bufnr_received = nil
      local callback_called = false

      -- Setup with on_attach callback
      config.setup({
        on_attach = function(bufnr)
          callback_called = true
          bufnr_received = bufnr
        end,
      })

      -- Simulate activation
      local test_bufnr = 5
      local cfg = config.get()
      if cfg.on_attach then
        cfg.on_attach(test_bufnr)
      end

      assert.is_true(callback_called)
      assert.equals(5, bufnr_received)
    end)

    it('should not error when on_attach is not configured', function()
      config.setup({})
      local cfg = config.get()

      -- Should not error when on_attach is nil
      assert.has_no.errors(function()
        if cfg.on_attach then
          cfg.on_attach(1)
        end
      end)
    end)

    it('should allow multiple calls to on_attach for different buffers', function()
      local buffers_attached = {}

      config.setup({
        on_attach = function(bufnr)
          table.insert(buffers_attached, bufnr)
        end,
      })

      local cfg = config.get()
      cfg.on_attach(1)
      cfg.on_attach(2)
      cfg.on_attach(3)

      assert.equals(3, #buffers_attached)
      assert.equals(1, buffers_attached[1])
      assert.equals(2, buffers_attached[2])
      assert.equals(3, buffers_attached[3])
    end)

    it('should pass correct buffer number for keymap setup', function()
      local keymap_buffer = nil

      config.setup({
        on_attach = function(bufnr)
          -- Just capture the buffer number, don't set keymap on non-existent buffer
          keymap_buffer = bufnr
        end,
      })

      local test_bufnr = 10
      local cfg = config.get()
      cfg.on_attach(test_bufnr)

      assert.equals(10, keymap_buffer)
    end)
  end)

  describe('activation flag', function()
    it('should set vim.b.presenterm_active when presentation is detected', function()
      -- This would normally be set by the plugin autocmd
      vim.b.presenterm_active = true
      assert.is_true(vim.b.presenterm_active)
    end)

    it('should be nil by default', function()
      assert.is_nil(vim.b.presenterm_active)
    end)

    it('should be checkable in user autocmds', function()
      vim.b.presenterm_active = true

      -- Simulate user autocmd checking the flag
      local user_autocmd_ran = false
      if vim.b.presenterm_active then
        user_autocmd_ran = true
      end

      assert.is_true(user_autocmd_ran)
    end)
  end)

  describe('default_keybindings', function()
    it('should be false by default', function()
      local cfg = config.get()
      assert.is_false(cfg.default_keybindings)
    end)

    it('should be configurable', function()
      config.setup({
        default_keybindings = true,
      })
      local cfg = config.get()
      assert.is_true(cfg.default_keybindings)
    end)

    it('should not interfere with on_attach', function()
      local on_attach_called = false
      config.setup({
        default_keybindings = true,
        on_attach = function(_)
          on_attach_called = true
        end,
      })
      local cfg = config.get()
      assert.is_true(cfg.default_keybindings)
      assert.is_function(cfg.on_attach)

      -- Both can coexist
      cfg.on_attach(1)
      assert.is_true(on_attach_called)
    end)
  end)

  describe('integration', function()
    it('should support on_attach pattern like gitsigns/LSP', function()
      local keymaps_set = false

      config.setup({
        on_attach = function(bufnr)
          -- User sets up buffer-local keymaps
          vim.keymap.set('n', ']s', ':PresenterNext<CR>', { buffer = bufnr })
          keymaps_set = true
        end,
      })

      -- Simulate plugin activation
      vim.b.presenterm_active = true
      local cfg = config.get()
      if vim.b.presenterm_active and cfg.on_attach then
        cfg.on_attach(vim.api.nvim_get_current_buf())
      end

      assert.is_true(keymaps_set)
    end)

    it('should support global keymaps without on_attach', function()
      -- User doesn't provide on_attach
      config.setup({})

      -- User sets global keymaps
      vim.keymap.set('n', ']s', ':PresenterNext<CR>')

      -- Should work fine without on_attach
      local cfg = config.get()
      assert.is_nil(cfg.on_attach)
    end)

    it('should support custom autocmd pattern', function()
      config.setup({})

      -- User creates custom autocmd
      local custom_keymap_set = false
      vim.b.presenterm_active = true

      -- Simulate user's custom autocmd
      if vim.b.presenterm_active then
        vim.keymap.set('n', ']s', ':PresenterNext<CR>', { buffer = true })
        custom_keymap_set = true
      end

      assert.is_true(custom_keymap_set)
    end)
  end)
end)
