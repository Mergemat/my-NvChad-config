-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "poimandres",
  transparency = true,
}

M.ui = {
  statusline = {
    theme = "minimal",
  },
  cmp = {
    format_colors = {
      tailwind = true,
    },
    icons_left = true,

    icons = true,
  },
  tabufline = {
    order = { "treeOffset", "buffers" },
  },
}

M.nvdash = {
  load_on_startup = true,
  header = {
    " .o o  .'.+  +'. . . o    *..  + '      '.*.   ' * ",
    "'..o'+...     .   oo  .       '+''  .'   ' **'++ . ",
    " '  ..   +   *' * * '.+ ' o     '    o' ' '   ..+' ",
    ".+ o. . *  .  '   +'++   o *'   o  . +  '. ..   . +",
    "    +  .'+. '* +   o.'+ ..    *..  .o  +    'o. '+ ",
    "      +   \\  .     . ''.'    'o    ' '. . ..     + ",
    "  .  +     \\    :.  .+'+o*.+..     o+.o. .' + . ' +",
    " . +.  +.   *.'*''::._' +.'     + . +o    o       .",
    "         ..'.       '._)   *'    .*  o  '    o   o* ",
    "  o*   o  . +* '* + + + ' + .  .. *  * +  '   +  '  ",
    "'           .  o .  ' .  '  +   ..        .   o *  ",
    "o    . o    .       +'.'.   ' ' +. .    *   *      ",
  },
}

M.mason = {
  pkgs = {

    "lua-language-server",
    "stylua",
    "pyright",
    -- web dev stuff
    "css-lsp",
    "html-lsp",
    "typescript-language-server",
    "eslint_d",
    "oxlint",
    "deno",
    "prettier",
    "biome",
    "solhint",
    "solidity-ls",
    "nomicfoundation-solidity-language-server",
    "eslint-lsp",
    "jsonls",
    "prisma-language-server",

    -- c/cpp stuff
    "clangd",
    "clang-format",
  },
}

M.colorify = {
  enabled = false,
}

return M
