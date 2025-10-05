describe('slides', function()
  local slides

  before_each(function()
    -- Clear module cache
    package.loaded['presenterm.slides'] = nil
    package.loaded['presenterm.config'] = nil

    -- Set up default config
    vim.g.presenterm = {
      slide_marker = '<!-- end_slide -->',
      partials = {
        directory = '_partials',
        resolve_relative = true,
      },
    }

    slides = require('presenterm.slides')
  end)

  describe('module structure', function()
    it('should export required functions', function()
      assert.is_function(slides.get_frontmatter_end)
      assert.is_function(slides.get_slide_positions)
      assert.is_function(slides.get_current_slide)
      assert.is_function(slides.is_presentation)
      assert.is_function(slides.new_slide)
      assert.is_function(slides.split_slide)
      assert.is_function(slides.delete_slide)
      assert.is_function(slides.yank_slide)
      assert.is_function(slides.select_slide)
      assert.is_function(slides.get_slide_content)
      assert.is_function(slides.move_slide_up)
      assert.is_function(slides.move_slide_down)
      assert.is_function(slides.interactive_reorder)
    end)
  end)

  describe('new_slide', function()
    local buffer_lines
    local cursor_line
    local cursor_col

    before_each(function()
      -- Mock buffer content
      buffer_lines = {
        '# Slide 1',
        'Content for slide 1',
        '',
        '<!-- end_slide -->',
        '',
        '# Slide 2',
        'Content for slide 2',
        '',
        '<!-- end_slide -->',
      }

      -- Mock vim functions
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

      vim.fn.cursor = function(line, col)
        cursor_line = line
        cursor_col = col
      end

      vim.fn.append = function(line, lines_to_add)
        -- Insert in reverse order at a constant position to maintain order
        for i = #lines_to_add, 1, -1 do
          table.insert(buffer_lines, line + 1, lines_to_add[i])
        end
      end

      vim.cmd = function() end -- Mock startinsert
    end)

    it('should create new slide after current slide marker', function()
      -- Position cursor on slide 1
      cursor_line = 2

      -- Create new slide
      slides.new_slide()

      -- Verify structure: should have marker, blank, content area, blank, new marker
      assert.equals('<!-- end_slide -->', buffer_lines[4]) -- Original marker
      assert.equals('', buffer_lines[5]) -- Blank line
      assert.equals('', buffer_lines[6]) -- Cursor line (content area)
      assert.equals('', buffer_lines[7]) -- Blank line
      assert.equals('<!-- end_slide -->', buffer_lines[8]) -- New slide marker
      assert.equals('', buffer_lines[9]) -- After new marker
      assert.equals('# Slide 2', buffer_lines[10]) -- Original slide 2
    end)

    it('should position cursor in content area of new slide', function()
      -- Position cursor on slide 1
      cursor_line = 2

      -- Create new slide
      slides.new_slide()

      -- Cursor should be on the blank line ready for content (line 6)
      assert.equals(6, cursor_line)
      assert.equals(1, cursor_col)
    end)
  end)
end)
