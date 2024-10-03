-- This file  needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/NvChad/blob/v2.5/lua/nvconfig.lua

---@type ChadrcConfig
local M = {}

M.base46 = {
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
  tabufline = {
    order = { "treeOffset", "buffers", "nextjsLabel" },
    modules = {
      nextjsLabel = function()
        local current_buf = vim.api.nvim_get_current_buf()
        local bufname = vim.api.nvim_buf_get_name(current_buf)
        if string.match(bufname, "/app/") then
          local dirname = string.match(bufname, "/app/(.*)/page.tsx")
          if dirname == nil then
            return "index - Page"
          end
          dirname = string.gsub(dirname, "%[locale%]/", "")

          return string.format("%s - Page", dirname)
        end
        return ""
      end,
    },
  },

  -- hl_override = {
  -- 	Comment = { italic = true },
  -- 	["@comment"] = { italic = true },
  -- },
}

return M
