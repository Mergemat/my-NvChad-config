local M = {}

M.nvimtree = {
  git = {
    enable = true,
  },
  view = {
    adaptive_size = true,
    side = "left",
    width = 25,
  },

  actions = {
    open_file = {
      resize_window = true,
      quit_on_open = true,
    },
  },

  renderer = {
    -- highlight_opened_files = "all",
    highlight_git = true,
    icons = {
      show = {
        git = true,
      },
      glyphs = {
        git = {
          unstaged = "",
          deleted = "",
          untracked = "",
        },
      },
    },
  },
  filters = {
    dotfiles = true,
  },
}

return M
