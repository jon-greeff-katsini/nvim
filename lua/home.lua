vim.pack.add({ 'https://github.com/goolord/alpha-nvim' })

local alpha = require('alpha')

local drawing
local draw = alpha.draw
alpha.draw = function(conf, state)
  drawing = state
  draw(conf, state)
end

alpha.setup({
  layout = {
    {
      type = 'padding',
      val = function()
        return math.max(0, math.floor(drawing.win_height / 2) - 1)
      end,
    },
    {
      type = 'text',
      val = 'Make it work. Make it right. Make it fast.',
      opts = { position = 'center', hl = 'Title' },
    },
  },
  opts = {},
})

vim.api.nvim_create_autocmd('WinResized', {
  callback = function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'alpha' then
        vim.api.nvim_win_call(win, function()
          alpha.redraw()
        end)
      end
    end
  end,
})
