require "nvchad.options"

-- add yours here!

local o = vim.o
local opt = vim.opt

o.cursorlineopt = "both" -- to enable cursorline!
opt.relativenumber = true
o.mouse = ""

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank { higroup = "IncSearch", timeout = 100 }
  end,
})
vim.api.nvim_set_hl(0, "CmpItemKindSupermaven", { fg = "#6CC644" })
