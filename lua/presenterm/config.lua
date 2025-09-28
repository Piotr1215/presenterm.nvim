local M = {}

---@class PresenterMConfig
---@field slide_marker? string The marker used to separate slides
---@field partials? PresenterMPartialsConfig Partials configuration
---@field preview? PresenterMPreviewConfig Preview configuration
---@field telescope? PresenterMTelescopeConfig Telescope configuration

---@class PresenterMPartialsConfig
---@field directory? string Default partials directory name
---@field resolve_relative? boolean Resolve paths relative to current file

---@class PresenterMPreviewConfig
---@field command? string Command to run for preview

---@class PresenterMTelescopeConfig
---@field theme? string Telescope theme to use
---@field layout_config? table Layout configuration
---@field enable_preview? boolean Enable preview in telescope

---@type PresenterMConfig
M.defaults = {
  slide_marker = '<!-- end_slide -->',
  partials = {
    directory = '_partials',
    resolve_relative = true,
  },
  preview = {
    command = 'presenterm',
  },
  telescope = {
    theme = 'dropdown',
    layout_config = {
      width = 0.8,
      height = 0.6,
    },
    enable_preview = true,
  },
}

-- Initialize configuration

---Get current configuration
---@return PresenterMConfig
function M.get()
  if not vim.g.presenterm then
    vim.g.presenterm = vim.tbl_deep_extend('force', {}, M.defaults)
  end
  return vim.g.presenterm
end

---Setup configuration (optional)
---@param opts PresenterMConfig|table|nil
function M.setup(opts)
  if not opts then
    return
  end

  vim.g.presenterm = vim.tbl_deep_extend('force', M.defaults, opts)
end

return M
