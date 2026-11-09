vim.o.number = true
vim.o.relativenumber = true
vim.o.clipboard = 'unnamedplus'
vim.o.ignorecase = true
vim.o.smartcase = true

vim.api.nvim_set_hl(0, 'RealLineNr', { fg = '#9CAF88' })
vim.o.statuscolumn = '%s%#LineNr#%3{v:virtnum ? "" : v:relnum} %#RealLineNr#%-3{v:virtnum ? "" : v:lnum} '

vim.api.nvim_create_autocmd({ 'FileType', 'TermOpen' }, {
  pattern = { 'alpha', 'netrw', 'term://*' },
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.statuscolumn = ''
  end,
})
