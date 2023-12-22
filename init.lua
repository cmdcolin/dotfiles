local opt = vim.opt
opt.undofile = true
opt.nu = true
opt.clipboard = 'unnamedplus'
opt.cmdheight = 0

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = ','


require('lazy').setup({
  {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v3.x'
  },
  {
    'stevearc/oil.nvim',
    opts = {
      default_file_explorer = false,
    },
  },
  {
    'stevearc/conform.nvim',
  },
  -- Lsp-zero recommended - LSP Support
  { 'neovim/nvim-lspconfig' },
  {
    'williamboman/mason.nvim',
    opts = {}
  },
  { 'williamboman/mason-lspconfig.nvim' },

  -- Lsp-zero recommended - Autocompletion
  { 'hrsh7th/nvim-cmp' },
  { 'hrsh7th/cmp-nvim-lsp' },
  { 'hrsh7th/cmp-path' },
  { 'L3MON4D3/LuaSnip' },
  { 'saadparwaiz1/cmp_luasnip' },
  { 'hrsh7th/cmp-nvim-lua' },
  {
    'windwp/nvim-autopairs',
    opts = {}
  },
  {
    'windwp/nvim-ts-autotag',
    opts = {
      enable_close_on_slash = false,
    }
  },
  { 'rebelot/kanagawa.nvim' },
  {
    'goolord/alpha-nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require 'alpha'.setup(require 'alpha.themes.startify'.config)
    end
  },
  { 'nvim-tree/nvim-web-devicons' },
  {
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    build = ':TSUpdate',
  },
  { 'folke/trouble.nvim' },
  { 'nvim-treesitter/playground' },
  { 'tpope/vim-commentary' },
  {
    'ruifm/gitlinker.nvim',
    opts = {}
  },
  {
    'nvim-telescope/telescope.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim'
    }
  },
  {
    'j-hui/fidget.nvim',
    tag = "legacy",
    opts = {}
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {}
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      -- add any options here
    },
    dependencies = {
      -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
      "MunifTanjim/nui.nvim",
      -- OPTIONAL:
      --   `nvim-notify` is only needed, if you want to use the notification view.
      --   If not available, we use `mini` as the fallback
      "rcarriga/nvim-notify",
    }
  }
})



local lsp_zero = require('lsp-zero')

lsp_zero.on_attach(function(client, bufnr)
  lsp_zero.default_keymaps({ buffer = bufnr })
end)


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
  sources = {
    -- Copilot Source
    { name = "copilot",  group_index = 2 },
    -- Other Sources
    { name = "nvim_lsp", group_index = 2 },
    { name = "path",     group_index = 2 },
    { name = "nuffer",   group_index = 2 },
    { name = "luasnip",  group_index = 2 },
  },
  formatting = cmp_format,
  mapping = cmp.mapping.preset.insert({
    ['<CR>'] = cmp.mapping.confirm { select = true },
  }),

  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  }
})


vim.cmd 'colorscheme kanagawa'

require('nvim-treesitter.configs').setup {
  ensure_installed = { 'typescript', 'tsx', 'r', 'javascript', 'lua', 'rust', 'java' },
  highlight = { enable = true },
  indent = { enable = true },
  auto_install = true,
  autotag = { enable = true },
}




require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "isort", "ruff" },
    javascript = { { "prettierd", "prettier" } },
    javascriptreact = { { "prettierd", "prettier" } },
    typescript = { { "prettierd", "prettier" } },
    typescriptreact = { { "prettierd", "prettier" } },
    markdown = { { "prettierd", "prettier" } },
    mdx = { { "prettierd", "prettier" } },
    json = { { "prettierd", "prettier" } },
    css = { { "prettierd", "prettier" } },
    html = { { "prettierd", "prettier" } },
    yaml = { { "prettierd", "prettier" } },
  },
  format_on_save = {
    timeout_ms = 2000,
    lsp_fallback = true,
  },
})



local builtin = require 'telescope.builtin'
vim.keymap.set('i', 'jj', '<Esc>')
vim.keymap.set('i', 'kk', '<C-\\><C-o>:w<CR>')
vim.keymap.set('n', 'kk', '<cmd>:w<CR>')
vim.keymap.set('n', '00', '<cmd>q<cr>')
vim.keymap.set('n', '<leader>p', '"_dP')
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
vim.keymap.set('n', '<leader>ff', builtin.live_grep)
vim.keymap.set('n', '<leader>gg', builtin.find_files)
vim.keymap.set('n', '<leader>hh', ':Alpha<CR>')

local ls = require 'luasnip'
local p = ls.parser

local v = {
  p.parse_snippet('ts', '// @ts-expect-error'),
  p.parse_snippet('da', '// eslint-disable-next-line @typescript-eslint/no-explicit-any'),
  p.parse_snippet('da', '// eslint-disable-next-line @typescript-eslint/no-floating-promises'),
  p.parse_snippet('pa', '/**\n* #property\n*/'),
  p.parse_snippet('pa', '/**\n* #action\n*/'),
  p.parse_snippet('pa', '/**\n* #getter\n*/'),
  p.parse_snippet('pa', '/**\n* #method\n*/'),
  p.parse_snippet('cl', 'console.log({$1})'),
  p.parse_snippet('cl', 'console.log($1)'),
}

ls.add_snippets(nil, {
  javascript = v,
  javascriptreact = v,
  typescript = v,
  typescriptreact = v,
  rust = {
    p.parse_snippet('cl', 'println!("{}",$1)'),
  },
  java = {
    p.parse_snippet('cl', 'System.out.println($1)'),
  },
})

vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
vim.keymap.set("n", "<leader>fg", "<CMD>lua vim.lsp.buf.format()<CR>", { desc = "LSP format" })
