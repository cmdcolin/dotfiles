set nocompatible
set t_Co=256
filetype off


call plug#begin(stdpath('data') . '/plugged')
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'editorconfig/editorconfig-vim'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-vinegar'
Plug 'joshdick/onedark.vim'
Plug 'junegunn/fzf.vim'
Plug 'leafgarland/typescript-vim'
Plug 'peitalin/vim-jsx-typescript'
call plug#end()

colorscheme onedark
set nu
set mouse=a
set clipboard=unnamedplus


" use Ctrl+F to search in files <fzf based>
nnoremap  <C-F> :Rg<ENTER>
" use Ctrl+G to find file names <fzf based>
nnoremap  <C-G> :GFiles<ENTER>

set mouse=a


set rtp+=/home/linuxbrew/.linuxbrew/opt/fzf


nmap <silent> gd <Plug>(coc-definition)

inoremap <silent><expr> <Tab> coc#refresh()
