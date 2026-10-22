local M = {}

function M.new(consumed)
  local directory = vim.fn.tempname()
  vim.fn.mkdir(directory, 'p', 448)
  local bridge = { path = directory .. '/pending.json', revision = 0 }

  function bridge.publish(attachments)
    bridge.revision = bridge.revision + 1
    if #attachments == 0 then
      vim.fn.delete(bridge.path)
      return
    end
    local snapshot = {
      revision = bridge.revision,
      context = require('codex.context').format('', attachments),
    }
    vim.fn.writefile({ vim.json.encode(snapshot) }, bridge.path .. '.new', 'b')
    assert(vim.uv.fs_rename(bridge.path .. '.new', bridge.path))
  end

  local timer = vim.uv.new_timer()
  timer:start(100, 100, vim.schedule_wrap(function()
    if vim.fn.filereadable(bridge.path .. '.used') == 0 then return end
    local ok, revision = pcall(function()
      return vim.json.decode(table.concat(vim.fn.readfile(bridge.path .. '.used'), '\n'))
    end)
    vim.fn.delete(bridge.path .. '.used')
    if ok and revision == bridge.revision then consumed() end
  end))

  function bridge.close()
    if timer:is_closing() then return end
    timer:stop()
    timer:close()
    vim.fn.delete(directory, 'rf')
  end

  return bridge
end

return M
