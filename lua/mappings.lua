require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })

-- Centered navigation
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })
map("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
map("n", "n", "nzzzv", { desc = "Next search result (centered)" })
map("n", "N", "Nzzzv", { desc = "Prev search result (centered)" })

map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })

map("i", "<C-j>", vim.lsp.buf.signature_help)

map({ "n", "v" }, "<leader>fe", "<cmd>LspEslintFixAll<cr>", { desc = "Eslint fix all" })
map("x", "p", 'p:let @+=@0<CR>:let @"=@0<CR>', { desc = "Dont copy replaced text" })
map("n", "<leader>lf", vim.diagnostic.open_float, { desc = "lsp floating diagnostics" })
map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "lsp hover" })

vim.keymap.del("n", "<leader>wk")
vim.keymap.del("n", "<leader>wK")

-- Harpoon and Flash keymaps are defined in plugins/productivity.lua for proper lazy-loading
