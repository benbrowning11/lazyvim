# Laravel Neovim Configuration

A modern Neovim configuration for Laravel development with TypeScript and Vue 3 support.

## Features

This configuration includes all the great LazyVim features (including its much appreciated documentation), plus:

### PHP

- Intellephense as the language server
- Pint for PHP formatting
- Xdebug with UI, line output, and preconfigured for Sail

### Laravel

- ~~Blade language support~~ (Removed: Using Vue 3 instead)
- ~~Blade formatter~~ (Removed: Using Vue 3 instead)

### Vue 3

- Vue language support
- Vue 3 template intellisense
- Component auto-imports
- SFC (Single File Component) support

### TypeScript

- TypeScript language server
- Type checking and intellisense
- Auto-import support

### Tailwind

- Tailwind language server
- Tailwind color preview
- Rustywind (Rust-based Tailwind class sorter)

### Theme

- The only acceptable choice: Gruvbox

## Installation

1. Ensure you have the latest Neovim release (latest stable or HEAD)
2. Fork this repository
3. Clone the repository to `~/.config/nvim/`
   ```bash
   git clone https://github.com/YOUR_USERNAME/REPOSITORY_NAME ~/.config/nvim
   ```
4. Start Neovim
   ```bash
   nvim
   ```
5. Let lazy.nvim do its job (it will install all required plugins)
6. Restart Neovim
7. Open Mason (`:Mason`) and install the required packages
   - PHP: `intelephense`, `php-cs-fixer`, `pint`
   - TypeScript: `typescript-language-server`, `eslint-lsp`
   - Vue: `vue-language-server`, `volar`
   - Tailwind: `tailwindcss-language-server`, `rustywind`
8. Restart Neovim once more
9. Enjoy your Neovim setup for Laravel development!

## Keymaps

The configuration inherits all keymaps from LazyVim. Here are some additional keymaps specifically for Laravel development:

| Key Combination | Mode | Action                             |
| --------------- | ---- | ---------------------------------- |
| `<Leader>xd`    | n    | Toggle Xdebug                      |
| `<Leader>xb`    | n    | Toggle Xdebug breakpoint           |
| `<Leader>ts`    | n    | Run type check on current file     |
| `<Leader>tw`    | n    | Sort Tailwind classes in selection |

## Customization

You can customize this configuration by:

1. Editing `~/.config/nvim/lua/config/options.lua` for Neovim options
2. Editing `~/.config/nvim/lua/config/keymaps.lua` for keymaps
3. Editing `~/.config/nvim/lua/config/lazy.lua` for plugin management
4. Adding or modifying configuration in `~/.config/nvim/lua/plugins/` directory

## Troubleshooting

### Common Issues

#### PHP LSP Not Working

- Ensure Intellephense is installed via Mason (`:Mason` and check)
- Check if PHP is in your PATH

#### TypeScript Type Checking Issues

- Make sure you have a proper `tsconfig.json` in your project root
- Install required dependencies: `@vue/typescript-plugin` for Vue projects

#### Vue SFC Highlighting Problems

- Ensure Vue language server is installed via Mason
- Try reconnecting the language server with `:LspRestart`

## License

[MIT License](LICENSE)
