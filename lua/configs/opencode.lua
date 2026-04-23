local function set_opencode_config()
  local buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)

  if name == "" then
    name = vim.fn.getcwd()
  end

  local start_dir = vim.fn.fnamemodify(name, ":p:h")
  local matches = vim.fs.find({ "opencode.json", "opencode.jsonc" }, { path = start_dir, upward = true })

  if matches[1] then
    vim.env.OPENCODE_CONFIG = matches[1]
  else
    vim.env.OPENCODE_CONFIG = nil
  end
end

vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged" }, {
  callback = set_opencode_config,
})
