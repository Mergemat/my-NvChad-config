local overrides = require "configs.overrides"

return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    config = function()
      require "configs.conform"
    end,
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require("nvchad.configs.lspconfig").defaults()
      require "configs.lspconfig"
    end,
  },
  --
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "lua-language-server",
        "stylua",
        "pyright",
        -- web dev stuff
        "css-lsp",
        "html-lsp",
        "typescript-language-server",
        "eslint_d",
        "oxlint",
        "deno",
        "prettier",
        "biome",
        "solhint",
        "solidity-ls",
        "nomicfoundation-solidity-language-server",
        "eslint-lsp",
        "jsonls",
        "prisma-language-server",

        -- c/cpp stuff
        "clangd",
        "clang-format",
      },
    },
  },
  --
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim",
        "lua",
        "vimdoc",
        "html",
        "css",
        "javascript",
        "typescript",
        "tsx",
        "c",
        "markdown",
        "markdown_inline",
        "prisma",
        "go",
        "solidity",
      },
    },
  },
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

  {
    "mbbill/undotree",
    lazy = false,
  },

  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local harpoon = require "harpoon"
      harpoon:setup {}
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-context",
    lazy = false,
    enabled = true,
    opts = { mode = "cursor", max_lines = 3 },
    config = function()
      require("treesitter-context").setup {
        enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)

        max_lines = 4, -- How many lines the window should span. Values <= 0 mean no limit.
        throttle = true, -- Throttles plugin updates (may improve performance)
        patterns = { -- Match patterns for TS nodes. These get wrapped to match at word boundaries.
          -- For all filetypes
          -- Note that setting an entry here replaces all other patterns for this entry.
          -- By setting the 'default' entry below, you can control which nodes you want to
          -- appear in the context window.
          default = {
            "class",
            "function",
            "method",
          },
        },
      }
    end,
  },
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = false,
  },
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },
  {
    "kevinhwang91/nvim-bqf",
    lazy = false,
  },
  {
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    config = function()
      require("better_escape").setup()
    end,
  },
  {
    "nvim-tree/nvim-tree.lua",
    opts = overrides.nvimtree,
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
  },
  { "wakatime/vim-wakatime", lazy = false },
  {
    "laytan/cloak.nvim",
    event = "VeryLazy",
    opts = {},
  },
}
