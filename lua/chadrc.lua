-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua

---@type ChadrcConfig
local M = {}
local tools = require "configs.tools"

M.base46 = {
  theme = "poimandres",
  hl_override = {
    -- Tabline - use theme colors
    TbBufOn = { bold = true },
    TbBufOnModified = { fg = "green" },
    TbBufOnClose = { fg = "red" },

    -- Cursor & line
    CursorLine = { bg = "one_bg" },
    CursorLineNr = { fg = "white", bold = true },
    LineNr = { fg = "grey" },

    -- Floating windows - inherit from theme
    FloatBorder = { fg = "blue" },

    -- Telescope - colored titles
    TelescopePromptTitle = { fg = "black", bg = "blue", bold = true },
    TelescopeResultsTitle = { fg = "black", bg = "green", bold = true },
    TelescopePreviewTitle = { fg = "black", bg = "cyan", bold = true },

    -- Git signs
    DiffAdd = { fg = "green" },
    DiffChange = { fg = "yellow" },
    DiffDelete = { fg = "red" },

    -- Better visual mode
    Visual = { bg = "one_bg3" },

    -- Matching parens
    MatchParen = { fg = "orange", bold = true, underline = true },
  },
  hl_add = {
    -- Flash highlights
    FlashLabel = { fg = "black", bg = "red", bold = true },
    FlashMatch = { fg = "cyan" },
    FlashCurrent = { fg = "yellow", bold = true },

    -- Treesitter context - subtle bg
    TreesitterContext = { bg = "one_bg" },
    TreesitterContextLineNumber = { fg = "blue", bg = "one_bg" },
  },
  transparency = true,
}

M.ui = {
  statusline = {
    theme = "vscode_colored",
    separator_style = "round",
  },
  cmp = {
    icons_left = true,
    icons = true,
    style = "atom_colored",
  },
  tabufline = {
    order = { "treeOffset", "buffers", "tabs" },
  },
  telescope = {
    style = "bordered",
  },
}

M.nvdash = {
  load_on_startup = true,
  header = {
    "",
    "                                                       ",
    "                                                       ",
    "   ███╗   ██╗ ███████╗ ██████╗  ██╗   ██╗ ██╗ ███╗   ███╗",
    "   ████╗  ██║ ██╔════╝██╔═══██╗ ██║   ██║ ██║ ████╗ ████║",
    "   ██╔██╗ ██║ █████╗  ██║   ██║ ██║   ██║ ██║ ██╔████╔██║",
    "   ██║╚██╗██║ ██╔══╝  ██║   ██║ ╚██╗ ██╔╝ ██║ ██║╚██╔╝██║",
    "   ██║ ╚████║ ███████╗╚██████╔╝  ╚████╔╝  ██║ ██║ ╚═╝ ██║",
    "   ╚═╝  ╚═══╝ ╚══════╝ ╚═════╝    ╚═══╝   ╚═╝ ╚═╝     ╚═╝",
    "                                                       ",
    "",
  },
  buttons = {
    { txt = "  Find File", keys = "f f", cmd = "Telescope find_files" },
    { txt = "  Recent Files", keys = "f o", cmd = "Telescope oldfiles" },
    { txt = "󰈭  Find Word", keys = "f w", cmd = "Telescope live_grep" },
    { txt = "󱥚  Themes", keys = "t h", cmd = ":lua require('nvchad.themes').open()" },
    { txt = "  Mappings", keys = "c h", cmd = "NvCheatsheet" },

    { txt = "─", hl = "NvDashFooter", no_gap = true, rep = true },

    {
      txt = function()
        local stats = require("lazy").stats()
        local ms = math.floor(stats.startuptime) .. " ms"
        return "  Loaded " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms
      end,
      hl = "NvDashFooter",
      no_gap = true,
    },

    { txt = "─", hl = "NvDashFooter", no_gap = true, rep = true },
  },
}

M.mason = {
  pkgs = tools.mason_packages,
}

M.colorify = {
  enabled = false,
}

return M
