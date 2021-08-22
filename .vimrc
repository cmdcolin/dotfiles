set nocompatible


call plug#begin(stdpath('data') . '/plugged')
Plug 'neoclide/coc.nvim', {'branch': 'master', 'do': 'yarn install --frozen-lockfile'}
Plug 'editorconfig/editorconfig-vim'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-vinegar'
Plug 'tpope/vim-rhubarb'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'tjdevries/colorbuddy.vim'
Plug 'tjdevries/gruvbuddy.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
call plug#end()


lua require('colorbuddy').colorscheme('gruvbuddy')

" configure treesitter
lua << EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = "all",
  highlight = {
    enable = true,
  },
}
EOF

nnoremap <leader>ff <cmd>Telescope git_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>



set nu
set clipboard=unnamedplus
set smartcase
set termguicolors


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

nnoremap <silent> K :call <SID>show_documentation()<CR>

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



set mouse=a


" https://gist.github.com/nervetattoo/3652878
" Automatically generates console.log({|}) where | is cursor
inoremap cll console.log({});<esc><left><left>i
inoremap ckk console.log('');<esc><left><left>i
inoremap cjj console.log();<esc><left>i

" Save with ww instead of :w
noremap ww :w<CR>
noremap qq :q<CR>

" Goto definition with gd
nmap <silent> gd <Plug>(coc-definition)


