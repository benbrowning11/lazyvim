-- add more treesitter parsers
return {
  "nvim-treesitter/nvim-treesitter",
  build = function()
    require("nvim-treesitter.install").update({ with_sync = true })
  end,
  dependencies = {
    {
      "JoosepAlviste/nvim-ts-context-commentstring",
      opts = {
        custom_calculation = function(_, language_tree)
          if vim.bo.filetype == "blade" and language_tree._lang ~= "javascript" and language_tree._lang ~= "php" then
            return "{{-- %s --}}"
          end

          if vim.bo.filetype == "vue" then
            -- For Vue components, provide context-aware comments based on cursor position
            if language_tree._lang == "typescript" or language_tree._lang == "javascript" then
              return "// %s"
            elseif language_tree._lang == "css" or language_tree._lang == "scss" then
              return "/* %s */"
            else
              return "<!-- %s -->"  -- Default to HTML comments for template section
            end
          end
        end,
      },
    },
    "nvim-treesitter/nvim-treesitter-textobjects",
  },
  opts = {
    ensure_installed = "all",
    auto_install = true,
    highlight = {
      enable = true,
    },
    -- Needed because treesitter highlight turns off autoindent for php files
    indent = {
      enable = true,
    },
  },
  config = function(_, opts)
    ---@class ParserInfo[]
    local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
    parser_config.blade = {
      install_info = {
        url = "https://github.com/EmranMR/tree-sitter-blade",
        files = {
          "src/parser.c",
          -- 'src/scanner.cc',
        },
        branch = "main",
        generate_requires_npm = true,
        requires_generate_from_grammar = true,
      },
      filetype = "blade",
    }

    if not parser_config.vue then
      -- Vue parser should be part of official treesitter parsers
      -- but we can make sure it's properly installed
      vim.cmd [[TSInstall vue typescript]] 
    end

    require("nvim-treesitter.configs").setup(opts)
  end,
}