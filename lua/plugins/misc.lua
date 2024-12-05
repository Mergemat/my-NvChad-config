return {
  { "wakatime/vim-wakatime", lazy = false },
  --
  {
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    config = function()
      require("better_escape").setup()
    end,
  },
}
