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

  -- Remind to use relative jumps
  {
    "jk-spam-reminder",
    dir = vim.fn.stdpath("config") .. "/lua/custom/jk-spam-reminder",
    event = "VeryLazy",
    config = function()
      require("custom.jk-spam-reminder").setup({
        threshold = 4, -- number of consecutive presses before warning
        timeout = 1000, -- reset counter after this many ms of inactivity
        message = "Use relative jumps! Try %dj or %dk instead",
      })
    end,
  },
}
