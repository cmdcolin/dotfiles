require('mason').setup()
require('mason-lspconfig').setup()
require('leap').add_default_mappings()

local lsp = require 'lsp-zero'
lsp.preset 'recommended'
lsp.setup()
