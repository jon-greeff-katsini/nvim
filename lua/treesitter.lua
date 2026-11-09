vim.pack.add({
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
})

require('nvim-treesitter').install({
  'bash',
  'css',
  'html',
  'javascript',
  'json',
  'lua',
  'markdown',
  'markdown_inline',
  'powershell',
  'python',
  'toml',
  'tsx',
  'typescript',
  'yaml',
})

vim.api.nvim_create_autocmd('FileType', {
  callback = function()
    pcall(vim.treesitter.start)
  end,
})
