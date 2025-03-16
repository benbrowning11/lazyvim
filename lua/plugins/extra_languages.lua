return {
  {
    "jwalton512/vim-blade",
  },

  -- Add Vue 3 support
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "vue", "typescript" })
      end
      return opts
    end,
  },
  
  -- Add Vue support with automatic tag closing
  {
    "nvim-ts-autotag",
    opts = {
      filetypes = { "html", "xml", "javascript", "typescript", "vue" },
    },
  },
}
