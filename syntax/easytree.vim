" easytree.vim - simple tree file manager for vim
" Maintainer: Dmitry "troydm" Geurkov <d.geurkov@gmail.com>
" Version: 0.2.2
" Description: easytree.vim is a simple tree file manager
" Last Change: 5 November, 2020
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
syntax match EasyTreeFile /^\%>2l.*$/
syntax match EasyTreeDir /^\%>2l\s*[▸▾+-] .*$/

for indicator in keys(g:easytree_git_indicators)
    if indicator != 'Branch'
        exe 'syntax match EasyTreeGit'.indicator.' /'.g:easytree_git_indicators[indicator].'/ containedin=EasyTreeFile'
    endif
endfor
exe 'syntax match EasyTreeGitBranch /'.g:easytree_git_indicators['Branch']."[^)]\\+/ containedin=EasyTreeRootUp"

highlight default link EasyTreeRoot   Operator
highlight default link EasyTreeRootUp Title
highlight default link EasyTreeDir    Identifier
highlight default link EasyTreeFile   Normal
highlight default link EasyTreeFile   Identifier

highlight default link EasyTreeGitBranch    String
highlight default link EasyTreeGitStaged    Identifier
highlight default link EasyTreeGitUnstaged  Identifier
highlight default link EasyTreeGitSeparator Title
highlight default link EasyTreeGitAdded     Number
highlight default link EasyTreeGitModified  Character
highlight default link EasyTreeGitRenamed   Operator
highlight default link EasyTreeGitCopied    Operator
highlight default link EasyTreeGitDeleted   String
highlight default link EasyTreeGitUnmerged  Boolean
highlight default link EasyTreeGitIgnored   Comment
highlight default link EasyTreeGitUntracked Type
highlight default link EasyTreeGitUnknown   Comment

let b:current_syntax = "easytree"

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: ts=8 sw=4 sts=4 et foldenable foldmethod=marker foldcolumn=1
