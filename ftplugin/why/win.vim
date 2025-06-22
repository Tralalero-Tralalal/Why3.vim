
let s:python_dir = expand('<sfile>:p:h:h:h') . '/python'

function! s:Compat(python_dir) abort
  py3 import vim
  py3 if not vim.eval('a:python_dir') in sys.path:
    \    sys.path.insert(0, vim.eval('a:python_dir'))
endfunction

call s:Compat(s:python_dir)

command! Why3Start call s:StartWhy3Session()
command! Why3End call s:EndWhy3Session()
command! StartServer call s:Start_Shell()
command! StopServer call s:Stop_Shell()
command! PrintSession call s:Print_Session()
command! NextNode call s:Next_Node()
command! ExitSession call s:Exit_Session()
command! RefreshSession call s:Refresh_Session()

let s:job_id = 0
let s:regex_type = ""

py3 import why3

function! s:OnEvent(id, data, event) abort dict
  let str = join(a:data, "\n")
  call py3eval('why3.On_Ev(vim.eval("str"))') 
endfunction

function! s:Refresh_Session() abort
  let running = jobwait([s:job_id], 0)[0] == -1
  if running == 0
    throw "Shell server is not running"
  else 
    " run p on shell
    let s:regex_type = "initialize"
    let l:out = chansend(s:job_id, "p\n")
    if l:out == 0 
      throw "Failed to initialize session" 
    else 
    endif
  endif
endfunction

function! s:Start_Shell() abort
  let running = jobwait([s:job_id], 0)[0] == -1
  if running == 1 
    echomsg "shell server already running"
  else
    let s:regex_type = "start"
    let s:job_id = jobstart(['./why3', 'shell', 'hello.why'], {'on_stdout': function('s:OnEvent') })
    if s:job_id == 0 
      throw "Failed to start shell server?"
    elseif s:job_id == -1
      throw "Where is the executeable?"
    else
      echomsg "started shell with id of " . s:job_id
    endif
  endif
endfunction

function! s:Stop_Shell() abort
  let running = jobwait([s:job_id], 0)[0] == -1
  if running == 0
    throw "Shell server is not running"
  else
    " Run Quit on the shell
    let l:out = chansend(s:job_id, "Quit\n")
    if l:out == 0 
      throw "Failed to Quit" 
    else 
      let s:regex_type = "quit"
    endif
    " Stop the job running on vim
    echomsg "Stopping job of id " . s:job_id
    let l:err = jobstop(s:job_id)
    if l:err == 0 
      throw "Failed to stop job"
    else 
      let s:job_id = 0
    endif
  endif
endfunction

function! s:Print_Session() abort
  let running = jobwait([s:job_id], 0)[0] == -1
  if running == 0
    throw "Shell server is not running"
  else 
    " run p on shell
    let l:out = chansend(s:job_id, "p\n")
    if l:out == 0 
      throw "Failed to print session" 
    else 
      let s:regex_type = "p"
    endif
  endif
endfunction

function! s:Next_Node() abort
  let running = jobwait([s:job_id], 0)[0] == -1
  if running == 0
    throw "Shell server is not running"
  else
    " run ng on shell
    let l:out = chansend(s:job_id, "ng\n")
    if l:out == 0 
      throw "Failed to move to next node" 
    else 
      let s:regex_type = "ng"
    endif
  endif
endfunction

function! s:StartWhy3Session() abort
    if bufexists('[Goal_Panel]') && bufexists('[Log_Panel]')
      echomsg "Why3 sidebar is already active."
    elseif bufexists('[Goal_Panel]') || bufexists('[Log_Panel]')
      echomsg "Make sure to remove all panels before starting a new Session"
    else 
      call s:CreateWhy3Window()
    endif
endfunction

let s:goal_win_id = -1
let s:log_win_id = -1

function! s:CreateWhy3Window() abort
    try
      call s:Start_Shell()
      vnew
      wincmd L
      setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted nonumber norelativenumber 
      call append(0, [
            \ 'Why3 Goal Panel',
            \ '',
            \ 'Status:   Goals:',
            \ '--------|----------------',
            \ '        |',
            \ '        |',
            \ '        |',
            \ ])

      execute 'file [Goal_Panel]'
      let s:goal_win_id = win_getid()
      new
      setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted nonumber norelativenumber
      call append(0, [
            \ 'Why3 Log Panel',
            \ '',
            \ 'Log messages:',
            \ '---------------------'])
      execute 'file [Log_Panel]'
      let s:log_win_id = win_getid()
    catch 
      echomsg "Failed to start why3 ide: " . v:exception
    endtry
endfunction

function! s:GoToWindowById(target_win_id) abort
    let l:target_win_nr = win_id2win(a:target_win_id)
    if l:target_win_nr != 0
        let l:current_win_nr = winnr()
        execute l:target_win_nr . 'wincmd w'
    endif
endfunction

function! s:EndWhy3Session() abort
  if bufexists('[Goal_Panel]') && bufexists('[Log_Panel]')
    execute s:GoToWindowById(s:goal_win_id)
    quit
    execute s:GoToWindowById(s:log_win_id)
    quit
    endif
  try 
    call s:Stop_Shell()
  catch
    echomsg "Failed to stop server: " . v:exception
  endtry
endfunction

