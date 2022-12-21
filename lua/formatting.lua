local util = require 'formatter.util'
local rfmt = function()
  return {
    exe = 'Rscript',
    args = {
      '-e \'styler::style_file("'
        .. util.escape_path(util.get_current_buffer_file_path())
        .. '")\'',
    },
  }
end

require('formatter').setup {
  filetype = {
    r = { rfmt },
    javascriptreact = { require 'formatter.defaults.prettier' },
    javascript = { require 'formatter.defaults.prettier' },
    typescriptreact = { require 'formatter.defaults.prettier' },
    typescript = { require 'formatter.defaults.prettier' },
    json = { require 'formatter.defaults.prettier' },
    markdown = { require 'formatter.defaults.prettier' },
    html = { require 'formatter.defaults.prettier' },
    css = { require 'formatter.defaults.prettier' },
    svg = { require 'formatter.defaults.prettier' },
    lua = { require('formatter.filetypes.lua').stylua },
    rust = { require('formatter.filetypes.rust').rustfmt },
    ['*'] = { require('formatter.filetypes.any').remove_trailing_whitespace },
  },
}

vim.api.nvim_exec(
  [[
    augroup FormatAutogroup
      autocmd!
      autocmd BufWritePost * FormatWrite
    augroup END
  ]],
  true
)
