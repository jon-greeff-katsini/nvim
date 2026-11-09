vim.pack.add({
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/nvim-telescope/telescope.nvim',
  'https://github.com/nvim-telescope/telescope-file-browser.nvim',
})

require('telescope').setup({
  extensions = {
    file_browser = {
      hijack_netrw = true,
      initial_mode = 'normal',
      auto_depth = true,
      prompt_title = '[Tab] Search',
      mappings = {
        i = {
          ['<Tab>'] = function()
            vim.cmd('stopinsert')
          end,
        },
        n = {
          ['<Tab>'] = function()
            vim.cmd('startinsert!')
          end,
        },
      },
    },
  },
})

require('telescope').load_extension('file_browser')
