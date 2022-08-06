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

let s:save_cpo = &cpo
set cpo&vim

" options {{{
if !exists('g:easytree_loaded')
    let g:easytree_loaded = 0
endif

if !exists('g:easytree_use_python2')
    let g:easytree_use_python2 = 0
endif

if !exists("g:easytree_cascade_open_single_dir")
    let g:easytree_cascade_open_single_dir = 1
endif

if !exists("g:easytree_show_line_numbers")
    let g:easytree_show_line_numbers = 0
endif

if !exists("g:easytree_show_relative_line_numbers")
    let g:easytree_show_relative_line_numbers = 0
endif

if !exists("g:easytree_show_hidden_files")
    let g:easytree_show_hidden_files = 0
endif

if !exists("g:easytree_highlight_cursor_line")
    let g:easytree_highlight_cursor_line = 1
endif

if !exists("g:easytree_enable_vs_and_sp_mappings")
    let g:easytree_enable_vs_and_sp_mappings = 0
endif

if !exists("g:easytree_ignore_dirs")
    let g:easytree_ignore_dirs = []
endif

if !exists("g:easytree_ignore_files")
    let g:easytree_ignore_files = ['.easytree','*.swp']
endif

if !exists("g:easytree_ignore_find_result")
    let g:easytree_ignore_find_result = []
endif

if !exists("g:easytree_use_plus_and_minus")
    let g:easytree_use_plus_and_minus = 0
endif

if !exists("g:easytree_auto_load_settings")
    let g:easytree_auto_load_settings = 1
endif

if !exists("g:easytree_auto_save_settings")
    let g:easytree_auto_save_settings = 0
endif

if !exists("g:easytree_settings_file")
    let g:easytree_settings_file = '<dir>/.easytree'
endif

if !exists("g:easytree_hijack_netrw")
    let g:easytree_hijack_netrw = 1
endif

if !exists("g:easytree_width_auto_fit")
    let g:easytree_width_auto_fit = 0
endif

if !exists("g:easytree_win")
    let g:easytree_win = 'left'
endif

if !exists("g:easytree_toggle_win")
    let g:easytree_toggle_win = 'left'
endif

if !exists("g:easytree_git_enable")
    let g:easytree_git_enable = 1
endif

if !exists("g:easytree_git_indicators")
    let g:easytree_git_indicators = {
                    \ 'Branch'    : '',
                    \ 'Unstaged'  : '✗',
                    \ 'Staged'    : '✔︎',
                    \ 'Separator' : '|',
                    \ 'Modified'  : '✹',
                    \ 'Added'     : '✚',
                    \ 'Deleted'   : '✖',
                    \ 'Renamed'   : '➜',
                    \ 'Copied'    : '➜',
                    \ 'Unmerged'  : '═',
                    \ 'Ignored'   : '☒',
                    \ 'Untracked' : '✭',
                    \ 'Unknown'   : '?'
                    \ }
endif

" }}}

" commands {{{
command! -nargs=? -complete=dir EasyTree call easytree#OpenTree(g:easytree_win,<q-args>)
command! -nargs=? -complete=dir EasyTreeToggle call easytree#ToggleTree(g:easytree_toggle_win,<q-args>)
command! -nargs=? -complete=dir EasyTreeHere call easytree#OpenTree('edit here',<q-args>)
command! -nargs=? -complete=dir EasyTreeLeft call easytree#OpenTree('left',<q-args>)
command! -nargs=? -complete=dir EasyTreeRight call easytree#OpenTree('right',<q-args>)
command! -nargs=? -complete=dir EasyTreeTop call easytree#OpenTree('top',<q-args>)
command! -nargs=? -complete=dir EasyTreeBottom call easytree#OpenTree('bottom',<q-args>)
command! -nargs=? -complete=dir EasyTreeTopDouble call easytree#OpenTree('top double',<q-args>)
command! -nargs=? -complete=dir EasyTreeBottomDouble call easytree#OpenTree('bottom double',<q-args>)
command! -nargs=0 EasyTreeBuffer call easytree#OpenTree(g:easytree_win,fnamemodify(bufname(),':h:p'))
command! -nargs=0 EasyTreeBufferHere call easytree#OpenTree('edit here',fnamemodify(bufname(),':p:h'))
command! -nargs=0 EasyTreeBufferLeft call easytree#OpenTree('left',fnamemodify(bufname(),':p:h'))
command! -nargs=0 EasyTreeBufferRight call easytree#OpenTree('right',fnamemodify(bufname(),':p:h'))
command! -nargs=0 EasyTreeBufferTop call easytree#OpenTree('top',fnamemodify(bufname(),':p:h'))
command! -nargs=0 EasyTreeBufferBottom call easytree#OpenTree('bottom',fnamemodify(bufname(),':p:h'))
command! -nargs=0 EasyTreeBufferTopDouble call easytree#OpenTree('top double',fnamemodify(bufname(),':p:h'))
command! -nargs=0 EasyTreeBufferBottomDouble call easytree#OpenTree('bottom double',fnamemodify(bufname(),':p:h'))
command! -nargs=0 EasyTreeBufferReveal call easytree#OpenTreeReveal(fnamemodify(bufname(),':p'))
command! -nargs=0 EasyTreeFocus call easytree#OpenTreeFocus()
" }}}

" netrw hijacking related functions {{{
function! s:OpenDirHere(dir)
    if isdirectory(a:dir)
        call easytree#OpenTree('edit here',a:dir) 
    endif
endfunction

function! s:DisableFileExplorer()
    au! FileExplorer
endfunction

augroup EasyTree
    autocmd VimEnter * if g:easytree_hijack_netrw | call <SID>DisableFileExplorer() | endif
    autocmd BufEnter * if g:easytree_hijack_netrw | call <SID>OpenDirHere(expand('<amatch>')) | endif
augroup end
" }}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: set sw=4 sts=4 et fdm=marker:
