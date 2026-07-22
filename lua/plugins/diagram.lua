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

-- Hide the raw source of diagram code blocks so only the rendered image shows.
--
-- diagram.nvim only overlays an image; it leaves the ```mermaid ... ``` source
-- visible, so the block appears twice (text + picture). We conceal the whole
-- fenced block with `conceal_lines` extmarks.
--
-- `conceal_lines` only hides a line while 'conceallevel' > 0. markview already
-- sets conceallevel=3 in normal/preview modes and conceallevel=0 in insert
-- mode, so the source is hidden in normal mode and reappears for editing in
-- insert mode -- no manual per-mode toggling needed here.

-- Languages diagram.nvim's markdown integration knows how to render.
local diagram_langs = {
  mermaid = true,
  plantuml = true,
  d2 = true,
  gnuplot = true,
}

local conceal_ns = vim.api.nvim_create_namespace 'diagram_source_conceal'

local function conceal_diagram_sources(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype ~= 'markdown' then
    return
  end

  vim.api.nvim_buf_clear_namespace(buf, conceal_ns, 0, -1)

  local ok, parser = pcall(vim.treesitter.get_parser, buf, 'markdown')
  if not ok or not parser then
    return
  end
  local tree = parser:parse()[1]
  if not tree then
    return
  end

  local query = vim.treesitter.query.parse('markdown', [[
    (fenced_code_block
      (info_string (language) @lang)) @block
  ]])

  for _, match in query:iter_matches(tree:root(), buf, 0, -1) do
    local lang_node, block_node
    for id, nodes in pairs(match) do
      local node = nodes[#nodes]
      if query.captures[id] == 'lang' then
        lang_node = node
      elseif query.captures[id] == 'block' then
        block_node = node
      end
    end

    if lang_node and block_node then
      local lang = vim.treesitter.get_node_text(lang_node, buf)
      if diagram_langs[lang] then
        local srow, _, erow, ecol = block_node:range()
        -- A block's range often ends on the line *after* the closing fence at
        -- column 0; step back so we don't conceal an extra content line.
        local last = (ecol == 0) and (erow - 1) or erow

        -- image.nvim anchors the rendered picture to the first line of the
        -- block and reserves its vertical space with virt_lines hung off that
        -- line. If we fully remove that line the image loses its space and
        -- draws over following text, so the first line is kept present -- we
        -- only conceal its *text* (per-character), leaving a blank anchor row.
        local first_line = vim.api.nvim_buf_get_lines(buf, srow, srow + 1, false)[1] or ''
        vim.api.nvim_buf_set_extmark(buf, conceal_ns, srow, 0, {
          end_col = #first_line,
          conceal = '',
        })

        -- The remaining lines carry no image, so collapse them away entirely.
        if last > srow then
          vim.api.nvim_buf_set_extmark(buf, conceal_ns, srow + 1, 0, {
            end_row = last,
            conceal_lines = '',
          })
        end
      end
    end
  end
end

-- Refresh the conceal marks on the same events diagram.nvim redraws on, so the
-- hidden source and the rendered image stay in sync.
vim.api.nvim_create_autocmd({ 'BufWinEnter', 'InsertLeave', 'TextChanged' }, {
  group = vim.api.nvim_create_augroup('DiagramSourceConceal', { clear = true }),
  pattern = '*.md',
  callback = function(args)
    conceal_diagram_sources(args.buf)
  end,
})
