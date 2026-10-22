vim.opt.rtp:prepend(vim.fn.getcwd())
for _, plugin in ipairs { 'plenary.nvim', 'telescope.nvim' } do
  vim.opt.rtp:append(vim.fn.stdpath('data') .. '/site/pack/core/opt/' .. plugin)
end
require('telescope').setup {}
vim.o.columns, vim.o.lines = 120, 45
local popup = require('codex')
local root = vim.fn.tempname()
vim.fn.mkdir(root, 'p')
local received = root .. '/received'
local fake = root .. '/codex.py'
vim.fn.writefile({
  'import json, os, subprocess, sys, tty',
  'from pathlib import Path',
  'assert any("hooks.UserPromptSubmit" in arg for arg in sys.argv)',
  'tty.setraw(0)',
  'print("Ready", flush=True)',
  'pending = b""',
  'with open(sys.argv[1], "w", buffering=1) as output:',
  '    while True:',
  '        data = os.read(0, 65536)',
  '        if not data: break',
  '        pending += data',
  '        while b"\\r" in pending:',
  '            line, _, pending = pending.partition(b"\\r")',
  '            if line.startswith(b"/"): continue',
  '            result = subprocess.run([sys.executable, sys.argv[2]], input="{}", text=True, capture_output=True, check=True)',
  '            output.write(json.dumps({"prompt": line.decode(), "hook": json.loads(result.stdout) if result.stdout else None}) + "\\n")',
}, fake)
popup.setup { command = { 'python3', '-u', fake, received, vim.fn.getcwd() .. '/lua/codex/attach.py' } }
local function wait_for(fn, message)
  assert(vim.wait(3000, fn, 10), message)
end
local function floats()
  return vim.tbl_filter(function(win)
    return vim.api.nvim_win_get_config(win).relative == 'editor'
  end, vim.api.nvim_list_wins())
end
local function preview_text()
  for _, win in ipairs(floats()) do
    if vim.inspect(vim.api.nvim_win_get_config(win).title):find('Attachments', 1, true) then
      return table.concat(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false), '\n')
    end
  end
  return ''
end
local function submissions()
  if vim.fn.filereadable(received) == 0 then return {} end
  return vim.tbl_map(vim.json.decode, vim.fn.readfile(received))
end
local source = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_name(source, root .. '/example.lua')
vim.api.nvim_buf_set_lines(source, 0, -1, false, { 'unsaved content', 'another field' })
popup.add_file()
assert(#floats() == 2, 'only terminal and attachment preview should float')
local terminal = vim.api.nvim_get_current_buf()
assert(vim.bo[terminal].buftype == 'terminal', 'adding context must focus Codex directly')
assert(preview_text():find('example.lua', 1, true), 'filename must be visible')
assert(preview_text():find('lines 1–2', 1, true), 'whole-file range must be visible')
assert(preview_text():find('1 │ unsaved content', 1, true), 'numbered source must be visible')
for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(terminal, 't')) do
  assert(mapping.lhs ~= '<CR>', 'Enter must reach Codex unchanged')
  assert(mapping.lhs ~= '<C-S>', 'sending must not need a custom shortcut')
end
wait_for(function()
  return table.concat(vim.api.nvim_buf_get_lines(terminal, 0, -1, false), '\n'):find('Ready', 1, true)
end, 'fake Codex did not start')
local job = vim.bo[terminal].channel
-- Native slash commands do not submit a model prompt or consume attachments.
vim.api.nvim_chan_send(job, '/hooks\r')
assert(not preview_text():find('No attachments', 1, true))

popup.remove_context()
local picker_buf = vim.api.nvim_get_current_buf()
local action_state = require('telescope.actions.state')
local picker = action_state.get_current_picker(picker_buf)
wait_for(function() return picker.manager and picker.manager:num_results() == 2 end, 'picker did not populate')
require('telescope.actions').select_default(picker_buf)
wait_for(function()
  return vim.api.nvim_get_current_buf() == terminal and preview_text():find('No attachments', 1, true)
end, 'removal must update preview and return to Codex')
assert(preview_text():find('No attachments', 1, true), 'removal must update preview')
vim.api.nvim_chan_send(job, 'No context please\r')
wait_for(function() return #submissions() == 1 end, 'direct prompt did not submit')
assert(submissions()[1].hook == vim.NIL, 'removed context must not be attached')

popup.hide()
assert(#floats() == 0)
assert(vim.fn.jobwait({ job }, 0)[1] == -1, 'hiding must keep Codex running')
vim.api.nvim_set_current_buf(source)
popup.add_file()
popup.hide()
vim.api.nvim_set_current_buf(source)
vim.cmd.normal { args = { 'ggV' }, bang = true }
popup.add_selection()
assert(vim.api.nvim_get_current_buf() == terminal, 'selection must return to the same Codex terminal')
assert(preview_text():find('lines 1–1', 1, true), 'selected line range must be visible')
vim.api.nvim_chan_send(job, 'Explain these fields\r')
wait_for(function() return #submissions() == 2 end, 'attached prompt did not submit')
local submitted = submissions()[2]
assert(submitted.prompt == 'Explain these fields', 'prompt must be typed directly into Codex')
local attached = submitted.hook.hookSpecificOutput.additionalContext
assert(attached:find('unsaved content', 1, true), 'hook must deliver unsaved text')
assert(attached:find('example.lua', 1, true), 'hook must identify file')
assert(attached:find('lines 1–1', 1, true), 'hook must identify selected lines')
wait_for(function() return preview_text():find('No attachments', 1, true) end, 'consumed context must clear')
vim.api.nvim_chan_send(job, 'Next prompt\r')
wait_for(function() return #submissions() == 3 end, 'follow-up did not submit')
assert(submissions()[3].hook == vim.NIL, 'context must only be delivered once')

popup.hide()
vim.api.nvim_set_current_buf(source)
popup.add_file()
vim.fn.jobstop(job)
wait_for(function() return vim.fn.jobwait({ job }, 0)[1] ~= -1 end, 'job did not stop')
assert(preview_text():find('unsaved content', 1, true), 'exiting must preserve pending context')
popup.hide()
popup.open()
assert(vim.bo[vim.api.nvim_get_current_buf()].buftype == 'terminal', 'restarting must open terminal')
vim.o.columns, vim.o.lines = 100, 35
vim.api.nvim_exec_autocmds('VimResized', {})
for _, win in ipairs(floats()) do
  assert(vim.api.nvim_win_get_config(win).width == 90, 'popup must resize')
end
vim.api.nvim_win_close(vim.api.nvim_get_current_win(), true)
wait_for(function() return #floats() == 0 end, 'closing either window must close the popup')
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
  if vim.bo[buf].buftype == 'terminal' then pcall(vim.fn.jobstop, vim.bo[buf].channel) end
end
print('Codex direct terminal: all checks passed')
