describe('real buffer', function()
  it('hides the slide, keeps the cursor on its text, and undoes in one step', function()
    local buf = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(
      buf,
      0,
      -1,
      false,
      { '# 1', '<!-- end_slide -->', '# 2', 'body', '' }
    )
    vim.cmd('let &undolevels = &undolevels')
    vim.api.nvim_win_set_cursor(0, { 4, 0 })
    local slides = require('presenterm.slides')

    slides.toggle_hide_slide()

    assert.same({ 1 }, slides.get_visible_slides())
    assert.equals('body', vim.api.nvim_get_current_line())

    vim.cmd('silent undo')
    assert.same({ 1, 2 }, slides.get_visible_slides())
  end)
end)
