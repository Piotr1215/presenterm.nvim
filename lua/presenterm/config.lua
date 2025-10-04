local M = {}

---@class PresenterMConfig
---@field slide_marker? string The marker used to separate slides
---@field partials? PresenterMPartialsConfig Partials configuration
---@field preview? PresenterMPreviewConfig Preview configuration
---@field picker? PresenterMPickerConfig Picker configuration
---@field telescope? PresenterMTelescopeConfig Telescope configuration
---@field layout? PresenterMLayoutConfig Layout configuration
---@field on_attach? function Callback function when presenterm activates for a buffer
---@field default_keybindings? boolean Set up default buffer-local keybindings automatically

---@class PresenterMPartialsConfig
---@field directory? string Default partials directory name
---@field resolve_relative? boolean Resolve paths relative to current file

---@class PresenterMPreviewConfig
---@field command? string Command to run for preview
---@field presentation_preview_sync? boolean Enable bi-directional sync between terminal and buffer
---@field login_shell? boolean Use login shell (-icl) to load full environment (default: true)

---@class PresenterMPickerConfig
---@field provider? string Picker provider: "telescope", "fzf", "snacks", or "builtin"

---@class PresenterMLayoutConfig
---@field templates? table Custom layout templates

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
    presentation_preview_sync = false,
    login_shell = true, -- Load full shell environment (slower but safer)
  },
  telescope = {
    theme = 'dropdown',
    layout_config = {
      width = 0.8,
      height = 0.6,
    },
    enable_preview = true,
  },
  default_keybindings = false,
}

-- Initialize configuration

---Get current configuration
---@return PresenterMConfig
function M.get()
  if not vim.g.presenterm then
    ---@type PresenterMConfig
    vim.g.presenterm = vim.tbl_deep_extend('force', {}, M.defaults)
  end
  ---@type PresenterMConfig
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
