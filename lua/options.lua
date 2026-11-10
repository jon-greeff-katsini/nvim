vim.o.number = true
vim.o.relativenumber = true
vim.o.clipboard = 'unnamedplus'
vim.o.ignorecase = true
vim.o.smartcase = true

vim.api.nvim_create_autocmd({ 'FileType', 'TermOpen' }, {
  pattern = { 'alpha', 'netrw', 'term://*' },
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
  end,
})
