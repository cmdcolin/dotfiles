local opt = vim.opt
opt.undofile = true
opt.nu = true
opt.clipboard = 'unnamedplus'
opt.cmdheight = 0

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = ','


require('lazy').setup({
  { 'VonHeikemen/lsp-zero.nvim',        branch = 'v3.x' },

  -- Lsp-zero recommended - LSP Support
  { 'neovim/nvim-lspconfig' },
  { 'williamboman/mason.nvim' },
  { 'williamboman/mason-lspconfig.nvim' },

  -- Lsp-zero recommended - Autocompletion
  { 'hrsh7th/nvim-cmp' },
  { 'hrsh7th/cmp-nvim-lsp' },
  { 'L3MON4D3/LuaSnip' },

  -- My stuff
  { 'windwp/nvim-autopairs' },
  { 'windwp/nvim-ts-autotag' },
  { 'rebelot/kanagawa.nvim' },
  { 'goolord/alpha-nvim' },
  { 'nvim-tree/nvim-web-devicons' },
  { 'jose-elias-alvarez/null-ls.nvim' },
  {
    -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    build = ':TSUpdate',
  },
  { 'folke/trouble.nvim' },
  { 'nvim-treesitter/playground' },
  { 'tpope/vim-commentary' },
  { 'tpope/vim-fugitive' },
  { 'tpope/vim-vinegar' },
  { 'tpope/vim-rhubarb' },
  { 'nvim-telescope/telescope.nvim', dependencies = { 'nvim-lua/plenary.nvim' } },
  {
    'j-hui/fidget.nvim',
    tag = "legacy",
    opts = {}
  },
  {
    -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim',
    -- Enable `lukas-reineke/indent-blankline.nvim`
    -- See `:help indent_blankline.txt`
    opts = {
      char = '┊',
      show_trailing_blankline_indent = false,
    },
  },
})

local lsp_zero = require('lsp-zero')

lsp_zero.on_attach(function(client, bufnr)
  -- see :help lsp-zero-keybindings
  -- to learn the available actions
  lsp_zero.default_keymaps({ buffer = bufnr })
end)

require('mason').setup({})
require('mason-lspconfig').setup({
  ensure_installed = { 'tsserver', 'rust_analyzer', 'lua_ls' },
  handlers = {
    lsp_zero.default_setup,
    lua_ls = function()
      local lua_opts = lsp_zero.nvim_lua_ls()
      require('lspconfig').lua_ls.setup(lua_opts)
    end,
  }
})

local cmp = require('cmp')
local cmp_format = lsp_zero.cmp_format()

cmp.setup({
  formatting = cmp_format,
  mapping = cmp.mapping.preset.insert({
    -- scroll up and down the documentation window
    ['<C-u>'] = cmp.mapping.scroll_docs(-4),
    ['<C-d>'] = cmp.mapping.scroll_docs(4),
  }),
})


vim.cmd 'colorscheme kanagawa'
require 'keymaps'
require 'snips'

require('alpha').setup(require('alpha.themes.startify').config)
require('nvim-autopairs').setup {}
require('nvim-treesitter.configs').setup {
  ensure_installed = { 'typescript', 'tsx', 'r', 'javascript', 'lua', 'rust', 'java' },
  highlight = { enable = true },
  indent = { enable = true },
  auto_install = true,
  autotag = { enable = true },
}


lsp_zero.format_on_save({
  format_opts = {
    async = false,
    timeout_ms = 10000,
  },
  servers = {
    ['lua_ls'] = { 'lua' },
    ['rust_analyzer'] = { 'rust' },
    ['null-ls'] = {
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
      "css",
      "scss",
      "less",
      "html",
      "json",
      "yaml",
      "markdown",
      "markdown.mdx",
      "graphql",
    },
  },
})


local null_ls = require 'null-ls'

null_ls.setup {
  sources = {
    null_ls.builtins.formatting.prettier
  },
}
