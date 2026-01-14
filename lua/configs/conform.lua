local function find_config(bufnr, patterns)
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  if bufname == "" then
    return nil
  end
  return vim.fs.find(patterns, {
    upward = true,
    path = vim.fs.dirname(bufname),
    stop = vim.env.HOME,
  })[1]
end

local js_formatters = function(bufnr)
  local has_biome = find_config(bufnr, { "biome.json", "biome.jsonc" })
  local has_prettier = find_config(bufnr, {
    ".prettierrc",
    ".prettierrc.json",
    ".prettierrc.yml",
    ".prettierrc.yaml",
    ".prettierrc.js",
    ".prettierrc.cjs",
    ".prettierrc.mjs",
    "prettier.config.js",
    "prettier.config.cjs",
    "prettier.config.mjs",
  })

  -- Priority: biome > prettier
  if has_biome then
    return { "biome-check" }
  elseif has_prettier then
    return { "prettierd", "prettier", stop_after_first = true }
  else
    return { "prettierd", "prettier", stop_after_first = true }
  end
end

local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    css = { "biome-check", "prettierd", "prettier", stop_after_first = true },
    html = { "prettierd", "prettier", stop_after_first = true },
    javascript = js_formatters,
    typescript = js_formatters,
    javascriptreact = js_formatters,
    typescriptreact = js_formatters,
    json = { "biome-check", "prettierd", "prettier", stop_after_first = true },
    jsonc = { "biome-check", "prettierd", "prettier", stop_after_first = true },
  },

  -- format_on_save = {
  --   -- These options will be passed to conform.format()
  --   timeout_ms = 500,
  --   lsp_fallback = true,
  -- },
}

return options
