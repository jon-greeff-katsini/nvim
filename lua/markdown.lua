vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    local data = ev.data
    if data.spec.name == 'markdown-preview.nvim' and (data.kind == 'install' or data.kind == 'update') then
      vim.system({ 'npm', 'install' }, { cwd = data.path .. '/app' }):wait()
    end
  end,
})

vim.pack.add({
  'https://github.com/iamcco/markdown-preview.nvim',
})

local preview_path = vim.pack.get({ 'markdown-preview.nvim' })[1].path
local full_width_css = vim.fn.stdpath('cache') .. '/markdown-preview-full-width.css'
local base_css = vim.fn.readfile(preview_path .. '/app/_static/markdown.css')
table.insert(base_css, '#page-ctn { max-width: none !important; }')
vim.fn.writefile(base_css, full_width_css)
vim.g.mkdp_markdown_css = full_width_css
