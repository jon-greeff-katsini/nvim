vim.pack.add {
  { src = 'https://github.com/nvim-lua/plenary.nvim', name = 'plenary.nvim' },
  { src = 'https://github.com/nvim-telescope/telescope.nvim', name = 'telescope.nvim' },
  { src = 'https://github.com/nvim-telescope/telescope-file-browser.nvim' },
}


local builtin = require('telescope.builtin')

-- update keymaps for telescope
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
