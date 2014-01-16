" easytree.vim - simple tree file manager for vim
" Maintainer: Dmitry "troydm" Geurkov <d.geurkov@gmail.com>
" Version: 0.2.2
" Description: easytree.vim is a simple tree file manager
" Last Change: 16 January, 2014
" License: Vim License (see :help license)
" Website: https://github.com/troydm/easytree.vim
"
" See easytree.vim for help.  This can be accessed by doing:
" :help easytree

if exists("b:current_syntax")
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

syntax match EasyTreeRoot /\%1l.*/
syntax match EasyTreeRootUp /\%2l.*/
syntax match EasyTreeDir /^\%>2l\s*[▸▾+-] .*$/
syntax match EasyTreeFile /^\%>2l\s*[^▸▾+-]*$/

highlight default link EasyTreeRoot   Operator
highlight default link EasyTreeRootUp Title
highlight default link EasyTreeDir    Identifier
highlight default link EasyTreeFile   Normal

let b:current_syntax = "easytree"

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: ts=8 sw=4 sts=4 et foldenable foldmethod=marker foldcolumn=1
