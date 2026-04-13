vim.pack.add { { src = 'https://github.com/goolord/alpha-nvim' } }

local alpha = require('alpha')
local dashboard = require('alpha.themes.dashboard')

alpha.setup(dashboard.config)
