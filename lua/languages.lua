-- supported languages, the single source for lsp and treesitter.
-- each lsp needs its language server installed on the machine.
return {
	lua        = { lsp = 'lua_ls',    parsers = {} }, -- parser ships with neovim
	typescript = { lsp = 'ts_ls',     parsers = { 'typescript', 'tsx', 'javascript' } },
	html       = { lsp = 'html',      parsers = { 'html' } },
	css        = { lsp = 'cssls',     parsers = { 'css' } },
	python     = { lsp = 'pyright',   parsers = { 'python' } },
	sql        = { lsp = 'sqlls',     parsers = { 'sql' } },
	csharp     = { lsp = 'csharp_ls', parsers = { 'c_sharp' } },
}
