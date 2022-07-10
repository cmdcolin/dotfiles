return require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'
  use 'mhartington/formatter.nvim'
  use 'tjdevries/colorbuddy.vim'
  use 'tpope/vim-vinegar'
  use 'tpope/vim-commentary'
  use 'tjdevries/gruvbuddy.nvim'
  use { 'nvim-telescope/telescope.nvim', requires = { { 'nvim-lua/plenary.nvim' } } }
  use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' }
  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }
  use 'williamboman/nvim-lsp-installer'
  use 'neovim/nvim-lspconfig'
  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'
  use 'hrsh7th/cmp-path'
  use { 'saadparwaiz1/cmp_luasnip' }
  use 'L3MON4D3/LuaSnip'
  use 'mhinz/vim-startify'
  use {
    'numToStr/Comment.nvim',
    config = function()
      require('Comment').setup()
    end,
  }
end)
