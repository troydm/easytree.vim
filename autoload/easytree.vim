" easytree.vim - simple tree file manager for vim
" Maintainer: Dmitry "troydm" Geurkov <d.geurkov@gmail.com>
" Version: 0.2.1
" Description: easytree.vim is a simple tree file manager
" Last Change: 3 June, 2014
" License: Vim License (see :help license)
" Website: https://github.com/troydm/easytree.vim
"
" See easytree.vim for help.  This can be accessed by doing:
" :help easytree

let s:save_cpo = &cpo
set cpo&vim

" check if already loaded {{{
if !exists('g:easytree_loaded')
    let g:easytree_loaded = 1
elseif g:easytree_loaded
    let &cpo = s:save_cpo
    unlet s:save_cpo
    finish
else
    let g:easytree_loaded = 1
endif
" }}}

" load python module {{{
python << EOF
import vim, os, random, sys
easytree_path = vim.eval("expand('<sfile>:h')")
if not easytree_path in sys.path:
    sys.path.insert(0, easytree_path)
del easytree_path
import easytree
EOF
" }}}

let s:easytree_on_windows = pyeval('easytree.easytree_on_windows')
if s:easytree_on_windows
    let s:easytree_path_sep = '\'
else
    let s:easytree_path_sep = '/'
endif

" functions {{{
" input helpers {{{
function! s:AskInput(message,val)
    let r = input(a:message,a:val)
    redraw
    echo ''
    return r
endfunction

function! s:AskInputNoRedraw(message,val)
    let r = input(a:message,a:val)
    echo ' '
    return r
endfunction

function! s:AskInputComplete(message,val,complete)
    let r = input(a:message,a:val,a:complete)
    redraw
    echo ''
    return r
endfunction

function! s:AskConfirmation(message)
    let r = tolower(input(a:message.' (y/n) '))
    redraw
    echo ''
    return r == 'y' || r == 'ye' || r == 'yes'
endfunction

function! s:AskConfirmationNoRedraw(message)
    let r = tolower(input(a:message.' (y/n) '))
    echo ' '
    return r == 'y' || r == 'ye' || r == 'yes'
endfunction
" }}}

" utility functions {{{
function! s:IsDir(line)
    return !empty(matchlist(a:line,'^\s*[▸▾+\-] \(.*\)$'))
endfunction

function! s:IsExpanded(line)
    return !empty(matchlist(a:line,'^\s*[▾\-] \(.*\)$'))
endfunction

function! s:GetFName(line)
    return matchlist(a:line,'^[▸▾+\- ]\+\(.*\)$')[1]
endfunction

function! s:GetParentLvlLinen(linen)
    if a:linen == 1
        return 1
    endif
    let lvl = s:GetLvl(getline(a:linen))
    if lvl == 1
        return 1
    else
        let linen = a:linen - 1
        while linen > 2 && s:GetLvl(getline(linen)) >= lvl
            let linen -= 1
        endwhile
        return linen
    endif
endfunction

function! s:GetDirLine(linen)
    let linen = a:linen
    let line = getline(linen)
    if s:IsDir(line)
        return linen
    else
        let linelvl = s:GetLvl(line)-1
        let linen -= 1
        while linen > 2
            let line = getline(linen)
            if s:IsDir(line) && s:GetLvl(line) == linelvl
                return linen
            endif
            let linen -= 1
        endwhile
    endif
    return 1
endfunction

function! s:GetLvl(line)
    let lvl = 0
    let lvls = '[▸▾+\- ] '
    while match(a:line, '^'.lvls) == 0
        let lvl += 1
        let lvls = '  '.lvls
    endwhile
    return lvl
endfunction

function! s:GetFullPathDir(linen)
    let fpath = s:GetFullPath(a:linen)
    if pyeval("os.path.isdir(vim.eval('fpath'))")
        return fpath
    else
        let fpath = pyeval("os.path.dirname(vim.eval('fpath'))")
        return fpath
    endif
endfunction

function! s:GetFullPath(linen)
    if a:linen == 2
        let dirp = getline(1)
        if dirp != '/'
            let dirp = pyeval("os.path.abspath(vim.eval('dirp')+'".s:easytree_path_sep."..')")
        endif
        return dirp
    elseif a:linen == 1
        return getline(1)
    endif
    let dirp = getline(1)
    let dirm = ''
    let line = getline(a:linen)
    let fname = ''
    let lvl = s:GetLvl(line)
    let lvln = a:linen
    while lvl > 0
        let fname = s:easytree_path_sep.s:GetFName(getline(lvln)).fname
        let lvl -= 1
        if lvl > 0
            while s:GetLvl(getline(lvln)) != lvl
                let lvln -= 1
            endwhile
        endif
    endwhile
    if dirp == '/'
        return fname
    else
        if s:easytree_on_windows && len(dirp) == 3
            let dirp = dirp[:1]
        endif
        return dirp.fname
    endif
endfunction

function! s:DirName(path)
    let path = a:path
    return pyeval("os.path.dirname(vim.eval('path'))")
endfunction

function! s:FileName(path)
    let path = a:path
    return pyeval("os.path.basename(vim.eval('path'))")
endfunction

function! s:GetPasteBuffer()
    let files = split(getreg(v:register),"\n")
    return filter(files,'filereadable(v:val) || isdirectory(v:val)')
endfunction

function! s:SetPasteBuffer(files)
    call setreg(v:register,join(a:files,"\n"))
endfunction

function! s:FindBufnrByFilename(filename)
    for bnr in filter(range(1,bufnr('$')),"buflisted(v:val) && empty(getbufvar(v:val,'&buftype'))")
        if expand('#'.bnr.':p') == a:filename
            return bnr
        endif
    endfor
    return -1
endfunction

function! s:DeleteBuf(filename)
    let bnr = s:FindBufnrByFilename(a:filename)
    if bnr != -1
        let message = expand('#'.bnr.':p').' is opened in '.bnr.' buffer'
        if getbufvar(bnr,'&modified')
            let message .= ' and is modified!'
        else
            let message .= '!'
        endif
        let message .= ' are you sure you want to delete this buffer?'
        if s:AskConfirmation(message)
            exe bnr.'bwipeout!'
            return 1
        endif
    else
        return 1
    endif
    return 0
endfunction
" }}}

" action functions {{{
function! s:EditIgnoreFiles()
    let il = ''
    for f in b:ignore_files
        let il .= f.','
    endfor
    if len(il) > 0
        let il = il[:-2]
    endif
    let mil = ''
    for f in split(s:AskInput("ignore files: ",il),',')
        let mil .= "'".f."',"
    endfor
    if len(mil) > 0
        let mil = mil[:-2]
    endif
    exe 'let b:ignore_files = ['.mil.']'
    call s:RefreshAll()
endfunction

function! s:EditIgnoreDirs()
    let il = ''
    for d in b:ignore_dirs
        let il .= d.','
    endfor
    if len(il) > 0
        let il = il[:-2]
    endif
    let mil = ''
    for d in split(s:AskInput("ignore dirs: ",il),',')
        let mil .= "'".d."',"
    endfor
    if len(mil) > 0
        let mil = mil[:-2]
    endif
    exe 'let b:ignore_dirs = ['.mil.']'
    call s:RefreshAll()
endfunction

function! s:EditIgnoreFindResult()
    let il = ''
    for f in b:ignore_find_result
        let il .= f.','
    endfor
    if len(il) > 0
        let il = il[:-2]
    endif
    let mil = ''
    for f in split(s:AskInput("ignore find result: ",il),',')
        let mil .= "'".f."',"
    endfor
    if len(mil) > 0
        let mil = mil[:-2]
    endif
    exe 'let b:ignore_find_result = ['.mil.']'
endfunction

function! s:ChangeDir(linen)
    let fpath = s:GetFullPathDir(a:linen)
    call s:InitializeNewTree(fpath)
    normal! 3G0
endfunction

function! s:ChangeDirTo(...)
    if len(a:000) > 0
        let path = a:1
    else
        let path = s:AskInputComplete('go to ',getline(1),'dir')
    endif
    if !empty(path)
        if pyeval("os.path.isdir(os.path.expanduser(vim.eval('path')))")
            call s:InitializeNewTree(path)
        else
            redraw
            echo 'invalid path '.path
        endif
    endif
endfunction

function! s:ChangeCwdDir(linen)
    let fpath = s:GetFullPathDir(a:linen)
    exe 'cd '.substitute(fpath,' ','\\ ','g')
    echo 'cwd: '.fpath
endfunction

function! s:GoUpTree()
    normal! 2G0
    call s:EnterPressed()
endfunction

function! s:ToggleHidden()
    if b:showhidden
        let b:showhidden = 0
    else
        let b:showhidden = 1
    endif
    call s:RefreshAll()
    if b:showhidden
        echo 'showing hidden files'
    else
        echo 'not showning hidden files'
    endif
endfunction

function! s:CopyFile(linen)
    let fpath = s:GetFullPath(a:linen)
    call setreg(v:register,fpath)
    echo '1 file copied'
endfunction

function! s:CopyFilesRange() range
    let buf = ''
    let i = 0
    for l in range(a:firstline,a:lastline)
        let fpath = s:GetFullPath(l)
        let buf .= fpath."\n"
        let i += 1
    endfor
    call setreg(v:register,buf)
    if i == 1
        echo '1 file copied'
    else
        echo i.' files copied'
    endif
endfunction

function! s:MoveFiles(linen)
    echo 'paste buffer:'
    for f in s:GetPasteBuffer()
        echo f
    endfor
    if s:AskConfirmation('are you sure you want to move the files here?')
        let fpath = s:GetFullPathDir(a:linen)
        let files = s:GetPasteBuffer()

        let error = pyeval('easytree.EasyTreeCopyFiles()')
        if type(error) == 1 && error == 'error'
            return
        endif
        call s:Refresh(a:linen)
        if len(error) > 0
            for f in error
                let files = filter(files,'v:val != "'+f+'"')
            endfor
            call s:SetPasteBuffer(files)
            let files = s:GetPasteBuffer()
        endif

        call pyeval('easytree.EasyTreeRemoveFiles()')
        call s:RefreshAll()
        if len(files) == 0 && len(error) == 0
            echom 'No files were moved'
            return
        endif
        if len(files) > 0
            echom 'Following files were moved:'
            for f in files
                echom f
            endfor
        endif
        if len(error) > 0
            echom 'Following files couldn''t be moved:'
            for f in error
                echom f
            endfor
        endif
    endif
endfunction

function! s:EchoPasteBuffer()
    let files = s:GetPasteBuffer()
    if len(files) > 0
        echo 'paste buffer:'
        for f in s:GetPasteBuffer()
            echo f
        endfor
    else
        echo 'no files in paste buffer'
    endif
endfunction

function! s:PasteFiles(linen)
    let fpath = s:GetFullPathDir(a:linen)
    let files = s:GetPasteBuffer()
    if len(files) > 0
        let filesm = '1 file'
        if len(files) > 1
            let filesm = len(files).' files'
        endif
        for f in files
            echo f
        endfor
        if s:AskConfirmation('are you sure you want to paste '.filesm.'?')
            python easytree.EasyTreeCopyFiles()
            call s:Refresh(a:linen)
        endif
    endif
endfunction

function! s:RemoveFile(linen)
    let messages = []
    if a:linen > 2
        let fpath = s:GetFullPath(a:linen)
        let files = [fpath]
        if s:DeleteBuf(fpath) && s:AskConfirmation('are you sure you want to delete this file?')
            let messages = pyeval('easytree.EasyTreeRemoveFiles()')
            call s:Refresh(s:GetParentLvlLinen(a:linen))
        endif
    endif
    for m in messages
        echom m
    endfor
endfunction

function! s:RemoveFiles() range
    let files = []
    for l in range(a:firstline,a:lastline)
        if l > 2
            let fpath = s:GetFullPath(l)
            call add(files,fpath)
        endif
    endfor
    let messages = []
    if len(files) > 0
        for f in files
            if !s:DeleteBuf(f)
                return
            endif
            echo f
        endfor
        if s:AskConfirmation('are you really sure you want to delete this files?')
            let messages = pyeval('easytree.EasyTreeRemoveFiles()')
            call s:RefreshAll()
        endif
    endif
    for m in messages
        echom m
    endfor
endfunction

function! s:CreateFile(linen)
    let fpath = s:GetFullPathDir(a:linen).s:easytree_path_sep
    let path = s:AskInput('create '.fpath,'')
    if !empty(path)
        let path = fpath.path
        python easytree.EasyTreeCreateFile()
        call s:Refresh(a:linen)
    endif
endfunction

function! s:RenameFile(linen)
    let fpath = s:GetFullPath(a:linen)
    let dpath = s:DirName(fpath).s:easytree_path_sep
    let fname = s:FileName(fpath)
    let fnameto = s:AskInput('rename '.dpath,fname)
    if !empty(fnameto)
        if !s:DeleteBuf(fpath)
            return
        endif
        python easytree.EasyTreeRenameFile()
        call s:Refresh(s:GetParentLvlLinen(a:linen))
    endif
endfunction

function! s:RefreshAll()
    if line('.') > 2
        let prevfpath = s:GetFullPath(line('.'))
    endif
    let toexpand = {}
    let newtree = line('$') == 1
    if !newtree
        for d in keys(b:expanded)
            if b:expanded[d]
                let toexpand[d] = 1
            endif
        endfor
        let expanded = b:expanded
    endif
    let line = getline(1)
    let pos = getpos('.')
    call s:InitializeTree(line)
    if newtree
        let toexpand = filter(b:expanded,'v:val == 1')
    else
        let b:expanded = expanded
    endif
    let linen = 3
    setlocal modifiable
    while line('$') >= linen
        let line = getline(linen)
        if s:GetLvl(line) == 1 && s:IsDir(line)
            let fpath = s:GetFullPath(linen)
            if has_key(toexpand, fpath)
                call s:ExpandDir(fpath,linen)
            endif
        endif
        let linen += 1
    endwhile
    setlocal nomodifiable
    if pos[1] > 2
        if prevfpath != s:GetFullPath(pos[1])
            let i = 1
            let maxln = line('$')
            while (pos[1]-i) > 2 || (pos[1]+i) <= maxln
                if (pos[1]-i) > 2
                    if prevfpath == s:GetFullPath(pos[1]-i)
                        let pos[1] -= i
                        break
                    endif
                endif
                if (pos[1]+i) <= maxln
                    if prevfpath == s:GetFullPath(pos[1]+i)
                        let pos[1] += i
                        break
                    endif
                endif
                let i += 1
            endwhile
        endif
    endif
    call setpos('.',pos)
    redraw
endfunction

function! s:Refresh(linen)
    let linen = s:GetDirLine(a:linen)
    if linen == 1
        call s:RefreshAll()
    else
        let line = getline(linen)
        if s:IsExpanded(line)
            let fpath = s:GetFullPath(linen)
            let pos = getpos('.')
            setlocal modifiable
            call s:UnexpandDir(fpath,linen)
            call s:ExpandDir(fpath,linen)
            setlocal nomodifiable
            call setpos('.',pos)
        endif
    endif
endfunction

function! s:Find(linen, find)
    let linen = a:linen
    if linen == 2
        let linen = 1
    endif
    let fpath = s:GetFullPathDir(linen)
    let find = s:AskInputComplete('search in '.fpath.' for ',a:find,'file')
    if !empty(find)
        let @/ = ''
        let b:find = find
        echo 'searching for '.find
        exe "let b:findresult = pyeval(\"easytree.EasyTreeFind(vim.eval('find'),vim.eval('fpath'),".b:showhidden.")\")"
        redraw
        if fpath != getline(1)
            let fpath = fpath[len(getline(1)):]
            if len(fpath) > 0 && fpath[0] == s:easytree_path_sep
                let fpath = fpath[1:]
            endif
            if len(fpath) > 0
                let b:findresult = map(b:findresult,"fpath.'".s:easytree_path_sep."'.v:val")
            endif
        endif
        if !empty(b:findresult)
            echo ''
            let b:findindex = -1
            call s:FindNext()
        else
            echo 'no files found'
        endif
    endif
endfunction

function! s:FindNext()
    if !empty(@/)
        normal! n
        return
    end
    if empty(b:findresult)
        echo 'no files found'
        return
    endif
    let b:findindex += 1
    if b:findindex >= len(b:findresult)
        let b:findindex = 0
    endif
    call s:FindFile()
endfunction

function! s:FindBackward()
    if !empty(@/)
        normal! N
        return
    end
    if empty(b:findresult)
        echo 'no files found'
        return
    endif
    let b:findindex -= 1
    if b:findindex < 0
        let b:findindex = len(b:findresult)-1
    endif
    call s:FindFile()
endfunction

function! s:FindFile()
    if line('$') > 2
        let find = b:findresult[b:findindex]
        let findf = getline(1).s:easytree_path_sep.find
        let findp = split(find,s:easytree_path_sep)
        let lvl = 1
        let i = 3
        while line('$') >= i
            if s:GetLvl(getline(i)) == lvl
                let fpath = s:GetFullPath(i)
                if lvl == len(findp)
                    if fpath == findf
                        let pos = getpos('.')
                        let pos[1] = i
                        let pos[2] = 1
                        call setpos('.',pos)
                        return
                    endif
                else
                    let findlvlf = getline(1).s:easytree_path_sep.join(findp[:(lvl-1)],s:easytree_path_sep)
                    if fpath == findlvlf
                        call s:Expand(i)
                        let lvl += 1
                    endif
                endif
            endif
            let i += 1
        endwhile
    endif
endfunction

function! s:PrintFilePath()
    if line('.') < 3
        return
    endif

    let fpath = s:GetFullPath(line('.'))
    if v:count > 0
        echo fpath
    else
        let root  = s:GetFullPath(1)
        let rpath = fpath[len(root):]
        if rpath[0] == s:easytree_path_sep
            let rpath = rpath[1:]
        endif
        echo rpath
    endif
endfunction

function! s:EnterPressed()
    if line('.') > 2
        let fpath = s:GetFullPath(line('.'))
        let isdir = s:IsDir(getline('.'))
        if isdir
            setlocal modifiable
            if s:IsExpanded(getline('.'))
                call s:UnexpandDir(fpath,line('.'))
                let b:expanded[fpath] = 0
            else
                call s:ExpandDir(fpath,line('.'))
                let b:expanded[fpath] = 1
            endif
            setlocal nomodifiable
            call s:ExpandCleanup()
        else
            " Open file
            call s:OpenFile(fpath,'edit')
        endif
    elseif line('.') == 2
        let fpath = s:GetFullPath(line('.'))
        let pos = getpos('.')
        call s:InitializeNewTree(fpath)
        call setpos('.',pos)
    endif
endfunction

function! s:SpacePressed()
    if line('.') > 2
        let fpath = s:GetFullPath(line('.'))
        let isdir = s:IsDir(getline('.'))
        if isdir
            call s:EnterPressed()
        else
            let dirline = s:GetDirLine(line('.'))
            if dirline != 1
                let pos = getpos('.')
                let pos[1] = dirline
                call setpos('.', pos)
                call s:EnterPressed()
            endif
        endif
    endif
endfunction

function! s:Expand(linen)
    if a:linen > 2
        let fpath = s:GetFullPath(a:linen)
        let isdir = s:IsDir(getline(a:linen))
        if isdir
            setlocal modifiable
            if !s:IsExpanded(getline(a:linen))
                call s:ExpandDir(fpath,a:linen)
                let b:expanded[fpath] = 1
            endif
            setlocal nomodifiable
        endif
    endif
endfunction

function! s:ExpandAll(linen)
    if a:linen > 2
        let lines = line('$')
        call s:Expand(a:linen)
        let lines = line('$') - lines
        if lines > 0
            let linesexpanded = -lines
            for i in range(1,lines)
                let linesexpanded += lines
                if s:IsDir(getline(a:linen+i+linesexpanded))
                    let lines = line('$')
                    call s:ExpandAll(a:linen+i+linesexpanded)
                    let lines = line('$') - lines
                else
                    let lines = 0
                endif
            endfor
        endif
    endif
endfunction

function! s:ExpandCleanup()
    redraw
    echo ''
    silent! unlet b:expandtime
endfunction

function! s:Unexpand(linen)
    if a:linen > 2
        let fpath = s:GetFullPath(a:linen)
        let isdir = s:IsDir(getline(a:linen))
        if isdir
            setlocal modifiable
            if s:IsExpanded(getline(a:linen))
                call s:UnexpandDir(fpath,a:linen)
                let b:expanded[fpath] = 0
            endif
            setlocal nomodifiable
        endif
    endif
endfunction

function! s:UnexpandAll(linen)
    if a:linen > 2
        let fpath = s:GetFullPath(a:linen).s:easytree_path_sep
        call s:Unexpand(a:linen)
        let b:expanded = filter(b:expanded,"!(v:key =~ '".fpath."')")
    endif
endfunction

function! s:Open(linen)
    let fpath = s:GetFullPath(a:linen)
    call s:OpenFile(fpath,'edit')
endfunction

function! s:TabOpen(linen)
    let fpath = s:GetFullPath(a:linen)
    call s:OpenFile(fpath,'tab')
endfunction

function! s:SplitOpen(linen)
    let fpath = s:GetFullPath(a:linen)
    call s:OpenFile(fpath,'sp')
endfunction

function! s:VerticlySplitOpen(linen)
    let fpath = s:GetFullPath(a:linen)
    call s:OpenFile(fpath,'vs')
endfunction

function! s:OpenFile(fpath,mode)
    call s:OpenEasyTreeFile(b:location,a:fpath,a:mode)
endfunction

function! s:UnexpandDir(fpath,linen)
    let linen = a:linen
    if g:easytree_use_plus_and_minus
        call setline(linen,substitute(getline(linen),'-','+',''))
    else
        call setline(linen,substitute(getline(linen),'▾','▸',''))
    endif
    let lvl = s:GetLvl(getline(linen))
    let linen += 1
    let linee = linen
    while s:GetLvl(getline(linee)) > lvl
        let linee += 1
    endwhile
    let linee -= 1
    if linee != linen
        let linee = (linen-1).':'.linee
    else
        let linee -= 1
    endif
    exe 'python vim.current.buffer['.linee.'] = None'
    call s:WidthAutoFit()
endfunction

function! s:ExpandDir(fpath,linen)
    if !exists('b:expandtime')
        let b:expandtime = reltime()
    else
        if str2float(reltimestr(reltime(b:expandtime))) >= 0.5
            redraw
            echo 'expanding '.a:fpath
            let b:expandtime = reltime()
        endif
    endif
    let linen = a:linen
    if g:easytree_use_plus_and_minus
        call setline(linen,substitute(getline(linen),'+','-',''))
    else
        call setline(linen,substitute(getline(linen),'▸','▾',''))
    endif
    let lvl = s:GetLvl(getline(linen))
    let lvls = repeat('  ',lvl)
    let treelist = pyeval("easytree.EasyTreeListDir(vim.eval('a:fpath'),".b:showhidden.")")
    let cascade = g:easytree_cascade_open_single_dir && len(treelist[1]) == 1 && len(treelist[2]) == 0
    for d in treelist[1]
        if g:easytree_use_plus_and_minus
            call append(linen,lvls.'+ '.d)
        else
            call append(linen,lvls.'▸ '.d)
        endif
        let linen += 1
        let fpath = s:GetFullPath(linen)
        if (has_key(b:expanded,fpath) && b:expanded[fpath]) || cascade
            let linen = s:ExpandDir(fpath,linen)
        endif
    endfor
    for f in treelist[2]
        call append(linen,lvls.'  '.f)
        let linen += 1
    endfor
    call s:WidthAutoFit()
    return linen
endfunction
" }}}

" easytree window functions {{{
function! s:InitializeTree(dir)
    setlocal modifiable
    let b:find = ''
    let b:findresult = []
    let treelist = pyeval("easytree.EasyTreeListDir(vim.eval('a:dir'),".b:showhidden.")")
    silent! normal! gg"_dG
    call setline(1, treelist[0])
    call append(1, '  .. (up a dir)')
    for d in treelist[1]
        if g:easytree_use_plus_and_minus
            call append(line('$'),'+ '.d)
        else
            call append(line('$'),'▸ '.d)
        endif
    endfor
    for f in treelist[2]
        call append(line('$'),'  '.f)
    endfor
    setlocal nomodifiable
    call s:WidthAutoFit()
endfunction

function! s:InitializeNewTree(dir)
    let dir = a:dir
    if dir != '/' && dir[len(dir)-1] == s:easytree_path_sep
        let dir = dir[:-2]
        if s:easytree_on_windows && dir[len(dir)-1] == ':'
            let dir = dir.s:easytree_path_sep
        endif
    endif
    setlocal modifiable
    normal! gg"_dG
    call setline(1,dir)
    setlocal nomodifiable
    let b:showhidden = g:easytree_show_hidden_files
    let b:ignore_files = g:easytree_ignore_files
    let b:ignore_dirs = g:easytree_ignore_dirs
    let b:ignore_find_result = g:easytree_ignore_find_result
    if !(g:easytree_auto_load_settings && s:LoadSetting(dir))
        let b:expanded = {}
    endif
    call s:RefreshAll()
endfunction

function! s:WidthAutoFit()
    if g:easytree_width_auto_fit
        let m = max(map(range(1,line('$')),"len(getline(v:val))"))+1
        if m > winwidth(0)
            exe 'vertical resize '.m
        endif
    endif
endfunction

function! s:OpenEasyTreeFile(location,fpath,mode)
    let fpath = fnameescape(a:fpath)
    let wincreated = 0
    if winnr('$') == 1
        if a:location == 'left'
            wincmd v
            exe 'vertical resize '.(&columns/6)
        elseif a:location == 'right'
            wincmd v
            wincmd l
            exe 'vertical resize '.(&columns/6)
        elseif a:location == 'top'
            wincmd s
            exe 'resize '.(&lines/3)
        elseif a:location == 'bottom'
            wincmd s
            wincmd j
            exe 'resize '.(&lines/3)
        endif
        let wincreated = 1
    endif
    if a:location == 'left'
        wincmd l
    elseif a:location == 'right'
        wincmd h
    elseif a:location == 'top'
        wincmd j
    elseif a:location == 'bottom'
        wincmd k
    endif
    if !empty(&buftype) && a:mode == 'edit' && a:location != 'here' && !wincreated
        " find windows with file buffer
        let wnrs = filter(range(1,winnr('$')),"empty(getbufvar(winbufnr(v:val),'&buftype'))")
        if len(wnrs) > 0
            let wnr = winnr()
            wincmd k
            if !(winnr() != wnr && index(wnrs,winnr()) != -1)
                exe wnr.'wincmd w'
                wincmd j
                if !(winnr() != wnr && index(wnrs,winnr()) != -1)
                    exe wnrs[0].'wincmd w'
                endif
            endif
        else
            wincmd s
        endif
    endif
    stopinsert
    if a:mode == 'edit'
        exe 'edit '.fpath
    elseif a:mode == 'tab'
        exe 'tabnew '.fpath
    elseif a:mode == 'sp'
        if a:location == 'here' || a:location == 'left' || a:location == 'right' || a:location == 'top'
            wincmd s
            exe 'edit '.fpath
        elseif a:location == 'bottom'
            wincmd s
            wincmd j
            exe 'edit '.fpath
        endif
    elseif a:mode == 'vs'
        if a:location == 'here' || a:location == 'left' || a:location == 'top' || a:location == 'bottom'
            wincmd v
            exe 'edit '.fpath
        elseif a:location == 'right'
            wincmd v
            wincmd l
            exe 'edit '.fpath
        endif
    endif
endfunction

function! s:GetNewEasyTreeWindowId()
    let id = 1
    for t in filter(range(1,bufnr('$')),"getbufvar(v:val,'&filetype') == 'easytree'")
        if getbufvar(t,'treeid') >= id
            let id = getbufvar(t,'treeid')+1
        endif
    endfor
    return id
endfunction

function! s:GetInfo(linen)
    let fpath = s:GetFullPath(a:linen)
    let info = pyeval('easytree.EasyTreeGetInfo()')
    echo 'name: '.info[0].'  owner: '.info[1].(info[2] == '' ? '' : ':'.info[2]).'  size: '.info[3].'  mode: '.info[4].'  last modified: '.info[5]
    if pyeval('easytree.easytree_dirsize_calculator != None')
        while 1
            sleep 1
            let info[3] = pyeval("easytree.EasyTreeGetSize(easytree.easytree_dirsize_calculator_curr_size)+(('.'*random.randint(1,3)).ljust(3))")
            redraw
            echo 'name: '.info[0].'  owner: '.info[1].(info[2] == '' ? '' : ':'.info[2]).'  size: '.info[3].'  mode: '.info[4].'  last modified: '.info[5]
            if !pyeval('easytree.easytree_dirsize_calculator.isAlive()')
                let info[3] = pyeval("easytree.EasyTreeGetSize(easytree.easytree_dirsize_calculator_curr_size)")
                python easytree.easytree_dirsize_calculator = None
                break
            endif
        endwhile
    endif
    redraw
    echo 'name: '.info[0].'  owner: '.info[1].(info[2] == '' ? '' : ':'.info[2]).'  size: '.info[3].'  mode: '.info[4].'  last modified: '.info[5]
endfunction

function! s:OpenEasyTreeWindow(location)
    let prevbufnr = bufnr('%')
    let treeid = s:GetNewEasyTreeWindowId()
    let treename = fnameescape('easytree - '.treeid)
    let location = a:location
    if a:location == 'left'
        exe 'topleft '.(&columns/6).'vs '.treename
    elseif a:location == 'right'
        exe 'botright '.(&columns/6).'vs '.treename
    elseif a:location == 'top'
        exe 'topleft '.(&lines/3).'sp '.treename
    elseif a:location == 'bottom'
        exe 'botright '.(&lines/3).'sp '.treename
    elseif match(a:location,'edit') == 0
        let m = matchlist(a:location,'^edit \(.*\)')
        exe 'edit '.treename
        let location = m[1]
    endif
    let b:treeid = treeid
    let b:location = location
    let b:prevbufnr = prevbufnr
endfunction

function! s:CloseEasyTreeWindow()
    if b:location == 'here'
        exe ':b'.b:prevbufnr
    else
        bd!
    endif
endfunction

function! s:DestroyEasyTreeWindow()
    if g:easytree_auto_save_settings
        call s:SaveSetting()
    endif
endfunction
" }}}

" load/save settings functions {{{
function! s:MakeDirectory(path)
    if !isdirectory(a:path)
        call mkdir(a:path,'p')
    endif
endfunction

function! s:GetSettingFilePath(dir)
    return expand(substitute(g:easytree_settings_file, '<dir>', a:dir, ''))
endfunction

function! s:SaveSetting()
    let sf = s:GetSettingFilePath(s:GetFullPath(1))
    call s:MakeDirectory(fnamemodify(sf,':h'))
    call writefile(["let b:ignore_files = ".string(b:ignore_files),
                \ "let b:ignore_dirs = ".string(b:ignore_dirs),
                \ "let b:ignore_find_result = ".string(b:ignore_find_result),
                \ "let b:showhidden = ".b:showhidden,
                \ "let b:expanded = ".string(b:expanded)],
                \ sf)
endfunction

function! s:LoadSetting(dir)
    let sf = s:GetSettingFilePath(a:dir)
    if filereadable(sf)
        for c in readfile(sf)
            exe c
        endfor
        return 1
    endif
    return 0
endfunction

function! s:LoadGlobalTreeSetting()
    if s:AskConfirmation('are you sure you want to load global settings?')
        let b:showhidden = g:easytree_show_hidden_files
        let b:ignore_files = g:easytree_ignore_files
        let b:ignore_dirs = g:easytree_ignore_dirs
        let b:ignore_find_result = g:easytree_ignore_find_result
        let b:expanded = {}
        call s:RefreshAll()
    endif
endfunction

function! s:LoadTreeSetting()
    if s:AskConfirmation('are you sure you want to load settings?')
        if s:LoadSetting(getline(1))
            call s:RefreshAll()
        else
            echo 'no settings file'
        endif
    endif
endfunction

function! s:SaveTreeSetting()
    if s:AskConfirmation('are you sure you want to save settings?')
        call s:SaveSetting()
        echo 'settings file saved'
    endif
endfunction
" }}}

" global functions {{{
function! easytree#ToggleTree(win, dir)
    if a:win == 'edit here'
        if &filetype == 'easytree'
            edit #
        else
            call easytree#OpenTree(a:win, a:dir)
        endif
    else
        let win = a:win
        if win =~ 'double'
            let win = split(win, ' ')[0]
        endif
        let bnrlist = filter(range(1,bufnr("$")), "bufexists(v:val) && getbufvar(v:val,'&filetype') == 'easytree' && getbufvar(v:val,'location') == '".win."'")
        if len(bnrlist) == 0
            call easytree#OpenTree(a:win, a:dir)
        else
            let wn = winnr()
            for bnr in bnrlist
                exe bufwinnr(bnr).'wincmd w'
                wincmd q
            endfor
            silent! exe wn.'wincmd w'
        endif
    endif
endfunction

function! easytree#OpenTree(win, dir)
    if a:win == 'top double' || a:win == 'bottom double'
        let win = split(a:win, ' ')[0]
        call easytree#OpenTree(win,a:dir) 
        wincmd v 
        wincmd l
        call easytree#OpenTree('edit '.win,a:dir) 
        wincmd h
        return
    endif
    let dir = a:dir
    if empty(dir)
        let dir = getcwd()
    endif
    let dir = pyeval("os.path.expanduser(vim.eval('dir'))")
    if !pyeval("os.path.isdir(vim.eval('dir'))")
        echo 'invalid path '.dir
        return
    endif
    call s:OpenEasyTreeWindow(a:win)
    setlocal filetype=easytree buftype=nofile bufhidden=wipe nolist nobuflisted noswapfile nowrap nonumber
    if exists('+relativenumber')
        setlocal norelativenumber
    endif
    if a:win !~ "edit here"
        setlocal winfixwidth
    endif
    if g:easytree_show_line_numbers
        setlocal number
    endif
    if g:easytree_show_relative_line_numbers
        setlocal relativenumber
    endif
    if g:easytree_highlight_cursor_line
        setlocal cursorline
    endif
    au BufWipeout <buffer> silent! call <SID>DestroyEasyTreeWindow()
    nnoremap <silent> <buffer> <C-g> :<C-U>call <SID>PrintFilePath()<CR>
    nnoremap <silent> <buffer> <Enter> :call <SID>EnterPressed()<CR>
    nnoremap <silent> <buffer> <Space> :call <SID>SpacePressed()<CR>
    nnoremap <silent> <buffer> e :call <SID>Open(line('.'))<CR>
    if g:easytree_enable_vs_and_sp_mappings
        nnoremap <silent> <buffer> vs :call <SID>VerticlySplitOpen(line('.'))<CR>
        nnoremap <silent> <buffer> sp :call <SID>SplitOpen(line('.'))<CR>
    else
        nnoremap <silent> <buffer> v :call <SID>VerticlySplitOpen(line('.'))<CR>
        nnoremap <silent> <buffer> s :call <SID>SplitOpen(line('.'))<CR>
    endif
    nnoremap <silent> <buffer> t :call <SID>TabOpen(line('.'))<CR>
    nnoremap <silent> <buffer> q :call <SID>CloseEasyTreeWindow()<CR>
    nnoremap <silent> <buffer> o :call <SID>Expand(line('.')) \| call <SID>ExpandCleanup()<CR>
    nnoremap <silent> <buffer> O :call <SID>ExpandAll(line('.')) \| call <SID>ExpandCleanup()<CR>
    nnoremap <silent> <buffer> x :call <SID>Unexpand(line('.'))<CR>
    nnoremap <silent> <buffer> X :call <SID>UnexpandAll(line('.'))<CR>
    nnoremap <silent> <buffer> f :call <SID>Find(line('.'),'')<CR>
    nnoremap <silent> <buffer> zf :call <SID>EditIgnoreFiles()<CR>
    nnoremap <silent> <buffer> zd :call <SID>EditIgnoreDirs()<CR>
    nnoremap <silent> <buffer> zs :call <SID>EditIgnoreFindResult()<CR>
    nnoremap <silent> <buffer> F :call <SID>Find(line('.'),b:find)<CR>
    nnoremap <silent> <buffer> n :call <SID>FindNext()<CR>
    nnoremap <silent> <buffer> N :call <SID>FindBackward()<CR>
    nnoremap <silent> <buffer> u :call <SID>GoUpTree()<CR>
    nnoremap <silent> <buffer> C :call <SID>ChangeDir(line('.'))<CR>
    nnoremap <silent> <buffer> c :call <SID>RenameFile(line('.'))<CR>
    nnoremap <silent> <buffer> cd :call <SID>ChangeCwdDir(line('.'))<CR>
    nnoremap <silent> <buffer> <m-p> :call <SID>MoveFiles(line('.'))<CR>
    nnoremap <silent> <buffer> <esc>p :call <SID>MoveFiles(line('.'))<CR>
    nnoremap <silent> <buffer> a :call <SID>CreateFile(line('.'))<CR>
    nnoremap <silent> <buffer> m :call <SID>CreateFile(line('.'))<CR>
    nnoremap <silent> <buffer> r :call <SID>Refresh(line('.'))<CR>
    nnoremap <silent> <buffer> R :call <SID>RefreshAll()<CR>
    nnoremap <silent> <buffer> i :try \| call <SID>GetInfo(line('.')) \| finally \| exe 'py easytree.easytree_dirsize_calculator=None' \| endtry<CR>
    nnoremap <silent> <buffer> I :call <SID>ToggleHidden()<CR>
    nnoremap <silent> <buffer> H :call <SID>ChangeDirTo(expand('~'))<CR>
    nnoremap <silent> <buffer> J :call <SID>ChangeDirTo()<CR>
    nnoremap <silent> <buffer> K :call <SID>SaveTreeSetting()<CR>
    nnoremap <silent> <buffer> L :call <SID>LoadTreeSetting()<CR>
    nnoremap <silent> <buffer> gL :call <SID>LoadGlobalTreeSetting()<CR>
    nnoremap <silent> <buffer> y :call <SID>CopyFile(line('.'))<CR>
    nnoremap <silent> <buffer> yy :call <SID>CopyFile(line('.'))<CR>
    vnoremap <silent> <buffer> y :call <SID>CopyFilesRange()<CR>
    nnoremap <silent> <buffer> p :call <SID>PasteFiles(line('.'))<CR>
    nnoremap <silent> <buffer> P :call <SID>EchoPasteBuffer()<CR>
    nnoremap <silent> <buffer> dd :call <SID>RemoveFile(line('.'))<CR>
    vnoremap <silent> <buffer> d :call <SID>RemoveFiles()<CR>
    call s:InitializeNewTree(dir)
endfunction
" }}}
" }}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: set sw=4 sts=4 et fdm=marker:
