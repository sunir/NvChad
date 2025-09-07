# Neovim Learning Guide - New Features

This guide explains the new features added to your Neovim config and how to learn them **one at a time**. Don't try to learn everything at once!

## Learning Order (Start Here)

### 1. **Code Actions** - `<leader>C`
**Start with this first - highest impact, easy to learn**

**What it does:** Shows available actions for the code under your cursor (fix errors, refactor, add imports, etc.)

**How to use:**
- Put cursor on any error/warning (red/yellow squiggle)
- Press `<leader>C`
- Choose an action from the menu

**Practice:** Open a JavaScript file with an error and use `<leader>C` to fix it.

---

### 2. **Incremental Selection** - `Ctrl+Space`
**Learn this second - very useful for editing**

**What it does:** Smart text selection that expands by syntax scope

**How to use:**
- Put cursor inside a word
- Press `Ctrl+Space` → selects word
- Press `Ctrl+Space` again → selects function parameter
- Press again → selects whole function
- Press `Backspace` to shrink selection

**Practice:** Try in a JavaScript function - start inside a variable name and keep pressing `Ctrl+Space`.

---

### 3. **Trouble.nvim** - `<leader>xx`
**Learn this third - better error navigation**

**What it does:** Shows all errors/warnings in a organized list instead of jumping one by one

**Key bindings:**
- `<leader>xx` - Toggle trouble window
- `<leader>xd` - Show document diagnostics
- `<leader>xw` - Show workspace diagnostics

**How to use:**
1. Open a file with multiple errors
2. Press `<leader>xx`
3. Navigate through the list with `j/k`
4. Press `Enter` to jump to error

**Practice:** Open a file with TypeScript errors and use `<leader>xx` to see them all.

---

## Advanced Features (Learn Later)

### 4. **Multi-cursor Editing** - vim-visual-multi
**Learn this fourth - powerful but complex**

⚠️ **Performance Note:** This plugin loads on startup (`lazy = false`) which may slightly slow boot time. The trade-off is immediate availability.

**What it does:** Edit multiple identical words simultaneously (like VS Code's Ctrl+D)

**Basic usage:**
- Select a word in visual mode
- Press `Ctrl+N` to select next occurrence
- Keep pressing `Ctrl+N` to add more
- Edit all simultaneously

**Advanced:** See `:help visual-multi` for full commands

**Practice:** Find a variable used multiple times and rename it with multi-cursor.

---

### 5. **Project-wide Search/Replace** - `<leader>S`
**Learn this fifth - occasional but powerful**

**What it does:** Find and replace text across your entire project

**How to use:**
1. Press `<leader>S` to open Spectre
2. Enter search term in first field
3. Enter replacement in second field
4. Press `Ctrl+S` to replace all

**Practice:** Replace a function name across your project.

---

## Behind the Scenes (You Don't Need to Learn These)

### Enhanced Language Support
These LSP servers were added and work automatically:
- **Python** (`pyright`) - Python code completion/errors
- **JSON** (`jsonls`) - JSON file validation
- **YAML** (`yamlls`) - YAML file validation  
- **Markdown** (`marksman`) - Markdown navigation

### Enhanced Treesitter
Added syntax highlighting for more file types. Works automatically.

---

## Learning Strategy

**Week 1:** Master `<leader>C` (code actions)
- Use it every time you see an error
- Explore what actions are available

**Week 2:** Add `Ctrl+Space` (incremental selection)
- Use it when selecting text
- Practice expanding/shrinking selections

**Week 3:** Add `<leader>xx` (trouble window)
- Use instead of `:cnext/:cprev` for errors
- Try the different trouble modes

**Week 4+:** Experiment with multi-cursor and spectre when needed

---

## Quick Reference

| Feature | Key | What |
|---------|-----|------|
| Code Actions | `<leader>C` | Fix/refactor code |
| Incremental Select | `Ctrl+Space` | Smart selection |
| Trouble | `<leader>xx` | Error list |
| Multi-cursor | `Ctrl+N` | Select multiple |
| Find/Replace | `<leader>S` | Project-wide replace |

---

## Getting Help

- `:help trouble.nvim` - Trouble documentation
- `:help visual-multi` - Multi-cursor help
- `:Lazy` - Plugin manager (see installed plugins)
- `:Mason` - LSP server manager

**Remember:** Learn one feature at a time. Use it for a week before adding the next one!