vim.pack.add {
  { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range '1' },
}

require('blink.cmp').setup {
  keymap = { preset = 'default' }, -- <C-space> open, <C-n>/<C-p> cycle, <C-y> accept
  sources = { default = { 'lsp', 'path', 'buffer' } },
  fuzzy = { implementation = 'prefer_rust' },
  completion = {
    documentation = { auto_show = true },
    ghost_text = { enabled = true },
  },
  signature = { enabled = true },
}
