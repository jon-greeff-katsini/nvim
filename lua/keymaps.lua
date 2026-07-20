-- leader
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- disable arrow keys (use h/j/k/l instead)
for _, mode in ipairs { 'n', 'i', 'v' } do
  vim.keymap.set(mode, '<Left>', '<Nop>')
  vim.keymap.set(mode, '<Right>', '<Nop>')
  vim.keymap.set(mode, '<Up>', '<Nop>')
  vim.keymap.set(mode, '<Down>', '<Nop>')
end
