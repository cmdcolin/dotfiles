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
set ignorecase


" use Ctrl+F to search in files <fzf based>
nnoremap  <C-F> :Rg<ENTER>
" use Ctrl+G to find file names <fzf based>
nnoremap  <C-G> :GFiles<ENTER>

set mouse=a


set rtp+=/home/linuxbrew/.linuxbrew/opt/fzf


" https://gist.github.com/nervetattoo/3652878
" Console log from insert mode; Puts focus inside parentheses
imap cll console.log({});<Esc>==f{a
" Console log from visual mode on next line, puts visual selection inside parentheses
vmap cll yocll<Esc>p
" Console log from normal mode, inserted on next line with word your on inside parentheses
nmap cll yiwocll<Esc>p

imap ckk console.log('');<Esc>==f'a
" Console log from visual mode on next line, puts visual selection inside parentheses
vmap ckk yockk<Esc>p
" Console log from normal mode, inserted on next line with word your on inside parentheses
nmap ckk yiwockk<Esc>p

imap cjj console.log();<Esc>==f(a
" Console log from visual mode on next line, puts visual selection inside parentheses
vmap cjj yockk<Esc>p
" Console log from normal mode, inserted on next line with word your on inside parentheses
nmap cjj yiwockk<Esc>p


" Fast save
noremap ww :w<CR>


nmap <silent> gd <Plug>(coc-definition)

inoremap <silent><expr> <Tab> coc#refresh()
