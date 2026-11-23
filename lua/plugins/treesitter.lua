vim.pack.add{
	{
		src="https://github.com/nvim-treesitter/nvim-treesitter"
	}
}

-- install the parsers for each supported language
local parsers = {}
for _, language in pairs(require('languages')) do
	vim.list_extend(parsers, language.parsers)
end

require('nvim-treesitter').install(parsers)
