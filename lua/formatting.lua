local prettierfmt = function()
  return {
    exe = 'prettier',
    args = { '--stdin-filepath', vim.fn.fnameescape(vim.api.nvim_buf_get_name(0)) },
    stdin = true,
  }
end

local rustfmt = function()
  return {
    exe = 'rustfmt',
    stdin = true,
  }
end

local stylua = require('formatter.filetypes.lua').stylua

require('formatter').setup {
  filetype = {
    javascriptreact = { prettierfmt },
    javascript = { prettierfmt },
    typescriptreact = { prettierfmt },
    typescript = { prettierfmt },
    json = { prettierfmt },
    markdown = { prettierfmt },
    html = { prettierfmt },
    css = { prettierfmt },
    svg = { prettierfmt },
    lua = { stylua },
    rust = { rustfmt },
  },
}

vim.api.nvim_exec(
  [[
augroup FormatAutogroup
  autocmd!
  autocmd BufWritePost *.js,*.tsx,*.ts,*jsx,*json,*.md,*.R,*.r,*.html,*.css,*.svg,*.lua,*.rs FormatWrite
augroup END
]],
  true
)
