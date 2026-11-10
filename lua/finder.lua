vim.pack.add({
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/nvim-telescope/telescope.nvim',
  'https://github.com/nvim-telescope/telescope-file-browser.nvim',
})

local fb_actions = require('telescope').extensions.file_browser.actions

-- netrw's d: prompt for a folder name in the current directory
local function create_dir(prompt_bufnr)
  local picker = require('telescope.actions.state').get_current_picker(prompt_bufnr)
  vim.ui.input({ prompt = 'Create folder: ' }, function(name)
    vim.cmd.redraw()
    if not name or name == '' then
      return
    end
    vim.fn.mkdir(picker.finder.path .. '/' .. name, 'p')
    picker:refresh(picker.finder, { reset_prompt = true, multi = picker._multi })
  end)
end

require('telescope').setup({
  extensions = {
    file_browser = {
      initial_mode = 'normal',
      mappings = {
        n = {
          ['%'] = fb_actions.create,
          ['d'] = create_dir,
          ['D'] = fb_actions.remove,
          ['R'] = fb_actions.rename,
          ['-'] = fb_actions.goto_parent_dir,
        },
      },
    },
  },
})

require('telescope').load_extension('file_browser')
