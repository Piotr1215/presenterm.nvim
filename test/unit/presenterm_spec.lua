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
      local status = presenterm.slide_status()
      assert.equals('', status)
    end)
  end)
end)
