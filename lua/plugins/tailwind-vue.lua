return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      if not opts.servers then opts.servers = {} end
      
      -- Configure Tailwind CSS language server
      opts.servers.tailwindcss = {
        filetypes = { 
          "html", "css", "scss", "javascript", "javascriptreact", "typescript", "typescriptreact", "vue"
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
                "@?class\\(([^]*)\\)",
                "'([^']*)'",
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
  
  -- Add Tailwind colorizer support
  {
    "NvChad/nvim-colorizer.lua",
    opts = {
      user_default_options = {
        tailwind = true,
      },
    },
  },
  
  -- Add Tailwind completion with colors
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      { "roobert/tailwindcss-colorizer-cmp.nvim", config = true },
    },
    opts = function(_, opts)
      -- original LazyVim kind icon formatter
      local format_kinds = opts.formatting.format
      opts.formatting.format = function(entry, item)
        format_kinds(entry, item) -- add icons
        return require("tailwindcss-colorizer-cmp").formatter(entry, item)
      end
    end,
  },
}