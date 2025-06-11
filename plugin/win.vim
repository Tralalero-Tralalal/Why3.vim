command! Why3Start call s:StartWhy3Session()

function! s:StartWhy3Session() abort
    " Check if the Why3 buffer already exists.
    " bufnr('[Why3]') returns 
    " the buffer number if a buffer named '[Why3]' exists
    " otherwise it returns -1
    if bufexists('[Goal_Panel]') && bufexists('[Log_Panel]')
        echomsg "Why3 sidebar is already active."
        return "already_started"  
      elseif bufexists('[Goal_Panel]') || bufexists('[Log_Panel]')
        echomsg "Make sure to remove all panels before starting a new Session"
        return "not_enough_panels" 
    endif
    call s:CreateWhy3Window()

endfunction

function! s:CreateWhy3Window() abort
    " Create a new vertical split with a truly new, empty buffer
    vnew

    " Move the new window to the far left
    wincmd L

    " Set simple params
    setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted nonumber norelativenumber
    
    " Assign name
    execute 'file [Goal_Panel]'

    " Create a horizontal split for the Log Panel
    new

    " Set simple params
    setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted nonumber norelativenumber
    execute 'file [Log_Panel]'

endfunction

function! s:FocusBuffer(buf_id_or_name) abort
  let l:target_win_nr = bufwinnr(a:buf_id_or_name)
  if l:target_win_nr != -1
    execute l:target_win_nr . 'wincmd w'
  else
    echomsg "Buffer '" . a:buf_id_or_name . "' not found in any visible window."
  endif
endfunction

