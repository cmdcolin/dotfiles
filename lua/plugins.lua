return require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'
  use 'mhartington/formatter.nvim'
  use 'kyazdani42/nvim-web-devicons'
  use 'tpope/vim-vinegar'
  use 'tpope/vim-fugitive'
  use 'tpope/vim-rhubarb'
  use 'tpope/vim-commentary'
  use 'EdenEast/nightfox.nvim'
  use 'mhinz/vim-startify'
  use { 'nvim-telescope/telescope.nvim', requires = { { 'nvim-lua/plenary.nvim' } } }
  use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' }
  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }
  use {
    'kylechui/nvim-surround',
    config = function()
      require('nvim-surround').setup()
    end,
  }

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
