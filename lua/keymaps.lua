local map = vim.api.nvim_set_keymap
local default_opts = { noremap = true, silent = true }
map('i', 'jj', '<Esc>', { noremap = true })
map('i', 'kk', '<C-\\><C-o>:w<CR>', { noremap = true })
map('n', 'kk', '<cmd>:w<CR>', default_opts)
map('n', '00', '<cmd>q<cr>', default_opts)
map('n', '<leader>gg', '<cmd>Telescope git_files<cr>', default_opts)
map('n', '<leader>ff', '<cmd>Telescope live_grep<cr>', default_opts)
map('n', '<leader>uu', '<cmd>PackerUpdate<cr>', default_opts)
map('n', '<leader>f', '<cmd>LspZeroFormat<cr>', default_opts)
map('n', '<leader>o', 'o<Esc>', default_opts)
map('n', '<leader>O', 'O<Esc>', default_opts)
map('n', '<leader>p', '"_dP', default_opts)

