return {
  {
    "tris203/precognition.nvim",
    event = "VeryLazy",
    opts = {
      startVisible = true,
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
    cmd = "UndotreeToggle",
    keys = {
      { "<leader>u", "<cmd>UndotreeToggle<cr>", desc = "Toggle Undotree" },
    },
  },
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>a", function() require("harpoon"):list():add() end, desc = "Harpoon add file" },
      { "<C-e>", function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list()) end, desc = "Harpoon menu" },
      { "<C-j>", function() require("harpoon"):list():select(1) end, desc = "Harpoon file 1" },
      { "<C-k>", function() require("harpoon"):list():select(2) end, desc = "Harpoon file 2" },
      { "<C-l>", function() require("harpoon"):list():select(3) end, desc = "Harpoon file 3" },
      { "<C-;>", function() require("harpoon"):list():select(4) end, desc = "Harpoon file 4" },
    },
    config = function()
      require("harpoon"):setup {}
    end,
  },
  --
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", function() require("flash").jump() end, mode = { "n", "x", "o" }, desc = "Flash" },
      { "S", function() require("flash").treesitter() end, mode = { "n", "x", "o" }, desc = "Flash Treesitter" },
      { "r", function() require("flash").remote() end, mode = "o", desc = "Remote Flash" },
      { "R", function() require("flash").treesitter_search() end, mode = { "o", "x" }, desc = "Treesitter Search" },
      { "<c-s>", function() require("flash").toggle() end, mode = "c", desc = "Toggle Flash Search" },
    },
  },

  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    lazy = true,
    opts = { enable_autocmd = false },
  },
  {
    "echasnovski/mini.comment",
    event = "VeryLazy",
    dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
    config = function()
      require("mini.comment").setup {
        options = {
          custom_commentstring = function()
            return require("ts_context_commentstring").calculate_commentstring() or vim.bo.commentstring
          end,
        },
      }
    end,
  },
  {
    "windwp/nvim-ts-autotag",
    event = "InsertEnter",
    ft = { "html", "javascript", "typescript", "javascriptreact", "typescriptreact", "svelte", "vue", "tsx", "jsx", "xml", "markdown" },
    opts = {},
  },

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
