local M = {}

local function current_file(path)
  local buf = vim.fn.bufnr(path)
  if buf >= 0 and vim.api.nvim_buf_is_loaded(buf) then
    return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  end
  if vim.fn.filereadable(path) == 1 then return vim.fn.readfile(path) end
end

local function location(comment)
  if comment.line == 0 then return 'whole file' end
  local last = comment.line_end or comment.line
  local lines = comment.line == last and tostring(comment.line) or (comment.line .. '–' .. last)
  local selection = comment.codex_selection
  if selection and selection.mode ~= 'V' then
    lines = lines .. (' (columns %d–%d%s)'):format(selection.first_column, selection.last_column,
      selection.exclusive and ', end exclusive' or '')
  end
  return lines
end

function M.build(comments, root)
  if #comments == 0 then return nil, {} end
  local prompt = { 'Please address the following review comments in this repository.',
    'Attached excerpts preserve the reviewed version and line numbers. Current files are attached separately.', '' }
  local attachments, files = {}, {}
  for index, comment in ipairs(comments) do
    local snapshot = comment.codex_context
    local path = vim.fs.normalize(root .. '/' .. comment.file)
    assert(path:sub(1, #root + 1) == root .. '/', 'Review file is outside the repository: ' .. comment.file)
    if snapshot then
      assert(snapshot.root == root, 'Review snapshot belongs to another repository: ' .. comment.file)
    else
      -- Earlier comments lack a saved diff snapshot. Never substitute new code for an old-side comment.
      assert(comment.side ~= 'old', 'Re-add this old-side comment to capture its reviewed code: ' .. comment.file)
      local lines = assert(current_file(path), 'Review file is unavailable: ' .. comment.file)
      snapshot = { first = 1, last = #lines, text = table.concat(lines, '\n'), revision = 'WORKING' }
    end
    local side = comment.side or 'new'
    local label = ('%s · %s side @ %s · source lines %d–%d · comment %s'):format(
      path, side, snapshot.revision, snapshot.first, snapshot.last, location(comment))
    prompt[#prompt + 1] = ('%d. [%s] %s:%s (%s side @ %s)\n%s'):format(
      index, string.upper(comment.type), comment.file, location(comment), side, snapshot.revision, comment.text)
    if comment.codex_selection then
      prompt[#prompt] = prompt[#prompt] .. '\nSelected code:\n' .. comment.codex_selection.text
    end
    attachments[#attachments + 1] = {
      key = 'review:' .. comment.id, label = label, first = snapshot.first,
      last = snapshot.last, text = snapshot.text,
    }
    if not files[path] then
      local lines = current_file(path)
      if lines then
        attachments[#attachments + 1] = {
          key = 'file:' .. path,
          label = path .. ' · current working file · full file lines 1–' .. #lines .. ' (including unsaved edits)',
          text = table.concat(lines, '\n'),
        }
      end
      files[path] = true
    end
  end
  return table.concat(prompt, '\n\n'), attachments
end

local function capture(comment)
  local hooks = require('review.hooks')
  local session = hooks.get_session()
  local root = (session and session.git_root) or require('review.utils').git_root()
  if not root then return end
  root = vim.uv.fs_realpath(root) or root
  local path = vim.fs.normalize(root .. '/' .. comment.file)
  local old = comment.side == 'old'
  local reference = session and (old and session.original or session.modified)
  local matches = reference and ((type(reference) == 'table' and reference.relative == comment.file)
    or reference == path or reference == comment.file)
  local buf = matches and (old and session.original_bufnr or session.modified_bufnr)
  local revision = 'WORKING'
  if matches then
    revision = old and (session.original_revision or 'STAGED') or (session.modified_revision or 'WORKING')
  end
  local lines
  if buf and vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
    lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  else
    if old then return end
    lines = current_file(path)
  end
  if not lines then return end
  local first = comment.line == 0 and 1 or math.max(1, comment.line - 3)
  local last = comment.line == 0 and #lines or math.min(#lines, (comment.line_end or comment.line) + 3)
  comment.codex_context = {
    root = root, path = path, revision = revision or (old and 'STAGED' or 'WORKING'),
    first = first, last = last, text = table.concat(vim.list_slice(lines, first, last), '\n'),
  }
end

function M.add_range(from_marks, initial_type)
  local mode = vim.fn.mode()
  if from_marks and mode == 'n' then mode = vim.fn.visualmode() end
  if mode ~= 'v' and mode ~= 'V' and mode ~= '\22' then
    vim.notify('Select code with v or V, then press i.', vim.log.levels.WARN)
    return
  end
  local buf = vim.api.nvim_get_current_buf()
  local hooks = require('review.hooks')
  local file, _, side = hooks.get_cursor_position()
  if not file then return end
  local anchor = vim.fn.getpos(from_marks and "'<" or 'v')
  local cursor = vim.fn.getpos(from_marks and "'>" or '.')
  local region = require('codex.context').selection(buf, anchor, cursor, mode)
  if anchor[2] > cursor[2] or (anchor[2] == cursor[2] and anchor[3] > cursor[3]) then
    anchor, cursor = cursor, anchor
  end
  local function column(position)
    local line = vim.api.nvim_buf_get_lines(buf, position[2] - 1, position[2], false)[1] or ''
    return vim.fn.strchars(line:sub(1, math.min(#line, position[3] - 1))) + 1
  end
  local selection = {
    mode = mode, text = region.text, first_line = region.first, last_line = region.last,
    first_column = column(anchor), last_column = column(cursor), exclusive = vim.o.selection == 'exclusive',
  }
  local store = require('review.store')
  if store.get_overlapping(file, region.first, region.last, side) then
    vim.notify('A comment already covers this range. Use e to edit it or d to delete it.', vim.log.levels.WARN)
    return
  end
  local original = { file = file, line = region.first, line_end = region.last, side = side }
  capture(original)
  local in_review = hooks.get_session() ~= nil
  vim.cmd.normal { args = { '\27' }, bang = true }
  vim.schedule(function()
    require('review.popup').open(initial_type or 'note', nil, function(kind, text)
      if not kind or not text then return end
      local comment = store.add(file, region.first, kind, text, region.last, side)
      comment.codex_selection = selection
      if original.codex_context then comment.codex_context = original.codex_context end
      require('review.storage').save(store.comments)
      if in_review then require('review.marks').refresh() else require('review.marks').render_plain_buffer(buf) end
    end)
  end)
end

function M.clear_submitted(root, submitted)
  if require('review.utils').git_root() ~= root then
    vim.notify('Review submitted; comments kept because the active repository changed.', vim.log.levels.WARN)
    return
  end
  local store = require('review.store')
  local ids = {}
  for _, comment in ipairs(submitted) do
    if vim.deep_equal(store.get(comment.id), comment) then ids[#ids + 1] = comment.id end
  end
  if #ids == 0 then return end
  require('review.storage').archive()
  for _, id in ipairs(ids) do store.delete(id) end
  local marks = require('review.marks')
  marks.clear_all()
  marks.refresh()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == '' then marks.render_plain_buffer(buf) end
  end
end

function M.send()
  local root = require('review.utils').git_root()
  if not root then vim.notify('Open a repository before sending a review.', vim.log.levels.WARN); return false end
  local store = require('review.store')
  store.load()
  local submitted = vim.deepcopy(store.get_all())
  local ok, prompt, attachments = pcall(M.build, submitted, root)
  if not ok then vim.notify(prompt, vim.log.levels.ERROR); return false end
  if not prompt then vim.notify('No review comments to send.', vim.log.levels.INFO); return false end
  if require('codex').paste_review(prompt, attachments, root, function()
    M.clear_submitted(root, submitted)
  end) then
    vim.notify('Review and file context added to Codex. Edit the input, then press Enter to send.')
    return true
  end
  return false
end

function M.setup()
  local store = require('review.store')
  if not M.capture_installed then
    local add = store.add
    -- review.nvim has no comment-created event. Extend its store operation to retain diff provenance.
    store.add = function(...)
      local comment = add(...)
      capture(comment)
      require('review.storage').save(store.comments)
      return comment
    end
    local comments = require('review.comments')
    local add_range = comments.add_for_range
    comments.add_for_range = function(initial_type, first, last)
      if first or last then return add_range(initial_type, first, last) end
      M.add_range(true, initial_type)
    end
    local popup = require('review.popup')
    local open = popup.open
    popup.open = function(...)
      open(...)
      local cancel = vim.fn.maparg('<Esc>', 'n', false, true)
      if vim.api.nvim_win_get_config(0).relative ~= '' and type(cancel.callback) == 'function' then
        vim.keymap.set('i', '<Esc>', cancel.callback, { buffer = true, desc = 'Discard comment draft' })
      end
    end
    M.capture_installed = true
  end
  vim.keymap.set('n', '<leader>cr', '<cmd>Review<CR>', { desc = 'Review working-tree changes' })
  vim.keymap.set('n', '<leader>sr', M.send, { desc = 'Put review and files into Codex input' })
  vim.api.nvim_create_user_command('ReviewCodex', M.send, { desc = 'Put review and files into Codex input', force = true })
end

return M
