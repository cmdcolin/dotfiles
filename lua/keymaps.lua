local map = vim.api.nvim_set_keymap
local default_opts = { noremap = true, silent = true }
map('i', 'jj', '<Esc>', { noremap = true })
map('n', '<leader>w', '<cmd>w<cr>', default_opts)
map('n', '<leader>q', '<cmd>q<cr>', default_opts)
map('n', '<leader>gg', '<cmd>Telescope find_files<cr>', default_opts)
map('n', '<leader>ff', '<cmd>Telescope live_grep<cr>', default_opts)
map('n', '<leader>uu', '<cmd>PackerUpdate<cr>', default_opts)
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
