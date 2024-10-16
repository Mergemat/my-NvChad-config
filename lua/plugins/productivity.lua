return {
  {
    "supermaven-inc/supermaven-nvim",
    event = "VeryLazy",
    config = function()
      require("supermaven-nvim").setup {
        disable_inline_completion = true,
      }
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      table.insert(opts.sources, 1, { name = "supermaven" })
      return opts
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
