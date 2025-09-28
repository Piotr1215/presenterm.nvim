-- Minimal init for testing
local plenary_dir = os.getenv('PLENARY_DIR') or '/home/decoder/.local/share/nvim/lazy/plenary.nvim'
vim.opt.rtp:append('.')
vim.opt.rtp:append(plenary_dir)

vim.cmd('runtime plugin/plenary.vim')
require('plenary.busted')

vim.o.swapfile = false
vim.bo.swapfile = false
