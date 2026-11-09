vim.pack.add({ 'https://github.com/neovim/nvim-lspconfig' })

vim.lsp.config('powershell_es', {
  bundle_path = vim.fn.stdpath('data') .. '/PowerShellEditorServices',
})

vim.lsp.enable({
  'pyright',
  'html',
  'cssls',
  'ts_ls',
  'bashls',
  'powershell_es',
  'yamlls',
  'jsonls',
})
