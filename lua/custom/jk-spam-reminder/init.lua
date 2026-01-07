local M = {}

local defaults = {
  threshold = 7,
  timeout = 1000,
  message_timeout = 2000,
  message = "STOP SPAMMING! Use %dj or %dk",
}

local state = {
  count = 0,
  last_key = nil,
  timer = nil,
  win = nil,
  buf = nil,
}

local function reset_state()
  state.count = 0
  state.last_key = nil
end

local function close_popup()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
    state.win = nil
  end
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    vim.api.nvim_buf_delete(state.buf, { force = true })
    state.buf = nil
  end
end

local function show_warning(key, count)
  close_popup()

  local msg = string.format(M.config.message, count, count)
  local padding = 4
  local width = #msg + padding
  local height = 3

  -- Create buffer
  state.buf = vim.api.nvim_create_buf(false, true)
  local lines = {
    string.rep(" ", width),
    string.rep(" ", math.floor((width - #msg) / 2)) .. msg .. string.rep(" ", math.ceil((width - #msg) / 2)),
    string.rep(" ", width),
  }
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)

  -- Create centered floating window
  local ui = vim.api.nvim_list_uis()[1]
  local row = math.floor((ui.height - height) / 2)
  local col = math.floor((ui.width - width) / 2)

  state.win = vim.api.nvim_open_win(state.buf, false, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    zindex = 100,
  })

  -- Make it obnoxious with red background
  vim.api.nvim_set_hl(0, "JKSpamWarning", { bg = "#ff0000", fg = "#ffffff", bold = true })
  vim.api.nvim_win_set_option(state.win, "winhl", "Normal:JKSpamWarning,FloatBorder:JKSpamWarning")

  -- Flash effect
  local flash_count = 0
  local flash_timer = vim.loop.new_timer()
  flash_timer:start(0, 150, vim.schedule_wrap(function()
    if not state.win or not vim.api.nvim_win_is_valid(state.win) then
      flash_timer:stop()
      return
    end

    flash_count = flash_count + 1
    local hl = flash_count % 2 == 0 and "JKSpamWarning" or "WarningMsg"
    vim.api.nvim_win_set_option(state.win, "winhl", "Normal:" .. hl .. ",FloatBorder:" .. hl)

    if flash_count >= 10 then
      flash_timer:stop()
    end
  end))

  -- Auto close after timeout
  vim.defer_fn(function()
    close_popup()
  end, M.config.message_timeout)
end

local function create_mapping(key)
  vim.keymap.set("n", key, function()
    -- Cancel existing timer
    if state.timer then
      state.timer:stop()
    end

    -- Check if same key pressed consecutively
    if state.last_key == key then
      state.count = state.count + 1
    else
      state.count = 1
      state.last_key = key
    end

    -- Show warning if threshold exceeded (defer to avoid expr mapping issues)
    if state.count == M.config.threshold then
      vim.schedule(function()
        show_warning(key, state.count)
      end)
    end

    -- Reset after timeout
    state.timer = vim.defer_fn(function()
      reset_state()
    end, M.config.timeout)

    -- Execute the original key
    return key
  end, { expr = true, noremap = true })
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", defaults, opts or {})

  create_mapping("j")
  create_mapping("k")
end

return M
