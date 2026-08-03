-- Native LSP (nvim 0.12) — no lspconfig plugin needed.
vim.lsp.config('basedpyright', {
  cmd = { 'basedpyright-langserver', '--stdio' },
  capabilities = require('blink.cmp').get_lsp_capabilities(),
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'setup.py', 'requirements.txt', '.git' },
  settings = {
    basedpyright = {
      analysis = { typeCheckingMode = 'standard', autoSearchPaths = true },
    },
  },
})

vim.lsp.enable 'basedpyright'

vim.diagnostic.config { virtual_text = true }
