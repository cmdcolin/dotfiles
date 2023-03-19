local lsp = require('lsp-zero').preset {
  manage_nvim_cmp = {
    set_sources = 'recommended',
  },
}



lsp.on_attach(function(client, bufnr)
  lsp.default_keymaps { buffer = bufnr }
end)



-- (Optional) Configure lua language server for neovim
require('lspconfig').lua_ls.setup(lsp.nvim_lua_ls())
require('lspconfig').eslint.setup {}

lsp.setup()

local cmp = require 'cmp'

cmp.setup {
  mapping = {
    ['<CR>'] = cmp.mapping.confirm { select = true },
  },
}
