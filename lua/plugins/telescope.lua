local telescope = require('telescope')
local builtin = require('telescope.builtin')

telescope.setup {
  defaults = {
    layout_strategy = 'horizontal',
    layout_config = {
      horizontal = {
        preview_width = 0.5,
      },
    },
  },
}

vim.keymap.set('n', '<leader>ff', builtin.find_files, { noremap = true })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { noremap = true })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { noremap = true })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { noremap = true })
