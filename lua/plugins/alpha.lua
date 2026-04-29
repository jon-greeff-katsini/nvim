local alpha = require('alpha')
local dashboard = require('alpha.themes.dashboard')

dashboard.section.header.val = {
  '                                                    ',
  '  ██████╗ ███████╗ █████╗ ██████╗ ██╗   ██╗       ',
  '  ██╔══██╗██╔════╝██╔══██╗██╔══██╗╚██╗ ██╔╝       ',
  '  ██████╔╝█████╗  ███████║██║  ██║ ╚████╔╝        ',
  '  ██╔══██╗██╔══╝  ██╔══██║██║  ██║  ╚██╔╝         ',
  '  ██║  ██║███████╗██║  ██║██████╔╝   ██║          ',
  '  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝    ╚═╝          ',
  '                                                    ',
  '         Ready to make history?                    ',
  '                                                    ',
}

alpha.setup(dashboard.config)
