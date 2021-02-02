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
set clipboard=unnamedplus
set ignorecase


" TextEdit might fail if hidden is not set.
set hidden

" Some servers have issues with backup files, see #649.
set nobackup
set nowritebackup

" Give more space for displaying messages.
set cmdheight=2

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=100

" Don't pass messages to |ins-completion-menu|.
set shortmess+=c

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
if has("patch-8.1.1564")
  " Recently vim can merge signcolumn and number column into one
  set signcolumn=number
else
  set signcolumn=yes
endif


function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction

autocmd CursorHold * silent call CocActionAsync('highlight')
autocmd CursorHold * silent call CocActionAsync('doHover')



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

" Save with ww instead of :w
noremap ww :w<CR>

" Goto definition with gd
nmap <silent> gd <Plug>(coc-definition)

