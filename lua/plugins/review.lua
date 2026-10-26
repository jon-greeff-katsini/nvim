vim.pack.add {
  { src = 'https://github.com/esmuellert/codediff.nvim' },
  { src = 'https://github.com/MunifTanjim/nui.nvim' },
  { src = 'https://github.com/georgeguimaraes/review.nvim' },
}

require('codediff').setup {
  diff = { layout = 'side-by-side' },
  explorer = { view_mode = 'tree', focus_on_select = true },
  keymaps = {
    view = { toggle_stage = false, stage_hunk = false, unstage_hunk = false, discard_hunk = false, diff_get = false, diff_put = false },
    explorer = { stage_all = false, unstage_all = false, restore = false },
  },
}
require('review').setup {
  export = { clipboard = false, clear_on_close = false },
  keymaps = {
    export_clipboard = false, send_sidekick = false, popup_submit = '<C-c>',
    next_file = false, prev_file = false, close = false,
  },
}
require('codex.review').setup()
require('codex.review_navigation').setup()
