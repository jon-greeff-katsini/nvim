vim.pack.add {
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
}

require('nvim-treesitter').install { 'python', 'toml', 'json', 'yaml', 'bash', 'markdown', 'markdown_inline' }

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'python', 'toml', 'json', 'yaml', 'sh', 'lua', 'markdown' },
  callback = function()
    vim.treesitter.start()
  end,
})
