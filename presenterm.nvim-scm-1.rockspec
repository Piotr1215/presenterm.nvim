rockspec_format = "3.0"
package = "presenterm.nvim"
version = "scm-1"
source = {
  url = "git://github.com/Piotr1215/presenterm.nvim",
  branch = "main"
}
description = {
  summary = "Neovim plugin for creating and managing presenterm presentations",
  detailed = [[
    A Neovim plugin for creating and managing presenterm presentations with
    enhanced support for slide navigation, partials management, and live preview.
  ]],
  homepage = "https://github.com/Piotr1215/presenterm.nvim",
  license = "MIT"
}
dependencies = {
  "lua >= 5.1"
}
test_dependencies = {
  "busted"
}
test = {
  type = "command",
  command = "make test"
}

build = {
  type = "builtin",
  modules = {
    ["presenterm"] = "lua/presenterm/init.lua",
    ["presenterm.config"] = "lua/presenterm/config.lua",
    ["presenterm.navigation"] = "lua/presenterm/navigation.lua",
    ["presenterm.slides"] = "lua/presenterm/slides.lua",
    ["presenterm.partials"] = "lua/presenterm/partials.lua",
    ["presenterm.exec"] = "lua/presenterm/exec.lua",
    ["presenterm.preview"] = "lua/presenterm/preview.lua",
    ["presenterm.telescope"] = "lua/presenterm/telescope.lua",
  },
}