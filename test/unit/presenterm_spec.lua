local presenterm = require('presenterm')

describe('presenterm', function()
  describe('setup', function()
    it('should initialize with default config', function()
      presenterm.setup()
      assert.is_not_nil(presenterm)
    end)

    it('should accept custom config', function()
      presenterm.setup({
        slide_marker = '---',
        partials = {
          directory = 'custom_partials',
        },
      })
      assert.is_not_nil(presenterm)
    end)
  end)

  describe('slide_status', function()
    it('should return empty string when not in presentation', function()
      -- Clear any activation state
      vim.b.presenterm_active = nil
      local status = presenterm.slide_status()
      assert.equals('', status)
    end)
  end)

  describe('hide command', function()
    local saved_api, saved_presenterm, saved_keymap_set, saved_loaded

    before_each(function()
      saved_api = vim.tbl_extend('force', {}, vim.api)
      saved_presenterm = package.loaded['presenterm']
      saved_keymap_set = vim.keymap.set
      saved_loaded = vim.g.loaded_presenterm
    end)

    after_each(function()
      for name, fn in pairs(saved_api) do
        vim.api[name] = fn
      end
      package.loaded['presenterm'] = saved_presenterm
      package.loaded['presenterm.keybindings'] = nil
      vim.keymap.set = saved_keymap_set
      vim.g.loaded_presenterm = saved_loaded
    end)

    it('should toggle the slide through :Presenterm hide', function()
      local command
      local calls = 0
      vim.api.nvim_create_user_command = function(_, fn)
        command = fn
      end
      vim.api.nvim_create_autocmd = function() end
      vim.g.loaded_presenterm = nil
      dofile('plugin/presenterm.lua')
      package.loaded['presenterm'] = {
        toggle_hide_slide = function()
          calls = calls + 1
        end,
      }

      command({ fargs = { 'hide' } })

      assert.equals(1, calls)
    end)

    it('should bind and list <leader>sh as a default key', function()
      local bound = {}
      vim.keymap.set = function(mode, lhs, rhs)
        bound[mode .. lhs] = rhs
      end
      package.loaded['presenterm.keybindings'] = nil
      local keybindings = require('presenterm.keybindings')

      keybindings.setup_default(vim.api.nvim_get_current_buf())

      assert.is_function(presenterm.toggle_hide_slide)
      assert.equals(presenterm.toggle_hide_slide, bound['n<leader>sh'])
      assert.same(
        { { mode = 'n', lhs = '<leader>sh' } },
        vim.tbl_filter(function(key)
          return key.lhs == '<leader>sh'
        end, keybindings.default_keys)
      )
    end)
  end)
end)
