-- Set space as the leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

local map = vim.keymap.set


-- Custom Key Maps
------------------
-- Explorer
vim.keymap.set("n", "<leader>e", "<cmd>Telescope file_browser path=%:p:h select_buffer=true<cr>", { desc = "Open file browser" })

-- Wrap quotes 
-- Normal Mode (Wraps current word and returns to Normal Mode)
vim.keymap.set("n", "<leader>'", 'ciw\'\'<Left><C-r>"<Esc>', { desc = "Wrap word in single quotes" })
vim.keymap.set("n", '<leader>"', 'ciw""<Left><C-r>"<Esc>', { desc = "Wrap word in double quotes" })
vim.keymap.set("n", "<leader>`", 'ciw``<Left><C-r>"<Esc>', { desc = "Wrap word in backticks" })

-- Visual Mode (Wraps highlighted selection and returns to Normal Mode)
vim.keymap.set("v", "<leader>'", 'c\'\'<Left><C-r>"<Esc>', { desc = "Wrap selection in single quotes" })
vim.keymap.set("v", '<leader>"', 'c""<Left><C-r>"<Esc>', { desc = "Wrap selection in double quotes" })
vim.keymap.set("v", "<leader>`", 'c``<Left><C-r>"<Esc>', { desc = "Wrap selection in backticks" })

-- Telescope
vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find project files" })
vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Grep project" })
vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Find buffers" })

-- Markdown
vim.keymap.set("n", "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", { desc = "Toggle markdown preview" })

-- Windows
local function new_pane(split)
  vim.cmd(split)
  local empty = vim.api.nvim_get_current_buf()
  require("alpha").start(false)
  if empty ~= vim.api.nvim_get_current_buf() then
    vim.api.nvim_buf_delete(empty, { force = true })
  end
end

local function has_neighbour(direction)
  return vim.fn.winnr(direction) ~= vim.fn.winnr()
end

local function resize_mode()
  local steps = {
    h = function() return has_neighbour("l") and "vertical resize -2" or "vertical resize +2" end,
    l = function() return has_neighbour("l") and "vertical resize +2" or "vertical resize -2" end,
    j = function() return has_neighbour("j") and "resize +2" or "resize -2" end,
    k = function() return has_neighbour("j") and "resize -2" or "resize +2" end,
  }
  while true do
    vim.cmd.redraw()
    vim.api.nvim_echo({ { "-- RESIZE -- hjkl to resize, Enter or Ctrl-C to exit" } }, false, {})
    local ok, key = pcall(vim.fn.getcharstr)
    if not ok or key == "\3" or key == "\r" then
      break
    end
    if steps[key] then
      vim.cmd(steps[key]())
    end
  end
  vim.api.nvim_echo({ { "" } }, false, {})
end

local function pane(key, action, desc)
  vim.keymap.set({ "n", "t" }, "<C-Space>" .. key, function()
    if vim.fn.mode() == "t" then
      vim.cmd.stopinsert()
    end
    vim.schedule(action)
  end, { desc = desc })
end

pane("v", function() new_pane("rightbelow vnew") end, "Split vertical")
pane("-", function() new_pane("rightbelow new") end, "Split horizontal")
pane("h", function() vim.cmd.wincmd("h") end, "Go to left window")
pane("j", function() vim.cmd.wincmd("j") end, "Go to window below")
pane("k", function() vim.cmd.wincmd("k") end, "Go to window above")
pane("l", function() vim.cmd.wincmd("l") end, "Go to right window")
pane("r", resize_mode, "Resize windows")

-- Terminal
vim.keymap.set("n", "<leader>t", function()
  vim.cmd.terminal()
  vim.cmd.startinsert()
end, { desc = "Open terminal" })
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Leave terminal mode" })

