" Vim global plugin for correcting anti-patterns
" Last Change:	2015-12-08
" Author:	David Tenreiro <https://github.com/datf>
" Version:      0.06
"
" Modes: {{{
let s:modes = ['n', 'x', 's', 'o', 'i', 'v', '#', '@', '|', '~', 'c', 'l', '!']
" n: Normal -- :nmap
" x: Visual -- :vmap
" s: Select -- :smap
" o: Operator-pending -- :omap
" i: Insert -- :imap
" v: x + s -- :vmap
" #: n + o + x
" @: n + o + x + i _DEFAULT_
" |: n + o + x + s -- :map
" ~: All up to here -- :map!
" c: Command-line -- :cmap
" l: Language (i + c + few more things) -- :lmap
" !: Skip mapping this values. I only see it for g:annoyme_defaults_on = '!'
" }}}

" Plugin startup code {{{
if exists('g:loaded_annoyme')
  finish
endif

let g:loaded_annoyme = 1

let s:save_cpo = &cpo
set cpo&vim
" }}}

" Globals {{{
let s:e_cmd = 'This is Vim! Use `%s` instead!'
let s:annoyme_on = '@'
let s:annoyme_mouse = 1
let s:annoyme_insert = 1
let s:annoyme_bell = 1
let s:penalty = 1
let s:annoyme_scrollbars = 1

if exists('g:annoyme_errcmd') && !empty(g:annoyme_errcmd)
  let s:e_cmd = g:annoyme_errcmd
endif

if exists('g:annoyme_disable') && type(g:annoyme_disable) == type([])
  if index(g:annoyme_disable, 'm') > -1
    let s:annoyme_mouse = 0
  endif

  if index(g:annoyme_disable, 'b') > -1
    let s:annoyme_bell = 0
  endif

  if index(g:annoyme_disable, 's') > -1
    let s:annoyme_scrollbars = 0
  endif

  if index(g:annoyme_disable, 'i') > -1
    let s:annoyme_insert = 0
  endif
endif

if exists('g:annoyme_penalty')
  let s:penalty = g:annoyme_penalty
endif

if !exists('g:annoyme_defaults_on')
   \ || index(s:modes, g:annoyme_defaults_on) < 0
  let s:annoyme_on = '@'
else
  let s:annoyme_on = g:annoyme_defaults_on
endif

function! s:GenError(err)
  return printf(s:e_cmd, join(a:err, '`, `'))
endfunction

function! s:ExpandModes(mode)
  if a:mode == 'v' | return ['x', 's'] | endif
  if a:mode == '#' | return ['n', 'x', 'o'] | endif
  if a:mode == '@' | return ['n', 'x', 'o', 'i'] | endif
  if a:mode == '|' | return ['n', 'x', 's', 'o'] | endif
  if a:mode == '~' | return ['n', 'x', 's', 'o', 'i'] | endif
  return [a:mode]
endfunction

function! s:SortModes(i1, i2)
  return index(s:modes, a:i2) - index(s:modes, a:i1)
endfunction

let s:mapped = {}

let s:is_mapped = 0
" }}}

" Default key mappings {{{
let s:keymappings = { s:annoyme_on : {
                        \'<Up>': ['k'],
                        \ '<C-Up>': ['k'],
                        \ '<M-Up>': ['k'],
                        \ '<S-Up>': ['CTRL-B'],
                        \ '<Down>': ['j'],
                        \ '<C-Down>': ['j'],
                        \ '<S-Down>': ['CTRL-F'],
                        \ '<M-Down>': ['j'],
                        \ '<Left>': ['h', 'F', 'T', 'b', 'B'],
                        \ '<C-Left>': ['b'],
                        \ '<S-Left>': ['b'],
                        \ '<M-Left>': ['h'],
                        \ '<Right>': ['l', 'f', 't', 'e', 'E'],
                        \ '<C-Right>': ['w'],
                        \ '<S-Right>': ['w'],
                        \ '<M-Right>': ['l'],
                        \ '<Home>': ['1\|', '^', '0'],
                        \ '<S-Home>': ['1\|', '^', '0'],
                        \ '<M-Home>': ['1\|', '^', '0'],
                        \ '<C-Home>': ['gg'],
                        \ '<End>': ['$'],
                        \ '<S-End>': ['$'],
                        \ '<M-End>': ['$'],
                        \ '<C-End>': ['G'],
                        \ '<PageUp>': ['CTRL-B'],
                        \ '<S-PageUp>': ['CTRL-B'],
                        \ '<PageDown>': ['CTRL-F'],
                        \ '<S-PageDown>': ['CTRL-F'],
                        \ '<MiddleMouse>': ['"+p', '"*p'],
                        \ '<ScrollWheelUp>': ['3CTRL-Y'],
                        \ '<M-ScrollWheelUp>': ['3CTRL-Y'],
                        \ '<S-ScrollWheelUp>': ['CTRL-B'],
                        \ '<C-ScrollWheelUp>': ['CTRL-B'],
                        \ '<ScrollWheelDown>': ['3CTRL-E'],
                        \ '<M-ScrollWheelDown>': ['3CTRL-E'],
                        \ '<S-ScrollWheelDown>': ['CTRL-F'],
                        \ '<C-ScrollWheelDown>': ['CTRL-F'],
                        \ '<Insert>': ['i', 'a', 'I', 'A', 'o', 'O', 'CTRL-O'],
                        \ '<Del>': ['x', 's', 'd', 'D', 'c', 'C'],
                        \ '<BS>': ['CTRL-H', 'X', 's', 'd', 'D', 'c', 'C']
                      \ }
                    \ }
" }}}

function! s:Map() " {{{
  let s:mapped = {}

  if exists('g:annoyme_with')
    for mapmode in keys(g:annoyme_with)
      if !has_key(s:keymappings, mapmode)
        let s:keymappings[mapmode] = g:annoyme_with[mapmode]
      else
        let s:keymappings[mapmode] = extend(s:keymappings[mapmode],
                                     \ g:annoyme_with[mapmode])
      endif
    endfor
  endif

  for mapmode in sort(keys(s:keymappings), "<SID>SortModes")
    if mapmode == '!' | continue | endif
    let do_modes = s:ExpandModes(mapmode)
    for mapmreal in do_modes
      for key in keys(s:keymappings[mapmode])
        let kmap = mapmode

        if has_key(s:keymappings, mapmreal) 
           \ && has_key(s:keymappings[mapmreal], key)
          let kmap = mapmreal
        endif

        if !empty(s:keymappings[kmap][key])
           \ && empty(maparg(key, mapmreal, 0, 1))

          let value = ":AnnoyMeError " . kmap .
                \ " " . key . "<CR>"

          if index(['i', 'v', 'x', 's'], mapmreal) >= 0
            let value = '<Esc>' . value
          endif
          exe mapmreal . "noremap " . key . " " . value

          let value = mapcheck(key, mapmreal)
          if !has_key(s:mapped, mapmreal)
            let s:mapped[mapmreal] = {key : value}
          else
            let s:mapped[mapmreal][key] = value
          endif
        endif
      endfor
    endfor
  endfor
endfunction " }}}

function! s:AnnoyMeErr(map, key) " {{{
  if empty(a:map) || empty(a:key)
        \ || !has_key(s:keymappings, a:map)
        \ || !has_key(s:keymappings[a:map], a:key)
    return
  endif

  redraw

  " Show message with Error Highlighting
  echohl ErrorMsg
  echomsg s:GenError(s:keymappings[a:map][a:key])
  echohl None

  " Bell
  normal \<Esc>

  if s:penalty
    sleep 1
  endif
endfunction " }}}

function! s:Unmap() " {{{
  for mapmode in keys(s:mapped)
    for key in keys(s:mapped[mapmode])
      if mapcheck(key, mapmode) == s:mapped[mapmode][key]
        exe mapmode . "unmap " . key
      endif
    endfor
  endfor
endfunction " }}}

" Plugin API & mappings {{{
function! s:Enable()
  if s:is_mapped == 1 | return | endif

  call s:Map()

  if s:annoyme_mouse
    let s:save_mouse = &mouse
    set mouse=
  endif

  if s:annoyme_bell
    let s:save_bell = &visualbell
    set visualbell
  endif

  if has('gui_running') && s:annoyme_scrollbars
    let s:save_guiopt = &guioptions
    set guioptions-=rRlLbh
  endif

  if s:annoyme_insert
    augroup annoyme
      autocmd!
      autocmd CursorHoldI * if mode() == 'i' |
            \ redraw |
            \ echohl ErrorMsg |
            \ echomsg 'Too long on insert mode buddy!' |
            \ echohl None |
        \ endif
    augroup end
  endif

  let s:is_mapped = 1
endfunction

function! s:Disable()
  if s:is_mapped == 0 | return | endif

  call s:Unmap()

  if s:annoyme_mouse
    let &mouse = s:save_mouse
  endif

  if s:save_bell == 0
    set novisualbell
  endif

  if has('gui_running') && s:annoyme_scrollbars
    set guioptions=s:save_guioptions
  endif

  autocmd! annoyme

  let s:is_mapped = 0
endfunction

command! -n=+ AnnoyMeError call <SID>AnnoyMeErr(<f-args>)
command! -n=0 -bar AnnoyMeNot :call <SID>Disable()
command! -n=0 -bar AnnoyMe :call <SID>Enable()

noremap <unique> <script> <Plug>AnnoyMePlease <SID>AnnoyMeEnable
noremap <SID>AnnoyMeEnable :call <SID>Enable()<CR>

noremap <unique> <script> <Plug>AnnoyMeNot <SID>AnnoyMeDisable
noremap <SID>AnnoyMeDisable :call <SID>Disable()<CR>

silent call s:Enable()
" }}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: sw=2 sts=2 et ai fdm=marker cc=80
