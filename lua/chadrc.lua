-- This file  needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/NvChad/blob/v2.5/lua/nvconfig.lua

---@type ChadrcConfig
local M = {}

M.ui = {
  theme = "poimandres",
  transparency = true,
  nvdash = {
    load_on_startup = true,
  },
  statusline = {
    theme = "minimal",
  },
  cmp = {
    style = "default",
    icons = true,
    sources = {
      { name = "codeium" },
    },
  },

  -- hl_override = {
  -- 	Comment = { italic = true },
  -- 	["@comment"] = { italic = true },
  -- },
}

return M
