
" E = { } < > [ ] ( )
" S = , . / : ; + - * %
" 
" E    stuff stuff    S   stuff stuff    S   stuff stuff   E
"      |          |       |          |       |          |   
"      ===========--------|          |       |          |   
"      |          |       ===========--------|          |   
"      |          |       |          --------===========|   
"      |          |       |          |       |          |   
"      |          |       |          |       |          |   
"      ^ end of start     ^ end of middle    ^ end of middle
"                 |                  |                  |   
"                 ^ start of middle  ^ start of middle  ^ start of end
"
" E    stuff stuff    S   stuff stuff    S   stuff stuff     S    E
"      |          |       |          |       |          |         |  
"      ===========--------|          |       |          |         |
"      |          |       ===========--------|          |         |
"      |          |       |          |       ===========----------|
"      |          |       |          |       |          |         |  
"      |          |       |          |       |          |         |  
"      ^ end of start     ^ end of middle    ^ end of middle      ^ start of end
"                 |                  |                  |            
"                 ^ start of middle  ^ start of middle  ^ start of middle

" Returns whether or not there is a match for the given pattern at the given
" position.
function! s:is_pattern_at_pos(pattern, position)
  let oldposition = getpos('.') " copy the current position so we can restore it later

  call cursor(a:position)
  let nextoccourance = searchpos(a:pattern, 'nc')

  call setpos('.', oldposition) " restore the old position

  return a:position == nextoccourance
endfunction

" Selects the text in the given range, given by [[line, column], [line,
" column]] *including* the first character but *excluding* the last.
"
" If either the start or ending positions are [0, 0] this function does
" nothing.
function! s:select_range(range)
  let [start, end] = a:range
  if start == [0,0] || end == [0,0]
    return
  endif

  normal! v
  call cursor(start)
  normal! o
  call cursor(end)

  let [endline, endcol] = end

  " If we are in the first column...
  if endcol == 1
    " ...move up and to the end of the line.
    normal! k$
  else
    " Otherwise just move left 1 char.
    normal! h
  endif
endfunction

" Returns the range in the format [[line, column], [line, column]] for the
" text object that should be selected given the current cursor position and
" the regular expressions 'start', 'middle' and 'end' which denote the head,
" body and tail of a list (like "[", ",", "]" for a list like "[a, b, c]").
" Set 'inner' to true if you do not want the nearest list seperator to be
" included in the selection.
function! s:get_object(start, middle, end, inner)

  let start_of_middle = '\v' . '%(' . '\_s*' . a:middle . '\_s*' . ')' . '@='  . '\S' . '@<='
  let end_of_middle   = '\v' . '%(' . '\_s*' . a:middle . '\_s*' . ')' . '@<=' . '\S' . '@='
  let end_of_start    = '\v' . '%(' . ''     . a:start  . '\_s*' . ')' . '@<=' . '\S' . '@='
  \                          . '%(' . ''     . a:end    . ''     . ')' . '@!'
  let start_of_end    = '\v' . '%(' . '\_s*' . a:end    . ''     . ')' . '@='  . '\S' . '@<='
  \                          . '%(' . ''     . a:start  . ''     . ')' . '@<!'
  \                          . '%(' . ''     . a:middle . ''     . ')' . '@<!'
  \                          . '|'
  \                          . '%(' . ''     . a:end    . ''     . ')' . '@='
  \                          . '%(' . ''     . a:middle . '\_s*' . ')' . '@<='

  let s_skip ='synIDattr(synID(line("."), col("."), 0), "name") =~? "string\\|comment"'

  let start = searchpairpos(end_of_start, end_of_middle, start_of_end, 'cWnb', s_skip)
  let end   = searchpairpos(end_of_start, a:inner ? start_of_middle : end_of_middle, start_of_end, 'Wn', s_skip)

  " If we don't have the seperator and the end of our selection range, but we
  " do at the start...
  if !a:inner && end != [0,0] && !s:is_pattern_at_pos(end_of_middle, end)
    " ...set the start position to instead include the previous seperator.
    let start = searchpairpos(end_of_start, start_of_middle, start_of_end, 'cWnb')
  endif

  return [start, end]
endfunction

" Selects the text object for a list using the given seperator. The head and
" tail will be any of [...] {...} or (...) depending on what is nearest.
function! s:select_list_object(list_seperator, inner)
  call s:select_range( s:get_object( '[({[]', a:list_seperator, '[]})]', a:inner ) )
endfunction

onoremap <silent> a,      :call <SID>select_list_object(',', 0)<CR>
onoremap <silent> i,      :call <SID>select_list_object(',', 1)<CR>
vnoremap <silent> a, <ESC>:call <SID>select_list_object(',', 0)<CR>
vnoremap <silent> i, <ESC>:call <SID>select_list_object(',', 1)<CR>

onoremap <silent> a;      :call <SID>select_list_object(';', 0)<CR>
onoremap <silent> i;      :call <SID>select_list_object(';', 1)<CR>
vnoremap <silent> a; <ESC>:call <SID>select_list_object(';', 0)<CR>
vnoremap <silent> i; <ESC>:call <SID>select_list_object(';', 1)<CR>

onoremap <silent> a/      :call <SID>select_list_object('/', 0)<CR>
onoremap <silent> i/      :call <SID>select_list_object('/', 1)<CR>
vnoremap <silent> a/ <ESC>:call <SID>select_list_object('/', 0)<CR>
vnoremap <silent> i/ <ESC>:call <SID>select_list_object('/', 1)<CR>

onoremap <silent> a:      :call <SID>select_list_object(':', 0)<CR>
onoremap <silent> i:      :call <SID>select_list_object(':', 1)<CR>
vnoremap <silent> a: <ESC>:call <SID>select_list_object(':', 0)<CR>
vnoremap <silent> i: <ESC>:call <SID>select_list_object(':', 1)<CR>

