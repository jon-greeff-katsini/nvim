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

local capabilities = require('blink.cmp').get_lsp_capabilities()

vim.lsp.config('html', {
  cmd = { 'vscode-html-language-server', '--stdio' },
  capabilities = capabilities,
  filetypes = { 'html' },
  root_markers = { 'package.json', '.git' },
})

vim.lsp.config('cssls', {
  cmd = { 'vscode-css-language-server', '--stdio' },
  capabilities = capabilities,
  filetypes = { 'css', 'scss', 'less' },
  root_markers = { 'package.json', '.git' },
})

vim.lsp.config('ts_ls', {
  cmd = { 'typescript-language-server', '--stdio' },
  capabilities = capabilities,
  filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
  root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },
})

vim.lsp.enable { 'html', 'cssls', 'ts_ls' }

vim.diagnostic.config { virtual_text = true }
