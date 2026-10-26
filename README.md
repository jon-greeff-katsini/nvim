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
- **codediff.nvim + review.nvim**: changed-file tree, side-by-side diffs, and local review comments sent to Codex

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

## Review changes with Codex

`Space c r` opens a local code review: a changed-file tree, side-by-side diffs, and inline comments. Git supplies the change list; staging and discard shortcuts are disabled in this view.

| Key | Action |
|-----|--------|
| `<leader>cr` | Open the review view |
| `i` on a diff line | Add a typed review comment |
| `v` / `V`, select code, then `i` | Comment on exact text / a range of lines |
| `F` in a diff pane | Comment on the whole file |
| `e` / `d` | Edit / delete the comment at the cursor |
| `c` | List comments |
| `j` / `k` in the file tree | Move through entries |
| `<Enter>` in the file tree | Open the selected diff and focus its new side |
| `<Tab>` / `<S-Tab>` | Switch directly between the tree and diff |
| `[` / `]` | Previous / next changed file |
| `r` | Mark the file reviewed and move on |
| `<leader>sr` or `:ReviewCodex` | Put feedback and file attachments into Codex |
| `q` | Return to the file tree; close the review when already in the tree |

- In a comment popup, `Ctrl-C` saves and closes; `Esc` discards the unsaved draft. Neither action sends anything to Codex. On a commented line, `d` deletes the saved comment after confirmation.
- Character selections include the exact selected text and columns in Codex's feedback. Whole-line selections retain their line range. `h` and `l` keep their normal cursor movement; use `Tab` to switch between the tree and diff.
- Sending a review fills Codex's native input. Edit the feedback there and press Enter when ready. It never submits automatically, exports a Markdown file, or changes your clipboard.
- The attachment panel contains the commented excerpts with filenames, line numbers, diff sides, and revisions, plus one current snapshot of each available file, including unsaved edits.
- Excerpts capture the code when the comment is created, so feedback on removed or changed lines keeps its original context. Deleted files still have their reviewed excerpt.
- Comments and excerpts persist in review.nvim's local per-repository JSON store. Closing or staging a review keeps them. After you press Enter in Codex and the attachment hook consumes the review, submitted comments are archived and cleared. Comments added or edited since staging stay available. `:Review clear` also archives and clears comments manually.
- If Codex needs setup or hook approval, finish that first and press `Space s r` again. The review stays available. Feedback is refused if your existing Codex session belongs to another repository.

```text
Changed-file tree + diff → Comments → Space s r → Codex input + file context
                                                 ↓
                                            Edit → Enter
```

Review checks (the UI check creates an isolated temporary Git repository):

```sh
nvim --clean --headless -l tests/codex_review.lua
nvim --clean --headless -l tests/codex_review_ui.lua
```

## Adding a plugin

1. New file in `lua/plugins/foo.lua` with `vim.pack.add { { src = '...' } }` plus setup
2. `require('plugins.foo')` in `lua/plugins/init.lua`
3. Restart Neovim to fetch it
