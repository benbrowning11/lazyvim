-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local Util = require("lazyvim.util")
local function map(mode, lhs, rhs, opts)
  local keys = require("lazy.core.handler").handlers.keys
  ---@cast keys LazyKeysHandler
  -- do not create the keymap if a lazy keys handler exists
  if not keys.active[keys.parse({ lhs, mode = mode }).id] then
    opts = opts or {}
    opts.silent = opts.silent ~= false
    vim.keymap.set(mode, lhs, rhs, opts)
  end
end

-- LazyDocker mapping
map("n", "<leader>gd",
  function()
    require("lazyvim.util.terminal").open(
      { "lazydocker", "-f", Util.get_root() .. "docker-compose.yml" },
      { cwd = Util.get_root(), esc_esc = false }
    )
  end,
  { desc = "LazyDocker (root dir)" })

-- Vue-specific keymaps
vim.api.nvim_create_autocmd("FileType", {
  pattern = "vue",
  callback = function()
    -- Enhanced Vue section navigation - go to beginning of content, not just the tag
    local function goto_vue_section(section)
      -- Save cursor position
      local cursor_pos = vim.fn.getpos(".")
      
      -- Start from beginning of file for consistent behavior
      vim.cmd("normal! gg")
      
      -- Look for section tag at beginning of line or after whitespace
      local pattern = "^\\s*<" .. section .. "[\\s>]"
      local found = vim.fn.search(pattern, "W")
      
      if found == 0 then
        -- Restore position if not found
        vim.fn.setpos(".", cursor_pos)
        vim.notify("No " .. section .. " section found", vim.log.levels.WARN)
        return false
      end
      
      -- Move to first line after the tag
      vim.cmd("normal! j0")
      vim.cmd("nohlsearch")
      return true
    end
    
    -- Navigation mappings
    vim.keymap.set("n", "<leader>vt", function() goto_vue_section("template") end, 
      { buffer = true, desc = "Go to template section" })
    
    vim.keymap.set("n", "<leader>vs", function() goto_vue_section("script") end, 
      { buffer = true, desc = "Go to script section" })
    
    vim.keymap.set("n", "<leader>vc", function() goto_vue_section("style") end, 
      { buffer = true, desc = "Go to style section" })
    
    -- Enhanced CSS class finder with Tailwind detection
    vim.keymap.set("n", "<leader>vy", function()
      -- Extract class name under cursor with better detection
      local class_name = nil
      
      -- Get current line and cursor position
      local line = vim.api.nvim_get_current_line()
      local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
      
      -- Check various class syntaxes in Vue templates
      
      -- 1. Check static class="..." syntax
      local class_start, class_end, class_content = line:find('class="([^"]*)"')
      if class_content and class_start and cursor_col >= class_start - 1 and cursor_col <= class_end then
        -- Process individual classes in the attribute
        local classes = {}
        for cls in class_content:gmatch("%S+") do
          table.insert(classes, cls)
        end
        
        -- Determine which class contains the cursor
        local pos = class_start + 6 -- Position after class="
        for _, cls in ipairs(classes) do
          local cls_end = pos + #cls
          if cursor_col >= pos and cursor_col <= cls_end then
            class_name = cls
            break
          end
          pos = cls_end + 1 -- +1 for space between classes
        end
      end
      
      -- 2. Check dynamic :class binding
      if not class_name then
        local bind_start, bind_end, bind_content = line:find(':class="([^"]*)"')
        if bind_content and bind_start and cursor_col >= bind_start - 1 and cursor_col <= bind_end then
          -- Try to extract class from dynamic binding
          -- For dynamic bindings, just use word under cursor
          class_name = vim.fn.expand("<cword>")
        end
      end
      
      -- 3. Check v-bind:class syntax
      if not class_name then
        local vbind_start, vbind_end = line:find('v%-bind:class="[^"]*"')
        if vbind_start and cursor_col >= vbind_start - 1 and cursor_col <= vbind_end then
          class_name = vim.fn.expand("<cword>")
        end
      end
      
      -- 4. Fallback to word under cursor if no matches
      if not class_name or class_name == "" then
        class_name = vim.fn.expand("<cword>")
      end
      
      -- Detect Tailwind classes (common patterns)
      local tailwind_patterns = {
        "^[mp][tblrxy]?%-[0-9]", -- margin/padding 
        "^[hw]%-%d", -- height/width
        "^flex", -- flex
        "^grid", -- grid
        "^bg%-", -- background
        "^text%-", -- text
        "^border", -- border
        "^rounded", -- border radius
        "^shadow", -- shadow
        "^opacity", -- opacity
        "^z%-", -- z-index
        "^transform", -- transform
        "^transition", -- transition
        "^hover:", -- hover state
        "^focus:", -- focus state
        "^dark:", -- dark mode
      }
      
      -- Check if it's a Tailwind class
      local is_tailwind = false
      for _, pattern in ipairs(tailwind_patterns) do
        if class_name:match(pattern) then
          is_tailwind = true
          break
        end
      end
      
      if is_tailwind then
        vim.notify("Detected Tailwind class: " .. class_name, vim.log.levels.INFO)
        
        -- Try to use LSP to show Tailwind class info instead of searching
        local params = {
          textDocument = vim.lsp.util.make_text_document_params(),
          position = { 
            line = vim.api.nvim_win_get_cursor(0)[1] - 1,
            character = cursor_col 
          }
        }
        
        -- Try to get hover info for the Tailwind class
        vim.lsp.buf_request(0, "textDocument/hover", params, function(_, result)
          if result and result.contents then
            -- LSP successfully provided hover info
            vim.lsp.handlers["textDocument/hover"](_, result)
          end
        end)
        return
      end
      
      -- Notify about search
      vim.notify("Searching for CSS class: ." .. class_name, vim.log.levels.INFO)
      
      -- Save cursor position
      local current_pos = vim.fn.getpos(".")
      
      -- Try to find in current file's style section first
      local style_line = vim.fn.search("^\\s*<style", "wn") -- Find but don't move
      
      if style_line > 0 then
        -- Move to style section
        vim.fn.cursor(style_line, 1)
        
        -- Search for class definition
        local found = vim.fn.search("\\." .. class_name .. "\\([^-_a-zA-Z0-9]\\|$\\)", "W")
        
        if found > 0 and found > style_line then
          -- Found in current file
          vim.cmd("normal! zz") -- Center view
          vim.notify("Found class in current file", vim.log.levels.INFO)
          return
        end
        
        -- Restore position if not found
        vim.fn.setpos(".", current_pos)
      end
      
      -- Fall back to project-wide search
      -- Try FzfLua first if available
      local has_fzf = (vim.fn.exists(":FzfLua") > 0)
      
      if has_fzf then
        -- FzfLua is available, use grep
        vim.cmd("FzfLua grep pattern=\\." .. class_name .. "\\([^-_a-zA-Z0-9]\\|$\\)")
      else
        -- Try telescope as a fallback
        local has_telescope = pcall(require, "telescope")
        if has_telescope then
          vim.cmd("Telescope live_grep default_text=\\." .. class_name .. "\\b")
        else
          vim.notify("No search tool available. Install ripgrep and Telescope or FzfLua", vim.log.levels.ERROR)
        end
      end
    end, { buffer = true, desc = "Find CSS class definition" })
    
    -- Additional Vue specific mappings
    
    -- Toggle between <script> and <script setup>
    vim.keymap.set("n", "<leader>vS", function()
      local cursor_pos = vim.fn.getpos(".")
      local script_line = vim.fn.search("^\\s*<script", "wn")
      
      if script_line > 0 then
        vim.fn.cursor(script_line, 1)
        local line = vim.api.nvim_get_current_line()
        
        if line:match("setup") then
          -- Remove setup
          line = line:gsub("setup", "")
          vim.api.nvim_set_current_line(line)
          vim.notify("Converted to regular <script>", vim.log.levels.INFO)
        else
          -- Add setup
          line = line:gsub("<script", "<script setup")
          vim.api.nvim_set_current_line(line)
          vim.notify("Converted to <script setup>", vim.log.levels.INFO)
        end
        
        vim.fn.setpos(".", cursor_pos)
      else
        vim.notify("No script tag found", vim.log.levels.WARN)
      end
    end, { buffer = true, desc = "Toggle script setup" })
    
    -- Toggle between <style> and <style scoped>
    vim.keymap.set("n", "<leader>vC", function()
      local cursor_pos = vim.fn.getpos(".")
      local style_line = vim.fn.search("^\\s*<style", "wn")
      
      if style_line > 0 then
        vim.fn.cursor(style_line, 1)
        local line = vim.api.nvim_get_current_line()
        
        if line:match("scoped") then
          -- Remove scoped
          line = line:gsub("scoped", "")
          vim.api.nvim_set_current_line(line)
          vim.notify("Removed style scoping", vim.log.levels.INFO)
        else
          -- Add scoped
          line = line:gsub("<style", "<style scoped")
          vim.api.nvim_set_current_line(line)
          vim.notify("Added style scoping", vim.log.levels.INFO)
        end
        
        vim.fn.setpos(".", cursor_pos)
      else
        vim.notify("No style tag found", vim.log.levels.WARN)
      end
    end, { buffer = true, desc = "Toggle style scoped" })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "vue,html,css,scss",
  callback = function()
    vim.keymap.set("n", "K", function()
      local word = vim.fn.expand("<cword>")
      local line = vim.api.nvim_get_current_line()
      local col = vim.api.nvim_win_get_cursor(0)[2]
      
      -- Try to extract class name if cursor is in a class attribute
      local class_start, class_end, class_content = line:find('class="([^"]*)"')
      if class_content and class_start and col >= class_start - 1 and col <= class_end then
        -- Process individual classes in the attribute
        local classes = {}
        for cls in class_content:gmatch("%S+") do
          table.insert(classes, cls)
        end
        
        -- Get class under cursor
        local pos = class_start + 6 -- Position after class="
        for _, cls in ipairs(classes) do
          local cls_end = pos + #cls
          if col >= pos and col < cls_end then
            word = cls
            break
          end
          pos = cls_end + 1 -- +1 for space between classes
        end
      end
      
      -- First try LSP hover which works for both Tailwind and defined custom classes
      local has_hover = vim.lsp.buf.hover()
      
      -- If in a Vue file, also check for custom class definitions in <style> section
      if vim.bo.filetype == "vue" and (not has_hover or has_hover == false) then
        -- Save cursor position
        local cursor_pos = vim.fn.getpos(".")
        
        -- Look for class definition in current file's style section
        local style_line = vim.fn.search("^\\s*<style", "wn")
        if style_line > 0 then
          -- Temporarily move to style section
          local temp_pos = vim.fn.getpos(".")
          vim.fn.cursor(style_line, 1)
          
          -- Search for class definition
          local found = vim.fn.search("\\." .. word .. "\\([^-_a-zA-Z0-9]\\|$\\)", "W")
          
          if found > 0 and found > style_line then
            -- Found class definition, extract and display it
            local start_line = found
            local end_line = found
            
            -- Find the closing brace to get the full class definition
            while end_line <= vim.fn.line("$") do
              local line_text = vim.fn.getline(end_line)
              if line_text:find("}") then
                break
              end
              end_line = end_line + 1
            end
            
            -- Extract class definition
            local class_def = vim.fn.getline(start_line, end_line)
            
            -- Create float window with class definition
            local buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(buf, 0, -1, true, class_def)
            vim.api.nvim_buf_set_option(buf, "filetype", "css")
            
            vim.api.nvim_open_win(buf, false, {
              relative = "cursor",
              row = 1,
              col = 0,
              width = 60,
              height = #class_def,
              style = "minimal",
              border = "rounded",
            })
          end
          
          -- Restore cursor position
          vim.fn.setpos(".", cursor_pos)
        end
      end
    end, { buffer = true, desc = "Show CSS class info" })
  end,
})