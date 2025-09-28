describe('navigation', function()
  local navigation

  before_each(function()
    -- Clear module cache
    package.loaded['presenterm.navigation'] = nil
    package.loaded['presenterm.slides'] = nil
    package.loaded['presenterm.partials'] = nil
    package.loaded['presenterm.config'] = nil

    -- Set up default config
    vim.g.presenterm = {
      slide_marker = '<!-- end_slide -->',
      partials = {
        directory = '_partials',
        resolve_relative = true,
      },
    }

    navigation = require('presenterm.navigation')

    -- Mock buffer content
    vim.api.nvim_buf_get_lines = function()
      return {
        '---',
        'title: Test Presentation',
        '---',
        '',
        '# Slide 1',
        'Content for slide 1',
        '<!-- end_slide -->',
        '',
        '# Slide 2',
        'Content for slide 2',
        '<!-- end_slide -->',
        '',
        '# Slide 3',
        'Content for slide 3',
      }
    end

    -- Mock cursor functions
    vim.fn.cursor = function() end
    vim.cmd = function() end
    vim.fn.line = function(arg)
      if arg == '$' then
        return 14
      end
      if arg == '.' then
        return 5
      end
      return 1
    end
  end)

  describe('go_to_slide', function()
    it('should navigate to specific slide', function()
      local cursor_called = false
      vim.fn.cursor = function(line, col)
        cursor_called = true
        assert.is_number(line)
        assert.equals(1, col)
      end

      navigation.go_to_slide(2)
      assert.is_true(cursor_called)
    end)

    it('should clamp to first slide if number too low', function()
      local cursor_line
      vim.fn.cursor = function(line, _)
        cursor_line = line
      end

      navigation.go_to_slide(0)
      assert.is_not_nil(cursor_line)
    end)

    it('should clamp to last slide if number too high', function()
      local cursor_line
      vim.fn.cursor = function(line, _)
        cursor_line = line
      end

      navigation.go_to_slide(100)
      assert.is_not_nil(cursor_line)
    end)
  end)

  describe('next_slide', function()
    it('should move to next slide', function()
      local go_to_slide_called = false
      navigation.go_to_slide = function(num)
        go_to_slide_called = true
        assert.is_number(num)
      end

      navigation.next_slide()
      assert.is_true(go_to_slide_called)
    end)
  end)

  describe('previous_slide', function()
    it('should move to previous slide', function()
      local go_to_slide_called = false
      navigation.go_to_slide = function(num)
        go_to_slide_called = true
        assert.is_number(num)
      end

      navigation.previous_slide()
      assert.is_true(go_to_slide_called)
    end)
  end)

  describe('slide_status', function()
    it('should return formatted status string', function()
      local status = navigation.slide_status()
      assert.is_string(status)
      assert.truthy(status:match('%[Slide %d+/%d+%]'))
    end)
  end)

  describe('get_slide_titles', function()
    it('should extract slide titles', function()
      local titles = navigation.get_slide_titles()
      assert.is_table(titles)
      assert.is_true(#titles > 0)

      for _, slide in ipairs(titles) do
        assert.is_not_nil(slide.index)
        assert.is_not_nil(slide.title)
        assert.is_not_nil(slide.start_line)
        assert.is_not_nil(slide.preview)
      end
    end)

    it('should handle slides without titles', function()
      vim.api.nvim_buf_get_lines = function()
        return {
          'Content without header',
          '<!-- end_slide -->',
          'More content',
        }
      end

      local titles = navigation.get_slide_titles()
      assert.is_table(titles)
      -- Should have default "Slide N" titles
      if #titles > 0 then
        assert.truthy(titles[1].title:match('Slide %d'))
      end
    end)

    it('should mark slides containing partials', function()
      -- Clear and reload modules with proper mocks
      package.loaded['presenterm.navigation'] = nil
      package.loaded['presenterm.slides'] = nil

      -- Mock slides module before loading navigation
      package.loaded['presenterm.slides'] = {
        get_slide_positions = function()
          return { 0, 3, 8, 14 } -- positions for 3 slides
        end,
        is_presentation = function()
          return true
        end,
      }

      local nav = require('presenterm.navigation')

      vim.api.nvim_buf_get_lines = function()
        return {
          '# Slide 1',
          'Content without partial',
          '<!-- end_slide -->',
          '',
          '# Slide 2',
          '<!-- include: _partials/intro.md -->',
          'Content with partial',
          '<!-- end_slide -->',
          '',
          '# Slide 3',
          'More content',
          '<!-- include: _partials/demo.md -->',
          '<!-- include: _partials/outro.md -->',
          '<!-- end_slide -->',
        }
      end

      local titles = nav.get_slide_titles()
      assert.is_table(titles)
      assert.equals(3, #titles)

      -- First slide has no partial
      assert.equals(1, titles[1].index)
      assert.equals('Slide 1', titles[1].title)
      assert.is_false(titles[1].has_partial)

      -- Second slide has one partial
      assert.equals(2, titles[2].index)
      assert.equals('Slide 2', titles[2].title)
      assert.is_true(titles[2].has_partial)

      -- Third slide has multiple partials
      assert.equals(3, titles[3].index)
      assert.equals('Slide 3', titles[3].title)
      assert.is_true(titles[3].has_partial)
    end)

    it('should handle malformed partial includes correctly', function()
      -- Clear and reload modules with proper mocks
      package.loaded['presenterm.navigation'] = nil
      package.loaded['presenterm.slides'] = nil

      -- Mock slides module before loading navigation
      package.loaded['presenterm.slides'] = {
        get_slide_positions = function()
          return { 0, 3, 7, 11 } -- positions for 3 slides
        end,
        is_presentation = function()
          return true
        end,
      }

      local nav = require('presenterm.navigation')

      vim.api.nvim_buf_get_lines = function()
        return {
          '# Slide 1',
          '<!-- include: -->', -- Empty path
          '<!-- end_slide -->',
          '',
          '# Slide 2',
          '<!-- include _partials/intro.md -->', -- Missing colon
          '<!-- end_slide -->',
          '',
          '# Slide 3',
          '<!-- include: _partials/valid.md -->', -- Valid
          '<!-- end_slide -->',
        }
      end

      local titles = nav.get_slide_titles()
      assert.is_table(titles)
      assert.equals(3, #titles)

      -- First and second slides have malformed includes (not detected as partials)
      assert.is_false(titles[1].has_partial)
      assert.is_false(titles[2].has_partial)

      -- Third slide has valid partial
      assert.is_true(titles[3].has_partial)
    end)
  end)
end)
