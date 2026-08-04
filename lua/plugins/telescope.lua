vim.pack.add {
  { src = 'https://github.com/nvim-lua/plenary.nvim', name = 'plenary.nvim' },
  { src = 'https://github.com/nvim-telescope/telescope.nvim', name = 'telescope.nvim' },
  { src = 'https://github.com/nvim-telescope/telescope-file-browser.nvim' },
}

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

telescope.load_extension('file_browser')

vim.keymap.set('n', '<leader>o', function()
  telescope.extensions.file_browser.file_browser { path = '%:p:h', select_buffer = true }
end, { noremap = true })

vim.keymap.set('n', '<leader>ff', function()
  local ok = pcall(builtin.git_files, { show_untracked = true })
  if not ok then
    builtin.find_files()
  end
end, { noremap = true })
vim.keymap.set('n', '<leader>fa', function()
  builtin.find_files { hidden = true, no_ignore = true, no_ignore_parent = true }
end, { noremap = true })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { noremap = true })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { noremap = true })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { noremap = true })
