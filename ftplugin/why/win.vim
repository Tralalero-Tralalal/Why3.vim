command! Why3Start call s:StartWhy3Session()
command! Why3End call s:EndWhy3Session()

function! s:StartWhy3Session() abort
    if bufexists('[Goal_Panel]') && bufexists('[Log_Panel]')
        echomsg "Why3 sidebar is already active."
        return "already_started"  
      elseif bufexists('[Goal_Panel]') || bufexists('[Log_Panel]')
        echomsg "Make sure to remove all panels before starting a new Session"
        return "not_enough_panels" 
    endif
    call s:CreateWhy3Window()

endfunction

let s:goal_win_id = -1
let s:log_win_id = -1

function! s:CreateWhy3Window() abort
    " Create a new vertical split with a truly new, empty buffer
    vnew

    " Move the new window to the far left
    wincmd L

    " Set simple params
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

    " Assign name
    execute 'file [Goal_Panel]'

    let s:goal_win_id = win_getid()

    " Create a horizontal split for the Log Panel
    new

    " Set simple params
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
        " Store the current window number so we can potentially return focus later
        let l:current_win_nr = winnr()

        " Switch to the target window using its number, then close it.
        " We use 'execute' to build and run the command string.
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
    endif
endfunction

