local M = {}

-- Find the project virtual environment (.venv)
function M.get_project_venv(bufnr)
  bufnr = bufnr or 0
  local buf_name = vim.api.nvim_buf_get_name(bufnr)
  local start_dir = (buf_name ~= "" and vim.fs.dirname(buf_name)) or vim.fn.getcwd()

  local match = vim.fs.find(".venv", { path = start_dir, upward = true, type = "directory" })[1]
  if match then
    return match
  end

  if vim.env.VIRTUAL_ENV and vim.fn.isdirectory(vim.env.VIRTUAL_ENV) == 1 then
    return vim.env.VIRTUAL_ENV
  end

  return nil
end

-- Resolve or auto-register the Jupyter kernel for the current project/buffer
-- Always enforces the project's .venv kernel. Never uses or falls back to global python3!
function M.resolve_kernel(bufnr)
  bufnr = bufnr or 0

  -- 1. Detect project .venv (searches upward from buffer path or cwd)
  local venv = M.get_project_venv(bufnr)
  if venv then
    local venv_python = vim.fs.joinpath(venv, "bin", "python")
    local project_dir = vim.fs.dirname(venv)
    local project_name = vim.fs.basename(project_dir):gsub("[^%w_%-]", "_")

    local available = vim.fn.MoltenAvailableKernels and vim.fn.MoltenAvailableKernels() or {}
    if vim.tbl_contains(available, project_name) then
      return project_name
    end

    -- If not yet registered with Jupyter, auto-register using the project venv python
    if vim.fn.executable(venv_python) == 1 then
      -- Verify ipykernel is installed; auto-install via uv if missing
      local check_res = vim.fn.system({ venv_python, "-m", "ipykernel", "--version" })
      if vim.v.shell_error ~= 0 then
        vim.notify("Installing ipykernel in " .. project_name .. " (.venv) via uv...", vim.log.levels.INFO)
        vim.fn.system({ "uv", "pip", "install", "--python", venv_python, "ipykernel" })
      end

      local res = vim.fn.system({
        venv_python,
        "-m",
        "ipykernel",
        "install",
        "--user",
        "--name",
        project_name,
        "--display-name",
        "Python (" .. project_name .. ")",
      })
      if vim.v.shell_error == 0 then
        vim.notify("Auto-registered Jupyter kernel for .venv: " .. project_name, vim.log.levels.INFO)
        return project_name
      else
        vim.notify(
          "Failed to auto-register Jupyter kernel for .venv (" .. project_name .. "):\n" .. res,
          vim.log.levels.ERROR
        )
        return nil
      end
    end
  end

  -- 2. If .ipynb metadata specifies a specific non-default custom kernel (NOT "python3")
  local filename = vim.api.nvim_buf_get_name(bufnr)
  if filename:match("%.ipynb$") and vim.fn.filereadable(filename) == 1 then
    local ok, lines = pcall(vim.fn.readfile, filename)
    if ok and lines then
      local json_ok, data = pcall(vim.json.decode, table.concat(lines, "\n"))
      if json_ok and data and data.metadata and data.metadata.kernelspec and data.metadata.kernelspec.name then
        local spec_name = data.metadata.kernelspec.name
        if spec_name ~= "python3" then
          local available = vim.fn.MoltenAvailableKernels and vim.fn.MoltenAvailableKernels() or {}
          if vim.tbl_contains(available, spec_name) then
            return spec_name
          end
        end
      end
    end
  end

  -- Never fall back to global python3!
  return nil
end

-- Check if a kernel is attached to the current buffer
local function is_buf_initialized()
  local ok, k = pcall(function()
    return require("molten.status").kernels()
  end)
  return ok and k and k ~= ""
end

-- Ensure kernel is initialized before executing actions
function M.ensure_init(callback)
  if is_buf_initialized() then
    if callback then callback() end
    return
  end

  local kernel = M.resolve_kernel(0)
  if not kernel then
    vim.notify(
      "No .venv detected for this project!\nCreate a .venv or run :MoltenInit to pick a kernel manually.",
      vim.log.levels.ERROR
    )
    return
  end

  vim.notify("Initializing project kernel: " .. kernel .. " ...", vim.log.levels.INFO)
  vim.cmd("MoltenInit " .. kernel)

  -- Import output for ipynb buffers if available
  local filename = vim.api.nvim_buf_get_name(0)
  if filename:match("%.ipynb$") then
    vim.defer_fn(function()
      pcall(vim.cmd, "MoltenImportOutput")
    end, 300)
  end

  if callback then
    vim.defer_fn(callback, 250)
  end
end

-- Helper to extract current code cell range in either Markdown (```{python} ... ```) or Python (# %% ... # %%)
local function get_current_cell()
  local bufnr = vim.api.nvim_get_current_buf()
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local total = vim.api.nvim_buf_line_count(bufnr)
  local ft = vim.bo[bufnr].filetype

  if ft == "markdown" or ft == "quarto" then
    local start_l = nil
    for l = cur, 1, -1 do
      local line = vim.api.nvim_buf_get_lines(bufnr, l - 1, l, false)[1] or ""
      if line:match("^```+{%s*python") or line:match("^```+%s*python") then
        start_l = l + 1
        break
      elseif l < cur and line:match("^```+%s*$") then
        break
      end
    end

    if not start_l then return nil, nil end

    local end_l = nil
    for l = cur, total do
      local line = vim.api.nvim_buf_get_lines(bufnr, l - 1, l, false)[1] or ""
      if line:match("^```+%s*$") then
        end_l = l - 1
        break
      end
    end

    if not end_l or start_l > end_l then return nil, nil end
    return start_l, end_l
  else
    local start_l = 1
    for l = cur, 1, -1 do
      local line = vim.api.nvim_buf_get_lines(bufnr, l - 1, l, false)[1] or ""
      if line:match("^%s*#%s*%%%%") then
        start_l = l + 1
        break
      end
    end

    local end_l = total
    for l = cur + 1, total do
      local line = vim.api.nvim_buf_get_lines(bufnr, l - 1, l, false)[1] or ""
      if line:match("^%s*#%s*%%%%") then
        end_l = l - 1
        break
      end
    end

    return start_l, end_l
  end
end

-- Helper to collect all code cells in the buffer
local function get_all_cells()
  local bufnr = vim.api.nvim_get_current_buf()
  local total = vim.api.nvim_buf_line_count(bufnr)
  local ft = vim.bo[bufnr].filetype
  local cells = {}

  if ft == "markdown" or ft == "quarto" then
    local in_block = false
    local s_line = nil
    for l = 1, total do
      local line = vim.api.nvim_buf_get_lines(bufnr, l - 1, l, false)[1] or ""
      if not in_block and (line:match("^```+{%s*python") or line:match("^```+%s*python")) then
        in_block = true
        s_line = l + 1
      elseif in_block and line:match("^```+%s*$") then
        in_block = false
        if s_line <= l - 1 then
          table.insert(cells, { start_line = s_line, end_line = l - 1 })
        end
        s_line = nil
      end
    end
  else
    local s_line = 1
    for l = 1, total do
      local line = vim.api.nvim_buf_get_lines(bufnr, l - 1, l, false)[1] or ""
      if line:match("^%s*#%s*%%%%") then
        if l > s_line then
          table.insert(cells, { start_line = s_line, end_line = l - 1 })
        end
        s_line = l + 1
      end
    end
    if s_line <= total then
      table.insert(cells, { start_line = s_line, end_line = total })
    end
  end

  return cells
end

-- Run current cell
function M.run_cell()
  M.ensure_init(function()
    local s, e = get_current_cell()
    if s and e and s <= e then
      vim.fn.MoltenEvaluateRange(s, e)
    else
      vim.notify("Cursor is not inside a code cell", vim.log.levels.WARN)
    end
  end)
end

-- Run cell and above
function M.run_above()
  M.ensure_init(function()
    local cur = vim.api.nvim_win_get_cursor(0)[1]
    local all = get_all_cells()
    for _, cell in ipairs(all) do
      if cell.end_line <= cur then
        vim.fn.MoltenEvaluateRange(cell.start_line, cell.end_line)
      elseif cell.start_line <= cur then
        vim.fn.MoltenEvaluateRange(cell.start_line, cur)
        break
      end
    end
  end)
end

-- Run all cells
function M.run_all()
  M.ensure_init(function()
    local all = get_all_cells()
    for _, cell in ipairs(all) do
      vim.fn.MoltenEvaluateRange(cell.start_line, cell.end_line)
    end
  end)
end

-- Run current line
function M.run_line()
  M.ensure_init(function()
    vim.cmd("MoltenEvaluateLine")
  end)
end

-- Run visual selection
function M.run_selection()
  M.ensure_init(function()
    vim.cmd('execute "normal! \\<Esc>"')
    local start_pos = vim.api.nvim_buf_get_mark(0, "<")
    local end_pos = vim.api.nvim_buf_get_mark(0, ">")
    vim.fn.MoltenEvaluateRange(start_pos[1], end_pos[1])
  end)
end

-- Output window controls
function M.show_output()
  vim.cmd("noautocmd MoltenEnterOutput")
end

function M.hide_output()
  vim.cmd("MoltenHideOutput")
end

function M.delete_output()
  vim.cmd("MoltenDelete")
end

function M.restart_kernel()
  vim.cmd("MoltenRestart!")
  vim.notify("Jupyter kernel restarted", vim.log.levels.INFO)
end

function M.init_kernel()
  vim.cmd("MoltenInit")
end

-- Show active kernel details and python environment
function M.kernel_info()
  local kernel = M.resolve_kernel(0)
  local venv = M.get_project_venv(0)
  local python = venv and vim.fs.joinpath(venv, "bin", "python") or "python3 (host/system)"
  local running_kernels = pcall(vim.fn.MoltenRunningKernels) and vim.fn.MoltenRunningKernels() or {}
  local is_running = is_buf_initialized()

  local msg = string.format(
    "Active Kernel: %s\nStatus: %s\nPython Path:   %s",
    kernel,
    is_running and "Running / Attached" or "Idle (will auto-init on run)",
    python
  )
  vim.notify(msg, vim.log.levels.INFO, { title = "Jupyter Kernel Info" })
end

-- Cell navigation
local function is_cell_boundary(line_text)
  return line_text:match("^%s*#%s*%%%%") or line_text:match("^```%w*")
end

function M.next_cell()
  local bufnr = vim.api.nvim_get_current_buf()
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local total = vim.api.nvim_buf_line_count(bufnr)

  for l = cur + 1, total do
    local text = vim.api.nvim_buf_get_lines(bufnr, l - 1, l, false)[1] or ""
    if is_cell_boundary(text) then
      vim.cmd("normal! m'")
      vim.api.nvim_win_set_cursor(0, { l, 0 })
      return
    end
  end
  vim.notify("No next cell", vim.log.levels.INFO)
end

function M.prev_cell()
  local bufnr = vim.api.nvim_get_current_buf()
  local cur = vim.api.nvim_win_get_cursor(0)[1]

  for l = cur - 1, 1, -1 do
    local text = vim.api.nvim_buf_get_lines(bufnr, l - 1, l, false)[1] or ""
    if is_cell_boundary(text) then
      vim.cmd("normal! m'")
      vim.api.nvim_win_set_cursor(0, { l, 0 })
      return
    end
  end
  vim.notify("No previous cell", vim.log.levels.INFO)
end

-- Insert new cell below
function M.new_cell()
  local ft = vim.bo.filetype
  local buf_name = vim.api.nvim_buf_get_name(0)
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local lines = {}

  if buf_name:match("%.qmd$") then
    lines = { "", "```{python}", "", "```", "" }
  elseif ft == "markdown" or buf_name:match("%.ipynb$") then
    lines = { "", "```python", "", "```", "" }
  else
    lines = { "", "# %%", "" }
  end

  vim.api.nvim_buf_set_lines(0, cur, cur, false, lines)
  vim.api.nvim_win_set_cursor(0, { cur + 2, 0 })
end

-- Autocommands for notebook lifecycle
local group = vim.api.nvim_create_augroup("NotebookLifecycle", { clear = true })

local function init_starter_notebook_lines(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local kernel = M.resolve_kernel(bufnr) or "python3"
  local starter_lines = {
    "---",
    "jupyter:",
    "  jupytext:",
    "    text_representation:",
    "      extension: .md",
    "      format_name: markdown",
    "      format_version: '1.3'",
    "  kernelspec:",
    "    display_name: Python (" .. kernel .. ")",
    "    language: python",
    "    name: " .. kernel,
    "---",
    "",
    "```python",
    "",
    "```",
  }
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, starter_lines)
  vim.bo[bufnr].filetype = "markdown"
  vim.bo[bufnr].modified = false
  pcall(vim.api.nvim_win_set_cursor, 0, { #starter_lines - 1, 0 })
  pcall(vim.treesitter.start, bufnr, "markdown")
  pcall(function() require("quarto").activate() end)
  M.ensure_init()
end

-- Clean in-memory Jupytext conversion for .ipynb files (no temp files on disk!)
vim.api.nvim_create_autocmd("BufReadCmd", {
  group = group,
  pattern = { "*.ipynb" },
  callback = function(ev)
    local file = vim.fn.resolve(vim.fn.expand(ev.match))
    if vim.fn.filereadable(file) == 1 and vim.fn.getfsize(file) > 10 then
      local output = vim.fn.system({ "jupytext", "--from", "ipynb", "--to", "md", "--output", "-", file })
      if vim.v.shell_error == 0 then
        local lines = vim.split(output, "\n", { plain = true })
        -- Filter out any non-content warning lines from jupytext/nbformat
        while #lines > 0 and (lines[1]:match("Warning:") or lines[1]:match("MissingIDField")) do
          table.remove(lines, 1)
        end
        vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
        vim.bo.filetype = "markdown"
        vim.bo.modified = false
        pcall(vim.treesitter.start, 0, "markdown")
        pcall(function() require("quarto").activate() end)
        M.ensure_init()
        return
      end
    end

    -- Automatically initialize empty or new notebook buffer
    init_starter_notebook_lines(ev.buf)
  end,
})

-- Automatically initialize new unwritten notebook buffer
vim.api.nvim_create_autocmd("BufNewFile", {
  group = group,
  pattern = { "*.ipynb" },
  callback = function(ev)
    init_starter_notebook_lines(ev.buf)
  end,
})

-- Clean Jupytext save back to .ipynb on :w using a unique /tmp file
vim.api.nvim_create_autocmd("BufWriteCmd", {
  group = group,
  pattern = { "*.ipynb" },
  callback = function(ev)
    local file = vim.fn.resolve(vim.fn.expand(ev.match))
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    -- Generate a unique temporary file path under /tmp
    local base_name = vim.fs.basename(file):gsub("%.ipynb$", ""):gsub("[^%w_%-]", "_")
    local unique_id = vim.fn.getpid() .. "_" .. os.time() .. "_" .. math.random(1000, 9999)
    local temp_md = "/tmp/jupytext_" .. unique_id .. "_" .. base_name .. ".md"

    -- Write lines to the unique temp file
    local write_ok = pcall(vim.fn.writefile, lines, temp_md)
    if not write_ok or vim.fn.filereadable(temp_md) ~= 1 then
      vim.notify("Failed to write temporary markdown file in /tmp", vim.log.levels.ERROR)
      return
    end

    -- If notebook already exists and is non-empty, use --update to preserve existing outputs.
    -- If it's a new or empty file, create it fresh without --update to avoid JSONDecodeError.
    local is_existing = vim.fn.filereadable(file) == 1 and vim.fn.getfsize(file) > 10
    local cmd = { "jupytext", "--from", "md", "--to", "ipynb" }
    if is_existing then
      table.insert(cmd, "--update")
    end
    table.insert(cmd, "--output")
    table.insert(cmd, file)
    table.insert(cmd, temp_md)

    local res = vim.fn.system(cmd)

    -- Clean up the temporary file immediately
    pcall(vim.fn.delete, temp_md)

    if vim.v.shell_error == 0 then
      vim.bo.modified = false
      if is_buf_initialized() then
        pcall(vim.cmd, "MoltenExportOutput!")
      end
      vim.notify("Saved " .. vim.fs.basename(file), vim.log.levels.INFO)
    else
      vim.notify("Error updating .ipynb with Jupytext: " .. res, vim.log.levels.ERROR)
    end
  end,
})

-- Re-activate notebook environment whenever returning to a buffer from netrw or other buffers
local function reactivate_notebook_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(bufnr)

  if file:match("%.ipynb$") then
    -- If empty buffer, automatically initialize starter notebook
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    if #lines <= 1 and (lines[1] or "") == "" then
      init_starter_notebook_lines(bufnr)
      return
    end

    if vim.bo[bufnr].filetype ~= "markdown" then
      vim.bo[bufnr].filetype = "markdown"
    end
    pcall(vim.treesitter.start, bufnr, "markdown")
    pcall(function() require("quarto").activate() end)
    M.ensure_init()
  elseif file:match("%.qmd$") or file:match("%.md$") then
    pcall(vim.treesitter.start, bufnr, "markdown")
    pcall(function() require("quarto").activate() end)
    M.ensure_init()
  end
end

vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  group = group,
  pattern = { "*.ipynb", "*.qmd", "*.md" },
  callback = function(ev)
    reactivate_notebook_buffer(ev.buf)
  end,
})

-- Activate Quarto on Markdown and Quarto files
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "markdown", "quarto" },
  callback = function()
    pcall(function()
      require("quarto").activate()
    end)
  end,
})

-- Isolated Quarto Preview Manager (renders 100% in /tmp, never litters cwd)
M.preview_job_id = nil
M.preview_dir = nil
M.preview_file = nil

function M.start_preview()
  local src_file = vim.api.nvim_buf_get_name(0)
  if src_file == "" or vim.fn.filereadable(src_file) ~= 1 then
    vim.notify("Save buffer to a file before starting Quarto preview", vim.log.levels.WARN)
    return
  end

  local ext = vim.fn.fnamemodify(src_file, ":e")
  if ext ~= "qmd" and ext ~= "md" and ext ~= "ipynb" then
    vim.notify("Quarto preview supports .qmd, .md, or .ipynb files", vim.log.levels.WARN)
    return
  end

  -- If preview is already running, notify and return
  if M.preview_job_id and vim.fn.jobwait({ M.preview_job_id }, 0)[1] == -1 then
    vim.notify("Quarto preview is already running", vim.log.levels.INFO)
    return
  end

  -- Create an isolated temporary directory in /tmp
  local base_name = vim.fs.basename(src_file)
  -- Ensure markdown-formatted buffer is saved with .qmd extension for Quarto
  local mirror_name = base_name:gsub("%.ipynb$", ".qmd")
  local unique_id = vim.fn.getpid() .. "_" .. os.time()
  M.preview_dir = "/tmp/quarto_preview_" .. unique_id
  vim.fn.mkdir(M.preview_dir, "p")
  M.preview_file = M.preview_dir .. "/" .. mirror_name

  -- Copy current buffer contents to the /tmp mirror
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  vim.fn.writefile(lines, M.preview_file)

  vim.notify("Starting Quarto preview in " .. M.preview_dir .. " ...", vim.log.levels.INFO)

  -- Run preview completely inside /tmp (no tabs, zero cwd pollution)
  local cmd = { "quarto", "preview", M.preview_file }
  local browser_opened = false

  M.preview_job_id = vim.fn.jobstart(cmd, {
    cwd = M.preview_dir,
    on_stdout = function(_, data)
      if not data then return end
      for _, line in ipairs(data) do
        -- Strip ANSI escape codes
        local clean = line:gsub("\x1b%[[0-9;]*m", "")
        local url = clean:match("Browse at%s+(http%S+)") or clean:match("Listening on%s+(http%S+)")
        if url and not browser_opened then
          browser_opened = true
          vim.notify("Quarto preview live at: " .. url, vim.log.levels.INFO)
          pcall(vim.fn.system, { "open", url })
        end
      end
    end,
    on_stderr = function(_, data)
      if not data then return end
      for _, line in ipairs(data) do
        if line:match("ERROR") then
          vim.notify("Quarto preview error: " .. line, vim.log.levels.ERROR)
        end
      end
    end,
    on_exit = function()
      M.preview_job_id = nil
    end,
  })

  -- Whenever you save the file in Neovim, sync the change to the /tmp mirror
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_create_autocmd("BufWritePost", {
    buffer = bufnr,
    group = vim.api.nvim_create_augroup("QuartoPreviewSync_" .. bufnr, { clear = true }),
    callback = function()
      if M.preview_job_id and M.preview_file then
        local current_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        vim.fn.writefile(current_lines, M.preview_file)
      end
    end,
  })
end

function M.close_preview()
  if M.preview_job_id then
    pcall(vim.fn.jobstop, M.preview_job_id)
    M.preview_job_id = nil
    vim.notify("Quarto preview closed", vim.log.levels.INFO)
  else
    vim.notify("No active Quarto preview running", vim.log.levels.INFO)
  end

  -- Clean up temporary preview directory in /tmp
  if M.preview_dir and vim.fn.isdirectory(M.preview_dir) == 1 then
    pcall(vim.fn.delete, M.preview_dir, "rf")
    M.preview_dir = nil
    M.preview_file = nil
  end
end

-- Clean up any preview process when exiting Neovim
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = group,
  callback = function()
    if M.preview_job_id then
      pcall(vim.fn.jobstop, M.preview_job_id)
      M.preview_job_id = nil
    end
    if M.preview_dir and vim.fn.isdirectory(M.preview_dir) == 1 then
      pcall(vim.fn.delete, M.preview_dir, "rf")
    end
  end,
})

-- Override built-in :QuartoPreview & :QuartoClosePreview commands
vim.api.nvim_create_user_command("QuartoPreview", function()
  M.start_preview()
end, { force = true, desc = "Start Quarto live preview in /tmp" })

vim.api.nvim_create_user_command("QuartoClosePreview", function()
  M.close_preview()
end, { force = true, desc = "Close Quarto live preview" })

-- Rules normally ignored in Jupyter notebooks by Ruff and VS Code:
-- B018: Useless expression (lone variables/evaluations printed at bottom of cells)
-- E402: Module level import not at top of file (imports occur naturally across cells)
-- I001: Unsorted imports (imports across separated chunks shouldn't be merged)
-- T201/T203: Print/pprint statements (expected in notebook output)
-- D100: Missing module docstring (notebooks are not library modules)
-- reportUnusedExpression: Pyright equivalent of B018
local notebook_ignored_codes = {
  ["B018"] = true,
  ["E402"] = true,
  ["I001"] = true,
  ["T201"] = true,
  ["T203"] = true,
  ["D100"] = true,
  ["reportUnusedExpression"] = true,
}

-- Filter out notebook-specific false positives.
-- This ONLY affects embedded notebook chunks (otter namespace). Normal .py files remain 100% strict.
local orig_diagnostic_set = vim.diagnostic.set
vim.diagnostic.set = function(namespace, bufnr, diagnostics, opts)
  local ns_info = vim.diagnostic.get_namespaces()[namespace]
  local ns_name = ns_info and ns_info.name or ""

  if ns_name:match("otter") then
    local filtered = {}
    for _, d in ipairs(diagnostics) do
      local code = tostring(d.code or "")
      local is_ignored = notebook_ignored_codes[code]
        or (d.message and d.message:match("useless expression"))
        or (d.message and d.message:match("not at top of file"))

      if not is_ignored then
        table.insert(filtered, d)
      end
    end
    diagnostics = filtered
  end

  return orig_diagnostic_set(namespace, bufnr, diagnostics, opts)
end

return M
