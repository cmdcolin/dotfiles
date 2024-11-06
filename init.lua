local opt = vim.opt
opt.undofile = true
opt.nu = true
opt.clipboard = 'unnamedplus'
opt.cmdheight = 0

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out,                            "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)


vim.g.mapleader = ','


require('lazy').setup({
  {
    "refractalize/oil-git-status.nvim",

    dependencies = {
      "stevearc/oil.nvim",
    },

    config = true,
  },
  { 'rebelot/kanagawa.nvim' },
  {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v4.x'
  },
  {
    'stevearc/oil.nvim',
    opts = {
      default_file_explorer = false,
      win_options = {
        signcolumn = "yes:2",
      },
    },
  },
  { 'stevearc/conform.nvim', },
  {
    'numToStr/Comment.nvim',
    opts = {
      -- add any options here
    },
    lazy = false,
  },

  -- Lsp-zero recommended - LSP Support
  { 'neovim/nvim-lspconfig' },
  {
    'williamboman/mason.nvim',
    opts = {}
  },
  { 'williamboman/mason-lspconfig.nvim' },
  { 'hrsh7th/nvim-cmp' },
  { 'hrsh7th/cmp-nvim-lsp' },
  { 'hrsh7th/cmp-path' },
  { 'L3MON4D3/LuaSnip' },
  {
    'lukas-reineke/lsp-format.nvim',
    opts = {}
  },
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
  {
    'goolord/alpha-nvim',
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
  {
    "folke/trouble.nvim",
    opts = {}, -- for default options, refer to the configuration section for custom setup.
    cmd = "Trouble",
    keys = {
      {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>xX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>cs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
      {
        "<leader>cl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP Definitions / references / ... (Trouble)",
      },
      {
        "<leader>xL",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location List (Trouble)",
      },
      {
        "<leader>xQ",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix List (Trouble)",
      },
    },
  },
  { 'nvim-treesitter/playground' },
  {
    'ruifm/gitlinker.nvim',
    opts = {}
  },
  { 'nvim-telescope/telescope.nvim' },
  { 'nvim-lua/plenary.nvim' },
  {
    'j-hui/fidget.nvim',
    tag = "legacy",
    opts = {}
  },
  {
    'gera2ld/ai.nvim',
    opts = {
      api_key = os.getenv('GEMINI_API_KEY'),
      locale = 'en',
      prompts = {},
    },
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {}
  },
  checker = { enabled = true },
})



local lsp_zero = require('lsp-zero')

local cmp = require('cmp')
local cmp_format = lsp_zero.cmp_format()

cmp.setup({
  sources = {
    { name = 'nvim_lsp', group_index = 2 },
    { name = "path",     group_index = 2 },
    { name = "buffer",   group_index = 2 },
    { name = "luasnip",  group_index = 2 },
  },
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
  formatting = cmp_format,
  mapping = cmp.mapping.preset.insert({
    ['<CR>'] = cmp.mapping.confirm { select = true },
  }),
})


local lsp_attach = function(client, bufnr)
  -- see :help lsp-zero-keybindings
  -- to learn the available actions
  lsp_zero.default_keymaps({ buffer = bufnr })
end

lsp_zero.extend_lspconfig({
  capabilities = require('cmp_nvim_lsp').default_capabilities(),
  lsp_attach = lsp_attach,
  float_border = 'rounded',
  sign_text = true,
})


require('mason').setup({})
require('mason-lspconfig').setup({
  ensure_installed = { 'ts_ls', 'rust_analyzer', 'lua_ls', },
  handlers = {
    function(server_name)
      require('lspconfig')[server_name].setup({})
    end,

    lua_ls = function()
      require('lspconfig').lua_ls.setup({
        on_init = function(client)
          lsp_zero.nvim_lua_settings(client, {})
        end,
      })
    end,
  }
})

vim.cmd.colorscheme('kanagawa')

require('nvim-ts-autotag').setup {
  ensure_installed = {
    'typescript',
    'tsx',
    'r',
    'javascript',
    'lua',
    'rust',
    'java'
  },
  highlight = { enable = true },
  indent = { enable = true },
  auto_install = true,
  autotag = { enable = true },
}




require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "isort", "ruff" },
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
    markdown = { "prettier" },
    mdx = { "prettier" },
    json = { "prettier" },
    css = { "prettier" },
    html = { "prettier" },
    yaml = { "prettier" },
  },
  format_on_save = {
    timeout_ms = 2000,
    lsp_fallback = true,
  },
})


-- note my keybindings are ridiculous
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

require 'lspconfig'.eslint.setup({})

local v = {
  p.parse_snippet('ts', '// @ts-expect-error'),
  p.parse_snippet('da', '// eslint-disable-next-line @typescript-eslint/no-explicit-any'),
  p.parse_snippet('da', '// eslint-disable-next-line @typescript-eslint/no-floating-promises'),
  p.parse_snippet('da', '// eslint-disable-next-line @typescript-eslint/no-unnecessary-condition'),
  p.parse_snippet('pa', '/**\n* #property\n*/'),
  p.parse_snippet('pa', '/**\n* #action\n*/'),
  p.parse_snippet('pa', '/**\n* #getter\n*/'),
  p.parse_snippet('pa', '/**\n* #method\n*/'),
  p.parse_snippet('pa', '/**\n* #volatile\n*/'),
  p.parse_snippet('ps', 'const {$1} = self'),
  p.parse_snippet('ps', "import {expect,test} from 'vitest'"),
  p.parse_snippet('ps', "import {afterEach,expect,test} from 'vitest'\nafterEach(()=>{cleanup()})"),
  p.parse_snippet('cl', 'console.log({$1})'),
  p.parse_snippet('cl', 'console.log($1)'),
  p.parse_snippet('wa', '"language":["$1"],'),
  p.parse_snippet('wa', '"tags":["$1"],'),
  p.parse_snippet('wa', '"pub":{"doi":""},'),
}

ls.add_snippets(nil, {
  javascript = v,
  javascriptreact = v,
  typescript = v,
  typescriptreact = v,
  json = v,
  rust = {
    p.parse_snippet('cl', 'println!("{}",$1)'),
  },
  java = {
    p.parse_snippet('cl', 'System.out.println($1)'),
  },
})

vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })

-- manual lsp format with ,fg
-- i don't use this very much, mostly use conform format-on-save
vim.keymap.set("n", "<leader>fg", "<CMD>lua vim.lsp.buf.format()<CR>", { desc = "LSP format" })
