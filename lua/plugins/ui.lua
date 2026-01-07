-- UI enhancements: colors, input, diagnostics display
return {
  -- Better input/select UI
  {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
    opts = {
      input = {
        enabled = true,
        default_prompt = "> ",
        border = "rounded",
        win_options = {
          winblend = 0,
          winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
        },
      },
      select = {
        enabled = true,
        backend = { "telescope", "builtin" },
        builtin = {
          border = "rounded",
          win_options = {
            winblend = 0,
            winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
          },
        },
      },
    },
  },

  -- Dim inactive windows
  {
    "levouh/tint.nvim",
    event = "WinNew",
    opts = {
      tint = -30,
      saturation = 0.6,
      tint_background_colors = false,
    },
  },

  -- Todo comments highlighting
  {
    "folke/todo-comments.nvim",
    event = "BufReadPost",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      signs = true,
      keywords = {
        FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG", "ISSUE" } },
        TODO = { icon = " ", color = "info" },
        HACK = { icon = " ", color = "warning" },
        WARN = { icon = " ", color = "warning", alt = { "WARNING" } },
        PERF = { icon = " ", color = "default", alt = { "OPTIM", "PERFORMANCE" } },
        NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
      },
      highlight = {
        multiline = false,
        before = "",
        keyword = "bg",
        after = "fg",
      },
    },
    keys = {
      { "]t", function() require("todo-comments").jump_next() end, desc = "Next todo comment" },
      { "[t", function() require("todo-comments").jump_prev() end, desc = "Prev todo comment" },
      { "<leader>xt", "<cmd>TodoTrouble<cr>", desc = "Todo (Trouble)" },
      { "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "Find todos" },
    },
  },

  -- Better diagnostics display
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "LspAttach",
    priority = 1000,
    opts = {
      preset = "modern",
      options = {
        show_source = true,
        multilines = true,
        show_all_diags_on_cursorline = true,
      },
    },
    config = function(_, opts)
      require("tiny-inline-diagnostic").setup(opts)
      vim.diagnostic.config({ virtual_text = false })
    end,
  },
}
