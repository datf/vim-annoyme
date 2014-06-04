" Vim global plugin for correcting anti-patterns
" Last Change:	2014-06-02
" Author:	David Tenreiro <https://github.com/datf>
" Version:      0.05
"
" TODO: Restructure so mouse annoyance is not on the mapping Fn.
" TODO: au CursorHoldI * if mode() == 'i' | echom 'Get me out of here! | endif
" TODO: Should the plugin annoy you on other Vim anti-patterns?
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

if exists('g:annoyme_errcmd') && !empty(g:annoyme_errcmd)
  let s:e_cmd = g:annoyme_errcmd
endif

if exists('g:annoyme_but_mouse')
  let s:annoyme_mouse = g:annoyme_but_mouse
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

function! s:AnnoyMap() " {{{
  if s:is_mapped == 1 | return | endif
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
  for mapmode in sort(keys(s:keymappings))
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
  if s:annoyme_mouse
    let s:save_mouse = &mouse
    set mouse=
  endif
  " TODO: Make it optional when restructuring the code
  set visualbell
  let s:is_mapped = 1
endfunction " }}}

function! s:AnnoyMeErr(map, key)
  if empty(a:map) || empty(a:key)
        \ || !has_key(s:keymappings, a:map)
        \ || !has_key(s:keymappings[a:map], a:key)
    return
  endif
  redraw
  echohl ErrorMsg
  echomsg s:GenError(s:keymappings[a:map][a:key])
  echohl None
  normal \<Esc>
  sleep 1
endfunction
command! -n=+ AnnoyMeError call <SID>AnnoyMeErr(<f-args>)

function! s:AnnoyUnmap() " {{{
  if s:is_mapped == 0 | return | endif
  for mapmode in keys(s:mapped)
    for key in keys(s:mapped[mapmode])
      if mapcheck(key, mapmode) == s:mapped[mapmode][key]
        exe mapmode . "unmap " . key
      endif
    endfor
  endfor
  if s:annoyme_mouse
    let &mouse = s:save_mouse
  endif
  let s:is_mapped = 0
endfunction " }}}

" Plugin API & mappings {{{
command! -n=0 -bar AnnoyMeNot :call <SID>AnnoyUnmap()
command! -n=0 -bar AnnoyMe :call <SID>AnnoyMap()

noremap <unique> <script> <Plug>AnnoyMePlease <SID>Map
noremap <SID>Map :call <SID>AnnoyMap()<CR>

noremap <unique> <script> <Plug>AnnoyMeNot <SID>Unmap
noremap <SID>Unmap :call <SID>AnnoyUnmap()<CR>
" }}}

silent call s:AnnoyMap()

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: sw=2 sts=2 et ai fdm=marker cc=80
