-- Supermaven-style ghost text, paid for by a ChatGPT subscription. Signs in with ChatGPT the way the
-- Codex CLI does and calls the same backend directly, which skips the CLI's agent harness (~1s faster).
local M = {}

local cfg = {
  model = "gpt-6.2-sol", -- fastest and steadiest in a 24-run benchmark: ~1.6s to first text, ~0.25s ahead of gpt-6.1-sol
  effort = "low",
  service_tier = "priority", -- the "Fast" tier in Codex; ~0.3s faster than default
  debounce_ms = 100,
  -- Prompt size barely moves latency (600 -> 11k tokens costs ~0.1s), so the model gets a lot of context.
  file_chars = 48000, -- the current file, windowed around the cursor when larger
  related_files = 3, -- other open buffers of the same filetype, most recently used first
  related_chars = 6000,
  edits_shown = 10, -- your recent edits in this filetype, as style examples
  edits_kept = 60,
  keys = { accept = "<C-e>", accept_word = "<C-l>", clear = "<C-]>" },
}

-- Codex CLI's public OAuth client: the only one whose tokens the ChatGPT-plan backend accepts.
local ISSUER = "https://auth.openai.com"
local CLIENT_ID = "app_EMoamEEZ73f0CkXaXp7hrann"
local REDIRECT = "http://localhost:1455/auth/callback" -- the redirect registered for that client
local ORIGINATOR = "codex_cli_rs"
local BACKEND = "https://chatgpt.com/backend-api/codex/responses"
local AUTH_FILE = vim.fn.stdpath "data" .. "/codex_complete/auth.json"
local EDITS_FILE = vim.fn.stdpath "data" .. "/codex_complete/edits.json"

local MARKER = "<<<CURSOR>>>"
local SYSTEM = [[
You are the inline autocomplete in the user's code editor. Your reply is inserted verbatim at ]] .. MARKER .. [[ in <current_file>.

Output only the code to insert. No markdown fences, no explanations, no surrounding quotes.

How to complete:
- Continue from exactly the cursor. If it is mid-word or mid-line, finish that word or line. Never repeat text before the cursor, and never duplicate text right after it (closing brackets, quotes, the rest of the line).
- Usually finish the current line or statement. Write several lines only when they are clearly implied, such as a body after a new signature, and never go past the end of the enclosing block.
- Use only names, functions, imports and APIs that exist in the provided code or that you are certain exist in its libraries.
- Indent every new line exactly as the surrounding code does.
- Prefer a likely guess over nothing. Output nothing only when the code at the cursor is already complete.

Write it the way this user writes code. <recent_edits> are things they typed recently and <related_files> are their other open files. Match their naming, formatting, quotes, semicolons, comment style, error handling, and library choices, and follow the conventions of <current_file> first.
]]

local ns = vim.api.nvim_create_namespace "codex_complete"
local enabled = true
local req -- the in-flight completion: { buf, row, col, tick, proc, text, raw, t0 }
local ghost -- the visible suggestion: { buf, row, col, tick, text }
local timer = assert(vim.uv.new_timer())
local last = {}
local edits = {} -- the user's recent insertions: { ft, path, text }, oldest first, persisted in EDITS_FILE
local seen = {} -- finished suggestions by cursor context, so backspacing to the same spot shows one instantly
local seen_order = {}
local prefetch = false -- right after an accept, ask for the next suggestion without the debounce

-- Auth ----------------------------------------------------------------------

local tokens -- { access_token, refresh_token, id_token, account_id, expires_at, email, plan }
local refreshing -- callbacks waiting on an in-flight refresh

local function b64url(bytes)
  return (vim.base64.encode(bytes):gsub("+", "-"):gsub("/", "_"):gsub("=", ""))
end

local function jwt_claims(jwt)
  local p = jwt:match("^[^.]+%.([^.]+)"):gsub("-", "+"):gsub("_", "/")
  return vim.json.decode(vim.base64.decode(p .. string.rep("=", (4 - #p % 4) % 4)))
end

local function urlencode(s)
  return (s:gsub("[^%w%-._~]", function(c)
    return ("%%%02X"):format(c:byte())
  end))
end

local function urldecode(s)
  return (s:gsub("+", " "):gsub("%%(%x%x)", function(h)
    return string.char(tonumber(h, 16))
  end))
end

local function form(t)
  local parts = {}
  for k, v in pairs(t) do
    parts[#parts + 1] = k .. "=" .. urlencode(v)
  end
  return table.concat(parts, "&")
end

-- Quotes a value for a curl config file. Requests go through `--config -` on stdin so tokens never show up in `ps`.
local function q(s)
  return '"' .. s:gsub("\\", "\\\\"):gsub('"', '\\"') .. '"'
end

local function load_tokens()
  local f = io.open(AUTH_FILE)
  if not f then
    return nil
  end
  local ok, t = pcall(vim.json.decode, f:read "*a")
  f:close()
  return ok and t or nil
end

local function store_tokens(res)
  local prev = tokens or {}
  local id_token = res.id_token or prev.id_token
  local access, id = jwt_claims(res.access_token), jwt_claims(id_token)
  tokens = {
    access_token = res.access_token,
    refresh_token = res.refresh_token or prev.refresh_token,
    id_token = id_token,
    account_id = access["https://api.openai.com/auth"].chatgpt_account_id,
    expires_at = access.exp,
    email = id.email,
    plan = id["https://api.openai.com/auth"].chatgpt_plan_type,
  }
  vim.fn.mkdir(vim.fs.dirname(AUTH_FILE), "p")
  local fd = assert(vim.uv.fs_open(AUTH_FILE, "w", tonumber("600", 8)))
  vim.uv.fs_write(fd, vim.json.encode(tokens))
  vim.uv.fs_close(fd)
end

local function post_token(params, cb)
  vim.system({ "curl", "--silent", "--show-error", "--config", "-" }, {
    stdin = table.concat({
      "url = " .. q(ISSUER .. "/oauth/token"),
      'header = "Content-Type: application/x-www-form-urlencoded"',
      "data-raw = " .. q(form(params)),
    }, "\n"),
  }, function(out)
    vim.schedule(function()
      local ok, res = pcall(vim.json.decode, out.stdout or "")
      if out.code == 0 and ok and res.access_token then
        return cb(res)
      end
      local why = ok and type(res) == "table" and (res.error_description or vim.inspect(res.error)) or nil
      cb(nil, why or vim.trim(out.stderr or "") .. vim.trim(out.stdout or ""))
    end)
  end)
end

-- Calls cb(access_token) or cb(nil, why), refreshing the token first when it's about to expire.
local function with_token(cb)
  tokens = tokens or load_tokens()
  if not tokens then
    return cb(nil, "not signed in, run :CodexComplete login")
  end
  if tokens.expires_at - os.time() > 300 then
    return cb(tokens.access_token)
  end
  if refreshing then
    refreshing[#refreshing + 1] = cb
    return
  end
  refreshing = { cb }
  post_token({
    grant_type = "refresh_token",
    refresh_token = tokens.refresh_token,
    client_id = CLIENT_ID,
    scope = "openid profile email offline_access",
  }, function(res, why)
    if res then
      store_tokens(res)
    end
    local waiting = refreshing
    refreshing = nil
    for _, f in ipairs(waiting) do
      f(
        res and tokens.access_token,
        not res and ("token refresh failed (" .. why .. "), run :CodexComplete login") or nil
      )
    end
  end)
end

function M.login()
  local verifier = b64url(vim.uv.random(32))
  local challenge = b64url((vim.fn.sha256(verifier):gsub("%x%x", function(h)
    return string.char(tonumber(h, 16))
  end)))
  local state = b64url(vim.uv.random(16))

  local server = vim.uv.new_tcp()
  local ok, err = server:bind("127.0.0.1", 1455)
  if not ok then
    server:close()
    return vim.notify(
      "codex complete: port 1455 is busy (" .. err .. "). Is another sign-in open?",
      vim.log.levels.ERROR
    )
  end
  local function stop()
    if not server:is_closing() then
      server:close()
    end
  end
  vim.defer_fn(stop, 5 * 60 * 1000) -- an abandoned sign-in shouldn't hold the port forever

  server:listen(8, function()
    local client = vim.uv.new_tcp()
    server:accept(client)
    local data = ""
    client:read_start(function(_, chunk)
      if not chunk then
        return client:close()
      end
      data = data .. chunk
      if not data:find "\r\n\r\n" then
        return
      end
      client:read_stop()
      local query = (data:match "^GET (%S+)" or ""):match "^/auth/callback%?(.*)$"
      local params = {}
      for k, v in (query or ""):gmatch "([^&=]+)=([^&]*)" do
        params[k] = urldecode(v)
      end
      local good = params.state == state and params.code ~= nil
      local reply = not query and "Not found"
        or good and "Signed in. You can close this tab and go back to Neovim."
        or "Sign-in failed. Check Neovim for details."
      client:write(
        ("HTTP/1.1 %s\r\nContent-Type: text/plain\r\nConnection: close\r\n\r\n%s"):format(
          query and "200 OK" or "404 Not Found",
          reply
        ),
        function()
          client:close()
        end
      )
      if not query then
        return -- e.g. /favicon.ico; keep waiting for the real callback
      end
      stop()
      vim.schedule(function()
        if not good then
          local why = params.error_description or params.error or "state mismatch"
          return vim.notify("codex complete: sign-in failed: " .. why, vim.log.levels.ERROR)
        end
        post_token({
          grant_type = "authorization_code",
          code = params.code,
          redirect_uri = REDIRECT,
          client_id = CLIENT_ID,
          code_verifier = verifier,
        }, function(res, why)
          if not res then
            return vim.notify("codex complete: sign-in failed: " .. why, vim.log.levels.ERROR)
          end
          store_tokens(res)
          last.error = nil
          vim.notify(("codex complete: signed in as %s (%s)"):format(tokens.email, tokens.plan))
        end)
      end)
    end)
  end)

  vim.ui.open(ISSUER .. "/oauth/authorize?" .. form {
    response_type = "code",
    client_id = CLIENT_ID,
    redirect_uri = REDIRECT,
    scope = "openid profile email offline_access",
    code_challenge = challenge,
    code_challenge_method = "S256",
    id_token_add_organizations = "true",
    codex_cli_simplified_flow = "true",
    state = state,
    originator = ORIGINATOR,
  })
  vim.notify "codex complete: finish signing in with ChatGPT in your browser"
end

function M.logout()
  os.remove(AUTH_FILE)
  tokens = nil
  vim.notify "codex complete: signed out"
end

-- Ghost text ----------------------------------------------------------------

local function cursor()
  local pos = vim.api.nvim_win_get_cursor(0)
  return vim.api.nvim_get_current_buf(), pos[1] - 1, pos[2]
end

local function clear()
  if ghost then
    pcall(vim.api.nvim_buf_clear_namespace, ghost.buf, ns, 0, -1)
    ghost = nil
  end
end

local function render()
  vim.api.nvim_buf_clear_namespace(ghost.buf, ns, 0, -1)
  ghost.tick = vim.api.nvim_buf_get_changedtick(ghost.buf)
  local lines = vim.split(ghost.text, "\n", { plain = true })
  local virt_lines = {}
  for i = 2, #lines do
    virt_lines[#virt_lines + 1] = { { lines[i], "CodexGhost" } }
  end
  vim.api.nvim_buf_set_extmark(ghost.buf, ns, ghost.row, ghost.col, {
    virt_text = { { lines[1], "CodexGhost" } },
    virt_text_pos = "inline",
    virt_lines = #virt_lines > 0 and virt_lines or nil,
  })
end

local function clean(text)
  return (text:gsub("^```[^\n]*\n", ""):gsub("\n?```%s*$", ""):gsub("%s+$", ""))
end

local function show(r)
  local text = clean(r.text)
  local buf, row, col = cursor()
  if text == "" or buf ~= r.buf or row ~= r.row or col ~= r.col or vim.fn.mode() ~= "i" then
    return
  end
  ghost = { buf = buf, row = row, col = col, text = text }
  render()
end

-- Keys a suggestion by everything that decides it locally: the buffer, the line, and what's before the cursor on it.
local function seen_key(buf, row, col)
  return ("%d:%d:%s"):format(buf, row, vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]:sub(1, col))
end

local function remember_seen(key, text)
  if not seen[key] then
    seen_order[#seen_order + 1] = key
    if #seen_order > 200 then
      seen[table.remove(seen_order, 1)] = nil
    end
  end
  seen[key] = text
end

-- Requests ------------------------------------------------------------------

local function cancel()
  timer:stop()
  if req and req.proc then
    req.proc:kill(15)
  end
  req = nil
end

local function on_event(r, ev)
  if ev.type == "response.output_text.delta" then
    if r.text == "" then
      last.ms = math.floor((vim.uv.hrtime() - r.t0) / 1e6)
    end
    r.text = r.text .. ev.delta
    show(r)
  elseif ev.type == "response.failed" or ev.type == "error" then
    local e = ev.response and ev.response.error or ev.error or ev
    last.error = e.message or vim.inspect(e)
  end
end

local function on_done(r, code, stderr)
  if req ~= r then
    return -- cancelled
  end
  req = nil
  local err
  if r.raw ~= "" then -- a non-SSE body means the backend rejected the request
    local ok, body = pcall(vim.json.decode, r.raw)
    local e = ok and type(body) == "table" and (body.error or body) or {}
    err = e.message or e.detail or vim.trim(r.raw)
  elseif code ~= 0 then
    err = "curl: " .. vim.trim(stderr or "")
  end
  if not err then
    local text = clean(r.text)
    last.empty, last.error = text == "", nil
    if text ~= "" then
      remember_seen(r.key, text)
    end
    return
  end
  if err ~= last.error then -- once per distinct error, so a bad token doesn't spam every keystroke
    vim.notify("codex complete: " .. err, vim.log.levels.WARN)
  end
  last.error = err
end

local function stream(r, prompt, token)
  local body = vim.json.encode {
    model = cfg.model,
    instructions = SYSTEM,
    input = { { type = "message", role = "user", content = { { type = "input_text", text = prompt } } } },
    reasoning = { effort = cfg.effort },
    service_tier = cfg.service_tier,
    -- Same key per project so the backend can reuse its cache of the unchanged prompt prefix.
    prompt_cache_key = "codex_complete:" .. vim.fn.sha256(vim.fn.getcwd()):sub(1, 32),
    stream = true,
    store = false,
  }
  local pending = ""
  r.proc = vim.system({ "curl", "--silent", "--show-error", "--no-buffer", "--config", "-" }, {
    stdin = table.concat({
      "url = " .. q(BACKEND),
      "header = " .. q("Authorization: Bearer " .. token),
      "header = " .. q("chatgpt-account-id: " .. tokens.account_id),
      "header = " .. q("originator: " .. ORIGINATOR),
      'header = "OpenAI-Beta: responses=experimental"',
      'header = "Content-Type: application/json"',
      'header = "Accept: text/event-stream"',
      "data-raw = " .. q(body),
    }, "\n"),
    stdout = function(_, data)
      if not data then
        return
      end
      pending = pending .. data
      local lines = vim.split(pending, "\n", { plain = true })
      pending = table.remove(lines)
      vim.schedule(function()
        for _, line in ipairs(lines) do
          local json = line:match "^data: (.*)"
          local ok, ev = pcall(vim.json.decode, json or "")
          if req == r and json and ok then
            on_event(r, ev)
          elseif not json and not line:match "^event:" and not line:match "^:" then
            r.raw = r.raw .. line
          end
        end
      end)
    end,
  }, function(out)
    vim.schedule(function()
      r.raw = r.raw .. vim.trim(pending)
      on_done(r, out.code, out.stderr)
    end)
  end)
end

local function eligible()
  return enabled and vim.bo.buftype == "" and vim.bo.modifiable
end

-- Context --------------------------------------------------------------------

local function relpath(buf)
  return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":~:.")
end

local function load_edits()
  local f = io.open(EDITS_FILE)
  if f then
    local ok, t = pcall(vim.json.decode, f:read "*a")
    f:close()
    edits = ok and type(t) == "table" and t or {}
  end
end

local function save_edits()
  vim.fn.mkdir(vim.fs.dirname(EDITS_FILE), "p")
  local f = io.open(EDITS_FILE, "w")
  if f then
    f:write(vim.json.encode(edits))
    f:close()
  end
end

-- On InsertLeave, the '[ '] marks span what was just typed: that's the user's own style, in their own words.
local function remember_edit()
  local buf = vim.api.nvim_get_current_buf()
  if not eligible() then
    return
  end
  local s, e = vim.api.nvim_buf_get_mark(buf, "["), vim.api.nvim_buf_get_mark(buf, "]")
  if s[1] == 0 or e[1] < s[1] or e[1] - s[1] > 80 then
    return -- nothing typed, or a paste too big to be a style sample
  end
  local text = table.concat(vim.api.nvim_buf_get_lines(buf, s[1] - 1, e[1], false), "\n")
  if #vim.trim(text) < 20 or (edits[#edits] and edits[#edits].text == text) then
    return
  end
  load_edits() -- pick up what other Neovim instances saved, so we don't overwrite it
  edits[#edits + 1] = { ft = vim.bo[buf].filetype, path = relpath(buf), text = text:sub(1, 2000) }
  while #edits > cfg.edits_kept do
    table.remove(edits, 1)
  end
  save_edits()
end

-- Stable parts first (other files, past edits), the current file last, so consecutive prompts share a long prefix.
local function build_prompt(buf, row, col)
  local ft = vim.bo[buf].filetype
  local parts = {}

  local others = vim.tbl_filter(function(b)
    return b.bufnr ~= buf and b.name ~= "" and vim.bo[b.bufnr].filetype == ft and vim.bo[b.bufnr].buftype == ""
  end, vim.fn.getbufinfo { buflisted = 1, bufloaded = 1 })
  table.sort(others, function(a, b)
    return a.lastused > b.lastused
  end)
  if #others > 0 then
    parts[#parts + 1] = "<related_files>"
    for i = 1, math.min(cfg.related_files, #others) do
      local text = table.concat(vim.api.nvim_buf_get_lines(others[i].bufnr, 0, -1, false), "\n")
      parts[#parts + 1] = ("<file path=%q>\n%s\n</file>"):format(
        relpath(others[i].bufnr),
        text:sub(1, cfg.related_chars)
      )
    end
    parts[#parts + 1] = "</related_files>"
  end

  local recent = {}
  for i = #edits, 1, -1 do
    if edits[i].ft == ft and #recent < cfg.edits_shown then
      table.insert(recent, 1, ("<edit path=%q>\n%s\n</edit>"):format(edits[i].path, edits[i].text))
    end
  end
  if #recent > 0 then
    parts[#parts + 1] = "<recent_edits>\n" .. table.concat(recent, "\n") .. "\n</recent_edits>"
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local line = lines[row + 1]
  local before = table.concat(vim.list_slice(lines, 1, row), "\n") .. (row > 0 and "\n" or "") .. line:sub(1, col)
  local after = line:sub(col + 1) .. "\n" .. table.concat(vim.list_slice(lines, row + 2), "\n")
  local budget_after = math.floor(cfg.file_chars / 4)
  local budget_before = cfg.file_chars - math.min(#after, budget_after)
  if #before > budget_before then
    before = before:sub(-budget_before):gsub("^[^\n]*\n", "") -- cut at a line boundary
  end
  if #after > budget_after then
    after = after:sub(1, budget_after):gsub("\n[^\n]*$", "")
  end
  parts[#parts + 1] = ("<current_file path=%q filetype=%q>\n%s%s%s\n</current_file>"):format(
    relpath(buf),
    ft,
    before,
    MARKER,
    after
  )
  return table.concat(parts, "\n\n")
end

local function request()
  if not eligible() or vim.fn.mode() ~= "i" then
    return
  end
  local buf, row, col = cursor()
  local key = seen_key(buf, row, col)
  local prompt = build_prompt(buf, row, col)

  local r = {
    key = key,
    buf = buf,
    row = row,
    col = col,
    tick = vim.api.nvim_buf_get_changedtick(buf),
    text = "",
    raw = "",
    t0 = vim.uv.hrtime(),
  }
  req = r
  with_token(function(token, why)
    if req ~= r then
      return
    end
    if not token then
      req = nil
      if last.error ~= why then
        vim.notify("codex complete: " .. why, vim.log.levels.WARN)
      end
      last.error = why
      return
    end
    stream(r, prompt, token)
  end)
end

-- Events --------------------------------------------------------------------

local function on_text_changed()
  local buf, row, col = cursor()
  if ghost and ghost.buf == buf and ghost.row == row then
    if col == ghost.col then
      return -- our own edit from accept_word, which already moved the ghost
    end
    -- Typing the suggested characters shortens the ghost instead of discarding it.
    local typed = vim.api.nvim_get_current_line():sub(ghost.col + 1, col)
    if col > ghost.col and ghost.text:sub(1, #typed) == typed then
      ghost.text, ghost.col = ghost.text:sub(#typed + 1), col
      if ghost.text == "" then
        clear()
      else
        render()
      end
      return
    end
  end
  clear()
  cancel()
  local delay = prefetch and 0 or cfg.debounce_ms
  prefetch = false
  if not eligible() then
    return
  end
  local hit = seen[seen_key(buf, row, col)]
  if hit then
    ghost = { buf = buf, row = row, col = col, text = hit }
    return render()
  end
  timer:start(delay, 0, vim.schedule_wrap(request))
end

-- CursorMovedI also fires for typing (before TextChangedI); only motion without an edit clears here.
local function on_cursor_moved()
  local buf, row, col = cursor()
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local function moved(o)
    return o and o.tick == tick and (o.buf ~= buf or o.row ~= row or o.col ~= col)
  end
  if moved(ghost) then
    clear()
  end
  if moved(req) then
    cancel()
  end
end

-- Actions -------------------------------------------------------------------

local function contains_in_order(text, chars)
  local i = 0
  for c in chars:gsub("%s", ""):gmatch "." do
    i = text:find(c, i + 1, true)
    if not i then
      return false
    end
  end
  return true
end

function M.accept(word_only)
  if not ghost or ghost.buf ~= vim.api.nvim_get_current_buf() then
    return false
  end
  local text = ghost.text
  if word_only then
    text = text:match "^%s*[%w_]+" or text:match "^%s*[^%w_%s]+" or text
  end
  local lines = vim.split(text, "\n", { plain = true })
  local row, col = ghost.row, ghost.col
  -- Autopairs leaves closers after the cursor that the suggestion repeats; replace them instead of duplicating.
  local line = vim.api.nvim_buf_get_lines(ghost.buf, row, row + 1, false)[1]
  local tail, replace_to = line:sub(col + 1), col
  if not word_only and tail:match "^[%)%]}>\"'`;,%s]+$" and contains_in_order(lines[1], tail) then
    replace_to = #line
  end
  vim.api.nvim_buf_set_text(ghost.buf, row, col, row, replace_to, lines)
  local end_row = row + #lines - 1
  local end_col = (#lines == 1 and col or 0) + #lines[#lines]
  vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col })
  local rest = ghost.text:sub(#text + 1)
  if rest == "" then
    clear()
    prefetch = true
  else
    ghost.text, ghost.row, ghost.col = rest, end_row, end_col
    render()
  end
  return true
end

function M.accept_word()
  return M.accept(true)
end

function M.clear()
  local had = ghost ~= nil
  clear()
  cancel()
  return had
end

function M.toggle()
  enabled = not enabled
  if not enabled then
    M.clear()
  end
  vim.notify("codex complete " .. (enabled and "on" or "off"))
end

function M.status()
  tokens = tokens or load_tokens()
  vim.notify(table.concat({
    "codex complete: " .. (enabled and "on" or "off"),
    "account: "
      .. (tokens and ("%s (%s)"):format(tokens.email, tokens.plan) or "not signed in, run :CodexComplete login"),
    ("model: %s (%s, %s)"):format(cfg.model, cfg.effort, cfg.service_tier),
    "last suggestion appeared after: " .. (last.ms and (last.ms .. " ms") or "none"),
    "last reply: " .. (last.empty == nil and "none" or last.empty and "empty (model had nothing to add)" or "text"),
    "last error: " .. (last.error or "none"),
    ("remembered edits (style examples): %d, see :CodexComplete edits"):format(#edits),
  }, "\n"))
end

function M.edits()
  vim.cmd.split(EDITS_FILE)
end

function M.forget()
  edits = {}
  save_edits()
  vim.notify "codex complete: forgot remembered edits"
end

-- Falls back to whatever the key did before, so <C-e>/<C-l> still move the cursor with no suggestion.
local function map(lhs, action)
  local old = vim.fn.maparg(lhs, "i", false, true)
  vim.keymap.set("i", lhs, function()
    if action() then
      return
    end
    if old.callback then
      old.callback()
    elseif old.rhs and old.rhs ~= "" then
      vim.api.nvim_feedkeys(vim.keycode(old.rhs), old.noremap == 1 and "n" or "m", false)
    else
      vim.api.nvim_feedkeys(vim.keycode(lhs), "n", false)
    end
  end, { desc = "Codex complete" })
end

function M.setup(opts)
  cfg = vim.tbl_deep_extend("force", cfg, opts or {})
  vim.api.nvim_set_hl(0, "CodexGhost", { link = "Comment", default = true })

  local group = vim.api.nvim_create_augroup("codex_complete", { clear = true })
  vim.api.nvim_create_autocmd("TextChangedI", { group = group, callback = on_text_changed })
  vim.api.nvim_create_autocmd("CursorMovedI", { group = group, callback = on_cursor_moved })
  vim.api.nvim_create_autocmd({ "InsertLeave", "BufLeave" }, { group = group, callback = M.clear })
  vim.api.nvim_create_autocmd("InsertLeave", { group = group, callback = remember_edit })
  load_edits()

  map(cfg.keys.accept, M.accept)
  map(cfg.keys.accept_word, M.accept_word)
  map(cfg.keys.clear, M.clear)

  local commands = {
    status = M.status,
    toggle = M.toggle,
    login = M.login,
    logout = M.logout,
    edits = M.edits,
    forget = M.forget,
  }
  vim.api.nvim_create_user_command("CodexComplete", function(a)
    (commands[a.args] or M.status)()
  end, {
    nargs = "?",
    complete = function()
      return vim.tbl_keys(commands)
    end,
  })
end

return M
