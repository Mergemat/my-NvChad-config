return {
  {
    "supermaven-inc/supermaven-nvim",
    event = "VeryLazy",
    config = function()
      require("supermaven-nvim").setup {
        keymaps = {
          accept_suggestion = "<C-e>",
        },
        disable_keymaps = false,
      }
    end,
  },
  --
  {
    "mbbill/undotree",
    lazy = false,
  },
  --
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local harpoon = require "harpoon"
      harpoon:setup {}
    end,
  },
  --
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
  },
}
