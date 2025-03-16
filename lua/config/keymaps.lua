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

    -- Override K to handle CSS classes in Vue files
    vim.keymap.set("n", "K", function()
      -- Get current line and cursor position
      local line = vim.api.nvim_get_current_line()
      local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
      
      -- Check if we're looking at a potential CSS class
      local is_css_class = false
      local class_name = nil
      
      -- Check various class syntaxes in Vue templates
      -- 1. Check static class="..." syntax
      local class_start, class_end, class_content = line:find('class="([^"]*)"')
      if class_content and class_start and cursor_col >= class_start - 1 and cursor_col <= class_end then
        is_css_class = true
        
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
      if not is_css_class then
        local bind_start, bind_end = line:find(':class="[^"]*"')
        if bind_start and cursor_col >= bind_start - 1 and cursor_col <= bind_end then
          is_css_class = true
          -- For dynamic bindings, just use word under cursor
          class_name = vim.fn.expand("<cword>")
        end
      end
      
      -- 3. Check v-bind:class syntax
      if not is_css_class then
        local vbind_start, vbind_end = line:find('v%-bind:class="[^"]*"')
        if vbind_start and cursor_col >= vbind_start - 1 and cursor_col <= vbind_end then
          is_css_class = true
          class_name = vim.fn.expand("<cword>")
        end
      end
      
      -- 4. Check if cursor is over a CSS selector in style section
      if not is_css_class and not class_name then
        local current_line_num = vim.api.nvim_win_get_cursor(0)[1]
        local style_line = vim.fn.search("^\\s*<style", "bn") -- Find style tag before cursor
        local style_end = vim.fn.search("^\\s*</style>", "n") -- Find end of style
        
        if style_line > 0 and style_end > 0 and current_line_num > style_line and current_line_num < style_end then
          -- We're in the style section, check if we're on a CSS selector
          local current_word = vim.fn.expand("<cword>")
          if current_word and #current_word > 0 then
            -- Check if current word is part of a CSS selector
            local line_text = vim.api.nvim_get_current_line()
            
            -- Check for class selector syntax (.class-name)
            if line_text:match("%." .. current_word) then
              is_css_class = true
              class_name = current_word
            end
          end
        end
      end
      
      -- 5. Fallback to word under cursor if no matches but in CSS context
      if not class_name or class_name == "" then
        if is_css_class then
          class_name = vim.fn.expand("<cword>")
        end
      end
      
      -- If we don't have a class name, use standard LSP hover
      if not class_name or class_name == "" then
        return vim.lsp.buf.hover()
      end
      
      -- For CSS classes, try LSP hover first but prepare to fall back to searching
      local hover_success = false
      local lsp_content_shown = false
      
      -- Keep track of the original hover handler
      local orig_hover_handler = vim.lsp.handlers["textDocument/hover"]
      
      -- Create a temporary hover handler to detect if content was displayed
      vim.lsp.handlers["textDocument/hover"] = function(err, result, ctx, config)
        -- Check if the result contains any useful information
        if result and result.contents then
          local markdown_lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
          if markdown_lines and #markdown_lines > 0 then
            -- Filter out "No information available" messages
            local has_content = false
            for _, line in ipairs(markdown_lines) do
              if line ~= "No information available" and line ~= "" then
                has_content = true
                break
              end
            end
            
            if has_content then
              lsp_content_shown = true
            end
          end
        end
        
        -- Call the original handler
        orig_hover_handler(err, result, ctx, config)
        
        -- Restore the original handler
        vim.lsp.handlers["textDocument/hover"] = orig_hover_handler
      end
      
      -- Try the hover
      hover_success = pcall(vim.lsp.buf.hover)
      
      -- If LSP hover succeeded and showed something useful, we're done
      if hover_success and lsp_content_shown then
        return
      end
      
      -- If we get here, LSP didn't provide useful info, so search for the class
      vim.notify("Looking for CSS class: ." .. class_name, vim.log.levels.INFO)
      
      -- Save cursor position for restore
      local current_pos = vim.fn.getpos(".")
      
      -- Try to find in current file's style section first
      local style_line = vim.fn.search("^\\s*<style", "wn") -- Find but don't move
      
      if style_line > 0 then
        -- Move to style section
        vim.fn.cursor(style_line, 1)
        
        -- Search patterns for both normal and scoped styles
        local patterns = {
          "\\." .. class_name .. "\\([^-_a-zA-Z0-9]\\|$\\)",  -- Standard class
          "\\." .. class_name .. "\\[data%-v%-",               -- Scoped class
          "\\." .. class_name .. "[:\\.]",                     -- Class with pseudo-element or nested class
          "\\." .. class_name .. "\\s*{",                      -- Class followed by opening bracket
        }
        
        local found = 0
        for _, pattern in ipairs(patterns) do
          found = vim.fn.search(pattern, "W")
          if found > 0 and found > style_line then
            -- Found in current file
            vim.cmd("normal! zz") -- Center view
            vim.notify("Found class in current file", vim.log.levels.INFO)
            return
          end
        end
        
        -- Restore position if not found
        vim.fn.setpos(".", current_pos)
      end
      
      -- If not found in current file, try project-wide search
      -- Try FzfLua first if available
      local has_fzf = (vim.fn.exists(":FzfLua") > 0)
      
      if has_fzf then
        -- FzfLua with pattern for Vue scoped styles
        vim.cmd("FzfLua grep pattern=\"\\." .. class_name .. "(\\s*[:{\\[]|\\s+|$)\"")
      else
        -- Try telescope as fallback
        local has_telescope = pcall(require, "telescope")
        if has_telescope then
          vim.cmd("Telescope live_grep default_text=\\." .. class_name)
        else
          vim.notify("No search tool available. Install ripgrep and Telescope or FzfLua", vim.log.levels.ERROR)
        end
      end
    end, { buffer = true, desc = "Show hover information or find CSS class" })
  end,
})