vim.pack.add {
  { src = 'https://github.com/nvim-tree/nvim-web-devicons' },
  { src = 'https://github.com/nvim-tree/nvim-tree.lua' },
}

require('nvim-tree').setup()

vim.keymap.set('n', '<leader>e', '<cmd>NvimTreeToggle<cr>', { noremap = true, silent = true })
