set number
syntax enable
set mouse=a
set visualbell
set tabstop=8 softtabstop=0 expandtab shiftwidth=4 smarttab

" set background=dark
" colorscheme gruvbox

" colorscheme 256_noir

if &term =~ '256color'
  " disable Background Color Erase (BCE) so that color schemes
  " render properly when inside 256-color tmux and GNU screen.
  " see also http://snk.tuxfamily.org/log/vim-256color-bce.html
  set t_ut=
endif

set clipboard=unnamed

" powerline
set rtp+=/usr/local/lib/python3.6/dist-packages/powerline/bindings/vim
set laststatus=2
set t_Co=256
