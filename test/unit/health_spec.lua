describe('health', function()
  local health
  local health_state

  before_each(function()
    -- Clear module cache
    package.loaded['presenterm.health'] = nil
    package.loaded['presenterm.config'] = nil
    package.loaded['presenterm'] = nil

    -- Reset health state for tracking calls
    health_state = {
      starts = {},
      oks = {},
      warns = {},
      errors = {},
      infos = {},
    }

    -- Mock vim.health API (compatible with both old and new API)
    vim.health = {
      start = function(name)
        table.insert(health_state.starts, name)
      end,
      ok = function(msg)
        table.insert(health_state.oks, msg)
      end,
      warn = function(msg)
        table.insert(health_state.warns, msg)
      end,
      error = function(msg)
        table.insert(health_state.errors, msg)
      end,
      info = function(msg)
        table.insert(health_state.infos, msg)
      end,
    }

    -- Mock vim.fn functions
    vim.fn = vim.fn or {}
    vim.fn.expand = function()
      return ''
    end
    vim.fn.fnamemodify = function()
      return ''
    end

    -- Mock vim.loop
    vim.loop = vim.loop or {}
    vim.loop.fs_stat = function()
      return nil
    end

    -- Set up basic config
    vim.g.presenterm = {
      slide_marker = '<!-- end_slide -->',
      partials = {
        directory = '_partials',
        resolve_relative = true,
      },
      preview = {
        command = 'presenterm',
        presentation_preview_sync = false,
        login_shell = true,
      },
      picker = {
        provider = nil,
      },
      default_keybindings = false,
    }

    -- Mock io.popen for CLI checks
    _G.original_io_popen = io.popen
  end)

  after_each(function()
    -- Restore io.popen
    if _G.original_io_popen then
      io.popen = _G.original_io_popen
      _G.original_io_popen = nil
    end
    health_state = nil
  end)

  describe('check', function()
    it('should run without errors when plugin is properly loaded', function()
      -- Mock presenterm module loading
      package.loaded['presenterm'] = {
        next_slide = function() end,
      }

      -- Mock io.popen to simulate presenterm CLI found
      io.popen = function(cmd)
        if cmd:match('which presenterm') then
          return {
            read = function()
              return '/usr/local/bin/presenterm\n'
            end,
            close = function() end,
          }
        end
        return {
          read = function()
            return ''
          end,
          close = function() end,
        }
      end

      health = require('presenterm.health')

      assert.has_no_error(function()
        health.check()
      end)

      -- Should have multiple start sections
      assert.is_true(#health_state.starts > 0)
      -- Should have some OK messages
      assert.is_true(#health_state.oks > 0)
    end)

    it('should run basic health checks', function()
      -- Mock presenterm module
      package.loaded['presenterm'] = {
        next_slide = function() end,
      }

      -- Mock io.popen
      io.popen = function()
        return {
          read = function()
            return ''
          end,
          close = function() end,
        }
      end

      health = require('presenterm.health')
      health.check()

      -- Should have started health check and produced some output
      assert.is_true(#health_state.starts > 0, 'Should start health check sections')
      -- Should have at least some messages (ok, info, or warn)
      local total_messages = #health_state.oks + #health_state.infos + #health_state.warns
      assert.is_true(total_messages > 0, 'Should produce health check messages')
    end)

    it('should detect presenterm CLI when available', function()
      -- Mock presenterm module
      package.loaded['presenterm'] = {
        next_slide = function() end,
      }

      -- Mock io.popen to simulate presenterm CLI found
      io.popen = function(cmd)
        if cmd:match('which presenterm') then
          return {
            read = function()
              return '/usr/local/bin/presenterm\n'
            end,
            close = function() end,
          }
        end
        return {
          read = function()
            return ''
          end,
          close = function() end,
        }
      end

      health = require('presenterm.health')
      health.check()

      local has_cli_message = vim.tbl_filter(function(msg)
        return msg:match('presenterm CLI found')
      end, health_state.oks)
      assert.is_true(#has_cli_message > 0, 'Should detect presenterm CLI')
    end)

    it('should warn when presenterm CLI is not available', function()
      -- Mock presenterm module
      package.loaded['presenterm'] = {
        next_slide = function() end,
      }

      -- Mock io.popen to simulate presenterm CLI not found
      io.popen = function(cmd)
        if cmd:match('which presenterm') then
          return {
            read = function()
              return ''
            end,
            close = function() end,
          }
        end
        return {
          read = function()
            return ''
          end,
          close = function() end,
        }
      end

      health = require('presenterm.health')
      health.check()

      local has_cli_warning = vim.tbl_filter(function(msg)
        return msg:match('presenterm CLI not found')
      end, health_state.warns)
      assert.is_true(#has_cli_warning > 0, 'Should warn when CLI not found')
    end)

    it('should check picker plugins availability', function()
      -- Mock presenterm module
      package.loaded['presenterm'] = {
        next_slide = function() end,
      }

      -- Mock telescope as available
      package.loaded['telescope'] = {}

      -- Mock io.popen for CLI check
      io.popen = function()
        return {
          read = function()
            return ''
          end,
          close = function() end,
        }
      end

      health = require('presenterm.health')
      health.check()

      local all_messages =
        vim.list_extend(vim.list_extend({}, health_state.oks), health_state.infos)
      local telescope_message = vim.tbl_filter(function(msg)
        return type(msg) == 'string' and msg:match('telescope')
      end, all_messages)
      assert.is_true(#telescope_message > 0, 'Should check for telescope')
    end)

    it('should validate configuration settings', function()
      -- Mock presenterm module
      package.loaded['presenterm'] = {
        next_slide = function() end,
      }

      -- Mock io.popen
      io.popen = function()
        return {
          read = function()
            return ''
          end,
          close = function() end,
        }
      end

      health = require('presenterm.health')
      health.check()

      local slide_marker_message = vim.tbl_filter(function(msg)
        return msg:match('Slide marker')
      end, health_state.oks)
      assert.is_true(#slide_marker_message > 0, 'Should validate slide marker')
    end)

    it('should check preview configuration', function()
      -- Mock presenterm module
      package.loaded['presenterm'] = {
        next_slide = function() end,
      }

      -- Mock io.popen
      io.popen = function()
        return {
          read = function()
            return ''
          end,
          close = function() end,
        }
      end

      health = require('presenterm.health')
      health.check()

      -- Should have info messages about preview configuration
      local preview_messages = vim.tbl_filter(function(msg)
        return type(msg) == 'string'
          and (msg:match('[Pp]review') or msg:match('sync') or msg:match('shell'))
      end, health_state.infos)
      assert.is_true(#preview_messages > 0, 'Should report preview configuration')
    end)

    it('should check bi-directional sync configuration', function()
      -- Enable sync
      vim.g.presenterm.preview.presentation_preview_sync = true

      -- Mock presenterm module
      package.loaded['presenterm'] = {
        next_slide = function() end,
      }

      -- Mock io.popen
      io.popen = function()
        return {
          read = function()
            return ''
          end,
          close = function() end,
        }
      end

      health = require('presenterm.health')
      health.check()

      local all_messages =
        vim.list_extend(vim.list_extend({}, health_state.oks), health_state.infos)
      local sync_messages = vim.tbl_filter(function(msg)
        return type(msg) == 'string' and msg:match('sync')
      end, all_messages)
      assert.is_true(#sync_messages > 0, 'Should report sync status')
    end)
  end)
end)
