local M = {}

local function source(buf)
  local path = vim.api.nvim_buf_get_name(buf)
  return path ~= '' and path or '[No Name: ' .. buf .. ']'
end

function M.file(buf)
  local path = source(buf)
  return {
    key = 'file:' .. path,
    label = path,
    text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n'),
  }
end

function M.selection(buf, anchor, cursor, mode)
  anchor, cursor = vim.deepcopy(anchor), vim.deepcopy(cursor)
  anchor[1], cursor[1] = buf, buf
  local first, last = math.min(anchor[2], cursor[2]), math.max(anchor[2], cursor[2])
  local path = source(buf)
  return {
    key = table.concat({ 'selection', path, mode, anchor[2], anchor[3], cursor[2], cursor[3] }, ':'),
    label = path .. ' · lines ' .. first .. '–' .. last,
    first = first,
    last = last,
    text = table.concat(vim.fn.getregion(anchor, cursor, { type = mode, exclusive = vim.o.selection == 'exclusive' }), '\n'),
  }
end

function M.add(items, item)
  for i, existing in ipairs(items) do
    if existing.key == item.key then
      items[i] = item
      return
    end
  end
  items[#items + 1] = item
end

-- Strip terminal controls, including bracketed-paste delimiters from source text.
function M.clean(text)
  return (text:gsub('[%z\1-\8\11-\31\127]', ''))
end

function M.format(prompt, items)
  local parts = { prompt }
  if #items > 0 then
    parts[#parts + 1] = 'Attached editor context (snapshots, including unsaved edits):'
    for _, item in ipairs(items) do
      parts[#parts + 1] = ('--- %s ---\n%s\n--- End attachment ---'):format(item.label, item.text)
    end
  end
  return M.clean(table.concat(parts, '\n\n'))
end

return M
