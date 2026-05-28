vim.pack.add {
  { src = 'https://github.com/mason-org/mason.nvim' },
}

require('mason').setup()

-- Advertise blink.cmp's completion capabilities to every LSP server.
vim.lsp.config('*', {
  capabilities = require('blink.cmp').get_lsp_capabilities(),
})

-- Servers to install via :MasonInstall (or run the command below once):
--   :MasonInstall basedpyright ruff
-- Mason puts their binaries on Neovim's PATH automatically.

-- Find a venv's python interpreter for a given buffer.
-- Honours an active $VIRTUAL_ENV, otherwise looks for .venv/ or venv/
-- in the project root (nearest pyproject.toml / setup.py / .git ancestor).
local function find_venv_python(bufnr)
  if vim.env.VIRTUAL_ENV and vim.env.VIRTUAL_ENV ~= '' then
    return vim.env.VIRTUAL_ENV .. '/bin/python'
  end
  local fname = vim.api.nvim_buf_get_name(bufnr)
  local root = vim.fs.root(fname ~= '' and fname or vim.uv.cwd(), {
    'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', '.git',
  }) or vim.uv.cwd()
  for _, dir in ipairs { '.venv', 'venv' } do
    local py = root .. '/' .. dir .. '/bin/python'
    if vim.uv.fs_stat(py) then
      return py
    end
  end
  return nil
end

-- Push a python interpreter path into a running basedpyright client.
local function apply_python_path(client, py)
  client.settings = vim.tbl_deep_extend('force', client.settings or {}, {
    python = { pythonPath = py },
  })
  client:notify('workspace/didChangeConfiguration', { settings = client.settings })
end

-- basedpyright: type checking + completion
vim.lsp.config('basedpyright', {
  settings = {
    basedpyright = {
      analysis = {
        typeCheckingMode = 'standard',
        autoImportCompletions = true,
        diagnosticMode = 'openFilesOnly',
      },
    },
  },
  on_attach = function(client, bufnr)
    local py = find_venv_python(bufnr)
    if py then
      apply_python_path(client, py)
    end
  end,
})

-- :VenvSet <path-to-python>  — point basedpyright at a specific interpreter
vim.api.nvim_create_user_command('VenvSet', function(opts)
  local py = vim.fn.expand(opts.args)
  for _, client in ipairs(vim.lsp.get_clients { name = 'basedpyright' }) do
    apply_python_path(client, py)
  end
  vim.notify('basedpyright interpreter set to ' .. py)
end, { nargs = 1, complete = 'file' })

-- ruff: fast linting + formatting
vim.lsp.config('ruff', {})

vim.lsp.enable { 'basedpyright', 'ruff' }

-- LSP keymaps, set when a server attaches to a buffer
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local opts = { buffer = args.buf, silent = true }
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', '<leader>f', function()
      vim.lsp.buf.format { async = true }
    end, opts)
    vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
    vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
  end,
})
