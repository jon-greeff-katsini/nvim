vim.pack.add {
  { src = 'https://github.com/github/copilot.vim' },
}

-- Use the language server bundled with the plugin instead of fetching it via npx on every start
vim.g.copilot_npx_command = 0

-- <Tab> belongs to blink.cmp (super-tab preset), so accept suggestions with <C-y>
vim.g.copilot_no_tab_map = true
vim.keymap.set('i', '<C-y>', 'copilot#Accept("\\<C-y>")', {
  expr = true,
  replace_keycodes = false,
  desc = 'Accept Copilot suggestion',
})
