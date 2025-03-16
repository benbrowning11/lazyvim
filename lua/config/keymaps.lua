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

map("n", "<leader>gd",
  function()
    require("lazyvim.util.terminal").open(
      { "lazydocker", "-f", Util.get_root() .. "docker-compose.yml" },
      { cwd = Util.get_root(), esc_esc = false }
    )
  end,
  { desc = "LazyDocker (root dir)" })

-- Add Vue-specific keymaps
vim.api.nvim_create_autocmd("FileType", {
  pattern = "vue",
  callback = function()
    -- Navigate between Vue sections
    vim.keymap.set("n", "<leader>vt", "/\\<template\\><CR>:nohl<CR>", { buffer = true, desc = "Go to template" })
    vim.keymap.set("n", "<leader>vs", "/\\<script\\><CR>:nohl<CR>", { buffer = true, desc = "Go to script" })
    vim.keymap.set("n", "<leader>vc", "/\\<style\\><CR>:nohl<CR>", { buffer = true, desc = "Go to style" })
    
    -- Enhanced CSS class finder
    vim.keymap.set("n", "<leader>vy", function()
      local word = vim.fn.expand("<cword>")
      
      -- If cursor is on a class attribute, try to extract the class name
      local line = vim.api.nvim_get_current_line()
      local col = vim.api.nvim_win_get_cursor(0)[2] + 1
      local class_pattern = 'class="([^"]*)"'
      local class_start, class_end, class_str = line:find(class_pattern)
      
      if class_start and col >= class_start and col <= class_end then
        -- We're inside a class attribute, extract the specific class under cursor
        local cursor_pos = col - class_start
        local classes = vim.split(class_str, "%s+")
        local pos = 0
        for _, class in ipairs(classes) do
          if pos <= cursor_pos and cursor_pos <= pos + #class then
            word = class
            break
          end
          pos = pos + #class + 1 -- +1 for the space
        end
      end
      
      -- First try to find the class in the current file's style section
      vim.cmd("/\\<style\\>")
      local style_line = vim.fn.line(".")
      local found = vim.fn.search("\\." .. word .. "\\b", "W")
      
      -- If not found or found before style section, try project-wide search
      if found == 0 or found < style_line then
        -- Try using FZF first if available
        local has_fzf = pcall(vim.cmd, "FzfLua grep pattern=\\." .. word .. "\\b")
        
        -- Fall back to Telescope if FZF is not available
        if not has_fzf then
          vim.cmd("Telescope live_grep default_text=\\." .. word .. "\\b")
        end
      else
        -- Center the screen on the found class
        vim.cmd("normal! zz")
      end
    end, { buffer = true, desc = "Find CSS class definition" })
  end,
})