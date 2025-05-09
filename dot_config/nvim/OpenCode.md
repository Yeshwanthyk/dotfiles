# OpenCode.md - Neovim Configuration Guidelines

## Commands
- Format Lua: `stylua .`
- Lint: `luacheck .`
- Test: `busted -o TAP`
- Test single file: `busted -o TAP path/to/test.lua`

## Code Style
- Indentation: 2 spaces (defined in stylua.toml)
- Line width: 120 characters max
- Naming: snake_case for variables/functions, PascalCase for classes
- Imports: group by core/plugins/local, alphabetize within groups
- Error handling: use pcall for protected calls, check return values
- Comments: use -- for single line, --[[ ]] for multiline
- Functions: prefer local functions when possible
- Tables: trailing comma on multiline tables
- Strings: prefer single quotes for simple strings

## Plugin Development
- Follow LazyVim plugin structure
- Use plenary.nvim for testing
- Provide clear keymaps with leader prefixes
- Document public API functions