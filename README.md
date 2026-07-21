# nvim config

Personal Neovim config using the built-in `vim.pack` plugin manager (no lazy.nvim/packer). Plugin revisions are pinned in `nvim-pack-lock.json`.

## Structure

- `init.lua` — loads `options` → `keymaps` → `plugins`
- `lua/options.lua` — editor options (relative numbers, smart search, system clipboard, cursorline)
- `lua/keymaps.lua` — leader = space; arrow keys disabled (hjkl only)
- `lua/plugins/` — one file per plugin, loaded from `lua/plugins/init.lua`

## Plugins

- **catppuccin** — colorscheme
- **alpha-nvim** — start screen
- **nvim-tree** — file explorer (`<leader>e`)
- **lualine** — statusline (catppuccin theme)
- **telescope** — fuzzy finder
- **nvim-treesitter** — syntax highlighting (python, toml, json, yaml, bash, lua, markdown)
- **markview** — inline markdown rendering
- **blink.cmp** — completion
- **mason** + LSP — `basedpyright` and `ruff` enabled via `vim.lsp.enable`

## Keybindings

| Key | Action |
|-----|--------|
| `<leader>e` | Toggle file tree |
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>fb` | Buffers |
| `<leader>fh` | Help tags |
| `gd` / `gr` | Go to definition / references |
| `K` | Hover docs |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action |
| `<leader>f` | Format buffer |
| `[d` / `]d` | Prev / next diagnostic |

## Adding a plugin

1. New file in `lua/plugins/foo.lua` with `vim.pack.add { { src = '...' } }` plus setup
2. `require('plugins.foo')` in `lua/plugins/init.lua`
3. Restart Neovim to fetch it
