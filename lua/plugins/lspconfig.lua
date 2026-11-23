vim.pack.add{

	{ src = "https://github.com/neovim/nvim-lspconfig" }
}

-- enable the language server for each supported language
local servers = {}
for _, language in pairs(require('languages')) do
	table.insert(servers, language.lsp)
end

vim.lsp.enable(servers)
