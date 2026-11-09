vim.pack.add({
  { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range('1') },
  'https://github.com/github/copilot.vim',
})

require('blink.cmp').setup({
  fuzzy = { implementation = 'lua' },
})
