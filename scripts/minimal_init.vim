set rtp+=.
set rtp+=../plenary.nvim/
set rtp+=~/.local/share/nvim/lazy/plenary.nvim/

runtime! plugin/plenary.vim
runtime! plugin/load_present.lua

let g:telescope_test_delay = 100
