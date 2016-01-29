" Compare two position arrays. Return a negative value if lhs occurs before rhs,
" positive value if after, and 0 if they are the same.
function! s:compare_pos(l, r)
  " If number lines are the same, compare columns
  return a:l[0] ==# a:r[0] ? a:l[1] - a:r[1] : a:l[0] - a:r[0]
endfunction

" Return the position of the input marker as a two element array. First element
" is the line number, second element is the column number
function! s:pos(mark)
  let pos = getpos(a:mark)
  return [pos[1], pos[2]]
endfunction

" Return the region covered by the input markers as a two element array. First
" element is the position of the start marker, second element is the position of
" the end marker
function! s:region(start_mark, end_mark)
  return [s:pos(a:start_mark), s:pos(a:end_mark)]
endfunction

" The highlight group we use for all the visual selection
let s:hi_group_visual = 'multiple_cursors_visual'



" Set up highlighting
if !hlexists(s:hi_group_visual)
  exec "highlight link ".s:hi_group_visual." Visual"
endif


" Highlight the area bounded by the input region. The logic here really stinks,
" it's frustrating that Vim doesn't have a built in easier way to do this. None
" of the \%V or \%'m solutions work because we need the highlighting to stay for
" multiple places.
function! s:highlight_region(region)
  let s = sort(copy(a:region), "s:compare_pos")
  "if s:to_mode ==# 'V'
    "let pattern = '\%>'.(s[0][0]-1).'l\%<'.(s[1][0]+1).'l.*\ze.\_$'
  "else
    if (s[0][0] == s[1][0])
      " Same line
      let pattern = '\%'.s[0][0].'l\%>'.(s[0][1]-1).'c.*\%<'.(s[1][1]+1).'c.'
    else
      " Two lines
      let s1 = '\%'.s[0][0].'l.\%>'.s[0][1].'c.*'
      let s2 = '\%'.s[1][0].'l.*\%<'.s[1][1].'c..'
      let pattern = s1.'\|'.s2
      " More than two lines
      if (s[1][0] - s[0][0] > 1)
        let pattern = pattern.'\|\%>'.s[0][0].'l\%<'.s[1][0].'l.*\ze.\_$'
      endif
    endif
  "endif
  return matchadd(s:hi_group_visual, pattern)
endfunction

function! s:highlight_all()
    call s:remove_all()
    for interval in b:intervals
        call add(b:highlights, s:highlight_region(interval))
    endfor
endfunction

function! s:remove(hi_id)
  if a:hi_id
    " If the user did a matchdelete or a clearmatches, we don't want to barf if
    " the matchid is no longer valid
    silent! call matchdelete(a:hi_id)
  endif
endfunction

function! s:remove_all()
    for hi_id in b:highlights
        call s:remove(hi_id)
    endfor
    let b:highlights = []
endfunction

let b:highlights = []
let b:intervals = [[[1,1], [1,3]], [[2, 2], [2, 5]]]

"map x :let b:visual_hi_id=<SID>highlight_region(<SID>region([1,1], [1,3]))<CR>
map X :call <SID>remove_all()<CR>
map x :call <SID>highlight_all()<CR>


