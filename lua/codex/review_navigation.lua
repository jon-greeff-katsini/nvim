local M = {}

local function valid(win)
  return win and vim.api.nvim_win_is_valid(win)
end

local function view()
  local lifecycle = require('codediff.ui.lifecycle')
  local tab = vim.api.nvim_get_current_tabpage()
  return lifecycle, tab, lifecycle.get_session(tab), require('review.hooks').get_explorer(tab)
end

local function focus_tree()
  local _, _, session, explorer = view()
  if not session then return end
  local current = vim.api.nvim_get_current_win()
  if current == session.original_win or current == session.modified_win then
    session.review_last_diff = current
  end
  if explorer then
    if not valid(explorer.winid) then require('codediff.ui.explorer').toggle_visibility(explorer) end
    if valid(explorer.winid) then vim.api.nvim_set_current_win(explorer.winid) end
  end
end

local function focus_diff()
  local _, _, session = view()
  if not session then return end
  local target = session.review_last_diff
  if not valid(target) or (target ~= session.original_win and target ~= session.modified_win) then
    target = valid(session.modified_win) and session.modified_win or session.original_win
  end
  if valid(target) then vim.api.nvim_set_current_win(target) end
end

local function toggle()
  local _, _, session = view()
  if not session then return end
  local current = vim.api.nvim_get_current_win()
  if current == session.original_win or current == session.modified_win then
    focus_tree()
  else
    focus_diff()
  end
end

local function back()
  local lifecycle, tab, session, explorer = view()
  if not session then return end
  if explorer and vim.api.nvim_get_current_win() ~= explorer.winid then
    focus_tree()
  else
    lifecycle.close(tab)
  end
end

local function apply()
  local lifecycle, tab, session = view()
  if not session then return end
  local function map(key, action, description)
    lifecycle.set_tab_keymap(tab, 'n', key, action, { desc = description })
  end
  map('<Tab>', toggle, 'Switch file tree / diff')
  map('<S-Tab>', toggle, 'Switch file tree / diff')
  map('[', function() require('codediff').prev_file() end, 'Previous changed file')
  map(']', function() require('codediff').next_file() end, 'Next changed file')
  map('q', back, 'Back to file tree / close review')
end

function M.setup()
  local group = vim.api.nvim_create_augroup('CodexReviewNavigation', { clear = true })
  local function refresh() vim.schedule(apply) end
  vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter', 'TabEnter' }, { group = group, callback = refresh })
  vim.api.nvim_create_autocmd('User', {
    group = group, pattern = { 'CodeDiffOpen', 'CodeDiffFileSelect' },
    callback = function()
      refresh()
      -- The diff and review plugins finish rebinding replacement buffers asynchronously.
      vim.defer_fn(apply, 150)
    end,
  })
end

return M
