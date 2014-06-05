# easytree.vim - simple tree file manager for vim
# Maintainer: Dmitry "troydm" Geurkov <d.geurkov@gmail.com>
# Version: 0.2.1
# Description: easytree.vim is a simple tree file manager
# Last Change: 3 June, 2014
# License: Vim License (see :help license)
# Website: https://github.com/troydm/easytree.vim

import vim,random,os,time,stat,sys,shutil,fnmatch,threading

easytree_on_windows = os.name == 'nt'

if not easytree_on_windows:
    import grp,pwd

easytree_dirsize_calculator = None
easytree_dirsize_calculator_cur_size = 0

def EasyTreeFnmatchList(f,patterns):
    for p in patterns:
        if fnmatch.fnmatch(f,p):
            return True
    return False

def EasyTreeFind(pattern,dir,showhidden):
    if not ('*' in pattern or '?' in pattern or '[' in pattern):
        pattern = '*'+pattern+'*'
    ignore_find_result = vim.eval('b:ignore_find_result')
    filelist = EasyTreeList(dir,showhidden, lambda f: fnmatch.fnmatch(f,pattern))
    filelist = filter(lambda f: not EasyTreeFnmatchList(f,ignore_find_result), filelist)
    return filelist

def EasyTreeList(dir,showhidden,findfilter):
    dir = os.path.expanduser(dir)
    ignore_dirs = vim.eval('b:ignore_dirs')
    ignore_files = vim.eval('b:ignore_files')
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
    ignore_dirs = vim.eval('b:ignore_dirs')
    ignore_files = vim.eval('b:ignore_files')
    for root, dirs, files in os.walk(dir):
        if int(showhidden) == 0:
            dirs = filter(lambda d: not d.startswith("."),dirs)
            files = filter(lambda f: not f.startswith("."),files)
        dirs = filter(lambda d: not EasyTreeFnmatchList(d,ignore_dirs), dirs)
        files = filter(lambda f: not EasyTreeFnmatchList(f,ignore_files), files)
        dirs = sorted(dirs)
        files = sorted(files)
        return [root, dirs, files]
    return [dir,[],[]]

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

def EasyTreeCopyFile(src, dst, overwrite):
    if os.path.isdir(src):
        if overwrite:
            vim.command("echom 'overwriting directory: "+dst+"'")
            shutil.rmtree(dst)
        EasyTreeCopyFileTree(src,dst)
    else:
        shutil.copyfile(src,dst)

def EasyTreeCopyFileTree(src, dst):
    rdirs = [dst]
    rfiles = []
    for root, dirs, files in os.walk(src):
        rdirs.extend(map(lambda d: dst+root[len(src):]+os.path.sep+d, dirs))
        rfiles.extend(map(lambda f: (root+os.path.sep+f,dst+root[len(src):]+os.path.sep+f), files))
    map(os.makedirs,rdirs)
    map(lambda (s,d): shutil.copyfile(s,d),rfiles)

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
            copy = False
            overwrite = False
            if not os.path.exists(dst):
                copy = True
            else:
                vim.command("echom '"+dst+" already exists'")
                if int(vim.eval("<SID>AskConfirmationNoRedraw('would you like to overwrite it?')")) == 1:
                    copy = True
                    overwrite = True
                elif int(vim.eval("<SID>AskConfirmationNoRedraw('would you like to paste it as another file?')")) == 1:
                    while True:
                        newbase = vim.eval("<SID>AskInputNoRedraw('"+dpath+"','"+base+"')")
                        if newbase == None or len(newbase) == 0:
                            break
                        elif not os.path.exists(dpath+newbase):
                            copy = True
                            dst = dpath+newbase
                            vim.command("echom 'saving file as "+dst+"'")
                            break
            if copy:
                if f != dst:
                    try:
                        EasyTreeCopyFile(f,dst,overwrite)
                        i += 1
                    except OSError, e:
                        print str(repr(e))
                else:
                    vim.command("echom 'can''t copy from same source to same destination'")
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

def EasyTreeGetSize(size):
    if size >= 1073741824:
        size = str(size/1073741824.0)
        if size.find('.') != -1:
            size = size[:size.index('.')+2]
        return size + ' Gb'
    elif size >= 1048576:
        size = str(size/1048576.0) 
        if size.find('.') != -1:
            size = size[:size.index('.')+2]
        return size + ' Mb'
    elif size >= 1024:
        size = str(size/1024.0) 
        if size.find('.') != -1:
            size = size[:size.index('.')+2]
        return size + ' Kb'
    else:
        return str(size) + ' bytes'
    
def EasyTreeGetMode(m):
    mode = ''
    modes = 'drwxrwxrwx'
    fs = [stat.S_IFDIR, stat.S_IRUSR, stat.S_IWUSR, stat.S_IXUSR, stat.S_IRGRP, stat.S_IWGRP, stat.S_IXGRP, stat.S_IROTH, stat.S_IWOTH, stat.S_IXOTH]
    i = 0
    for f in fs:
        if f & m:
            mode += modes[i]
        else:
            mode += '-'
        i += 1
    return mode

def EasyTreeGetDirSize(dir):
    global easytree_dirsize_calculator, easytree_dirsize_calculator_curr_size
    total = os.path.getsize(dir)
    easytree_dirsize_calculator_curr_size = total
    for dirpath, dirnames, filenames in os.walk(dir):
        if easytree_dirsize_calculator == None:
            return
        for d in dirnames:
            dp = os.path.join(dirpath, d)
            try:
                total += os.path.getsize(dp)
            except:
                pass
        for f in filenames:
            fp = os.path.join(dirpath, f)
            try:
                total += os.path.getsize(fp)
            except:
                pass
        easytree_dirsize_calculator_curr_size = total
    easytree_dirsize_calculator_curr_size = total
    return total

def EasyTreeGetInfo():
    global easytree_dirsize_calculator, easytree_on_windows
    path = vim.eval('fpath')
    if os.path.exists(path):
        st = os.stat(path)
        name = os.path.basename(path)
        if easytree_on_windows:
            p = os.popen('dir /q /a "'+path+'"')
            user = p.read().split("\n")[5]
            p.close()
            if '>' in user:
                user = user[user.index('>')+1:]
                if user[-1] == '.':
                    user = user[:-1]
                user = user.strip()
            elif 'AM' in user:
                user = user[user.index('AM')+2:]
                user = user.strip().lstrip("0123456789,.").strip()
            elif 'PM' in user:
                user = user[user.index('PM')+2:]
                user = user.strip().lstrip("0123456789,.").strip()
            if name in user:
                user = user[:user.rindex(name)]
            user = user.strip()
            group = ''
        else:
            user = pwd.getpwuid(st.st_uid).pw_name
            group = grp.getgrgid(st.st_gid).gr_name
        if stat.S_ISDIR(st.st_mode):
            size = 0
            if easytree_dirsize_calculator != None:
                t = easytree_dirsize_calculator
                easytree_dirsize_calculator = None
                t.join()
            easytree_dirsize_calculator = threading.Thread(target=EasyTreeGetDirSize, args=(path,))
            easytree_dirsize_calculator.setDaemon(True)
            easytree_dirsize_calculator.start()
        else:
            size = st.st_size
        return [name,user,group,EasyTreeGetSize(size), EasyTreeGetMode(st.st_mode), time.ctime(st.st_mtime)]

