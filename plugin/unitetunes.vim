"#############################################################################
"###                            UNITETUNES                                 ###
"#############################################################################
if exists('g:loaded_unitetunes')
  finish
elseif v:version < 703
  echoerr 'unitetunes.vim does not work on Vim "' . v:version . '".'
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

set encoding=utf-8
scriptencoding=utf-8

"=============================================================================
" UniteSettings
"=============================================================================

" Unite keymap
nmap <silent> su :UniteMenuToggle shortcut<CR>
nmap <silent> sU :Unite menu:shortcut<CR>

" Unite settings
let g:unite_force_overwrite_statusline=0
let g:unite_source_history_yank_enable=1

" Unite buffer keymap
autocmd FileType unite call s:unite_my_settings()
function! s:unite_my_settings()
	nmap <buffer> q :UniteMenuBack shortcut<CR>
	nmap <buffer> Q :UniteClose default<CR>
	nmap <buffer> <C-c> :UniteClose default<CR>
	"nmap <buffer> su <Nop>
	"nmap <buffer> sU <Nop>
	autocmd CursorMoved  <buffer> :call UniteCursorMoved()
	autocmd CursorMovedI <buffer> :call UniteCursorMoved()
	UniteMenuNestEcho
endfunction

" Unite cursor move. record line number for resume.
let s:unite_line = 0
function! UniteCursorMoved()
	let s:unite_line = line('.')
endfunction

" Unite menu:* nest show
let s:unite_stack = []
command! -nargs=0 UniteMenuNestEcho :call UniteMenuNestEcho()
function! UniteMenuNestEcho()
	let mesg = ''
	for i in s:unite_stack
		let mesg .= '/'. i[0]
	endfor
	let unite = unite#get_current_unite()
	if unite.args[0][0] == "menu"
		let mesg .= '/['. unite.args[0][1][0]. ']'
	else
		let mesg .= '/['. unite.profile_name. ']'
	endif
	redraw | echo mesg
endfunction

" Unite menu:* nest open
command! -nargs=+ UniteMenuNest :call UniteMenuNest(<f-args>)
function! UniteMenuNest(...)
	let unite = unite#get_current_unite()
	if unite != {} && unite.args[0][0] == "menu"
		let name = unite.args[0][1][0]
		let line = (s:unite_line >= 2)? s:unite_line - 2 : 0
		let item = [name, line]
		call add(s:unite_stack, item)
		exec "Unite ". join(a:000, " ")
	else
		echoerr "No Unite menu."
	endif
endfunction

" Unite menu:* back
command! -nargs=1 UniteMenuBack :call UniteMenuBack(<f-args>)
function! UniteMenuBack(root_menu_name)
	let unite = unite#get_current_unite()
	if unite != {} && unite.is_finalized == 0
		if unite.args[0][0] == "menu"
		 \ && unite.args[0][1][0] == a:root_menu_name
			UniteClose default
		elseif len(s:unite_stack) > 0
			let item = remove(s:unite_stack, -1)
			let name = item[0]
			let line = item[1]
			exec "Unite -silent -select=". line. " menu:". name
			" redraw cursor after 'Unite -select'
			let  unite = unite#get_current_unite()
			let  unite.cursor_line_time = [0, 0]
			call unite#set_current_unite(unite)
			call unite#force_redraw()
		else
			exec "Unite -silent menu:". a:root_menu_name
		endif
	endif
endfunction

" Unite menu:* toggle
command! -nargs=1 UniteMenuToggle :call UniteMenuToggle(<f-args>)
function! UniteMenuToggle(root_menu_name)
	let unite = unite#get_current_unite()
	if unite == {} || !exists("t:unite")
		exec "Unite -wrap -multi-line -silent menu:". a:root_menu_name
	elseif unite#get_unite_winnr(unite.buffer_name) < 0 "|| unite.is_finalized == 1
		UniteResume -silent
	else
		UniteClose default
	endif
endfunction

" Map Unite menu:*
function! UniteMap(key, value)
	let [word, value] = a:value
	if isdirectory(value)
		" directory
		return {
		\    "word" : "[/] ". word,
		\    "kind" : "directory",
		\    "action__directory" : value
		\}
	elseif !empty(glob(value))
		" file
		return {
		\    "word" : "[e] ". word,
		\    "kind" : "file",
		\    "default_action" : "tabdrop",
		\    "action__path" : value,
		\}
	else
		" command
		return {
		\    "word" : "[:] ". word,
		\    "kind" : "command",
		\    "action__command" : value
		\}
	endif
endfunction

"=============================================================================
" UniteMenu
"=============================================================================

" Initialize Unite menu:*
if !exists("g:unite_source_menu_menus")
	let g:unite_source_menu_menus = {}
endif

" Unite menu:shortcut
let g:unite_source_menu_menus.shortcut = {
\   "description" : "shortcut",
\   "map"         : function("UniteMap"),
\   "candidates"  : [
\       ["[1sh] Enter    Shell",                                                      "normal 1sh"],
\       ["[2sh] VimFiler BufferDir",                                                  "call VimFiler(0)"],
\       ["[3sh]          Project",                                                    "call VimFiler(1)"],
\       [" [1/] VimGrep  BufferDir",                                                  "normal 1/"],
\       [" [2/]          Project",                                                    "normal 2/"],
\       ["               Qfreplace",                                                  "Qfreplace"],
\       [" [sr]  QuickRun",                                                           "QuickRun"],
\       [" [so]  only",                                                               "only"],
\       [" [sO]  tabonly",                                                            "tabonly"],
\       [" [^p]  CtrlP",                                                              "CtrlP"],
\       ["[1^p]  CtrlP MRUFiles",                                                     "CtrlPMRUFiles"],
\       ["[2^p]  CtrlP Buffer",                                                       "CtrlPBuffer"],
\       ["[3^p]  CtrlP Line",                                                         "CtrlPLine"],
\       ["[9^p]  CtrlP ClearCache",                                                   "CtrlPClearCache"],
\       ["[gd]   YcmCompleter GotoDefinitionElseDeclaration",                         "normal gd"],
\       ["[gI]   YcmCompleter GotoImplementation",                                    "normal gI"],
\       ["[gr]   OmniSharpFindUsages",                                                "normal gr"],
\       ["[K]    OmniSharpDocumentation",                                             "normal K"],
\       ["[s^p]  OmniSharpFindType",                                                  "OmniSharpFindType"],
\       ["[S^p]  OmniSharpFindSymbol",                                                "OmniSharpFindSymbol"],
\       ["[9gr]  OmniSharpFindUsages With ReloadSolution",                            "normal 9gr"],
\       ["[9K]   OmniSharpDocumentation With ReloadSolution",                         "normal 9K"],
\       ["[9s^p] OmniSharpFindType With ReloadSolution",                              "normal 9s<C-p>"],
\       ["[9S^p] OmniSharpFindSymbol With ReloadSolution",                            "normal 9S<C-p>"],
\       ["Vinarise (Edit current file as binary file)",                               "Vinarise"],
\       ["Gist List",                                                                 "Gist -l"],
\       ["     Post",                                                                 "Gist"],
\       ["[`<][`>] Goto last visual mode start/end position",                         "normal `<"],
\       ["[`[][`]] Goto last yanked start/end position",                              "normal `["],
\       ["[g;][g,] next/preg changelist",                                             "normal g;"],
\       ["[<C-r>.] Insert last inserted text",                                        "normal <C-r>."],
\       ["[<C-r>.] Insert last inserted text",                                        "normal <C-r>."],
\       ["[<C-r>/] Insert last searched text",                                        "normal <C-r>/"],
\       ["[<C-r>%] Insert current filename text",                                     "normal <C-r>%"],
\       ["[_] Switch Word",                                                           "Switch"],
\       ["[~] Toggle Case",                                                           "normal ~"],
\       ["[o]                   goto   Opponent selection position (in visual mode)", "normal vo"],
\       ["[^h],[^j],[^k],[^l]   expand opponent selection / cursor (in visual mode)", "normal v<C-h>"],
\       ["[^w],[^b]             expand opponent selection / word   (in visual mode)", "normal v<C-w>"],
\       ["[+],[-]               expand opponent selection / block  (in visual mode)", "normal v+"],
\       ["[<CR><delim>]         EasyAlign <delim>                  (in visual mode)", "normal v<CR>="],
\       ["[<CR>*<delim>]        EasyAlign All <delim>              (in visual mode)", "normal v<CR>*="],
\       ["[<CR><right>*<delim>] EasyAlign to Right All <delim>     (in visual mode)", "normal v<CR><Right>*="],
\       ["[s<CR>]               Autoformat",                                          "Autoformat"],
\       ["[^o] prev jumplist",                                                        "normal ^o"],
\       ["[^g] next jumplist and output filename",                                    "normal ^g"],
\       ["[sc] toggle colorcolumn color",                                             "normal sc"],
\       ["[sC] toggle colorcolumn width",                                             "normal sC"],
\       ["Ricty OpenFontDir",                                                         "RictyOpenFontDir"],
\       ["      Use RictyDiminished",                                                 "RictyUse Ricty_Diminished:h18:cSHIFTJIS Ricty_Diminished:h24"],
\       ["      Use Osaka",                                                           "RictyUse Osaka－等幅:h18:cSHIFTJIS Osaka-Mono:h24"],
\       ["      Use Migu 1M",                                                         "RictyUse Migu\\ 1M\\ Regular:h18:cSHIFTJIS Migu\\ 1M\\ Regular:h26"],
\       ["      Use Inconsolata",                                                     "RictyUse Inconsolata:h18:cSHIFTJIS Inconsolata:h26"],
\       ["      Use Ubuntu Mono",                                                     "RictyUse Ubuntu\\ Mono:h18:cSHIFTJIS Ubuntu\\ Mono:h26"],
\       ["      Unuse",                                                               "RictyUnuse"],
\       ["YouCompleteMe Bundle Valloric/YouCompleteMe (Win + ManualBuild and Mac)",   "exec 'OpenBrowser https://goo.gl/1eB6jq' | KeySet ycm_bundle Valloric/YouCompleteMe ycm_name YouCompleteMe"],
\       ["                     nunun/ycmx64           (Win + Prebuild 64bit)",        "exec 'OpenBrowser https://github.com/nunun/ycmx64' | KeySet ycm_bundle nunun/ycmx64 ycm_name ycmx64"],
\       ["                     Unuse",                                                "KeyDel ycm_bundle ycm_name"],
\       ["UltiSnips Edit!                             (edit snippets)",               "exec 'UltiSnipsEdit! '. &ft"],
\       ["git",                                                                       "UniteMenuNest menu:version_controls_git"],
\       ["svn",                                                                       "UniteMenuNest menu:version_controls_svn"],
\       ["tabmove 0    (tab move first)",                                             "tabm0"],
\       ["tabmove 1000 (tab move last)",                                              "tabm1000"],
\       ["[<op>av],  [<op>iv]  operate A/Inner Vertical word column",                 "normal vav"],
\       ["[<op>ac],  [<op>ic]  operate A/Inner Comment",                              "normal vac"],
\       ["[<op>ax(], [<op>ix(] operate A/Inner X()",                                  "normal vax("],
\       ["[<op>af],  [<op>if]  operate A/Inner Function",                             "normal vaf"],
\       ["[<op>a,],  [<op>i,]  operate A/Inner function argument (,)",                "normal va,"],
\       ["[<op>ap],  [<op>ip]  operate A/Inner Paragraph",                            "normal vap"],
\       ["[^-^-] toggle comment",                                                     "TComment"],
\       ["[sg] OpenBrowserSmartSearch",                                               "call openbrowser#_keymapping_smart_search('n')"],
\       ["[sr] toggle line",                                                          "normal sr"],
\       ["[st] toggle tabspace",                                                      "normal st"],
\       ["[sT] toggle tabchar",                                                       "normal sT"],
\       ["[qa] record  macro (@a), [q] to quit record",                               "normal qa"],
\       ["[@a] execute macro (@a)",                                                   "normal @a"],
\       ["NeoComplCache Enable  (enable  neocomplcache)",                             "NeoComplCacheUnlock | NeoComplCacheEnable"],
\       ["              Disable (disable neocomplcache)",                             "NeoComplCacheDisable | NeoComplCacheLock "],
\       ["file_mru",                                                                  "UniteMenuNest file_mru"],
\       ["history/yank",                                                              "UniteMenuNest history/yank"],
\       ["vimgrep",                                                                   "UniteMenuNest vimgrep"],
\       ["quickfix",                                                                  "UniteMenuNest quickfix"],
\       ["quickrun (QuickRun)",                                                       "QuickRun"],
\       ["line",                                                                      "UniteMenuNest -start-insert line"],
\       ["source",                                                                    "UniteMenuNest source"],
\       ["open .vimrc",                                                               $HOME. "/.vimrc"],
\       ["NeoBundle List",                                                            "NeoBundleList"],
\       ["          Install",                                                         "NeoBundleInstall"],
\       ["          Clean",                                                           "NeoBundleClean"],
\       ["          Update",                                                          "NeoBundleUpdate"],
\   ],
\}
" PENDING
"["[<op>i|] operate Inner word column(|)", "normal vi|"],

" Unite menu:version_controls_git
let g:unite_source_menu_menus.version_controls_git = {
\   "description" : "version_controls_git",
\   "map"         : function("UniteMap"),
\   "candidates"  : [
\       ["git log",    "UniteMenuNest versions/git/log"],
\       ["    status", "UniteMenuNest versions/git/status"],
\   ],
\}

" Unite menu:version_controls_svn
let g:unite_source_menu_menus.version_controls_svn = {
\   "description" : "version_controls_svn",
\   "map"         : function("UniteMap"),
\   "candidates"  : [
\       ["svn diff",   "UniteMenuNest svn/diff"],
\       ["    blame",  "UniteMenuNest svn/blame"],
\       ["    status", "UniteMenuNest svn/status"],
\       ["    log",    "UniteMenuNest versions/svn/log"],
\   ],
\}

"BACKUP
"["register","UniteMenuNest register"],
"["outline","UniteMenuNest outline"],
"["options (only work-file on windows gvim)","Unite toggle-options"],
"["vimrc",$HOME."/.vimrc"],
"["options","Unite toggle-options"],
"["vimrc.registry",$HOME."/.vimrc.registry.".$VIM_PLATFORM],
"["neobundles",s:neobundle_root],
"["OpenUrl","OpenBrowser <url>"],
"" Unite menu:vimrc
"let g:unite_source_menu_menus.vimrc = {
"\   "description" : "vimrc",
"\   "map"         : function("UniteMap"),
"\   "candidates"  : [
"\       ["vimrc",          $HOME. "/.vimrc"],
"\       ["vimrc.registry", g:vimrc_registry],
"\   ],
"\}
"["NeoComplCacheUnlock  (enable neocomplcache)",  "NeoComplCacheUnlock"],
"["NeoComplCacheLock    (disable neocomplcache)", "NeoComplCacheLock"],
"["neobundle", "UniteMenuNest neobundle"],
"["vimrc", "UniteMenuNest menu:vimrc"],
"["[a/], [i/]  A/Inner last searched pattern", "normal a/"],
"["[axb],[ixb] A/Inner X Brackets", "normal axb"],

let g:loaded_unitetunes = 1
let &cpo = s:save_cpo
unlet s:save_cpo
