return {
  -- Vue 3 support
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      if not opts.servers then opts.servers = {} end
      
      -- Configure Volar for Vue 3
      opts.servers.volar = {
        filetypes = { "vue", "typescript", "javascript" },
        init_options = {
          typescript = {
            tsdk = vim.fn.expand("$HOME/node_modules/typescript/lib")
            -- You may need to adjust this path based on your project
          },
        },
      }
      
      -- Configure TypeScript server
      opts.servers.tsserver = {
        root_dir = require("lspconfig").util.root_pattern("package.json", "tsconfig.json"),
        single_file_support = true,
        settings = {
          typescript = {
            inlayHints = {
              includeInlayParameterNameHints = "all",
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
            },
          },
        },
      }
      
      return opts
    end,
  },
  
  -- Ensure rustywind works with Vue files for Tailwind sorting
  {
    "tlaceby/rustywind.nvim",
    optional = true,
    opts = function(_, opts)
      if opts.filetypes then
        table.insert(opts.filetypes, "vue")
      else
        opts.filetypes = { "html", "css", "javascript", "typescript", "vue" }
      end
      return opts
    end,
  },
  
  -- Configure formatter for Vue and TypeScript
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function(_, opts)
      if not opts.formatters_by_ft then opts.formatters_by_ft = {} end
      
      opts.formatters_by_ft.vue = { "prettierd" }
      opts.formatters_by_ft.typescript = { "prettierd" }
      
      return opts
    end,
  },
  
  -- Disable Blade plugins if they exist
  { "jwalton512/vim-blade", enabled = false },
  { "EmranMR/blade-formatter", enabled = false },
}