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

local function keymap_exists_for_buffer(mode, lhs, buf)
  for _, keymap in ipairs(vim.api.nvim_buf_get_keymap(buf, mode)) do
    if keymap.lhs == lhs then
      return true
    end
  end
  return false
end

local function delete_keymaps(args)
  vim.schedule(function()
    local buffer = args.buf
    local keymaps_to_delete = {
      " wa",
      " wr",
      " wl",
    }

    for _, key_to_del in ipairs(keymaps_to_delete) do
      if keymap_exists_for_buffer("n", key_to_del, buffer) then
        vim.keymap.del("n", key_to_del, { buffer = buffer })
      end
    end
  end)
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    delete_keymaps(args)
  end,
})
