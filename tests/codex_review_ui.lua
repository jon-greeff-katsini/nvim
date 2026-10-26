local config_root = vim.fn.getcwd()
local data = vim.fn.stdpath('data')
vim.opt.rtp:prepend(config_root)
for _, plugin in ipairs { 'codediff.nvim', 'nui.nvim', 'review.nvim' } do
  vim.opt.rtp:append(data .. '/site/pack/core/opt/' .. plugin)
end
local isolated = vim.fn.tempname()
vim.env.XDG_DATA_HOME = isolated
vim.env.XDG_STATE_HOME = isolated .. '/state'
vim.fn.mkdir(isolated .. '/state/nvim', 'p')
vim.o.columns, vim.o.lines = 80, 24
require('codediff').setup { explorer = { view_mode = 'tree', focus_on_select = true } }
require('review').setup {
  export = { clipboard = false, clear_on_close = false },
  keymaps = { export_clipboard = false, send_sidekick = false, next_file = false, prev_file = false, close = false, popup_submit = '<C-c>' },
}
require('codex.review').setup()
require('codex.review_navigation').setup()
vim.cmd.runtime('plugin/codediff.lua')
vim.cmd.runtime('plugin/review.lua')
local root = vim.fn.tempname()
vim.fn.mkdir(root, 'p')
root = vim.uv.fs_realpath(root)
local function git(args)
  local command = { 'git', '-C', root }
  vim.list_extend(command, args)
  local result = vim.system(command, { text = true }):wait()
  assert(result.code == 0, result.stderr)
end
git { 'init', '-q' }
vim.fn.writefile({ 'before', 'old validation', 'return old' }, root .. '/example.lua')
vim.fn.writefile({ 'other before' }, root .. '/other.lua')
git { 'add', 'example.lua', 'other.lua' }
git { '-c', 'user.name=Test', '-c', 'user.email=test@example.invalid', 'commit', '-qm', 'Initial version' }
vim.fn.writefile({ 'after', 'new validation', 'return new' }, root .. '/example.lua')
vim.fn.writefile({ 'other after' }, root .. '/other.lua')
vim.cmd.cd(root)
vim.cmd.Review()
local hooks = require('review.hooks')
assert(vim.wait(5000, function() return hooks.get_session() ~= nil end, 20), 'review view did not initialise')
local session = hooks.get_session()
assert(vim.wait(5000, function()
  return table.concat(vim.api.nvim_buf_get_lines(session.original_bufnr, 0, -1, false), '\n'):find('old validation', 1, true)
end, 20), 'old diff source did not finish loading')
assert(#vim.api.nvim_tabpage_list_wins(0) >= 3, 'review needs a change tree and side-by-side panes')
local function press(key)
  local mapping = vim.fn.maparg(key, 'n', false, true)
  assert(type(mapping.callback) == 'function', 'missing navigation callback: ' .. key)
  mapping.callback()
end
local explorer = hooks.get_explorer(vim.api.nvim_get_current_tabpage())
assert(vim.wait(1000, function()
  return vim.fn.maparg('<Tab>', 'n', false, true).desc == 'Switch file tree / diff'
end, 10), 'review navigation must override file-switching Tab')
vim.api.nvim_set_current_win(explorer.winid)
press('<Tab>')
assert(vim.api.nvim_get_current_win() == session.modified_win, 'Tab must go directly from tree to diff')
press('<Tab>')
assert(vim.api.nvim_get_current_win() == explorer.winid, 'Tab must return directly to tree')
press('<S-Tab>')
assert(vim.api.nvim_get_current_win() == session.modified_win, 'Shift-Tab must also toggle tree and diff')
assert(vim.fn.maparg('h', 'n') == '' and vim.fn.maparg('l', 'n') == '', 'h/l must remain ordinary cursor movement')
vim.api.nvim_set_current_win(session.original_win)
press('<Tab>')
press('<Tab>')
assert(vim.api.nvim_get_current_win() == session.original_win, 'return to the last-used diff side')
press('q')
assert(vim.api.nvim_get_current_win() == explorer.winid, 'q must return to tree before closing')
press(']')
assert(vim.wait(2000, function()
  return hooks.get_session().modified.relative == 'other.lua'
end, 10), '] must open the next changed file')
assert(vim.wait(1000, function()
  return vim.fn.maparg('[', 'n', false, true).desc == 'Previous changed file'
end, 10), 'navigation must follow recreated diff buffers')
press('[')
assert(vim.wait(2000, function()
  return hooks.get_session().modified.relative == 'example.lua'
    and table.concat(vim.api.nvim_buf_get_lines(hooks.get_session().original_bufnr, 0, -1, false), '\n'):find('old validation', 1, true)
end, 10), '[ must open the previous changed file')
session = hooks.get_session()
local store = require('review.store')
local old = store.add('example.lua', 2, 'issue', 'Keep the old validation', nil, 'old')
assert(old.codex_context, 'old-side comments must capture their original source')
assert(old.codex_context.text:find('old validation', 1, true), 'old-side snapshot must contain old code')
assert(not old.codex_context.text:find('new validation', 1, true), 'old-side context must not use new code')
local new = store.add('example.lua', 2, 'suggestion', 'Extract this check', nil, 'new')
assert(new.codex_context.text:find('new validation', 1, true), 'new-side context must use reviewed code')
vim.bo[session.modified_bufnr].modifiable = true
vim.bo[session.modified_bufnr].readonly = false
vim.api.nvim_buf_set_lines(session.modified_bufnr, 0, 1, false, { 'unsaved after review' })
local delivered
package.loaded.codex = { paste_review = function(prompt, attachments, repo, on_submitted)
  delivered = { prompt = prompt, attachments = attachments, root = repo, on_submitted = on_submitted }
  return true
end }
assert(require('codex.review').send(), 'review handoff failed')
assert(delivered.root == root, 'handoff must use the reviewed repository')
assert(delivered.prompt:find('example.lua:2', 1, true), 'handoff must preserve line numbers')
assert(#delivered.attachments == 3, 'attach both reviewed sides and one current file')
local all_text = vim.inspect(delivered.attachments)
assert(all_text:find('old validation', 1, true) and all_text:find('unsaved after review', 1, true), 'attach reviewed and unsaved versions')
assert(store.count() == 2, 'staging must keep the comments')
local acknowledge = delivered.on_submitted
local persisted = table.concat(vim.fn.readfile(require('review.storage').get_storage_path()), '\n')
assert(persisted:find('codex_context', 1, true), 'review snapshots must persist with comments')
-- Keep an unsaved file while leaving the review; no clipboard export or Codex submission should occur.
vim.bo[session.modified_bufnr].bufhidden = 'hide'
vim.fn.setreg = function() error('review close must not touch the clipboard') end
delivered = nil
vim.api.nvim_set_current_win(explorer.winid)
press('q')
assert(delivered == nil, 'closing must never send a review')
assert(store.count() == 2, 'closing must preserve comments')
assert(hooks.get_session() == nil, 'closing must leave the review view')
store.update(new.id, 'Edited after staging')
local extra = store.add('example.lua', 3, 'note', 'Added after staging', nil, 'new')
acknowledge()
assert(store.get(old.id) == nil, 'submitted unchanged comments must clear')
assert(store.get(new.id) and store.get(extra.id), 'edited and newly added comments must stay')
assert(store.count() == 2, 'clear only the comments actually submitted')
assert(require('codex.review').send(), 'remaining comments should still be sendable')
delivered.on_submitted()
assert(store.count() == 0, 'submitting the remaining review must clear it')
vim.cmd.Review()
assert(vim.wait(3000, function()
  local active = hooks.get_session()
  return active and vim.api.nvim_buf_get_lines(active.modified_bufnr, 0, 1, false)[1] ~= ''
end, 10), 'review must reopen for range comments')
session = hooks.get_session()
vim.api.nvim_set_current_win(session.modified_win)
local selected = vim.api.nvim_buf_get_lines(session.modified_bufnr, 0, 1, false)[1]:sub(1, 5)
assert(vim.wait(1000, function() return vim.fn.maparg('i', 'x') ~= '' end, 10), 'Visual i must add range comments')
vim.cmd.normal { args = { 'gg0v4l' }, bang = true }
vim.api.nvim_feedkeys('i', 'x', false)
assert(vim.wait(1000, function() return vim.api.nvim_win_get_config(0).relative ~= '' end, 10), 'range popup must open after leaving Visual mode')
assert(vim.api.nvim_win_get_config(0).relative ~= '', 'range comment must open an input popup')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'Rename this exact fragment' })
local save = vim.fn.maparg('<C-c>', 'i', false, true)
assert(type(save.callback) == 'function', 'Ctrl-C must save a selection comment')
save.callback()
assert(store.count() == 1, 'saving must create one comment')
local ranged = store.get_all()[1]
assert(ranged.codex_selection.text == selected, 'preserve the exact character selection')
local range_prompt = require('codex.review').build(store.get_all(), root)
assert(range_prompt:find('columns 1–5', 1, true), 'Codex must receive selection column information')
assert(range_prompt:find(selected, 1, true), 'Codex must receive the selected fragment')
assert(vim.wait(500, function() return vim.api.nvim_get_current_win() == session.modified_win end, 10), 'saving must restore diff focus')
vim.api.nvim_win_set_cursor(0, { 1, 0 })
vim.ui.select = function(_, _, callback) callback('Yes') end
press('d')
assert(store.count() == 0, 'd action must delete a saved comment')
vim.cmd.normal { args = { 'ggVj' }, bang = true }
require('codex.review').add_range()
assert(vim.wait(1000, function() return vim.api.nvim_win_get_config(0).relative ~= '' end, 10), 'second range popup must open')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'Throw away this draft' })
local cancel = vim.fn.maparg('<Esc>', 'i', false, true)
assert(type(cancel.callback) == 'function', 'Escape must discard an unsaved comment in Insert mode')
cancel.callback()
assert(store.count() == 0, 'discarding a draft must not create a comment')
assert(vim.wait(500, function() return vim.api.nvim_get_current_win() == session.modified_win end, 10), 'discard must return to the diff')
vim.cmd.normal { args = { 'ggVj' }, bang = true }
require('codex.review').add_range()
assert(vim.wait(1000, function() return vim.api.nvim_win_get_config(0).relative ~= '' end, 10), 'line-range popup must open')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'Simplify these two lines' })
vim.fn.maparg('<C-c>', 'i', false, true).callback()
local line_comment = store.get_all()[1]
assert(line_comment.line == 1 and line_comment.line_end == 2, 'whole-line comments must preserve the selected line range')
assert(line_comment.codex_selection.mode == 'V', 'whole-line comments must retain selection type')
print('Codex review UI: all checks passed')
