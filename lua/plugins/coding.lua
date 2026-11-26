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

  -- Undo history tree
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    keys = {
      { "<leader>u", "<cmd>UndotreeToggle<cr>", desc = "Toggle Undotree" },
    },
  },
}
