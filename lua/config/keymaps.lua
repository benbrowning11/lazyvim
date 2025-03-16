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
  end,
})