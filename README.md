# nvim config

Personal Neovim config using the built-in `vim.pack` plugin manager (no lazy.nvim/packer). Plugin revisions are pinned in `nvim-pack-lock.json`.

## Structure

- `init.lua` — loads `options` → `keymaps` → `plugins`
- `lua/options.lua` — editor options (relative numbers, smart search, system clipboard, cursorline)
- `lua/keymaps.lua` — leader = space
- `lua/plugins/` — one file per plugin, loaded from `lua/plugins/init.lua`

## Plugins

- **alpha-nvim** — start screen (stock `startify` theme)
- **catppuccin** — colorscheme
- **lualine** — statusline (`catppuccin-nvim` theme, global statusline, no separators)
- **telescope** — fuzzy finder, plus the **telescope-file-browser** extension
- **nvim-treesitter** — syntax highlighting (installs python, toml, json, yaml, bash; also started for lua and markdown)

## Keybindings

| Key | Action |
|-----|--------|
| `<leader>e` | netrw (`:Ex`) |
| `<leader>o` | File browser (telescope), opens at the current file's directory |
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>fb` | Buffers |
| `<leader>fh` | Help tags |

### Inside the file browser

Press `<Esc>` for normal mode, then: `c` create (trailing `/` makes a folder), `r` rename,
`d` delete, `m` move, `y` copy, `g` parent dir, `h` toggle hidden files.
Insert-mode equivalents use Alt (`<A-c>` etc.) — unreliable in macOS terminals.

## Adding a plugin

1. New file in `lua/plugins/foo.lua` with `vim.pack.add { { src = '...' } }` plus setup
2. `require('plugins.foo')` in `lua/plugins/init.lua`
3. Restart Neovim to fetch it
