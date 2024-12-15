vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)
vim.opt.undofile = true
vim.opt.nu = true
vim.opt.cmdheight = 0
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.cursorline = true

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, {
  desc = 'Open diagnostic [Q]uickfix list'
})

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
  { "refractalize/oil-git-status.nvim", config = true, },
  { 'rebelot/kanagawa.nvim' },
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
  { 'numToStr/Comment.nvim',            opts = {}, lazy = false, },
  { 'neovim/nvim-lspconfig' },
  { 'williamboman/mason.nvim',          opts = {} },
  { 'williamboman/mason-lspconfig.nvim' },
  { 'hrsh7th/nvim-cmp' },
  { 'hrsh7th/cmp-nvim-lsp' },
  { 'hrsh7th/cmp-path' },
  { 'L3MON4D3/LuaSnip' },
  { 'lukas-reineke/lsp-format.nvim',    opts = {} },
  { 'saadparwaiz1/cmp_luasnip' },
  { 'hrsh7th/cmp-nvim-lua' },
  { 'windwp/nvim-autopairs',            opts = {} },
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

  {
    'folke/which-key.nvim',
    event = 'VimEnter', -- Sets the loading event to 'VimEnter'
    opts = {
      icons = {
        -- set icon mappings to true if you have a Nerd Font
        mappings = vim.g.have_nerd_font,
        -- If you are using a Nerd Font: set icons.keys to an empty table which will use the
        -- default which-key.nvim defined Nerd Font icons, otherwise define a string table
        keys = vim.g.have_nerd_font and {} or {
          Up = '<Up> ',
          Down = '<Down> ',
          Left = '<Left> ',
          Right = '<Right> ',
          C = '<C-…> ',
          M = '<M-…> ',
          D = '<D-…> ',
          S = '<S-…> ',
          CR = '<CR> ',
          Esc = '<Esc> ',
          ScrollWheelDown = '<ScrollWheelDown> ',
          ScrollWheelUp = '<ScrollWheelUp> ',
          NL = '<NL> ',
          BS = '<BS> ',
          Space = '<Space> ',
          Tab = '<Tab> ',
          F1 = '<F1>',
          F2 = '<F2>',
          F3 = '<F3>',
          F4 = '<F4>',
          F5 = '<F5>',
          F6 = '<F6>',
          F7 = '<F7>',
          F8 = '<F8>',
          F9 = '<F9>',
          F10 = '<F10>',
          F11 = '<F11>',
          F12 = '<F12>',
        },
      },

      -- Document existing key chains
      spec = {
        { '<leader>c', group = '[C]ode',     mode = { 'n', 'x' } },
        { '<leader>d', group = '[D]ocument' },
        { '<leader>r', group = '[R]ename' },
        { '<leader>s', group = '[S]earch' },
        { '<leader>w', group = '[W]orkspace' },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      },
    },
  },
  { 'nvim-treesitter/playground' },
  { 'ruifm/gitlinker.nvim',                opts = {} },
  { 'nvim-telescope/telescope.nvim' },
  { 'nvim-lua/plenary.nvim' },
  { 'j-hui/fidget.nvim',                   opts = {} },
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },
  checker = {
    enabled = true
  },
})


-- https://lsp-zero.netlify.app/blog/you-might-not-need-lsp-zero
vim.keymap.set('n', 'gl', '<cmd>lua vim.diagnostic.open_float()<cr>')
vim.keymap.set('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<cr>')
vim.keymap.set('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<cr>')
vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'LSP actions',
  callback = function(event)
    local opts = { buffer = event.buf }

    -- these will be buffer-local keybindings
    -- because they only work if you have an active language server

    vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
    vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
    vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
    vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
    vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
    vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
    vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
    vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
    vim.keymap.set({ 'n', 'x' }, '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
    vim.keymap.set('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)


    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
      local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })

      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
        end,
      })
    end
  end
})


local lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()

require('mason').setup({})
require('mason-lspconfig').setup({
  ensure_installed = {},
  handlers = {
    function(server_name)
      require('lspconfig')[server_name].setup({
        capabilities = lsp_capabilities,
      })
    end,
  },
})

local cmp = require('cmp')

cmp.setup({
  sources = {
    { name = 'nvim_lsp', group_index = 2 },
    { name = "path",     group_index = 2 },
    { name = "buffer",   group_index = 2 },
    { name = "luasnip",  group_index = 2 },
  },
  mapping = cmp.mapping.preset.insert({
    -- Enter key confirms completion item
    ['<CR>'] = cmp.mapping.confirm({ select = false }),

    -- Ctrl + space triggers completion menu
    ['<C-Space>'] = cmp.mapping.complete(),
  }),
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
})



require('mason').setup({})
require('mason-lspconfig').setup({
  ensure_installed = {
    'ts_ls',
    'rust_analyzer',
    'lua_ls',
  },
  handlers = {
    function(server_name)
      require('lspconfig')[server_name].setup({
        capabilities = lsp_capabilities,
      })
    end,
  },
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
    python = { "isort", "ruff_format" },
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
vim.keymap.set('n', '<leader>rf', builtin.grep_string)
vim.keymap.set('n', '<leader>gg', builtin.find_files)
vim.keymap.set('n', '<leader>hh', ':Alpha<CR>')
vim.keymap.set('n', '<leader>fd', ':LspZeroFormat<CR>')

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', {
    clear = true
  }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

local ls = require 'luasnip'
local p = ls.parser

require 'lspconfig'.eslint.setup({})

local v = {
  p.parse_snippet('ts', '// @ts-expect-error'),
  p.parse_snippet('da', '// eslint-disable-next-line @typescript-eslint/no-explicit-any'),
  p.parse_snippet('da', '// eslint-disable-next-line @typescript-eslint/no-floating-promises'),
  p.parse_snippet('da', '// eslint-disable-next-line @typescript-eslint/no-unnecessary-condition'),
  p.parse_snippet('da', 'const decoder = new TextDecoder("utf8")'),
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
  p.parse_snippet('cl', 'console.log("$1")'),
  p.parse_snippet('cl', 'console.log(e)'),
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


vim.keymap.set('v', '<leader>ca', vim.lsp.buf.code_action)
