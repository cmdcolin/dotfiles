local opt = vim.opt
opt.undofile = true
opt.mouse = 'a'
opt.termguicolors = true
opt.nu = true
opt.clipboard = 'unnamedplus'
opt.cmdheight = 0
opt.lazyredraw = true
opt.sw = 2
opt.expandtab = true
opt.termguicolors = true
vim.cmd [[colorscheme tokyonight]]
require('telescope').setup {}
require('nvim-autopairs').setup {}
require('nvim-treesitter.configs').setup {
  ensure_installed = { 'typescript', 'tsx', 'r', 'javascript', 'lua', 'rust' },
  highlight = { enable = true },
  indent = { enable = true },
  auto_install = true,
}
