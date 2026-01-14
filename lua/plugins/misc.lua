-- Miscellaneous plugins: tracking, escape handling
return {
  -- Time tracking
  { "wakatime/vim-wakatime", event = "VeryLazy" },

  -- Better escape from insert mode
  {
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    config = function()
      require("better_escape").setup()
    end,
  },
}
