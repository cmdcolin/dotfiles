return require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'
  use 'mhartington/formatter.nvim'
  use 'kyazdani42/nvim-web-devicons'
  use 'tpope/vim-vinegar'
  use 'tpope/vim-fugitive'
  use 'tpope/vim-rhubarb'
  use 'tpope/vim-commentary'
  use 'KeitaNakamura/neodark.vim'
  use 'mhinz/vim-startify'
  use 'kylechui/nvim-surround'
  use 'windwp/nvim-autopairs'
  use 'ggandor/leap.nvim'
  use { 'nvim-telescope/telescope.nvim', requires = { 'nvim-lua/plenary.nvim' } }
  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }

  -- all requires from https://github.com/VonHeikemen/lsp-zero.nvim
  use {
    'VonHeikemen/lsp-zero.nvim',
    requires = {
      { 'neovim/nvim-lspconfig' },
      { 'williamboman/mason.nvim' },
      { 'williamboman/mason-lspconfig.nvim' },
      { 'hrsh7th/nvim-cmp' },
      { 'hrsh7th/cmp-buffer' },
      { 'hrsh7th/cmp-path' },
      { 'saadparwaiz1/cmp_luasnip' },
      { 'hrsh7th/cmp-nvim-lsp' },
      { 'hrsh7th/cmp-nvim-lua' },
      { 'L3MON4D3/LuaSnip' },
    },
  }
end)
