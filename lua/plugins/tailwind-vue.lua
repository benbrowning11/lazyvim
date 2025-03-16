return {
  -- Tailwind CSS support for Vue
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      if not opts.servers then opts.servers = {} end
      
      -- Configure Tailwind CSS language server
      opts.servers.tailwindcss = {
        filetypes = { 
          -- Standard filetypes
          "html", "css", "scss", "javascript", "javascriptreact", "typescript", "typescriptreact",
          -- Add Vue support
          "vue",
        },
        init_options = {
          userLanguages = {
            vue = "html",
          },
        },
        settings = {
          tailwindCSS = {
            classAttributes = { "class", "className", ":class", "v-bind:class" },
            includeLanguages = {
              vue = "html",
            },
            experimental = {
              classRegex = {
                -- Support for class utilities like clsx and cva
                [[clsx\\(([^)]*)\\)]],
                [[cva\\(([^)]*)\\)]],
                [[tv\\(([^)]*)\\)]],
              },
            },
          },
        },
      }
      
      return opts
    end,
  },
}