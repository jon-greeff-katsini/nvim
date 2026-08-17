# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Neovim configuration repository (`~/.config/nvim`) that manages editor settings, keymaps, and plugins using Neovim's built-in package management system (`vim.pack`).

## Project Structure

- **`init.lua`**: Entry point; requires core modules in order: `options`, `keymaps`, `plugins`
- **`lua/options.lua`**: Editor options and settings (currently minimal)
- **`lua/keymaps.lua`**: Key mappings (leader key is set to space)
- **`lua/plugins/`**: Plugin configurations
  - `init.lua`: Requires all plugin modules
  - `catppuccin.lua`: Color scheme setup
  - `nvim-tree.lua`: File explorer with icons
- **`nvim-pack-lock.json`**: Lock file tracking exact plugin revisions (similar to a package-lock.json)

## Plugin Management

This configuration uses Neovim's native `vim.pack` system (no external package manager like packer.nvim or lazy.nvim).

**Key plugins:**
- **catppuccin**: Color scheme
- **nvim-tree.lua**: File tree explorer
- **nvim-web-devicons**: Icon support

**To add a new plugin:**
1. Create a new file in `lua/plugins/` (e.g., `lua/plugins/foobar.lua`)
2. Add `vim.pack.add { { src = 'https://github.com/user/repo' } }` to load it
3. Call `require('foobar')` from `lua/plugins/init.lua`
4. Run `:PackerSync` in Neovim (or restart Neovim) to fetch the plugin
5. The `nvim-pack-lock.json` will be updated with the plugin revision

**To update plugin revisions:**
The lock file pins exact commits. Update manually by editing `nvim-pack-lock.json` and restarting Neovim, or use Neovim commands to manage plugin versions.

## Testing Configuration

- **Test the config:** Restart Neovim or reload with `:source $MYVIMRC` (or `:luafile %` for Lua files)
- **Check for errors:** Run `:checkhealth` in Neovim to diagnose issues
- **Inspect plugin status:** Use `:scriptnames` to see loaded scripts, or check `~/.local/share/nvim/site/pack/` for installed plugins

## Key Conventions

- Leader key is space (set in `keymaps.lua`)
- All configuration is Lua-based (no Vimscript)
- Plugins are loaded in order: catppuccin → nvim-tree (order matters for dependencies)
