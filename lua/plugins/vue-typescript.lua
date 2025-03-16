return {
  -- Configure LSP for Vue and TypeScript
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      if not opts.servers then opts.servers = {} end
      
       -- Vue language server (Volar)
      opts.servers.volar = {
        filetypes = { "vue", "typescript", "javascript" },
        init_options = {
          typescript = {
            -- Fix for Windows path to TypeScript
            tsdk = vim.fn.expand(vim.fn.stdpath("data") .. "/mason/packages/typescript-language-server/node_modules/typescript/lib"),
          },
        },
      }

      if opts.setup then
        opts.setup.volar = function(_, _opts)
          -- Fix path for Windows
          local mason_bin = vim.fn.stdpath("data") .. "/mason/bin/vue-language-server"
          if vim.fn.has("win32") == 1 then
            mason_bin = mason_bin .. ".CMD" -- Windows needs .CMD extension
          end
          _opts.cmd = { mason_bin, "--stdio" }
          return false
        end
      end
      
      -- TypeScript language server
      opts.servers.tsserver = {
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
  }
}