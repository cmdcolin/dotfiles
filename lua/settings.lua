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
require('nvim-autopairs').setup {}
require('Comment').setup()
require('leap').add_default_mappings()
require('nvim-treesitter.configs').setup {
  highlight = { enable = true },
  indent = { enable = true },
  auto_install = true,
}

require('mason').setup()
require('mason-lspconfig').setup()
local lsp = require 'lsp-zero'
lsp.preset 'recommended'
lsp.ensure_installed {
  'tsserver',
  'eslint',
}
lsp.nvim_workspace()
lsp.setup()

require('lspconfig').eslint.setup {}
