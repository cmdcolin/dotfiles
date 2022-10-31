local opt = vim.opt

opt.undofile = true
opt.mouse = 'a'
opt.termguicolors = true
opt.clipboard = 'unnamedplus'
opt.cmdheight = 0
opt.lazyredraw = true
opt.sw = 2
opt.expandtab = true
opt.updatetime = 200

vim.cmd [[colorscheme nightfox]]
require('nvim-surround').setup {}
require('telescope').setup {}
require('telescope').load_extension 'fzf'
require('nvim-treesitter.configs').setup {
  highlight = { enable = true },
  indent = { enable = true },
  auto_install = true,
}
