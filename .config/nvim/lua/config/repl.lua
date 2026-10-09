local M = {}

M.job_id = nil
M.buf_id = nil
M.win_id = nil

-- Helper to find python/ipython in local virtualenv or system
local function get_ipython_cmd()
  local cwd = vim.fn.getcwd()
  local match = vim.fs.find(".venv", { path = cwd, upward = true, type = "directory" })[1]
  if match then
    local venv_ipython = vim.fs.joinpath(match, "bin", "ipython")
    if vim.fn.executable(venv_ipython) == 1 then
      return { venv_ipython }
    end
    local venv_python = vim.fs.joinpath(match, "bin", "python")
    if vim.fn.executable(venv_python) == 1 then
      return { venv_python, "-m", "IPython" }
    end
  end

  if vim.fn.executable("ipython") == 1 then
    return { "ipython" }
  end
  return { "python3" }
end

-- Create or reveal the REPL split
M.create_repl = function()
  -- If terminal buffer exists and job is alive
  if M.job_id and M.buf_id and vim.api.nvim_buf_is_valid(M.buf_id) then
    -- If window is not currently open, split and display it
    if not (M.win_id and vim.api.nvim_win_is_valid(M.win_id)) then
      vim.cmd("botright 15split")
      vim.api.nvim_win_set_buf(0, M.buf_id)
      M.win_id = vim.api.nvim_get_current_win()
      vim.cmd("wincmd p") -- return focus to previous window
    end
    return
  end

  -- Otherwise, open fresh split and launch IPython
  local cur_win = vim.api.nvim_get_current_win()
  vim.cmd("botright 15new")
  M.win_id = vim.api.nvim_get_current_win()
  M.buf_id = vim.api.nvim_get_current_buf()

  -- Terminal buffer settings
  vim.bo[M.buf_id].buflisted = false
  vim.wo[M.win_id].number = false
  vim.wo[M.win_id].relativenumber = false

  local cmd = get_ipython_cmd()
  M.job_id = vim.fn.jobstart(cmd, {
    term = true,
    on_exit = function()
      M.job_id = nil
      M.buf_id = nil
      M.win_id = nil
    end,
  })

  -- Return focus to the code window
  vim.api.nvim_set_current_win(cur_win)
  vim.wait(150, function() return false end)
end

-- Toggle REPL window visibility
M.toggle = function()
  if M.win_id and vim.api.nvim_win_is_valid(M.win_id) then
    vim.api.nvim_win_close(M.win_id, true)
    M.win_id = nil
  else
    M.create_repl()
  end
end

-- Send raw text using bracketed paste mode to preserve indents
local function send_to_repl(text)
  M.create_repl()
  if not M.job_id then return end

  -- Bracketed paste escape sequences
  local paste_start = "\x1b[200~"
  local paste_end = "\x1b[201~"

  -- Ensure ending newline triggers execution
  if not text:match("\n$") then
    text = text .. "\n"
  end

  vim.fn.chansend(M.job_id, paste_start .. text .. paste_end .. "\n")
  vim.wait(50, function() return false end)
end

-- Send current line
M.send_line = function()
  local line = vim.api.nvim_get_current_line()
  send_to_repl(line)
end

-- Send visual selection
M.send_selection = function()
  -- Exit visual mode to update marks
  vim.cmd('execute "normal! \\<Esc>"')
  local start_pos = vim.api.nvim_buf_get_mark(0, "<")
  local end_pos = vim.api.nvim_buf_get_mark(0, ">")

  local lines = vim.api.nvim_buf_get_lines(0, start_pos[1] - 1, end_pos[1], false)
  if #lines == 0 then return end

  -- Trim columns for partial line visual selection
  lines[#lines] = string.sub(lines[#lines], 1, end_pos[2] + 1)
  lines[1] = string.sub(lines[1], start_pos[2] + 1)

  local text = table.concat(lines, "\n")
  send_to_repl(text)
end

-- Send current cell (between '# %%' markers, or current paragraph)
M.send_cell = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local total_lines = vim.api.nvim_buf_line_count(bufnr)

  local start_line = 1
  for l = cursor_line, 1, -1 do
    local text = vim.api.nvim_buf_get_lines(bufnr, l - 1, l, false)[1] or ""
    if text:match("^%s*#%s*%%%%") then
      start_line = l + 1
      break
    end
  end

  local end_line = total_lines
  for l = cursor_line + 1, total_lines do
    local text = vim.api.nvim_buf_get_lines(bufnr, l - 1, l, false)[1] or ""
    if text:match("^%s*#%s*%%%%") then
      end_line = l - 1
      break
    end
  end

  -- Trim empty lines
  while start_line <= end_line do
    local text = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, start_line, false)[1] or ""
    if text:match("%S") then break end
    start_line = start_line + 1
  end
  while end_line >= start_line do
    local text = vim.api.nvim_buf_get_lines(bufnr, end_line - 1, end_line, false)[1] or ""
    if text:match("%S") then break end
    end_line = end_line - 1
  end

  if start_line <= end_line then
    local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
    send_to_repl(table.concat(lines, "\n"))
  else
    vim.notify("Cell is empty", vim.log.levels.WARN)
  end
end

-- Send entire file/buffer
M.send_buffer = function()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  send_to_repl(table.concat(lines, "\n"))
end

-- Clear REPL screen
M.clear = function()
  if M.job_id then
    vim.fn.chansend(M.job_id, "%clear\n")
  end
end

return M
