require "nvchad.options"

local o = vim.o
local opt = vim.opt

-- Performance optimizations
o.updatetime = 200
o.timeoutlen = 300
o.redrawtime = 1500
o.synmaxcol = 240

-- Visual/UI settings
o.cursorlineopt = "both"
opt.relativenumber = true
o.mouse = ""
o.pumblend = 0               -- No transparency
o.winblend = 0               -- No transparency
o.scrolloff = 8
o.sidescrolloff = 8
o.signcolumn = "yes"
o.wrap = true
o.linebreak = true
o.breakindent = true
o.showmode = false

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

o.laststatus = 3

-- Global LSP floating window config (hover, signature, diagnostics)
local border = {
  { "╭", "FloatBorder" },
  { "─", "FloatBorder" },
  { "╮", "FloatBorder" },
  { "│", "FloatBorder" },
  { "╯", "FloatBorder" },
  { "─", "FloatBorder" },
  { "╰", "FloatBorder" },
  { "│", "FloatBorder" },
}

local orig_open_floating_preview = vim.lsp.util.open_floating_preview
---@diagnostic disable-next-line: duplicate-set-field
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
  opts = opts or {}
  opts.border = opts.border or border
  opts.max_width = opts.max_width or 80
  return orig_open_floating_preview(contents, syntax, opts, ...)
end
