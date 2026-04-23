local tools = require "configs.tools"

-- Miscellaneous plugins: tracking, escape handling
return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    event = "VeryLazy",
    dependencies = { "mason.nvim" },
    opts = {
      ensure_installed = tools.mason_packages,
      run_on_start = true,
      start_delay = 0,
    },
  },

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
  {
    "ThePrimeagen/vim-be-good",
    cmd = "VimBeGood",
  },
  { "vuciv/golf", cmd = "Golf" },
}
