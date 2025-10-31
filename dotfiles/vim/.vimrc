"set mouse=a
"set ttymouse=xterm2

set autoindent

set number
syntax on
highlight LineNr ctermfg=darkgray
set nobackup
set nowritebackup
set noerrorbells
set belloff=all
set title
set noswapfile
set undodir=~/.vim/undodir
set undofile
set incsearch
set bs=2
set nocp
" set colorcolumn=120
" highlight ColorColumn ctermbg=0 guibg=lightgrey

" Backspace over
set backspace+=indent  " autoindent
set backspace+=eol     " line breaks
set backspace+=start   " start of insert

" Use spaces instead of tabs
set expandtab
set smartindent
set shiftwidth=4
set tabstop=4
set softtabstop=4

" Highlight matches
set hlsearch
set incsearch

" Prefer case insensitive search
set ignorecase
set smartcase

" set rtp+=/opt/homebrew/opt/fzf

" NERDTree
nnoremap <leader>n :NERDTreeFocus<CR>
nnoremap <C-n> :NERDTree<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
nnoremap <C-f> :NERDTreeFind<CR>

" === PLUGINS ===
" https://github.com/junegunn/vim-plug
"call plug#begin('~/.vim/plugged')
"    Plug 'mtdl9/vim-log-highlighting'
"    Plug 'scrooloose/nerdtree'
"call plug#end()
" === PLUGINS ===

