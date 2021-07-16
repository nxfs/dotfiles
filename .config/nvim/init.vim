" line numbers
set nu

" spaces instead of tabs
set smarttab

" git
au FileType gitcommit set tw=75

" remove trailing spaces on save
autocmd BufWritePre * :%s/\s\+$//e
autocmd BufWritePre *.cpp :retab

" background
set background=dark

" reopen file at the same location
if has("autocmd")
  au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
    \| exe "normal! g'\"" | endif
endif

" specify a directory for plugins
" - for Neovim: stdpath('data') . '/plugged'
" - avoid using standard Vim directory names like 'plugin'
call plug#begin(stdpath('data') . '/plugged')

" fuzzy file opener
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" language server
Plug 'prabirshrestha/vim-lsp'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'
Plug 'mattn/vim-lsp-settings'

" debugger
Plug 'puremourning/vimspector'

" typescript highlight
Plug 'leafgarland/typescript-vim'

" initialize plugin system
call plug#end()

" debugger config
let g:vimspector_enable_mappings = 'HUMAN'

" rust lsp config
if executable('rust-analyzer')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'rust-analyzer',
        \ 'cmd': {server_info->['rust-analyzer']},
        \ 'allowlist': ['rust'],
        \ })
endif

" c/cpp lsp config
if executable('clangd') && filereadable("compile_commands.json")
    au User lsp_setup call lsp#register_server({
        \ 'name': 'clangd',
        \ 'cmd': {server_info->['clangd']},
        \ 'allowlist': ['c', 'cpp'],
        \ })
endif

" lsp shortcuts
function! s:on_lsp_buffer_enabled() abort
    if (filereadable(".lspdisable"))
	:call lsp#disable_diagnostics_for_buffer()
	return
    endif

    setlocal omnifunc=lsp#complete
    setlocal signcolumn=yes
    if exists('+tagfunc') | setlocal tagfunc=lsp#tagfunc | endif
    nmap <buffer> gd <plug>(lsp-definition)
    nmap <buffer> gs <plug>(lsp-workspace-symbol-search)
    nmap <buffer> gS <plug>(lsp-document-symbol-search)
    nmap <buffer> gr <plug>(lsp-references)
    nmap <buffer> gi <plug>(lsp-implementation)
    nmap <buffer> gt <plug>(lsp-type-definition)
    nmap <buffer> <leader>rn <plug>(lsp-rename)
    nmap <buffer> [g <plug>(lsp-previous-diagnostic)
    nmap <buffer> ]g <plug>(lsp-next-diagnostic)
    nmap <buffer> K <plug>(lsp-hover)
    inoremap <buffer> <expr><c-f> lsp#scroll(+4)
    inoremap <buffer> <expr><c-d> lsp#scroll(-4)

    " autoformat rust
    let g:lsp_format_sync_timeout = 1000
    autocmd! BufWritePre *.rs call execute('LspDocumentFormatSync')

    " ctags like mappings
    nmap <buffer> <C-]> :LspDefinition<CR>

    " refer to doc to add more commands
endfunction

augroup lsp_install
    au!
    " call s:on_lsp_buffer_enabled only for languages that has the server registered.
   autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
augroup END

" sincs lsp uses quick fix to display list of choices, close quick fix after
" selecting an entry
:autocmd FileType qf nnoremap <buffer> <CR> <CR>:cclose<CR>

" autocomplete
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <cr>    pumvisible() ? asyncomplete#close_popup() : "\<cr>"

" remamp ctrl+p (open file) and ctrl+e (recent files) to fzf
if (isdirectory(".git"))
	nmap <C-p> :GFiles<CR>
else
	nmap <C-p> :FZF<CR>
endif
nmap <C-e> :History<CR>

" cscope
if has("cscope")
	set csprg=cscope
	set csto=0
	set cst
	" add any database in current directory
	if filereadable("cscope.out")
	    silent cs add cscope.out
	" else add database pointed to by environment
	elseif $CSCOPE_DB != ""
	    silent cs add $CSCOPE_DB
	endif

        " lsp-like mappings
        nmap gd :cs find g <C-R>=expand("<cword>")<CR><CR>
        nmap gr :cs find s <C-R>=expand("<cword>")<CR><CR>
	nmap gD :cs find g<Space>
	nmap gs :cs find s<Space>

	nmap <C-\>s :cs find s <C-R>=expand("<cword>")<CR><CR>
	nmap <C-\>g :cs find g <C-R>=expand("<cword>")<CR><CR>
    	nmap <C-\>c :cs find c <C-R>=expand("<cword>")<CR><CR>
    	nmap <C-\>t :cs find t <C-R>=expand("<cword>")<CR><CR>
    	nmap <C-\>e :cs find e <C-R>=expand("<cword>")<CR><CR>
    	nmap <C-\>f :cs find f <C-R>=expand("<cfile>")<CR><CR>
    	nmap <C-\>i :cs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
    	nmap <C-\>d :cs find d <C-R>=expand("<cword>")<CR><CR>
endif

nnoremap <A-down> :m .+1<CR>==
nnoremap <A-up> :m .-2<CR>==
inoremap <A-down> <Esc>:m .+1<CR>==gi
inoremap <A-up> <Esc>:m .-2<CR>==gi
vnoremap <A-down> :m '>+1<CR>gv=gv
vnoremap <A-up> :m '<-2<CR>gv=gv

" more intuitive wild menu
set wildcharm=<C-Z>
cnoremap <expr> <up> wildmenumode() ? "\<left>" : "\<up>"
cnoremap <expr> <down> wildmenumode() ? "\<right>" : "\<down>"
cnoremap <expr> <left> wildmenumode() ? "\<up>" : "\<left>"
cnoremap <expr> <right> wildmenumode() ? " \<bs>\<C-Z>" : "\<right>"
set wildmode=longest:full

" auto indent on paste
:nnoremap p ]p

" load local .nvimrc
set exrc
set secure
