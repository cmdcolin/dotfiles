local opt = vim.opt
opt.undofile = true
opt.nu = true
opt.clipboard = 'unnamedplus'
opt.cmdheight = 0

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = ','

require('lazy').setup {
  'VonHeikemen/lsp-zero.nvim',
  branch = 'v2.x',
  dependencies = {
    { 'rebelot/kanagawa.nvim' },
    { 'mhartington/formatter.nvim' },
    { 'nvim-treesitter/nvim-treesitter' },
    { 'tpope/vim-commentary' },
    { 'nvim-telescope/telescope.nvim', dependencies = { 'nvim-lua/plenary.nvim' } },
    { 'tpope/vim-vinegar' },
    { 'tpope/vim-rhubarb' },
    { 'windwp/nvim-autopairs' },
    -- LSP Support
    { 'neovim/nvim-lspconfig' },
    { 'williamboman/mason.nvim' },
    { 'williamboman/mason-lspconfig.nvim' },

    -- Autocompletion
    { 'hrsh7th/nvim-cmp' },
    { 'hrsh7th/cmp-nvim-lsp' },
    { 'hrsh7th/cmp-buffer' },
    { 'hrsh7th/cmp-path' },
    { 'saadparwaiz1/cmp_luasnip' },
    { 'hrsh7th/cmp-nvim-lua' },

    -- Snippets
    { 'L3MON4D3/LuaSnip' },
  },
}

vim.cmd 'colorscheme kanagawa'
require 'lsp'
require 'keymaps'
require 'formatting'
require 'snips'

require('nvim-autopairs').setup {}
require('nvim-treesitter.configs').setup {
  ensure_installed = { 'typescript', 'tsx', 'r', 'javascript', 'lua', 'rust' },
  highlight = { enable = true },
  indent = { enable = true },
  auto_install = true,
}
