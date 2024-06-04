return {
  { "wakatime/vim-wakatime", lazy = false },
  --
  {
    "laytan/cloak.nvim",
    event = "VeryLazy",
    opts = {},
  },
  --
  {
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    config = function()
      require("better_escape").setup()
    end,
  },
}
