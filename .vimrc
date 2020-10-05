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
" onedark.vim override: Don't set a background color when running in a terminal;
" just use the terminal's background color
" `gui` is the hex color code used in GUI mode/nvim true-color mode
" `cterm` is the color code used in 256-color mode
" `cterm16` is the color code used in 16-color mode
if (has("autocmd") && !has("gui_running"))
  augroup colorset
    autocmd!
    let s:white = { "gui": "#ABB2BF", "cterm": "145", "cterm16" : "7" }
    autocmd ColorScheme * call onedark#set_highlight("Normal", { "fg": s:white }) " `bg` will not be styled since there is no `bg` setting
  augroup END
endif
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
