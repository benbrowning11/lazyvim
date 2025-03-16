-- CSS class lookup utility for Vue files
return {
    "LazyVim/LazyVim",
    dependencies = {},
    config = function()
      -- Create CSS lookup module
      local M = {}
      
      -- Debug mode
      M.debug = true
      
      -- Debug function
      M.log = function(msg)
        if M.debug then
          vim.notify("CSS Lookup: " .. msg, vim.log.levels.INFO)
        end
      end
      
      -- Main lookup function
      M.css_class_lookup = function()
        M.log("Starting CSS class lookup")
        
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
              M.log("Found class name in static class: " .. cls)
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
            M.log("Found class in dynamic binding: " .. class_name)
          end
        end
        
        -- 3. Check v-bind:class syntax
        if not is_css_class then
          local vbind_start, vbind_end = line:find('v%-bind:class="[^"]*"')
          if vbind_start and cursor_col >= vbind_start - 1 and cursor_col <= vbind_end then
            is_css_class = true
            class_name = vim.fn.expand("<cword>")
            M.log("Found class in v-bind: " .. class_name)
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
                M.log("Found class in style section: " .. class_name)
              end
            end
          end
        end
        
        -- 5. Fallback to word under cursor if no matches but in CSS context
        if not class_name or class_name == "" then
          if is_css_class then
            class_name = vim.fn.expand("<cword>")
            M.log("Using word under cursor as fallback: " .. class_name)
          end
        end
        
        -- If we don't have a class name, use standard LSP hover
        if not class_name or class_name == "" then
          M.log("No CSS class detected, using standard hover")
          vim.lsp.buf.hover()
          return
        end
        
        M.log("Detected CSS class: " .. class_name)
        
        -- Store the original hover handler
        local orig_hover_handler = vim.lsp.handlers["textDocument/hover"]
        local lsp_executed = false
        
        -- Set up an intercept for the LSP hover handler
        vim.lsp.handlers["textDocument/hover"] = function(err, result, ctx, config)
          lsp_executed = true
          
          -- Check if the result contains any useful information
          local has_useful_content = false
          
          if result and result.contents then
            local markdown_lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
            if markdown_lines and #markdown_lines > 0 then
              -- Filter out "No information available" and similar messages
              for _, line in ipairs(markdown_lines) do
                if line ~= "No information available" and 
                   line ~= "" and 
                   not line:match("Could not find") then
                  has_useful_content = true
                  M.log("Found useful LSP content")
                  break
                end
              end
            end
          end
          
          -- Only show LSP results if we have useful content
          if has_useful_content then
            orig_hover_handler(err, result, ctx, config)
          else
            M.log("LSP returned no useful content, will fall back to manual search")
          end
          
          -- Restore the original handler
          vim.lsp.handlers["textDocument/hover"] = orig_hover_handler
          
          -- If LSP had no useful info, do a manual search
          if not has_useful_content then
            -- Use a small delay to ensure LSP windows are closed
            vim.defer_fn(function()
              -- Search in the current file first
              local current_pos = vim.fn.getpos(".")
              
              -- Try to find in current file's style section
              local style_line = vim.fn.search("^\\s*<style", "wn") -- Find but don't move
              
              if style_line > 0 then
                -- Move to style section
                vim.fn.cursor(style_line, 1)
                M.log("Searching for class in style section")
                
                -- Search patterns for CSS classes
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
                    vim.notify("Found class ." .. class_name .. " in current file", vim.log.levels.INFO)
                    return
                  end
                end
                
                -- Restore position if not found
                vim.fn.setpos(".", current_pos)
                M.log("Class not found in current file")
              end
              
              -- If we're still here, offer project-wide search
              vim.notify("Looking for CSS class: ." .. class_name, vim.log.levels.INFO)
              
              -- Try FzfLua first if available
              local has_fzf = (vim.fn.exists(":FzfLua") > 0)
              
              if has_fzf then
                -- FzfLua with pattern for CSS classes
                vim.cmd("FzfLua grep pattern=\"\\." .. class_name .. "(\\s*[:{\\[]|\\s+|$)\"")
                M.log("Using FzfLua for project search")
              else
                -- Try telescope as fallback
                local has_telescope = pcall(require, "telescope")
                if has_telescope then
                  vim.cmd("Telescope live_grep default_text=\\." .. class_name)
                  M.log("Using Telescope for project search")
                else
                  vim.notify("No search tool available. Install ripgrep with Telescope or FzfLua", vim.log.levels.ERROR)
                end
              end
            end, 150) -- Small delay to ensure LSP windows are closed
          end
        end
        
        -- Trigger the LSP hover to start the process
        pcall(vim.lsp.buf.hover)
        
        -- If LSP didn't execute for some reason, do the manual search directly
        vim.defer_fn(function()
          if not lsp_executed then
            M.log("LSP didn't execute, doing manual search directly")
            vim.lsp.handlers["textDocument/hover"] = orig_hover_handler -- Restore handler
            
            -- Trigger manual search
            vim.notify("Looking for CSS class: ." .. class_name, vim.log.levels.INFO)
            
            -- Try FzfLua first if available
            local has_fzf = (vim.fn.exists(":FzfLua") > 0)
            
            if has_fzf then
              vim.cmd("FzfLua grep pattern=\"\\." .. class_name .. "(\\s*[:{\\[]|\\s+|$)\"")
            else
              -- Try telescope as fallback
              local has_telescope = pcall(require, "telescope")
              if has_telescope then
                vim.cmd("Telescope live_grep default_text=\\." .. class_name)
              else
                vim.notify("No search tool available. Install ripgrep with Telescope or FzfLua", vim.log.levels.ERROR)
              end
            end
          end
        end, 500) -- Give LSP time to execute
      end
      
      -- Set up a global variable we can access
      _G.CSS_LOOKUP = M
      
      -- Add Vue-specific autocommand
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "vue",
        callback = function()
          -- Register the K mapping
          vim.keymap.set("n", "K", _G.CSS_LOOKUP.css_class_lookup, 
            { buffer = true, desc = "Show hover information or find CSS class" })
            
          vim.notify("Vue keymaps loaded with CSS lookup", vim.log.levels.INFO)
        end,
      })
    end,
  }