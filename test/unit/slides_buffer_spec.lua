describe('hidden slides', function()
  local directive = '<!-- skip_slide -->'
  local marker = '<!-- end_slide -->'
  local slides
  local notifications
  local original_notify

  -- Reset undolevels after the fixture so undo stops at the fixture, not before it
  local function open_buffer(lines, cursor)
    vim.api.nvim_set_current_buf(vim.api.nvim_create_buf(false, false))
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.cmd('let &undolevels = &undolevels')
    vim.api.nvim_win_set_cursor(0, { cursor or 1, 0 })
  end

  local function buffer_lines()
    return vim.api.nvim_buf_get_lines(0, 0, -1, false)
  end

  before_each(function()
    package.loaded['presenterm.slides'] = nil
    package.loaded['presenterm.config'] = nil
    package.loaded['presenterm.navigation'] = nil

    vim.g.presenterm = {
      slide_marker = marker,
      partials = {
        directory = '_partials',
        resolve_relative = true,
      },
    }

    slides = require('presenterm.slides')

    notifications = {}
    original_notify = vim.notify
    vim.notify = function(message)
      table.insert(notifications, message)
    end
  end)

  after_each(function()
    package.loaded['presenterm.navigation'] = nil
    vim.notify = original_notify
    vim.api.nvim_buf_delete(0, { force = true })
  end)

  for _, case in ipairs({
    { 'a middle slide', { '# 1', marker, '# 2', '', marker, '# 3' }, 3, { 1, 3 } },
    { 'the slide a marker closes', { '# 1', marker, '# 2' }, 2, { 2 } },
    { 'the last slide', { '# 1', marker, '# 2', '' }, 3, { 1 } },
    { 'a slide from its body', { '# 1', marker, '# 2', 'body', '' }, 4, { 1 } },
    { 'an empty slide', { '# 1', marker, marker, '# 3' }, 3, { 1, 3 } },
    { 'a slide after frontmatter', { '---', 'title: Deck', '---', '', marker, '# 2' }, 4, { 2 } },
    { 'a slide between hidden ones', { directive, marker, '# 2', marker, directive }, 3, {} },
    { 'a slide with a fenced directive', { '```', directive, '```' }, 1, {} },
    { 'a slide mentioning the directive', { 'Add skip_slide here' }, 1, {} },
  }) do
    local name, lines, cursor, visible = unpack(case)

    it('should hide and restore ' .. name, function()
      open_buffer(lines, cursor)

      slides.toggle_hide_slide()
      assert.same(visible, slides.get_visible_slides())
      assert.equals(lines[cursor], vim.api.nvim_get_current_line())

      slides.toggle_hide_slide()
      assert.same(lines, buffer_lines())
      assert.equals(lines[cursor], vim.api.nvim_get_current_line())
      assert.are_not.equal(notifications[1], notifications[2])
    end)

    it('should undo hiding ' .. name .. ' in one step', function()
      open_buffer(lines, cursor)

      slides.toggle_hide_slide()
      vim.cmd('silent undo')

      assert.same(lines, buffer_lines())
    end)
  end

  for _, spelling in ipairs({ directive, '<!--skip_slide-->', '   ' .. directive }) do
    it('should show a slide hidden by "' .. spelling .. '"', function()
      open_buffer({ spelling, '# 1', marker, '# 2' })

      slides.toggle_hide_slide()

      assert.same({ 1, 2 }, slides.get_visible_slides())
    end)
  end

  it('should keep a hidden first slide hidden when it moves', function()
    local lines = { '# 1', marker, '# 2' }
    open_buffer(lines)

    slides.toggle_hide_slide()
    slides.move_slide_down()

    assert.same({ 1 }, slides.get_visible_slides())
    assert.equals(lines[1], vim.api.nvim_get_current_line())
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
      open_buffer(lines)

      assert.same(visible, slides.get_visible_slides())
    end)
  end
end)
