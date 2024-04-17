require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

map("n", "<leader>w", "<cmd>w<CR>")
map("n", "<C-u>", "<C-u>zz")
map("n", "<C-d>", "<C-d>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })

map({ "n", "v" }, "<leader>fe", "<cmd>EslintFixAll<cr>", { desc = "Eslint fix all" })

-- Harpoon

map("n", "<leader>a", function()
  require("harpoon"):list():add()
end)

map("n", "<C-e>", function()
  local harpoon = require "harpoon"
  harpoon.ui:toggle_quick_menu(harpoon:list())
end)

map("n", "<C-j>", function()
  require("harpoon"):list():select(1)
end)

map("n", "<C-k>", function()
  require("harpoon"):list():select(2)
end)

map("n", "<C-l>", function()
  require("harpoon"):list():select(3)
end)

map("n", "<C-;>", function()
  require("harpoon"):list():select(4)
end)

-- Flash

map({ "n", "x", "o" }, "s", function()
  require("flash").jump()
end, { desc = "Flash" })

map({ "n", "x", "o" }, "S", function()
  require("flash").treesitter()
end, { desc = "Flash Treesitter" })

map("o", "r", function()
  require("flash").remote()
end, { desc = "Remote Flash" })

map({ "o", "x" }, "R", function()
  require("flash").treesitter_search()
end, { desc = "Treesitter Search" })

map("c", "<c-s>", function()
  require("flash").toggle()
end, { desc = "Toggle Flash Search" })
