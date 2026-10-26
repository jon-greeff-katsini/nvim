vim.opt.rtp:prepend(vim.fn.getcwd())
local review = require('codex.review')
local root = vim.fn.tempname()
vim.fn.mkdir(root, 'p')
local path = root .. '/example.lua'
vim.fn.writefile({ 'local current = 1', 'return current' }, path)
local buf = vim.fn.bufadd(path)
vim.fn.bufload(buf)
vim.api.nvim_buf_set_lines(buf, 0, 1, false, { 'local unsaved = 2' })
local comments = {
  { id = 'one', file = 'example.lua', line = 1, line_end = 2, side = 'new', type = 'suggestion', text = 'Extract a helper',
    codex_context = { root = root, path = path, revision = 'WORKING', first = 1, last = 2, text = 'local earlier = 0\nreturn earlier' } },
  { id = 'two', file = 'deleted.lua', line = 3, side = 'old', type = 'issue', text = 'Keep this validation',
    codex_context = { root = root, path = root .. '/deleted.lua', revision = 'HEAD', first = 2, last = 4, text = 'before\nvalidate()\nafter' } },
}
local prompt, attachments = review.build(comments, root)
assert(prompt:find('example.lua:1–2', 1, true), 'prompt must identify comment range')
assert(prompt:find('new side', 1, true), 'prompt must identify diff side')
assert(prompt:find('Extract a helper', 1, true), 'prompt must include comment')
assert(#attachments == 3, 'attach each reviewed excerpt and deduplicate current files')
assert(attachments[1].text:find('local earlier = 0', 1, true), 'preserve reviewed version')
assert(attachments[2].text:find('local unsaved = 2', 1, true), 'include current unsaved file')
assert(attachments[3].text:find('validate()', 1, true), 'deleted files retain old-side context')
assert(attachments[3].label:find('HEAD', 1, true), 'old snapshot must identify revision')
assert(attachments[3].label:find('source lines 2–4', 1, true), 'attachment must identify the excerpt starting line for Codex')
assert(attachments[3].first == 2, 'preview must use original source line numbers')
local empty = review.build({}, root)
assert(empty == nil, 'empty reviews must not open Codex')
local wrong = vim.deepcopy(comments)
wrong[1].codex_context.root = '/somewhere/else'
assert(not pcall(review.build, wrong, root), 'must reject another repository')
print('Codex review: all checks passed')
