local lsp = require('lsp-zero').preset {
  manage_nvim_cmp = {
    set_sources = 'recommended',
  },
}


lsp.on_attach(function(client, bufnr)
  lsp.default_keymaps { buffer = bufnr }
end)

require('lspconfig').lua_ls.setup(lsp.nvim_lua_ls())
require('lspconfig').eslint.setup {}

lsp.format_on_save {
  format_opts = {
    async = false,
    timeout_ms = 10000,
  },
  servers = {
    ['lua_ls'] = { 'lua' },
    ['rust_analyzer'] = { 'rust' },
    ['null-ls'] = {
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
      "vue",
      "css",
      "scss",
      "less",
      "html",
      "json",
      "jsonc",
      "yaml",
      "markdown",
      "markdown.mdx",
      "graphql",
      "handlebars"
    },
  },
}

lsp.setup()

local null_ls = require 'null-ls'

null_ls.setup {
  sources = {
    null_ls.builtins.formatting.prettier
  },
}

local cmp = require 'cmp'

cmp.setup {
  mapping = {
    ['<CR>'] = cmp.mapping.confirm { select = true },
  },
}
