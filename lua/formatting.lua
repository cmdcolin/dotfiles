local null_ls = require 'null-ls'
local formatting = null_ls.builtins.formatting
local diagnostics = null_ls.builtins.diagnostics
local action = null_ls.builtins.code_actions

local lsp_formatting = function(bufnr)
  vim.lsp.buf.format {
    filter = function(client)
      return client.name ~= 'tsserver'
    end,
    bufnr = bufnr,
  }
end

local augroup = vim.api.nvim_create_augroup('LspFormatting', {})

null_ls.setup {
  debug = false,
  sources = {
    formatting.prettier,
    formatting.stylua,
    formatting.codespell.with { filetypes = { 'markdown' } },
    diagnostics.eslint,
    action.eslint,
  },
  -- This is for formatting on save
  on_attach = function(client, bufnr)
    if client.supports_method 'textDocument/formatting' then
      vim.api.nvim_clear_autocmds { group = augroup, buffer = bufnr }
      vim.api.nvim_create_autocmd('BufWritePre', {
        group = augroup,
        buffer = bufnr,
        callback = function()
          lsp_formatting(bufnr)
        end,
      })
    end
  end,
}

vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics,
  {
    virtual_text = false,
    signs = true,
    update_in_insert = false,
  }
)
