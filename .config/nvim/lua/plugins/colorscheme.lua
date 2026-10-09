local dark_theme = "onedark" -- options: 'onedark', 'onedark_vivid', 'onedark_dark'
local light_theme = "onelight" -- Atom One Light / One Half Light

local function get_system_theme_sync()
  if vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1 then
    local res = vim.system({ "defaults", "read", "-g", "AppleInterfaceStyle" }, { text = true }):wait()
    if res.code == 0 and (res.stdout or ""):match("Dark") then
      return "dark"
    end
    return "light"
  elseif vim.fn.has("unix") == 1 then
    if vim.fn.executable("gsettings") == 1 then
      local res = vim.system({ "gsettings", "get", "org.gnome.desktop.interface", "color-scheme" }, { text = true }):wait()
      if res.code == 0 and (res.stdout or ""):match("dark") then
        return "dark"
      end
    end
    return "dark"
  elseif vim.fn.has("win32") == 1 then
    local res = vim.system({
      "reg", "query",
      [[HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize]],
      "/v", "AppsUseLightTheme",
    }, { text = true }):wait()
    if res.code == 0 and (res.stdout or ""):match("0x0") then
      return "dark"
    end
    return "light"
  end
  return "dark"
end

local function query_system_theme_async(callback)
  if vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1 then
    vim.system({ "defaults", "read", "-g", "AppleInterfaceStyle" }, { text = true }, function(res)
      local mode = (res.code == 0 and (res.stdout or ""):match("Dark")) and "dark" or "light"
      callback(mode)
    end)
  elseif vim.fn.has("unix") == 1 then
    if vim.fn.executable("gsettings") == 1 then
      vim.system({ "gsettings", "get", "org.gnome.desktop.interface", "color-scheme" }, { text = true }, function(res)
        local mode = (res.code == 0 and (res.stdout or ""):match("dark")) and "dark" or "light"
        callback(mode)
      end)
    else
      callback("dark")
    end
  elseif vim.fn.has("win32") == 1 then
    vim.system({
      "reg", "query",
      [[HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize]],
      "/v", "AppsUseLightTheme",
    }, { text = true }, function(res)
      local mode = (res.code == 0 and (res.stdout or ""):match("0x0")) and "dark" or "light"
      callback(mode)
    end)
  else
    callback("dark")
  end
end

return {
  {
    "olimorris/onedarkpro.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("onedarkpro").setup({
        caching = false,
        options = {
          cursorline = true, -- Enable cursorline highlighting
          transparency = false,
          terminal_colors = true,
        },
        highlights = {
          -- Harmonize cursorline and cursorcolumn crosshair for both light and dark
          CursorLine = {
            bg = { onedark = "${cursorline}", onelight = "#ececec" },
          },
          CursorColumn = {
            bg = { onedark = "${cursorline}", onelight = "#ececec" },
          },
          CursorLineNr = {
            bg = { onedark = "${cursorline}", onelight = "#ececec" },
            fg = "${purple}",
            bold = true,
          },
        },
      })

      local current_theme = nil
      local last_system_theme = nil
      local is_switching = false

      local function apply_theme(mode)
        if current_theme == mode then
          return
        end
        current_theme = mode
        is_switching = true

        if mode == "light" then
          vim.o.background = "light"
          vim.cmd("colorscheme " .. light_theme)
        else
          vim.o.background = "dark"
          vim.cmd("colorscheme " .. dark_theme)
        end

        is_switching = false
      end

      -- Initial detection on startup
      local initial_mode = get_system_theme_sync()
      last_system_theme = initial_mode
      apply_theme(initial_mode)

      -- Real-time update helper
      local function check_and_update()
        query_system_theme_async(function(detected)
          if detected and detected ~= last_system_theme then
            last_system_theme = detected
            vim.schedule(function()
              apply_theme(detected)
            end)
          end
        end)
      end

      -- React to external :set background changes
      vim.api.nvim_create_autocmd("OptionSet", {
        pattern = "background",
        callback = function()
          if is_switching then
            return
          end
          local bg = vim.o.background
          if bg ~= current_theme then
            apply_theme(bg)
          end
        end,
      })

      -- Check immediately on window focus
      vim.api.nvim_create_autocmd("FocusGained", {
        callback = check_and_update,
      })

      -- macOS live event listener via notifyutil
      local monitor_proc = nil
      if (vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1) and vim.fn.executable("notifyutil") == 1 then
        monitor_proc = vim.system({ "notifyutil", "-w", "AppleInterfaceThemeChangedNotification" }, {
          text = true,
          stdout = function(_, data)
            if data and #data > 0 then
              check_and_update()
            end
          end,
        })
      end

      -- Fallback periodic timer (every 2 seconds)
      local timer = vim.uv.new_timer()
      if timer then
        timer:start(2000, 2000, function()
          check_and_update()
        end)
      end

      -- Clean up processes and timers on exit
      vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
          if timer and not timer:is_closing() then
            timer:stop()
            timer:close()
          end
          if monitor_proc and not monitor_proc:is_closing() then
            pcall(function()
              monitor_proc:kill("sigterm")
            end)
          end
        end,
      })

      -- User commands
      vim.api.nvim_create_user_command("ThemeSync", function()
        query_system_theme_async(function(detected)
          last_system_theme = detected
          vim.schedule(function()
            apply_theme(detected)
            print("Theme synced with system: " .. vim.g.colors_name)
          end)
        end)
      end, { desc = "Sync colorscheme with system theme" })

      vim.api.nvim_create_user_command("ToggleTheme", function()
        local target = current_theme == "light" and "dark" or "light"
        apply_theme(target)
        print("Switched theme to: " .. vim.g.colors_name)
      end, { desc = "Toggle between dark and light themes" })
    end,
  },
}
