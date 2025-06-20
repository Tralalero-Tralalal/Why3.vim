command! Why3Start call s:StartWhy3Session()
command! Why3End call s:EndWhy3Session()
command! StartServer call s:Start_Shell()
command! StopServer call s:Stop_Shell()
command! PrintSession call s:Print_Session()
command! ExitSession call s:Exit_Session()

let s:job_id = 0
let s:regex_type = ""

" regex for selected node. gets everything between ** **, not greedy
" \*\*(.*?)\*\*   \gs global singeline

" regex for goals. gets everything between {}, greedy
" \{[^}]*\}       \gs global singeline

" regex for first word
" ^(\S+)

" regex for file name
" File\s(.*),

" regex for file ID
" id\s\d+

" regex for Theory name
" Theory\s+(.*),

" regex for Theory ID
" \vid:\s\d+

" SUB REGEXES

" Get goal name from Goal
" Goal=(.*),

" Get ID of Goal
"id = (\d+)

" Get parent name of Goal
" parent=(.*);

" Get data about goal. It'll be a list of 2, the provenness is in the first
" element, while unknown data is in the 2nd
" \[.*?\]

" root  File hello.why, id 1;
"     [ Theory HelloProof, id: 2;
"       [{ Goal=G1, id = 3; parent=HelloProof; [] [] };
"       { Goal=G2, id = 4; parent=HelloProof; [] [] };
"       { Goal=G3, id = 5; parent=HelloProof; [] [] };
"       { Goal=G4, id = 6; parent=HelloProof; [] [] }]];

let s:python_dir = expand('<sfile>:p:h:h:h') . '/python'

function! s:Compat(python_dir) abort
  py3 import vim
  py3 if not vim.eval('a:python_dir') in sys.path:
    \    sys.path.insert(0, vim.eval('a:python_dir'))
endfunction

call s:Compat(s:python_dir)

py3 from why3 import Regex

function! s:Any_value_is_empty(my_dict) abort
  for [key, value] in items(a:my_dict)
    if empty(value)
      return 1
    endif
  endfor
  return 0
endfunction

function! s:GrabData(str) abort 
  if s:regex_type == "p"
    return py3eval('Regex.grab_data_print(vim.eval("a:str"))')
  elseif s:regex_type == "start"
    return {'start': ['server']}
  endif
  return {}
endfunction

function! s:OnEvent(id, data, event) abort dict
  let str = join(a:data, "\n")
  let new_data = s:GrabData(str)

  if empty(new_data)
    echomsg "invalid command"
  else
      if s:Any_value_is_empty(new_data) == 0
        if s:regex_type == "p"
          echo new_data['name']
          echo new_data['id']
        elseif s:regex_type == "start"
        else
          echomsg "regex_type does not match any"
        endif
      else
        echomsg "Failed to regex"
      endif
  endif
endfunction

function! s:Start_Shell() abort
  let running = jobwait([s:job_id], 0)[0] == -1
  if running == 1 
    echomsg "shell server already running"
  else
    let s:job_id = jobstart(['./why3', 'shell', 'hello.why'], {'on_stdout': function('s:OnEvent') })
    if s:job_id == 0 
      echomsg "failed to start shell server"
    elseif s:job_id == -1
      echomsg "where is the executeable"
    else
      echomsg "started shell with id of " . s:job_id
      let s:regex_type = "start"
    endif
  endif
endfunction

function! s:Stop_Shell() abort
  let running = jobwait([s:job_id], 0)[0] == -1
  if running == 0
    echomsg "shell server is not running"
  else 
    echomsg "stopping job of id " . s:job_id
    let l:err = jobstop(s:job_id)
    if l:err == 0 
      echomsg "failed to stop job"
    else 
      echomsg "stopped job"
      let s:job_id = 0
    endif
  endif
endfunction

function! s:Print_Session() abort
  let running = jobwait([s:job_id], 0)[0] == -1
  if running == 0
    echomsg "shell server is not running"
  else 
    let l:out = chansend(s:job_id, "p\n")
    if l:out == 0 
      echomsg "failed to print session" 
    endif
  endif
  let s:regex_type = "p"
endfunction

function! s:StartWhy3Session() abort
    if bufexists('[Goal_Panel]') && bufexists('[Log_Panel]')
        echomsg "Why3 sidebar is already active."
        return "already_started"  
      elseif bufexists('[Goal_Panel]') || bufexists('[Log_Panel]')
        echomsg "Make sure to remove all panels before starting a new Session"
        return "not_enough_panels" 
    endif
    call s:CreateWhy3Window()
    call s:Start_Shell()
endfunction

let s:goal_win_id = -1
let s:log_win_id = -1

function! s:CreateWhy3Window() abort
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
      echomsg "closing goal window with id of " . s:goal_win_id
        execute s:GoToWindowById(s:goal_win_id)
          quit

      echomsg "closing log window with id of " . s:log_win_id
        execute s:GoToWindowById(s:log_win_id)
          quit
          call s:Stop_Shell()
    endif
endfunction

