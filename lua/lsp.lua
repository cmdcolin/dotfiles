require('mason').setup()
require('mason-lspconfig').setup()

local lsp = require 'lsp-zero'
lsp.preset 'recommended'
lsp.setup()
