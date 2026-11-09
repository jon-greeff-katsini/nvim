vim.pack.add({
  'https://github.com/nvim-tree/nvim-web-devicons',
  'https://github.com/nvim-lualine/lualine.nvim',
})

local function is_terminal()
  return vim.bo.buftype == 'terminal'
end

local pane_title = {
  lualine_c = {
    {
      'filename',
      symbols = { modified = '●' },
      cond = function()
        return not is_terminal()
      end,
    },
    {
      function()
        return 'Terminal'
      end,
      cond = is_terminal,
    },
  },
}

require('lualine').setup({
  options = {
    globalstatus = true,
    disabled_filetypes = { winbar = { 'alpha', 'netrw' } },
  },
  winbar = pane_title,
  inactive_winbar = pane_title,
})
