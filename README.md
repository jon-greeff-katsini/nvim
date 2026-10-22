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

## Codex popup

Uses your installed `codex` CLI, Python 3, and your existing login and permissions. No additional plugin is needed.

| Key | Action |
|-----|--------|
| `<leader>ac` | Show or hide the floating Codex terminal |
| `<leader>af` | Attach the current file and open Codex |
| `<leader>as` in Visual mode | Attach selected code and open Codex |
| `<leader>ax` | Preview and remove attachments with Telescope |

- Type directly into the Codex terminal and press Enter normally. There is no separate draft or send shortcut.
- The panel below Codex shows pending attachments: filenames, line ranges, and numbered source text.
- `Ctrl-G` switches between Codex and the attachment panel; `Ctrl-P` also focuses attachments for scrolling.
- `Ctrl-X` opens the attachment picker. Enter removes the chosen attachment or clears all; Escape cancels.
- `Ctrl-C` hides the popup and keeps Codex running.
- Attachments capture unsaved buffer text when added. Adding the same file again refreshes its snapshot.
- A session-local `UserPromptSubmit` hook delivers pending context when Codex submits your next prompt. The panel clears after the hook consumes it. Slash commands and approval menus keep their normal behaviour.
- Codex requires review of new hooks. At first launch, choose “Review hooks” and trust the `attach.py` command labelled “Adding Neovim attachments”; `/hooks` also opens this review later. Until trusted, the hook is skipped and context stays pending. See [Codex hook trust](https://learn.chatgpt.com/docs/hooks#review-and-trust-hooks).
- Context already sent stays in the conversation history.
- Hiding the popup preserves the process and pending attachments until you quit Neovim. If Codex exits, hide and reopen the popup to restart it.
- Codex starts in the first file's Git root, or Neovim's current directory outside a Git repository. That session keeps its working directory when you switch files.
- The popup launches Codex without its shared daemon so the hook inherits this Neovim instance's private attachment path. Other Codex sessions are unaffected, and no global hook configuration is changed.
- Codex's normal controls, including Escape and multiline input, work in Terminal mode. `Ctrl-C`, `Ctrl-G`, `Ctrl-P`, and `Ctrl-X` are reserved for the popup.

Restart Neovim to load the bindings, or run `:lua require('codex').setup()` in an existing session.

Checks (Neovim 0.12+, Python 3, and the installed Telescope/Plenary plugins):

```sh
nvim --clean --headless -l tests/codex_context.lua
nvim --clean --headless -l tests/codex_terminal.lua
python3 tests/codex_hook.py
```

## Adding a plugin

1. New file in `lua/plugins/foo.lua` with `vim.pack.add { { src = '...' } }` plus setup
2. `require('plugins.foo')` in `lua/plugins/init.lua`
3. Restart Neovim to fetch it
