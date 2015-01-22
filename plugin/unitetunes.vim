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

"==============================================================================
" UniteSettings
"==============================================================================

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

"==============================================================================
" UniteMenu
"==============================================================================

" Initialize Unite menu:*
if !exists("g:unite_source_menu_menus")
	let g:unite_source_menu_menus = {}
endif

" Unite menu:shortcut
let g:unite_source_menu_menus.shortcut = {
\   "description" : "shortcut",
\   "map"         : function("UniteMap"),
\   "candidates"  : [
\       ["tabmove 0    (tab move first)",                 "tabm0"],
\       ["tabmove 1000 (tab move last)",                  "tabm1000"],
\       ["VimFiler BufferDir",                            "VimFilerBufferDir -tab -auto-cd -status"],
\       ["         Project",                              "VimFilerBufferDir -tab -auto-cd -status -project"],
\       ["[s/] VimFind",                                  "VimFind"],
\       ["[s?] VimGrep",                                  "VimGrep"],
\       ["     Qfreplace",                                "Qfreplace"],
\       ["[^p] CtrlP",                                    "CtrlP"],
\       ["     CtrlP Buffer",                             "CtrlPBuffer"],
\       ["     CtrlP Line",                               "CtrlPLine"],
\       ["     CtrlP ClearCache",                         "CtrlPClearCache"],
\       ["git",                                           "UniteMenuNest menu:version_controls_git"],
\       ["svn",                                           "UniteMenuNest menu:version_controls_svn"],
\       ["OmniSharp GotoDefinition (.cs only)",           "tab split | OmniSharpGotoDefinition"],
\       ["          StartServer    (.cs only)",           "OmniSharpStartServer"],
\       ["          Rename         (.cs only)",           "OmniSharpRename"],
\       ["[ac], [ic]  A/Inner Comment",                   "normal ac"],
\       ["[a,], [i,]  A/Inner function arguments",        "normal a,"],
\       ["[vap],[vip] Visual-mode A/Inner Paragraph",     "normal vap"],
\       ["[sg] OpenBrowserSmartSearch",                   "call openbrowser#_keymapping_smart_search('n')"],
\       ["[^-][^-] toggle comment",                       "TComment"],
\       ["[sr] toggle line",                              "normal sr"],
\       ["[st] toggle tabspace",                          "normal st"],
\       ["[sT] toggle tabchar",                           "normal sT"],
\       ["[qa] record  macro (@a), [q] to quit record",   "normal qa"],
\       ["[@a] execute macro (@a)",                       "normal @a"],
\       ["NeoComplCache Enable  (enable  neocomplcache)", "NeoComplCacheUnlock | NeoComplCacheEnable"],
\       ["              Disable (disable neocomplcache)", "NeoComplCacheDisable | NeoComplCacheLock "],
\       ["file_mru",                                      "UniteMenuNest file_mru"],
\       ["history/yank",                                  "UniteMenuNest history/yank"],
\       ["vimgrep",                                       "UniteMenuNest vimgrep"],
\       ["quickfix",                                      "UniteMenuNest quickfix"],
\       ["quickrun (QuickRun)",                           "QuickRun"],
\       ["line",                                          "UniteMenuNest -start-insert line"],
\       ["source",                                        "UniteMenuNest source"],
\       ["open .vimrc",                                   $HOME. "/.vimrc"],
\       ["NeoBundle List",                                "NeoBundleList"],
\       ["          Install",                             "NeoBundleInstall"],
\       ["          Clean",                               "NeoBundleClean"],
\       ["          Update",                              "NeoBundleUpdate"],
\   ],
\}

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
