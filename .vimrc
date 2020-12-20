set nocompatible
set t_Co=256
filetype off


call plug#begin(stdpath('data') . '/plugged')
Plug 'neoclide/coc.nvim', {'branch': 'master', 'do': 'yarn install --frozen-lockfile'}
Plug 'editorconfig/editorconfig-vim'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-vinegar'
Plug 'joshdick/onedark.vim'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
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


" https://gist.github.com/nervetattoo/3652878
" Automatically generates console.log({|}) where | is cursor
inoremap cll console.log({});<esc><left><left>i
inoremap ckk console.log('');<esc><left><left>i
inoremap cjj console.log();<esc><left>i
" vmap cll yocll<Esc>p
" nmap cll yiwocll<Esc>p

" " Automatically generates console.log('|') where | is cursor
" imap ckk console.log('');<Esc>==f'a
" vmap ckk yockk<Esc>p
" nmap ckk yiwockk<Esc>p

" " Automatically generates console.log(|) where | is cursor
" imap cjj console.log();<Esc>==f(a
" vmap cjj yockk<Esc>p
" nmap cjj yiwockk<Esc>p


" Save with ww instead of :w
noremap ww :w<CR>


" Goto definition with gd
nmap <silent> gd <Plug>(coc-definition)


inoremap <silent><expr> <Tab> coc#refresh()
