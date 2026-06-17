colorscheme darkblue
call plug#begin()

" List your plugins here

Plug 'https://github.com/tpope/vim-commentary.git'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

call plug#end()
