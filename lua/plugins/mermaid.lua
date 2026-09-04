vim.pack.add {
  { src = 'https://github.com/searleser97/mermaid-nvim' },
}

require('mermaid-nvim').setup {
  cmd = { 'termaid', '--gap', '2', '--padding-x', '0', '--padding-y', '0' },
  -- Marker group: every diagram line arrives tagged with it and gets
  -- recoloured per character below.
  highlights = { diagram = 'MermaidDiagram' },
}

-- Colours ------------------------------------------------------------------
--
-- termaid only colours its output through the optional rich package, and
-- mermaid-nvim would display those escape codes as literal text, so the
-- plugin paints every diagram line with a single highlight group (Comment by
-- default). Recolour each rendered line by character class instead: box
-- borders, shape decorators, arrowheads, node labels and edge labels.

local function charset(s)
  local set = {}
  for _, ch in ipairs(vim.fn.split(s, '\\zs')) do
    set[ch] = true
  end
  return set
end

-- Glyph sets taken from termaid's renderer package.
local BORDER = charset '─│└┘┐┌╭╰╮╯├┤┬┴┼┄┆┃━║═╔╗╚╝╋┊▏▎—'
local SHAPE = charset '◆◇◯●◉◈■█░▒▓▄▀▌▚▞★'
local ARROW = charset '►◄▲▼▶◁▷△▽→○×✖╳'
-- Glyphs that form the vertical sides of a node box. Text bounded by these on
-- both sides is a node label; anything else is an edge label. Rounded corners
-- count only when the text touches them directly (cylinder and stadium tops
-- like ╰Database╯), since edge labels often sit next to a neighbouring box.
local SIDE = charset '│┃┆║├┤◇'
local ROUND = charset '╭╮╰╯'

local function define_highlights()
  local function fg_of(group)
    local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
    return hl.fg
  end
  local function hl(name, opts)
    opts.default = true
    vim.api.nvim_set_hl(0, name, opts)
  end
  hl('MermaidDiagram', {})
  hl('MermaidBorder', { fg = fg_of 'Function' })
  hl('MermaidShape', { fg = fg_of 'Keyword' })
  hl('MermaidArrow', { fg = fg_of 'Constant', bold = true })
  hl('MermaidLabel', { fg = fg_of 'Normal', bold = true })
  hl('MermaidEdgeLabel', { fg = fg_of 'String', italic = true })
end

define_highlights()
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('MermaidColours', { clear = true }),
  callback = define_highlights,
})

local CLASS_GROUP = {
  space = 'MermaidDiagram',
  border = 'MermaidBorder',
  shape = 'MermaidShape',
  arrow = 'MermaidArrow',
  label = 'MermaidLabel',
  edge_label = 'MermaidEdgeLabel',
}

---Split one rendered line into { text, hl_group } chunks.
---@param line string
---@return { [1]: string, [2]: string }[]
local function colour_line(line)
  local chars = vim.fn.split(line, '\\zs')
  local n = #chars
  local classes = {}
  for i, ch in ipairs(chars) do
    if ch == ' ' then
      classes[i] = 'space'
    elseif BORDER[ch] then
      classes[i] = 'border'
    elseif SHAPE[ch] then
      classes[i] = 'shape'
    elseif ARROW[ch] then
      classes[i] = 'arrow'
    else
      classes[i] = 'text'
    end
  end

  local chunks = {}
  local i = 1
  while i <= n do
    local cls = classes[i]
    local j = i
    while j < n do
      if classes[j + 1] == cls then
        j = j + 1
      elseif cls == 'text' and classes[j + 1] == 'space' then
        -- Keep multi-word labels together: skip spaces followed by more text.
        local k = j + 1
        while k <= n and classes[k] == 'space' do
          k = k + 1
        end
        if k <= n and classes[k] == 'text' then
          j = k
        else
          break
        end
      else
        break
      end
    end

    if cls == 'text' then
      local left, right = i - 1, j + 1
      while left >= 1 and classes[left] == 'space' do
        left = left - 1
      end
      while right <= n and classes[right] == 'space' do
        right = right + 1
      end
      local function side(idx, touching)
        local ch = chars[idx]
        return SIDE[ch] or (touching and ROUND[ch]) or false
      end
      local boxed = left >= 1 and right <= n and side(left, left == i - 1) and side(right, right == j + 1)
      cls = boxed and 'label' or 'edge_label'
    end

    chunks[#chunks + 1] = { table.concat(chars, '', i, j), CLASS_GROUP[cls] }
    i = j + 1
  end
  if #chunks == 0 then
    chunks[1] = { '', 'MermaidDiagram' }
  end
  return chunks
end

local renderer = require 'mermaid-nvim.renderer'

-- Inline diagrams: recolour the chunks before they become virtual lines.
local apply_extmarks = renderer.apply_extmarks
renderer.apply_extmarks = function(buf, block, result)
  local coloured = vim.tbl_extend('force', {}, result)
  coloured.chunks = {}
  for idx, line_chunks in ipairs(result.chunks or {}) do
    if #line_chunks == 1 and line_chunks[1][2] == 'MermaidDiagram' then
      coloured.chunks[idx] = colour_line(line_chunks[1][1])
    else
      coloured.chunks[idx] = line_chunks
    end
  end
  return apply_extmarks(buf, block, coloured)
end

-- Float and tab previews: the plugin writes plain lines with no highlight,
-- so colour them with extmarks after each content update.
local colour_ns = vim.api.nvim_create_namespace 'mermaid_colours'
local replace_content = renderer.replace_content
renderer.replace_content = function(buf, win, new_output, opts)
  replace_content(buf, win, new_output, opts)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, colour_ns, 0, -1)
  for row, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    local col = 0
    for _, chunk in ipairs(colour_line(line)) do
      local text, group = chunk[1], chunk[2]
      if #text > 0 and group ~= 'MermaidDiagram' then
        pcall(vim.api.nvim_buf_set_extmark, buf, colour_ns, row - 1, col, {
          end_col = col + #text,
          hl_group = group,
        })
      end
      col = col + #text
    end
  end
end

-- mermaid-nvim draws the diagram as virtual lines above the block but leaves
-- the ```mermaid source visible below it, so every block shows twice. Hide
-- the source of each block that currently has a rendered diagram, two layers
-- deep:
--
--  * conceal_lines extmarks hide the lines visually. They only apply while
--    conceallevel > 0; markview sets it to 3 in normal mode and 0 in insert,
--    so the source reappears automatically when editing.
--  * a closed manual fold over the same lines makes the cursor cross the
--    whole hidden region in one step instead of walking every hidden line.
--    The fold header row is itself hidden by the conceal_lines mark on it.
--
-- The opening fence line stays outside both: the diagram's virtual lines and
-- the Expand button are anchored to it, and virtual lines don't display when
-- their anchor sits inside a closed fold.
local conceal_ns = vim.api.nvim_create_namespace 'mermaid_source_conceal'

-- Folds under the cursor open on any insert-mode command, so arrowing into a
-- hidden block while inserting reveals it for editing.
vim.opt.foldopen:append 'insert'

local function conceal_mermaid_sources(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype ~= 'markdown' then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, conceal_ns, 0, -1)

  -- Rows that currently have a rendered diagram (blocks toggled to source
  -- mode or cleared have no virt_lines extmark, so their source stays open).
  local mermaid_ns = vim.api.nvim_get_namespaces()['mermaid_nvim']
  if not mermaid_ns then
    return
  end
  local rendered = {}
  for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, mermaid_ns, 0, -1, { details = true })) do
    if mark[4].virt_lines then
      rendered[mark[2]] = true
    end
  end

  local ok, parser = pcall(vim.treesitter.get_parser, buf, 'markdown')
  if not ok or not parser then
    return
  end
  local tree = parser:parse()[1]
  if not tree then
    return
  end

  local query = vim.treesitter.query.parse(
    'markdown',
    [[
      (fenced_code_block
        (info_string (language) @lang)) @block
    ]]
  )

  -- 0-indexed rows to hide per block: body plus closing fence.
  local ranges = {} ---@type { first: integer, last: integer, hidden: boolean }[]
  for _, match in query:iter_matches(tree:root(), buf) do
    local lang_node = match[1] and match[1][1]
    local block_node = match[2] and match[2][1]
    if lang_node and block_node and vim.treesitter.get_node_text(lang_node, buf) == 'mermaid' then
      local srow, _, erow, ecol = block_node:range()
      -- If the block ends at col 0 the range spills onto the next line.
      local last = (ecol == 0) and erow - 1 or erow
      if last > srow then
        ranges[#ranges + 1] = { first = srow + 1, last = last, hidden = rendered[srow] == true }
      end
    end
  end

  for _, range in ipairs(ranges) do
    if range.hidden then
      for row = range.first, range.last do
        pcall(vim.api.nvim_buf_set_extmark, buf, conceal_ns, row, 0, { conceal_lines = '' })
      end
    end
  end

  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if vim.wo[win].foldmethod == 'manual' then
      -- Empty foldtext renders the fold's first line transparently, so in
      -- insert mode (where conceal is off) a folded block shows a dim
      -- ```mermaid line instead of the default "+-- N lines" banner.
      vim.wo[win].foldtext = ''
      vim.api.nvim_win_call(win, function()
        for _, range in ipairs(ranges) do
          local first, last = range.first + 1, range.last + 1
          if last > first then
            vim.cmd(('silent! %d,%dfolddelete'):format(first, last))
            if range.hidden then
              pcall(vim.cmd, ('%d,%dfold'):format(first, last))
              vim.cmd(('silent! %dfoldclose'):format(first))
            end
          end
        end
      end)
    end
  end
end

vim.api.nvim_create_autocmd({ 'BufWinEnter', 'InsertLeave', 'TextChanged', 'CursorHold' }, {
  group = vim.api.nvim_create_augroup('MermaidSourceConceal', { clear = true }),
  pattern = '*.md',
  callback = function(args)
    conceal_mermaid_sources(args.buf)
    -- The diagram extmarks appear asynchronously (external termaid process,
    -- plus a 300ms debounce on text changes), so run again after they land.
    for _, delay in ipairs { 500, 1500 } do
      vim.defer_fn(function()
        conceal_mermaid_sources(args.buf)
      end, delay)
    end
  end,
})
