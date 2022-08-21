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

require('telescope').setup {}
require('telescope').load_extension 'fzf'
require('colorbuddy').colorscheme 'gruvbuddy'
require('nvim-treesitter.configs').setup {
  highlight = { enable = true },
  indent = { enable = true },
}
