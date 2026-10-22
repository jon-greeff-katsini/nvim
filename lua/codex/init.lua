local M = {}
local context = require('codex.context')
local state = { attachments = {}, command = { 'codex' } }

local function valid(win)
  return win and vim.api.nvim_win_is_valid(win)
end

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = 'Codex' })
end

local function update_context()
  local lines = {}
  for _, item in ipairs(state.attachments) do
    local source_lines = vim.split(item.text, '\n', { plain = true })
    local first = item.first or 1
    local label = item.label
    if not item.first then label = label .. ' · lines 1–' .. #source_lines .. ' (whole file)' end
    lines[#lines + 1] = label
    for i, text in ipairs(source_lines) do
      lines[#lines + 1] = ('%d │ %s'):format(first + i - 1, text)
    end
    lines[#lines + 1] = ''
  end
  if #lines == 0 then lines = { 'No attachments. Add a file or Visual selection from your editor.' } end
  if state.preview and vim.api.nvim_buf_is_valid(state.preview) then
    vim.bo[state.preview].modifiable = true
    vim.api.nvim_buf_set_lines(state.preview, 0, -1, false, lines)
    vim.bo[state.preview].modifiable = false
    if valid(state.preview_win) then
      vim.api.nvim_win_set_cursor(state.preview_win, { 1, 0 })
    end
  end
  if valid(state.preview_win) then
    vim.api.nvim_win_set_config(state.preview_win, {
      title = (' Attachments · %d attached · Ctrl-G switch · Ctrl-X remove '):format(#state.attachments),
      title_pos = 'center',
    })
  end
end

local function sync_context()
  if state.bridge then state.bridge.publish(state.attachments) end
  update_context()
end

function M.hide()
  vim.cmd.stopinsert()
  for _, name in ipairs { 'preview_win', 'term_win' } do
    if valid(state[name]) then
      vim.api.nvim_win_close(state[name], true)
    end
    state[name] = nil
  end
  if valid(state.source_win) then
    vim.api.nvim_set_current_win(state.source_win)
  end
end

function M.focus_preview()
  if valid(state.preview_win) then
    vim.cmd.stopinsert()
    vim.api.nvim_set_current_win(state.preview_win)
  end
end

function M.focus_terminal()
  if valid(state.term_win) then
    vim.api.nvim_set_current_win(state.term_win)
    vim.cmd.startinsert()
  end
end

local function switch()
  if vim.api.nvim_get_current_win() == state.term_win then
    M.focus_preview()
  else
    M.focus_terminal()
  end
end

local function local_maps(buf)
  local modes = { 'n', 't' }
  local function map(lhs, fn, desc)
    vim.keymap.set(modes, lhs, fn, { buffer = buf, desc = desc })
  end
  map('<C-g>', switch, 'Switch Codex terminal/attachments')
  map('<C-c>', M.hide, 'Hide Codex popup')
  map('<C-x>', M.remove_context, 'Manage Codex attachments')
  map('<C-p>', M.focus_preview, 'Inspect attached code')
  vim.keymap.set('n', '<Esc>', M.hide, { buffer = buf, desc = 'Hide Codex popup' })
end

local function geometry()
  local width = math.min(140, math.floor(vim.o.columns * 0.9))
  local height = math.floor((vim.o.lines - vim.o.cmdheight - 2) * 0.85)
  if width < 30 or height < 12 then
    return nil
  end
  local preview_height = math.min(6, math.max(3, math.floor(height * 0.2)))
  return {
    width = width,
    term_height = height - preview_height - 2,
    preview_height = preview_height,
    row = math.floor((vim.o.lines - height - 2) / 2),
    col = math.floor((vim.o.columns - width - 2) / 2),
  }
end

local function window_config(g)
  return {
    relative = 'editor',
    style = 'minimal',
    border = 'rounded',
    width = g.width,
    height = g.term_height,
    row = g.row,
    col = g.col,
    title = ' Codex · ' .. vim.fn.fnamemodify(state.cwd or vim.fn.getcwd(), ':t') .. ' · Ctrl-G attachments · Ctrl-C hide ',
    title_pos = 'center',
  }
end

local function preview_config(g)
  local config = window_config(g)
  config.row = g.row + g.term_height + 2
  config.height = g.preview_height
  config.title = ' Attachments · Ctrl-G switch · Ctrl-X remove '
  return config
end

local function start_terminal()
  if state.job and vim.fn.jobwait({ state.job }, 0)[1] == -1 then
    return true
  end
  if vim.fn.executable(state.command[1]) ~= 1 then
    notify('Cannot find ' .. state.command[1] .. ' on PATH.', vim.log.levels.ERROR)
    return false
  end
  if vim.fn.executable('python3') ~= 1 then
    notify('Python 3 is required for the Codex attachment hook.', vim.log.levels.ERROR)
    return false
  end
  if not state.bridge then
    state.bridge = require('codex.bridge').new(function()
      state.attachments = {}
      update_context()
    end)
    state.bridge.publish(state.attachments)
  end
  local script = vim.fs.dirname(debug.getinfo(1, 'S').source:sub(2)) .. '/attach.py'
  local hook = vim.fn.shellescape(vim.fn.exepath('python3')) .. ' ' .. vim.fn.shellescape(script)
  local command = vim.deepcopy(state.command)
  -- The hook must inherit this popup's context path rather than a shared daemon's environment.
  if not vim.tbl_contains(command, '--no-daemon') then command[#command + 1] = '--no-daemon' end
  vim.list_extend(command, {
    '-c', 'features.hooks=true',
    '-c', 'hooks.UserPromptSubmit=[{hooks=[{type="command",command=' .. vim.json.encode(hook)
      .. ',timeout=5,statusMessage="Adding Neovim attachments"}]}]',
  })
  state.terminal = vim.api.nvim_create_buf(false, true)
  vim.bo[state.terminal].bufhidden = 'hide'
  local_maps(state.terminal)
  local job
  vim.api.nvim_buf_call(state.terminal, function()
    job = vim.fn.jobstart(command, {
      term = true,
      cwd = state.cwd,
      env = { NVIM_CODEX_CONTEXT = state.bridge.path },
      on_exit = function(_, code)
        vim.schedule(function()
          if state.job == job then
            state.job = nil
            notify('Codex exited (' .. code .. '). Toggle the popup to start again.')
          end
        end)
      end,
    })
  end)
  if job <= 0 then
    notify('Could not start Codex.', vim.log.levels.ERROR)
    return false
  end
  state.job = job
  return true
end

function M.open()
  if valid(state.term_win) then
    M.focus_terminal()
    return true
  end
  local g = geometry()
  if not g then
    notify('Enlarge the terminal to open the Codex popup.', vim.log.levels.WARN)
    return false
  end
  state.source_win = vim.api.nvim_get_current_win()
  local path = vim.api.nvim_buf_get_name(0)
  if not state.job then
    state.cwd = (path ~= '' and vim.fs.root(path, '.git')) or vim.fn.getcwd()
  end
  if not start_terminal() then return false end
  if not state.preview or not vim.api.nvim_buf_is_valid(state.preview) then
    state.preview = vim.api.nvim_create_buf(false, true)
    vim.bo[state.preview].bufhidden = 'hide'
    vim.keymap.set('n', '<C-g>', M.focus_terminal, { buffer = state.preview, desc = 'Return to Codex terminal' })
    vim.keymap.set('n', '<C-x>', M.remove_context, { buffer = state.preview, desc = 'Remove Codex attachments' })
    vim.keymap.set('n', '<C-c>', M.hide, { buffer = state.preview, desc = 'Hide Codex popup' })
    vim.keymap.set('n', 'q', M.focus_terminal, { buffer = state.preview, desc = 'Return to Codex terminal' })
  end
  state.term_win = vim.api.nvim_open_win(state.terminal, false, window_config(g))
  state.preview_win = vim.api.nvim_open_win(state.preview, false, preview_config(g))
  vim.wo[state.preview_win].wrap = false
  vim.wo[state.preview_win].cursorline = true
  update_context()
  M.focus_terminal()
  return true
end

function M.toggle()
  if valid(state.term_win) then M.hide() else M.open(false) end
end

local function source_buffer()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].buftype ~= '' then
    notify('Attach context from a file buffer.', vim.log.levels.WARN)
    return nil
  end
  return buf
end

function M.add_file()
  local buf = source_buffer()
  if not buf then return end
  context.add(state.attachments, context.file(buf))
  M.open()
  sync_context()
end

function M.add_selection()
  local buf = source_buffer()
  if not buf then return end
  local mode = vim.fn.mode()
  if mode ~= 'v' and mode ~= 'V' and mode ~= '\22' then
    notify('Select code in Visual mode first.', vim.log.levels.WARN)
    return
  end
  context.add(state.attachments, context.selection(buf, vim.fn.getpos('v'), vim.fn.getpos('.'), mode))
  -- Leave Visual mode before moving to the floating terminal.
  vim.cmd.normal { args = { '\27' }, bang = true }
  M.open()
  sync_context()
end

function M.remove_context()
  if #state.attachments == 0 then
    notify('No context attached.')
    return
  end
  vim.cmd.stopinsert()
  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local previewers = require('telescope.previewers')
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  local entries = { { label = 'Clear all attachments', clear = true } }
  vim.list_extend(entries, state.attachments)
  local function finish()
    sync_context()
    M.focus_terminal()
  end
  pickers.new(require('telescope.themes').get_dropdown { previewer = true }, {
    prompt_title = 'Remove context · Enter removes · Esc cancels',
    finder = finders.new_table {
      results = entries,
      entry_maker = function(item)
        return { value = item, display = item.label, ordinal = item.label }
      end,
    },
    sorter = require('telescope.config').values.generic_sorter {},
    previewer = previewers.new_buffer_previewer {
      define_preview = function(self, entry)
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false,
          vim.split(entry.value.text or 'Remove every attachment from the next prompt.', '\n', { plain = true }))
      end,
    },
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if entry then
          if entry.value.clear then
            state.attachments = {}
          else
            for i, item in ipairs(state.attachments) do
              if item == entry.value then table.remove(state.attachments, i); break end
            end
          end
        end
        vim.schedule(finish)
      end)
      local function cancel()
        actions.close(prompt_bufnr)
        vim.schedule(finish)
      end
      map('i', '<Esc>', cancel)
      map('n', '<Esc>', cancel)
      return true
    end,
  }):find()
end

function M.setup(opts)
  state.command = (opts and opts.command) or { 'codex' }
  vim.keymap.set('n', '<leader>ac', M.toggle, { desc = 'Toggle Codex popup' })
  vim.keymap.set('n', '<leader>af', M.add_file, { desc = 'Attach current file to Codex' })
  vim.keymap.set('x', '<leader>as', M.add_selection, { desc = 'Attach selection to Codex' })
  vim.keymap.set('n', '<leader>ax', M.remove_context, { desc = 'Remove Codex context' })
  local group = vim.api.nvim_create_augroup('CodexPopup', { clear = true })
  vim.api.nvim_create_autocmd('WinClosed', {
    group = group,
    callback = function(event)
      local closed = tonumber(event.match)
      if closed ~= state.term_win and closed ~= state.preview_win then return end
      vim.schedule(function()
        if closed == state.term_win or closed == state.preview_win then M.hide() end
      end)
    end,
  })
  vim.api.nvim_create_autocmd('VimResized', {
    group = group,
    callback = function()
      if not valid(state.term_win) then return end
      local g = geometry()
      if not g then M.hide(); return end
      vim.api.nvim_win_set_config(state.term_win, window_config(g))
      if valid(state.preview_win) then
        vim.api.nvim_win_set_config(state.preview_win, preview_config(g))
      end
      update_context()
    end,
  })
  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = group,
    callback = function()
      if state.bridge then state.bridge.close() end
    end,
  })
end

return M
