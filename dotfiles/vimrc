set t_Co=256


if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
      \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
Plug 'editorconfig/editorconfig-vim'
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-vinegar'
Plug 'joshdick/onedark.vim'
Plug 'vim-airline/vim-airline'
Plug 'w0rp/ale'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'yegappan/mru'
Plug 'lifepillar/vim-mucomplete'
Plug 'Quramy/tsuquyomi'
Plug 'leafgarland/typescript-vim'
call plug#end()
colorscheme onedark

" autofix using eslint, lifesaver...
let g:ale_fixers = ['eslint']
let g:ale_fix_on_save = 1
let g:ale_lint_on_text_changed = 'never'

" use Ctrl+F to search in files <fzf based>
nnoremap  <C-F> :Rg<ENTER>
" use Ctrl+G to find file names <fzf based>
nnoremap  <C-G> :GFiles<ENTER>
" use Ctrl+H to open most recently used files list
nnoremap  <C-H> :MRU<ENTER>


" completion args
let g:mucomplete#enable_auto_at_startup = 1
set completeopt+=menuone
set completeopt+=noselect
set belloff+=ctrlg " If Vim beeps during completion


set mouse=a

" line numbers
set nu

" display extra characters
set list

" search ignore case
set ignorecase

" search ignore case unless something is upper cased
set smartcase

" netrw/vim-vinegar, no nerdtree like sidebar is used. instead depend on fzf
" and occaisional browsing of the netrw via '-'
let g:netrw_banner = 0
let g:netrw_liststyle=3
let g:netrw_winsize = 20
let g:netrw_preview = 1


" allow using mouse to resize splits
" https://superuser.com/questions/549930/cant-resize-vim-splits-inside-tmux
if has("mouse_sgr")
    set ttymouse=sgr
else
    set ttymouse=xterm2
end

" larger MRU window height
let MRU_Window_Height = 20

" swp file location
set directory^=$HOME/.vim/tmp//
