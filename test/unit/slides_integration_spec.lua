describe('slides integration with custom markers', function()
  local slides
  local config

  local function setup_test_buffer(lines, marker)
    -- Clear module cache
    package.loaded['presenterm.slides'] = nil
    package.loaded['presenterm.config'] = nil

    -- Set up config with custom marker
    vim.g.presenterm = {
      slide_marker = marker,
      partials = {
        directory = '_partials',
        resolve_relative = true,
      },
    }

    -- Mock buffer content
    vim.api.nvim_buf_get_lines = function()
      return lines
    end

    vim.fn.line = function(arg)
      if arg == '$' then
        return #lines
      end
      if arg == '.' then
        return 1
      end
      return 1
    end

    slides = require('presenterm.slides')
    config = require('presenterm.config')
  end

  describe('default <!-- end_slide --> marker', function()
    before_each(function()
      setup_test_buffer({
        '# Slide 1',
        'Content for slide 1',
        '<!-- end_slide -->',
        '# Slide 2',
        'Content for slide 2',
        '<!-- end_slide -->',
        '# Slide 3',
      }, '<!-- end_slide -->')
    end)

    it('should detect presentation with default marker', function()
      assert.is_true(slides.is_presentation())
    end)

    it('should find correct slide positions', function()
      local positions = slides.get_slide_positions()
      assert.equals(4, #positions)
      assert.equals(0, positions[1]) -- frontmatter end (no frontmatter)
      assert.equals(3, positions[2]) -- first marker
      assert.equals(6, positions[3]) -- second marker
      assert.equals(8, positions[4]) -- end of buffer + 1
    end)

    it('should get slide content without marker', function()
      local positions = slides.get_slide_positions()
      local slide1 = slides.get_slide_content(1, positions, false)

      assert.equals(2, #slide1)
      assert.equals('# Slide 1', slide1[1])
      assert.equals('Content for slide 1', slide1[2])
    end)

    it('should not detect --- as marker when using default', function()
      setup_test_buffer({
        '# Slide 1',
        '---',
        '# Slide 2',
        '<!-- end_slide -->',
        '# Slide 3',
      }, '<!-- end_slide -->')

      local positions = slides.get_slide_positions()
      -- Should only find <!-- end_slide --> at line 4
      assert.equals(3, #positions)
      assert.equals(4, positions[2])
    end)
  end)

  describe('--- shorthand marker', function()
    before_each(function()
      setup_test_buffer({
        '# Slide 1',
        'Content for slide 1',
        '---',
        '# Slide 2',
        'Content for slide 2',
        '---',
        '# Slide 3',
      }, '---')
    end)

    it('should detect presentation with --- marker', function()
      assert.is_true(slides.is_presentation())
    end)

    it('should find correct slide positions with ---', function()
      local positions = slides.get_slide_positions()
      assert.equals(4, #positions)
      assert.equals(0, positions[1])
      assert.equals(3, positions[2]) -- first ---
      assert.equals(6, positions[3]) -- second ---
      assert.equals(8, positions[4])
    end)

    it('should get slide content without --- marker', function()
      local positions = slides.get_slide_positions()
      local slide1 = slides.get_slide_content(1, positions, false)

      assert.equals(2, #slide1)
      assert.equals('# Slide 1', slide1[1])
      assert.equals('Content for slide 1', slide1[2])
    end)

    it('should verify config has --- marker', function()
      local cfg = config.get()
      assert.equals('---', cfg.slide_marker)
    end)

    it('should detect BOTH <!-- end_slide --> and --- when using shorthand', function()
      setup_test_buffer({
        '# Slide 1',
        '<!-- end_slide -->',
        '# Slide 2',
        '---',
        '# Slide 3',
      }, '---')

      local positions = slides.get_slide_positions()
      -- Should find BOTH markers: <!-- end_slide --> at line 2 AND --- at line 4
      assert.equals(4, #positions)
      assert.equals(2, positions[2]) -- <!-- end_slide -->
      assert.equals(4, positions[3]) -- ---
    end)
  end)

  describe('thematic breaks of varying lengths', function()
    it('should detect all thematic breaks regardless of length in shorthand mode', function()
      setup_test_buffer({
        '# Slide 1',
        '---', -- 3 dashes - valid thematic break
        '# Slide 2',
        '----------', -- 10 dashes - also valid thematic break
        '# Slide 3',
        '--------------------', -- 20 dashes - also valid
        '# Slide 4',
      }, '---')

      local positions = slides.get_slide_positions()
      -- Should find ALL thematic breaks (any 3+ dash line)
      assert.equals(5, #positions)
      assert.equals(2, positions[2]) -- --- at line 2
      assert.equals(4, positions[3]) -- ---------- at line 4
      assert.equals(6, positions[4]) -- -------------------- at line 6
    end)
  end)

  describe('with frontmatter and --- marker', function()
    before_each(function()
      setup_test_buffer({
        '---',
        'title: My Presentation',
        'author: Test',
        '---',
        '',
        '# Slide 1',
        'Content',
        '---',
        '# Slide 2',
      }, '---')
    end)

    it('should detect frontmatter correctly', function()
      local frontmatter_end = slides.get_frontmatter_end()
      assert.equals(4, frontmatter_end)
    end)

    it('should find slide markers after frontmatter', function()
      local positions = slides.get_slide_positions()
      assert.equals(3, #positions)
      assert.equals(4, positions[1]) -- frontmatter end
      assert.equals(8, positions[2]) -- --- slide marker (after frontmatter)
    end)

    it('should detect as presentation via frontmatter', function()
      assert.is_true(slides.is_presentation())
    end)
  end)

  describe('config fallback behavior', function()
    it('should use default marker when config returns empty', function()
      package.loaded['presenterm.slides'] = nil
      package.loaded['presenterm.config'] = nil

      -- Mock config returning empty table
      package.loaded['presenterm.config'] = {
        get = function()
          return {} -- No slide_marker field
        end,
      }

      vim.api.nvim_buf_get_lines = function()
        return {
          '# Slide 1',
          '<!-- end_slide -->',
          '# Slide 2',
        }
      end

      vim.fn.line = function()
        return 3
      end

      slides = require('presenterm.slides')

      local positions = slides.get_slide_positions()
      assert.equals(3, #positions)
      assert.equals(2, positions[2]) -- Default marker found
    end)
  end)

  describe('slide operations with custom markers', function()
    describe('new_slide with ---', function()
      local buffer_lines
      local cursor_line

      before_each(function()
        buffer_lines = {
          '# Slide 1',
          'Content',
          '---',
          '# Slide 2',
        }

        package.loaded['presenterm.slides'] = nil
        package.loaded['presenterm.config'] = nil

        vim.g.presenterm = {
          slide_marker = '---',
        }

        vim.api.nvim_buf_get_lines = function()
          return buffer_lines
        end

        vim.fn.line = function(arg)
          if arg == '$' then
            return #buffer_lines
          end
          if arg == '.' then
            return cursor_line or 2
          end
          return 1
        end

        vim.fn.cursor = function(line)
          cursor_line = line
        end

        vim.fn.append = function(line, lines_to_add)
          for i = #lines_to_add, 1, -1 do
            table.insert(buffer_lines, line + 1, lines_to_add[i])
          end
        end

        vim.cmd = function() end

        slides = require('presenterm.slides')
      end)

      it('should insert --- marker when creating new slide', function()
        cursor_line = 2
        slides.new_slide()

        -- Count how many --- markers exist
        local marker_count = 0
        for _, line in ipairs(buffer_lines) do
          if line == '---' then
            marker_count = marker_count + 1
          end
        end

        assert.is_true(marker_count >= 2, 'Should have at least 2 --- markers')
      end)
    end)

    describe('split_slide with ---', function()
      local buffer_lines
      local cursor_line

      before_each(function()
        buffer_lines = {
          '# Slide 1',
          'First part',
          'Second part',
          '---',
        }

        package.loaded['presenterm.slides'] = nil
        package.loaded['presenterm.config'] = nil

        vim.g.presenterm = {
          slide_marker = '---',
        }

        vim.api.nvim_buf_get_lines = function()
          return buffer_lines
        end

        vim.fn.line = function(arg)
          if arg == '.' then
            return cursor_line or 3
          end
          return 1
        end

        vim.fn.cursor = function(line)
          cursor_line = line
        end

        vim.fn.append = function(line, lines_to_add)
          for i = #lines_to_add, 1, -1 do
            table.insert(buffer_lines, line + 1, lines_to_add[i])
          end
        end

        slides = require('presenterm.slides')
      end)

      it('should insert --- marker when splitting slide', function()
        local original_count = 0
        for _, line in ipairs(buffer_lines) do
          if line == '---' then
            original_count = original_count + 1
          end
        end

        cursor_line = 3
        slides.split_slide()

        local new_count = 0
        for _, line in ipairs(buffer_lines) do
          if line == '---' then
            new_count = new_count + 1
          end
        end

        assert.is_true(new_count > original_count, 'Should have added new --- marker')
      end)
    end)
  end)

  describe('edge cases', function()
    it('should handle empty presentation', function()
      setup_test_buffer({
        '# Only one slide',
      }, '---')

      local positions = slides.get_slide_positions()
      assert.equals(2, #positions) -- frontmatter + eof
    end)

    it('should handle presentation with no markers but with frontmatter', function()
      setup_test_buffer({
        '---',
        'title: Test',
        '---',
        '# Content',
      }, '---')

      assert.is_true(slides.is_presentation())
    end)

    it('should handle --- in content when using default marker', function()
      setup_test_buffer({
        '# Slide 1',
        'Here is some text with --- in the middle',
        '<!-- end_slide -->',
        '# Slide 2',
      }, '<!-- end_slide -->')

      local positions = slides.get_slide_positions()
      -- Should only detect the actual marker, not --- in content
      assert.equals(3, #positions)
      assert.equals(3, positions[2])
    end)
  end)
end)
