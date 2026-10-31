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
      assert.is_function(slides.toggle_hide_slide)
      assert.is_function(slides.get_visible_slides)
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

  describe('hidden slides', function()
    local directive = '<!-- skip_slide -->'
    local marker = '<!-- end_slide -->'
    local buffer_lines
    local cursor_line
    local notifications
    local original_set_lines
    local original_notify

    before_each(function()
      package.loaded['presenterm.navigation'] = nil
      notifications = {}
      cursor_line = 1
      original_set_lines = vim.api.nvim_buf_set_lines
      original_notify = vim.notify

      vim.api.nvim_buf_get_lines = function()
        return vim.deepcopy(buffer_lines)
      end

      vim.api.nvim_buf_set_lines = function(_, first, last, _, replacement)
        for _ = first + 1, last do
          table.remove(buffer_lines, first + 1)
        end
        for offset, line in ipairs(replacement) do
          table.insert(buffer_lines, first + offset, line)
        end
      end

      vim.fn.line = function(arg)
        return arg == '$' and #buffer_lines or cursor_line
      end

      vim.fn.cursor = function(line)
        cursor_line = line
      end

      vim.cmd = function() end

      vim.notify = function(message)
        table.insert(notifications, message)
      end
    end)

    after_each(function()
      package.loaded['presenterm.navigation'] = nil
      vim.api.nvim_buf_set_lines = original_set_lines
      vim.notify = original_notify
    end)

    for _, case in ipairs({
      { 'a middle slide', { '# 1', marker, '# 2', '', marker, '# 3' }, 3, { 1, 3 } },
      { 'the slide a marker closes', { '# 1', marker, '# 2' }, 2, { 2 } },
      { 'the last slide', { '# 1', marker, '# 2', '' }, 3, { 1 } },
      { 'an empty slide', { '# 1', marker, marker, '# 3' }, 3, { 1, 3 } },
      { 'a slide after frontmatter', { '---', 'title: Deck', '---', '', marker, '# 2' }, 4, { 2 } },
      { 'a slide between hidden ones', { directive, marker, '# 2', marker, directive }, 3, {} },
      { 'a slide with a fenced directive', { '```', directive, '```' }, 1, {} },
      { 'a slide mentioning the directive', { 'Add skip_slide here' }, 1, {} },
    }) do
      local name, lines, cursor, visible = unpack(case)

      it('should hide and restore ' .. name, function()
        buffer_lines, cursor_line = vim.deepcopy(lines), cursor

        slides.toggle_hide_slide()
        assert.same(visible, slides.get_visible_slides())

        slides.toggle_hide_slide()
        assert.same(lines, buffer_lines)
        assert.are_not.equal(notifications[1], notifications[2])
      end)
    end

    for _, spelling in ipairs({ directive, '<!--skip_slide-->', '   ' .. directive }) do
      it('should show a slide hidden by "' .. spelling .. '"', function()
        buffer_lines = { spelling, '# 1', marker, '# 2' }

        slides.toggle_hide_slide()

        assert.same({ 1, 2 }, slides.get_visible_slides())
      end)
    end

    it('should keep a hidden first slide hidden when it moves', function()
      buffer_lines = { '# 1', marker, '# 2' }

      slides.toggle_hide_slide()
      slides.move_slide_down()

      assert.same({ 1 }, slides.get_visible_slides())
    end)

    for _, case in ipairs({
      { 'no hidden slides', { '# 1', marker, '# 2' }, { 1, 2 } },
      { 'hidden slides', { '# 1', marker, directive, marker, '# 3', marker, '# 4' }, { 1, 3, 4 } },
      { 'a fenced directive', { '```', directive, '```', marker, '# 2' }, { 1, 2 } },
      { 'a directive after a fence', { '```', '```', directive, marker, '# 2' }, { 2 } },
      { 'prose mentioning the directive', { 'Add skip_slide here', marker, '# 2' }, { 1, 2 } },
    }) do
      local name, lines, visible = unpack(case)

      it('should read ' .. name, function()
        buffer_lines = lines

        assert.same(visible, slides.get_visible_slides())
      end)
    end
  end)
end)
