-- Install packer
local install_path = vim.fn.stdpath 'data' .. '/site/pack/packer/start/packer.nvim'

if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  vim.fn.execute('!git clone https://github.com/wbthomason/packer.nvim ' .. install_path)
end

local packer_group = vim.api.nvim_create_augroup('Packer', { clear = true })
vim.api.nvim_create_autocmd(
  'BufWritePost',
  { command = 'source <afile> | PackerCompile', group = packer_group, pattern = 'init.lua' }
)

require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'
  use 'tpope/vim-rhubarb'
  use 'numToStr/Comment.nvim'
  use 'neovim/nvim-lspconfig'
  use { 'nvim-telescope/telescope.nvim', requires = { 'nvim-lua/plenary.nvim' } }
  use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' }
  use 'mjlbach/onedark.nvim'
  use 'nvim-lualine/lualine.nvim'
  use 'nvim-treesitter/nvim-treesitter'
  use 'tjdevries/colorbuddy.vim'
  use 'tjdevries/gruvbuddy.nvim'
  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'saadparwaiz1/cmp_luasnip'
  use 'L3MON4D3/LuaSnip'
  use 'dstein64/vim-startuptime'
  use 'mhartington/formatter.nvim'
end)

--Set highlight on search
vim.o.hlsearch = false

--Make line numbers default
vim.wo.number = true

--Enable mouse mode
vim.o.mouse = 'a'

--Save undo history
vim.opt.undofile = true

--Case insensitive searching UNLESS /C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

--Decrease update time
vim.o.updatetime = 250

--Set colorscheme
vim.o.termguicolors = true

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'

-- Nightly only feature
vim.o.cmdheight = 0

vim.o.lazyredraw = true

require('colorbuddy').colorscheme 'gruvbuddy'

--Set statusbar
require('lualine').setup {
  options = {
    icons_enabled = false,
    theme = 'onedark',
    component_separators = '|',
    section_separators = '',
  },
}

--Enable Comment.nvim
require('Comment').setup()

--Remap , as leader key
vim.g.mapleader = ','
vim.g.maplocalleader = ','

-- Enable telescope fzf native
require('telescope').load_extension 'fzf'

--Add leader shortcuts
vim.keymap.set('n', '<leader>gg', require('telescope.builtin').git_files)
vim.keymap.set('n', '<leader>ff', require('telescope.builtin').live_grep)
vim.keymap.set('n', '<leader>bb', require('telescope.builtin').current_buffer_fuzzy_find)
vim.keymap.set('n', '<leader>hh', require('telescope.builtin').grep_string)
vim.keymap.set('n', 'ww', ':w<CR>')
vim.keymap.set('n', 'qq', ':q<CR>')

-- Treesitter configuration
-- Parsers must be installed manually via :TSInstall
require('nvim-treesitter.configs').setup {
  highlight = {
    enable = true, -- false will disable the whole extension
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = 'gnn',
      node_incremental = 'grn',
      scope_incremental = 'grc',
      node_decremental = 'grm',
    },
  },
  indent = {
    enable = true,
  },
}

vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist)

-- LSP settings
local lspconfig = require 'lspconfig'
local on_attach = function(_, bufnr)
  local opts = { buffer = bufnr }
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
  vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, opts)
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
  vim.keymap.set('n', '<leader>so', require('telescope.builtin').lsp_document_symbols, opts)
end

-- nvim-cmp supports additional completion capabilities
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities)

-- Enable the following language servers
local servers = { 'tsserver' }
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
  }
end

-- luasnip setup
local luasnip = require 'luasnip'
local snip = luasnip.snippet
local node = luasnip.snippet_node
local text = luasnip.text_node
local insert = luasnip.insert_node
local func = luasnip.function_node
local choice = luasnip.choice_node
local dynamicn = luasnip.dynamic_node

luasnip.add_snippets(nil, {
  all = {
    snip({
      trig = 'cl',
    }, {
      text { 'console.log({' },
      insert(1, ''),
      text { '})' },
    }),
    snip({
      trig = 'cj',
    }, {
      text { 'console.log(' },
      insert(1, ''),
      text { ')' },
    }),
    snip({
      trig = 'ck',
    }, {
      text { "console.log('" },
      insert(1, ''),
      text { "')" },
    }),
    snip({
      trig = 'da',
    }, {
      text { '// eslint-disable-next-line @typescript-eslint/no-explicit-any' },
    }),
    snip({
      trig = 'ts',
    }, {
      text { '// @ts-ignore' },
    }),
  },
})

local cmp = require 'cmp'
cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert {
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  },
}

vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics,
  {
    virtual_text = false,
    signs = true,
    update_in_insert = false,
  }
)

local prettierfmt = function()
  return {
    exe = 'prettier',
    args = { '--stdin-filepath', vim.fn.fnameescape(vim.api.nvim_buf_get_name(0)) },
    stdin = true,
  }
end

require('formatter').setup {
  filetype = {
    javascriptreact = { prettierfmt },
    javascript = { prettierfmt },
    typescriptreact = { prettierfmt },
    typescript = { prettierfmt },
    json = { prettierfmt },
    markdown = { prettierfmt },
    r = { rfmt },
    html = { prettierfmt },
    css = { prettierfmt },
    svg = { prettierfmt },
  },
}

vim.api.nvim_exec(
  [[
augroup FormatAutogroup
  autocmd!
  autocmd BufWritePost *.js,*.tsx,*.ts,*jsx,*json,*.md,*.R,*.r,*.html,*.css,*.svg FormatWrite
augroup END
]],
  true
)
