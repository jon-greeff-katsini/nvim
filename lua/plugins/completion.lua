vim.pack.add {
  { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range('1.*') },
}

require('blink.cmp').setup {
  -- 'default' = C-y to accept, C-n/C-p or arrows to navigate,
  -- C-space to open the menu, C-e to hide it.
  keymap = { preset = 'default' },

  appearance = { nerd_font_variant = 'mono' },

  -- Show documentation popup automatically next to the menu.
  completion = {
    documentation = { auto_show = true, auto_show_delay_ms = 200 },
  },

  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer' },
  },

  -- Rust-based fuzzy matcher, downloaded as a prebuilt binary.
  fuzzy = { implementation = 'prefer_rust_with_warning' },
}
