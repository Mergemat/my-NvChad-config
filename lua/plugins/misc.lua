return {
  { "wakatime/vim-wakatime", event = "VeryLazy" },
  --
  {
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    config = function()
      require("better_escape").setup()
    end,
  },
}
