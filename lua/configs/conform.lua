local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    css = { "prettier" },
    html = { "prettier" },
    javascript = { "prettier" },
    typescript = { "prettier" },
    javascriptreact = { "prettier" },
    typescriptreact = { "prettier" },
    json = { "prettier" },
    jsonc = { "prettier" },
  },
  formatters = {
    injected = {
      options = {
        lang_to_formatters = {
          json = { "prettier" },
          jsonc = { "prettier" },
        },
      },
    },
  },

  ft_parsers = {
    json = "json",
    jsonc = "json",
  },

  -- format_on_save = {
  --   -- These options will be passed to conform.format()
  --   timeout_ms = 500,
  --   lsp_fallback = true,
  -- },
}

return options
