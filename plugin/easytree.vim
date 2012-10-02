" easytree.vim - simple tree file manager for vim
" Maintainer: Dmitry "troydm" Geurkov <d.geurkov@gmail.com>
" Version: 0.1
" Description: easytree.vim is a siple tree file manager
" Last Change: 1 October, 2012
" License: Vim License (see :help license)
" Website: https://github.com/troydm/easytree.vim
"
" See easytree.vim for help.  This can be accessed by doing:
" :help easytree

let s:save_cpo = &cpo
set cpo&vim

if !has("python")
    echo "easytree needs vim compiled with +python option"
    finish
endif

if !exists('*pyeval')
    echo "easytree needs vim 7.3 with atleast 569 patchset included"
    finish
endif

if !exists("g:easytree_cascade_open_single_dir")
    let g:easytree_cascade_open_single_dir = 1
endif

if !exists("g:easytree_show_line_numbers")
    let g:easytree_show_line_numbers = 0
endif

if !exists("g:easytree_show_hidden_files")
    let g:easytree_show_hidden_files = 0
endif

if !exists("g:easytree_highlight_cursor_line")
    let g:easytree_highlight_cursor_line = 1
endif

if !exists("g:easytree_ignore_dirs")
    let g:easytree_ignore_dirs = ['*.AppleDouble*','*.DS_Store*']
endif

if !exists("g:easytree_ignore_files")
    let g:easytree_ignore_files = ['*.swp']
endif

if !exists("g:easytree_ignore_find_result")
    let g:easytree_ignore_find_result = []
endif

if !exists("g:easytree_hijack_netrw")
    let g:easytree_hijack_netrw = 1
endif

python << END

import os,sys,shutil,fnmatch

def EasyTreeFnmatchList(f,patterns):
    for p in patterns:
        if fnmatch.fnmatch(f,p):
            return True
    return False

def EasyTreeFind(pattern,dir,showhidden):
    if not ('*' in pattern or '?' in pattern or '[' in pattern):
        pattern = '*'+pattern+'*'
    ignore_find_result = vim.eval('g:easytree_ignore_find_result')
    filelist = EasyTreeList(dir,showhidden, lambda f: fnmatch.fnmatch(f,pattern))
    filelist = filter(lambda f: not EasyTreeFnmatchList(f,ignore_find_result), filelist)
    return filelist

def EasyTreeList(dir,showhidden,findfilter):
    dir = os.path.expanduser(dir)
    ignore_dirs = vim.eval('g:easytree_ignore_dirs')
    ignore_files = vim.eval('g:easytree_ignore_files')
    filelist = []
    showhidden = int(showhidden) == 1
    for root, dirs, files in os.walk(dir):
        root = root.replace(dir,'')
        if root.startswith(os.sep):
            root = root[1:]
        if not showhidden:
            if root.startswith('.') or os.sep+'.' in root:
                continue
            dirs = filter(lambda d: not d.startswith("."),dirs)
            files = filter(lambda f: not f.startswith("."),files)
        if len(root) > 0:
            if EasyTreeFnmatchList(root,ignore_dirs):
                continue
            dirs = map(lambda d: root+os.sep+d,dirs)
            files = map(lambda f: root+os.sep+f,files)
        dirs = filter(findfilter, dirs)
        files = filter(findfilter, files)
        dirs = filter(lambda d: not EasyTreeFnmatchList(d,ignore_dirs), dirs)
        files = filter(lambda f: not EasyTreeFnmatchList(f,ignore_files), files)
        dirs = sorted(dirs)
        files = sorted(files)
        filelist.extend(dirs)
        filelist.extend(files)
    return filelist

def EasyTreeListDir(dir,showhidden):
    dir = os.path.expanduser(dir)
    ignore_dirs = vim.eval('g:easytree_ignore_dirs')
    ignore_files = vim.eval('g:easytree_ignore_files')
    for root, dirs, files in os.walk(dir):
        if int(showhidden) == 0:
            dirs = filter(lambda d: not d.startswith("."),dirs)
            files = filter(lambda f: not f.startswith("."),files)
        dirs = filter(lambda d: not EasyTreeFnmatchList(d,ignore_dirs), dirs)
        files = filter(lambda f: not EasyTreeFnmatchList(f,ignore_files), files)
        dirs = sorted(dirs)
        files = sorted(files)
        return [root, dirs, files]

def EasyTreeCreateFile():
    path = vim.eval('path')
    if path.endswith(os.sep):
        if not os.path.exists(path):
            os.makedirs(path)
        else:
            vim.command("redraw | echom 'directory "+path+" already exists'")
    else:
        dpath = os.path.dirname(path)
        if not os.path.exists(dpath):
            os.makedirs(dpath)
        if os.path.isdir(dpath):
            if not os.path.exists(path):
                open(path,'w').close()
            else:
                vim.command("redraw | echom 'file "+path+" already exists'")

def EasyTreeRenameFile():
    dpath = vim.eval('dpath')
    fname = vim.eval('fname')
    fnameto = vim.eval('fnameto')
    if os.path.exists(dpath+fname):
        if not os.path.exists(dpath+fnameto):
            os.rename(dpath+fname,dpath+fnameto)
        else:
            vim.command("redraw | echom 'file "+(dpath+fnameto)+" already exists'")
    else:
        vim.command("redraw | echom 'file "+(dpath+fname)+" doesn't exists'")

def EasyTreeCopyFiles():
    dpath = vim.eval('fpath')+os.sep
    files = vim.eval('files')
    i = 0
    if len(files) == 1:
        vim.command("redraw | echom 'copying 1 file, please wait...'")
    else:
        vim.command("redraw | echom 'copying "+str(len(files))+" files, please wait...'")
    for f in files:
        base = os.path.basename(f)
        dst = dpath+base
        if os.path.exists(f):
            if not os.path.exists(dst):
                try:
                    if os.path.isdir(f):
                        shutil.copytree(f,dst)
                    else:
                        shutil.copyfile(f,dst)
                    i += 1
                except OSError, e:
                    print str(repr(e))
            else:
                vim.command("echom '"+dst+" already exists'")
        else:
            vim.command("echom '"+f+" doesn't exists'")
    if i == 1:
        vim.command("echom '1 file copied'")
    else:
        vim.command("echom '"+str(i)+" files copied'")

def EasyTreeRemoveFiles():
    files = vim.eval('files')
    i = 0
    messages = []
    if len(files) == 1:
        messages.append("deleting 1 file, please wait...")
    else:
        messages.append("deleting "+str(len(files))+" files, please wait...")
    for f in files:
        if os.path.exists(f):
            try:
                if os.path.isdir(f):
                    shutil.rmtree(f)
                else:
                    os.remove(f)
                i += 1
            except OSError, e:
                messages.append(str(repr(e)))
        else:
            messages.append(f+" doesn't exists")
    if i == 1:
        messages.append("1 file deleted")
    else:
        messages.append(str(i)+" files deleted")
    return messages

END

function! s:AskInput(message,val)
    let r = input(a:message,a:val)
    redraw
    echo ''
    return r
endfunction

function! s:AskInputComplete(message,val,complete)
    let r = input(a:message,a:val,a:complete)
    redraw
    echo ''
    return r
endfunction

function! s:AskConfirmation(message)
    let r = input(a:message.' (y/n) ')
    redraw
    echo ''
    return r == 'y' || r == 'yes'
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

function! s:ChangeDir(linen)
    let fpath = s:GetFullPathDir(a:linen)
    call s:InitializeTree(fpath)
    normal! 3G0
endfunction

function! s:ChangeDirTo()
    let path = s:AskInputComplete('go to ',getline(1),'dir')
    if !empty(path) 
        if pyeval("os.path.isdir(os.path.expanduser(vim.eval('path')))")
            call s:InitializeTree(path)
        else
            redraw
            echo 'invalid path '.path
        endif
    endif
endfunction

function! s:ChangeCwdDir(linen)
    let fpath = s:GetFullPathDir(a:linen)
    exe 'cd '.fpath
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

function! s:EchoPasteBuffer()
    for f in split(getreg(v:register),"\n")
        echo f
    endfor
endfunction

function! s:PasteFiles(linen)
    let fpath = s:GetFullPathDir(a:linen)
    let files = split(getreg(v:register),"\n")
    if len(files) > 0
        let filesm = '1 file'
        if len(files) > 1
            let filesm = len(files).' files'
        endif
        call s:EchoPasteBuffer()
        if s:AskConfirmation('are you sure you want to paste '.filesm.'?')
            python EasyTreeCopyFiles()
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
            let messages = pyeval('EasyTreeRemoveFiles()')
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
            let messages = pyeval('EasyTreeRemoveFiles()')
            call s:RefreshAll()
        endif
    endif
    for m in messages
        echom m
    endfor
endfunction

function! s:CreateFile(linen)
    let fpath = s:GetFullPathDir(a:linen).'/'
    let path = s:AskInput('create '.fpath,'')
    if !empty(path)
        let path = fpath.path
        python EasyTreeCreateFile()
        call s:Refresh(a:linen)
    endif
endfunction

function! s:RenameFile(linen)
    let fpath = s:GetFullPath(a:linen)
    let dpath = s:DirName(fpath).'/'
    let fname = s:FileName(fpath)
    let fnameto = s:AskInput('rename '.dpath,fname)
    if !empty(fnameto)
        if !s:DeleteBuf(fpath)
            return
        endif
        python EasyTreeRenameFile()
        call s:Refresh(s:GetParentLvlLinen(a:linen))
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

function! s:RefreshAll()
    let toexpand = {}
    for linen in range(3,line('$')) 
        let line = getline(linen)
        if s:GetLvl(line) == 1 && s:IsDir(line) && s:IsExpanded(line)
            let toexpand[s:GetFullPath(linen)] = 1
        endif
    endfor
    let expanded = b:expanded
    let line = getline(1)
    let pos = getpos('.')
    call s:InitializeTree(line)
    let b:expanded = expanded
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

function! s:Find(find)
    let find = s:AskInputComplete('find ',a:find,'file')
    if !empty(find)
        let fpath = getline(1)
        let b:find = find
        echo 'searching for '.find
        exe "let b:findresult = pyeval(\"EasyTreeFind(vim.eval('find'),vim.eval('fpath'),".b:showhidden.")\")"
        redraw
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
        let findf = getline(1).'/'.find
        let findp = split(find,'/')
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
                    let findlvlf = getline(1).'/'.join(findp[:(lvl-1)],'/')
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
        else
            " Open file
            call s:OpenFile(fpath,'edit')
        endif
    elseif line('.') == 2
        let fpath = s:GetFullPath(line('.'))
        let pos = getpos('.')
        call s:InitializeTree(fpath)
        call setpos('.',pos)
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
                let lines = line('$')
                call s:ExpandAll(a:linen+i+linesexpanded)
                let lines = line('$') - lines
            endfor
        endif
    endif
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
        let fpath = s:GetFullPath(a:linen).'/'
        call s:Unexpand(a:linen)
        let b:expanded = filter(b:expanded,"!(v:key =~ '".fpath."')")
    endif
endfunction

function! s:Open(linen)
    let fpath = s:GetFullPath(a:linen)
    call s:OpenFile(fpath,'edit')
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

function! s:OpenDirHere(dir)
    if isdirectory(a:dir)
        call s:OpenTree('edit here',a:dir) 
    endif
endfunction

function! s:UnexpandDir(fpath,linen)
    let linen = a:linen
    call setline(linen,substitute(getline(linen),'▾','▸',''))
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
endfunction

function! s:ExpandDir(fpath,linen)
    let linen = a:linen
    call setline(linen,substitute(getline(linen),'▸','▾',''))
    let lvl = s:GetLvl(getline(linen))
    let lvls = repeat('  ',lvl) 
    exe "let treelist = pyeval(\"EasyTreeListDir(vim.eval('a:fpath'),".b:showhidden.")\")"
    for d in treelist[1]
        call append(linen,lvls.'▸ '.d)
        let linen += 1
        let fpath = s:GetFullPath(linen)
        if has_key(b:expanded,fpath) && b:expanded[fpath]
            let linen = s:ExpandDir(fpath,linen)
        endif
    endfor
    if g:easytree_cascade_open_single_dir && len(treelist[1]) == 1 && len(treelist[2]) == 0
        let fpath = s:GetFullPath(linen)
        let linen = s:ExpandDir(fpath,linen)
    endif
    for f in treelist[2]
        call append(linen,lvls.'  '.f)
        let linen += 1
    endfor
    return linen
endfunction

function! s:IsDir(line)
    return !empty(matchlist(a:line,'^\s*[▸▾] \(.*\)$'))
endfunction

function! s:IsExpanded(line)
    return !empty(matchlist(a:line,'^\s*▾ \(.*\)$'))
endfunction

function! s:GetFName(line)
    return matchlist(a:line,'^[▸▾ ]\+\(.*\)$')[1]
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

function! s:GetLvl(line)
    let lvl = 0
    let lvls = '[▸▾ ] '
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
            let dirp = pyeval("os.path.abspath(vim.eval('dirp')+'/..')")
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
        let fname = '/'.s:GetFName(getline(lvln)).fname
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
        return dirp.fname
    endif
endfunction

function! s:InitializeTree(dir)
    setlocal modifiable
    let b:expanded = {}
    let b:find = ''
    let b:findresult = []
    exe "let treelist = pyeval(\"EasyTreeListDir(vim.eval('a:dir'),".b:showhidden.")\")"
    silent! normal! ggdGG
    call setline(1, treelist[0])
    call append(1, '  .. (up a dir)')
    for d in treelist[1]
        call append(line('$'),'▸ '.d)
    endfor
    for f in treelist[2]
        call append(line('$'),'  '.f)
    endfor
    setlocal nomodifiable
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
        wincmd s
        stopinsert
    endif
    if a:mode == 'edit'
        exe a:mode.' '.fpath
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

function! s:OpenEasyTreeWindow(location)
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
endfunction

function! s:OpenTree(win, dir)
    let dir = a:dir
    if empty(dir)
        let dir = getcwd()
    endif
    if !pyeval("os.path.isdir(os.path.expanduser(vim.eval('dir')))")
        echo 'invalid path '.dir
        return
    endif
    call s:OpenEasyTreeWindow(a:win)
    setlocal filetype=easytree buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap nonumber 
    if g:easytree_show_line_numbers
        setlocal number
    endif
    if g:easytree_highlight_cursor_line
        setlocal cursorline
    endif
    let b:showhidden = g:easytree_show_hidden_files 
    nnoremap <silent> <buffer> <Enter> :call <SID>EnterPressed()<CR>
    nnoremap <silent> <buffer> e :call <SID>Open(line('.'))<CR>
    nnoremap <silent> <buffer> vs :call <SID>VerticlySplitOpen(line('.'))<CR>
    nnoremap <silent> <buffer> sp :call <SID>SplitOpen(line('.'))<CR>
    nnoremap <silent> <buffer> q :bd!<CR>
    nnoremap <silent> <buffer> o :call <SID>Expand(line('.'))<CR>
    nnoremap <silent> <buffer> O :call <SID>ExpandAll(line('.'))<CR>
    nnoremap <silent> <buffer> x :call <SID>Unexpand(line('.'))<CR>
    nnoremap <silent> <buffer> X :call <SID>UnexpandAll(line('.'))<CR>
    nnoremap <silent> <buffer> f :call <SID>Find('')<CR>
    nnoremap <silent> <buffer> F :call <SID>Find(b:find)<CR>
    nnoremap <silent> <buffer> n :call <SID>FindNext()<CR>
    nnoremap <silent> <buffer> N :call <SID>FindBackward()<CR>
    nnoremap <silent> <buffer> u :call <SID>GoUpTree()<CR>
    nnoremap <silent> <buffer> C :call <SID>ChangeDir(line('.'))<CR>
    nnoremap <silent> <buffer> c :call <SID>RenameFile(line('.'))<CR>
    nnoremap <silent> <buffer> cd :call <SID>ChangeCwdDir(line('.'))<CR>
    nnoremap <silent> <buffer> m :call <SID>CreateFile(line('.'))<CR>
    nnoremap <silent> <buffer> r :call <SID>Refresh(line('.'))<CR>
    nnoremap <silent> <buffer> R :call <SID>RefreshAll()<CR>
    nnoremap <silent> <buffer> I :call <SID>ToggleHidden()<CR>
    nnoremap <silent> <buffer> J :call <SID>ChangeDirTo()<CR>
    nnoremap <silent> <buffer> y :call <SID>CopyFile(line('.'))<CR>
    nnoremap <silent> <buffer> yy :call <SID>CopyFile(line('.'))<CR>
    vnoremap <silent> <buffer> y :call <SID>CopyFilesRange()<CR>
    nnoremap <silent> <buffer> p :call <SID>PasteFiles(line('.'))<CR>
    nnoremap <silent> <buffer> P :call <SID>EchoPasteBuffer()<CR>
    nnoremap <silent> <buffer> dd :call <SID>RemoveFile(line('.'))<CR>
    vnoremap <silent> <buffer> d :call <SID>RemoveFiles()<CR>
    nnoremap <silent> <buffer> ? :help EasyTree<CR>
    call s:InitializeTree(dir)
endfunction

function! s:DisableFileExplorer()
    au! FileExplorer
endfunction

augroup EasyTree
    autocmd VimEnter * if g:easytree_hijack_netrw | call <SID>DisableFileExplorer() | endif
    autocmd BufEnter * if g:easytree_hijack_netrw | call <SID>OpenDirHere(expand('<amatch>')) | endif
augroup end

command! -nargs=? -complete=dir EasyTree :EasyTreeLeft <args>
command! -nargs=? -complete=dir EasyTreeHere call <SID>OpenTree('edit here',<q-args>)
command! -nargs=? -complete=dir EasyTreeLeft call <SID>OpenTree('left',<q-args>)
command! -nargs=? -complete=dir EasyTreeRight call <SID>OpenTree('right',<q-args>)
command! -nargs=? -complete=dir EasyTreeTop call <SID>OpenTree('top',<q-args>)
command! -nargs=? -complete=dir EasyTreeBottom call <SID>OpenTree('bottom',<q-args>)
command! -nargs=? -complete=dir EasyTreeTopDouble call <SID>OpenTree('top',<q-args>) | wincmd v | wincmd l | call <SID>OpenTree('edit top',<q-args>) | wincmd h
command! -nargs=? -complete=dir EasyTreeBottomDouble call <SID>OpenTree('bottom',<q-args>) | wincmd v | wincmd l | call <SID>OpenTree('edit bottom',<q-args>) | wincmd h

let &cpo = s:save_cpo
unlet s:save_cpo
