-- Inline rendering of mermaid (and other) diagrams inside markdown buffers.
--
-- Requires external tools (installed via Homebrew):
--   * mmdc   -- mermaid-cli, renders mermaid blocks to images
--   * magick -- ImageMagick, used by image.nvim to process images
-- Ghostty speaks the kitty graphics protocol, which image.nvim uses to draw
-- the images directly in the buffer.

vim.pack.add {
  { src = 'https://github.com/3rd/image.nvim' },
  { src = 'https://github.com/3rd/diagram.nvim' },
}

-- mmdc drives a headless browser through puppeteer. Rather than downloading a
-- separate chromium, point it at the Google Chrome that's already installed.
vim.env.PUPPETEER_EXECUTABLE_PATH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'

require('image').setup {
  backend = 'kitty',
  processor = 'magick_cli', -- use the `magick` CLI (no luarock needed)
  integrations = {},        -- diagram.nvim handles the diagram blocks itself
}

require('diagram').setup {
  integrations = {
    require('diagram.integrations.markdown'),
  },
  renderer_options = {
    mermaid = {
      theme = 'dark',
      background = 'transparent',
      scale = 2,
    },
  },
}
