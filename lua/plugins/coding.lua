-- Coding assistance: AI, motion hints, undo history
return {
  -- Motion hints
  {
    "tris203/precognition.nvim",
    event = "VeryLazy",
    opts = {
      startVisible = true,
    },
  },

  -- AI completion
  {
    "supermaven-inc/supermaven-nvim",
    event = "VeryLazy",
    config = function()
      require("supermaven-nvim").setup {
        keymaps = {
          accept_suggestion = "<C-e>",
        },
      }
    end,
  },

  -- Undo history tree
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    keys = {
      { "<leader>u", "<cmd>UndotreeToggle<cr>", desc = "Toggle Undotree" },
    },
  },

  -- AI coding assistant
  {
    "NickvanDyke/opencode.nvim",
    dependencies = {
      { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
    },
    keys = {
      { "<C-a>", function() require("opencode").ask("@this: ", { submit = true }) end, mode = { "n", "x" }, desc = "Ask opencode" },
      { "<C-x>", function() require("opencode").select() end, mode = { "n", "x" }, desc = "Execute opencode action" },
      { "<C-.>", function() require("opencode").toggle() end, mode = { "n", "t" }, desc = "Toggle opencode" },
      { "go", function() return require("opencode").operator "@this " end, mode = { "n", "x" }, expr = true, desc = "Add range to opencode" },
      { "goo", function() return require("opencode").operator "@this " .. "_" end, expr = true, desc = "Add line to opencode" },
      { "<S-C-u>", function() require("opencode").command "session.half.page.up" end, desc = "opencode half page up" },
      { "<S-C-d>", function() require("opencode").command "session.half.page.down" end, desc = "opencode half page down" },
    },
    config = function()
      vim.g.opencode_opts = {}
      vim.o.autoread = true
      vim.keymap.set("n", "+", "<C-a>", { desc = "Increment", noremap = true })
      vim.keymap.set("n", "-", "<C-x>", { desc = "Decrement", noremap = true })
    end,
  },
}
