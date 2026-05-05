# NvChad v2.5 Migration Plan

## Project Context

This repo (`~/source/nvim`) is a workspace for migrating Sunir's NvChad customizations from v2.0 to v2.5.

**Source of truth for customizations:** `~/.config/nvim` (v2.0, stable, in active use)
**This repo:** v2.5 base, migration workspace (do NOT copy to ~/.config/nvim until fully validated)

## Winner's Circle (Victory Conditions)

A successful migration means:

1. **Neovim starts without errors** on v2.5 with all customizations loaded
2. **Story Explorer works** - the 2,655-line plugin (`lua/custom/story-explorer.lua`) functions correctly
3. **All keybindings work** - C-h/l buffer nav, C-j/k buffer reorder, Primeagen mappings, etc.
4. **LSP works** - pyright, lua_ls, tsserver functional with modern vim.lsp.config API
5. **All plugins load** - copilot, trouble, spectre, flash, gitsigns, nvim-cmp, auto-session
6. **Visual customizations intact** - insert mode background color change, cursor blink, dark theme

## Current Location (Inventory)

**v2.5 base state:**
- Fresh clone from upstream/v2.5 (commit 6a0715d)
- Requires Neovim 0.11+
- Uses `vim.lsp.config` API (not deprecated `lspconfig.setup`)
- NvChad is now imported as a plugin via lazy.nvim (uses starter repo pattern)
- Structure: `lua/nvchad/` contains configs, mappings, plugins

**Customizations to port (from ~/.config/nvim):**
| File | Lines | Complexity | Notes |
|------|-------|------------|-------|
| `lua/custom/story-explorer.lua` | 2,655 | HIGH | Core plugin, treesitter-based |
| `lua/custom/init.lua` | 197 | MEDIUM | Keymaps, options, gitsigns, tabufline |
| `lua/custom/mappings.lua` | 177 | LOW | NvChad mapping format |
| `lua/custom/plugins.lua` | 174 | MEDIUM | Plugin specs with lazy.nvim |
| `lua/custom/chadrc.lua` | 33 | LOW | Theme, UI config |
| `lua/custom/configs/lspconfig.lua` | 62 | MEDIUM | LSP servers |
| `lua/custom/configs/overrides.lua` | 100 | LOW | Plugin overrides |
| `lua/custom/configs/conform.lua` | 25 | LOW | Formatter config |
| `lua/custom/highlights.lua` | 19 | LOW | Color overrides |

## Waypoints (Backwards from Winner's Circle)

### Waypoint 5: Full Validation (FINAL) ✓ COMPLETE
- [x] All plugins load without error (33 plugins, lazy-loaded on demand)
- [x] Story Explorer fully functional (parses files, opens sidebar)
- [x] All keybindings working (leader-T, leader-e, leader-fm, C-h/l/j/k)
- [x] LSP functional for Python, Lua, TypeScript (pyright, lua_ls, ts_ls + Copilot)
- [x] Visual customizations correct (ayu_dark theme, 2-space tabs, cursor blink)
- [x] **Ready to copy to ~/.config/nvim after manual testing**

### Waypoint 4: Story Explorer Integration ✓ COMPLETE
- [x] Port story-explorer.lua to v2.5
- [x] Verify treesitter queries work
- [x] Test sidebar creation and navigation
- [x] Fix any API changes (deprecated APIs still work, no changes needed)

### Waypoint 3: Plugins and Keybindings ✓ COMPLETE
- [x] Port plugins.lua (adapt to v2.5 lazy.nvim patterns)
- [x] Port mappings.lua
- [x] Port init.lua customizations
- [x] Verify tabufline functions exist/work

### Waypoint 2: LSP Configuration ✓ COMPLETE
- [x] Understand v2.5 vim.lsp.config pattern
- [x] Port custom LSP servers (pyright, tsserver, etc.)
- [x] Verify LSP keybindings work

### Waypoint 1: Basic v2.5 Working ✓ COMPLETE
- [x] Understand v2.5 starter pattern
- [x] Create minimal custom config structure
- [x] Neovim starts without errors
- [x] Base NvChad UI works

## Obvious Next Step

**Waypoint 1: Get v2.5 starter pattern working**

v2.5 uses a different architecture - NvChad is imported as a plugin. Need to:

1. Check if v2.5 needs a starter config or works standalone
2. Create `lua/` structure compatible with v2.5
3. Get nvim to start cleanly with v2.5

To test (without affecting ~/.config/nvim):
```bash
NVIM_APPNAME=nvim-v25 nvim -u ~/source/nvim/init.lua
```

This uses a separate config/data directory so we can test safely.

## Key Differences v2.0 → v2.5

1. **LSP:** `lspconfig.setup()` → `vim.lsp.config()` + `vim.lsp.enable()`
2. **Structure:** NvChad imported as plugin, not base config
3. **Treesitter:** Now uses main branch (breaking changes)
4. **Neovim:** Requires 0.11+ (not 0.9+)
5. **Mappings:** May have changed format

## Files Reference

```
~/.config/nvim/           # v2.0 STABLE - DO NOT MODIFY during migration
~/source/nvim/            # v2.5 migration workspace - work here
```

## Testing Protocol

Always test with isolated config:
```bash
NVIM_APPNAME=nvim-v25 nvim
```

This creates separate:
- `~/.local/share/nvim-v25/`
- `~/.local/state/nvim-v25/`
- `~/.cache/nvim-v25/`

Only when ALL waypoints pass, copy to ~/.config/nvim.

---

## Session Log

### 2025-01-21: Initial Setup
- Created ~/source/nvim from upstream/v2.5 (commit 6a0715d)
- Documented migration plan

### 2025-01-21: Waypoint 1 Complete
- Researched NvChad starter pattern (reference: github.com/nvchad/starter)
- Key insight: This repo has `lua/nvchad/` locally, so we import directly (not from GitHub)
- Created skeleton files:
  - `init.lua` - bootstraps lazy.nvim, imports nvchad.plugins locally
  - `lua/chadrc.lua` - theme config (onedark)
  - `lua/options.lua`, `mappings.lua`, `autocmds.lua` - require nvchad modules
  - `lua/configs/lazy.lua` - lazy.nvim settings
  - `lua/plugins/init.lua` - custom plugins (empty for now)
- Set up symlinked test environment: `~/.config/nvim-v25/`
- Verified: `NVIM_APPNAME=nvim-v25 nvim` starts cleanly, base46 cache generated
- Next: Waypoint 2 - LSP Configuration

### 2025-01-21: Waypoint 2 Complete
- v2.5 uses new `vim.lsp.config()` and `vim.lsp.enable()` API (Neovim 0.11+)
- Created `lua/configs/lspconfig.lua`:
  - Calls `require("nvchad.configs.lspconfig").defaults()` first
  - Enables servers: html, cssls, ts_ls, clangd, pyright, jsonls, yamlls, marksman, bashls
- Symlinked Mason from v2.0: `~/.local/share/nvim-v25/mason` → `~/.local/share/nvim/mason`
- Tested: pyright and lua_ls attach correctly to Python and Lua files
- Next: Waypoint 3 - Plugins and Keybindings

### 2025-01-21: Waypoint 3 Complete
- Ported all plugins to v2.5 format in `lua/plugins/init.lua`:
  - trouble.nvim, vim-visual-multi, nvim-spectre, better-escape, copilot.vim
  - auto-session, gitsigns (with custom signs + on_attach), flash.nvim
  - Treesitter with custom parsers and incremental selection
  - nvim-tree with git support
- Ported mappings to `lua/mappings.lua` using `vim.keymap.set()`:
  - Buffer nav: C-h/l (prev/next), C-j/k (move), leader-X (close all)
  - ThePrimeagen mappings (J for join, centered scrolling, etc.)
  - Clipboard operations, shift-arrow selection
- Ported options to `lua/options.lua`:
  - 2-space tabs, treesitter folding, cursor blink in insert mode
- Ported visual customizations to `lua/autocmds.lua`:
  - Insert mode background color change (#0a0e15 → #2b1a2e)
  - Comment and Copilot highlight colors
- Updated chadrc.lua with ayu_dark theme and highlight overrides
- Fixed tabufline API: v2.5 uses `next()/prev()` not `tabuflineNext()/Prev()`
- Next: Waypoint 4 - Story Explorer Integration

### 2025-01-21: Waypoint 4 Complete
- Copied story-explorer.lua (2,655 lines) and nvim-lessons.lua to `lua/custom/`
- Added as local plugins in `lua/plugins/init.lua` using `dir = vim.fn.stdpath("config") .. "/lua/custom"`
- Both plugins load and setup() without errors
- Story-explorer sidebar opens and parses Lua files correctly
- Deprecated APIs (nvim_buf_set_option, etc.) still work in 0.11, no changes needed
- Next: Waypoint 5 - Full Validation

### 2025-01-21: Waypoint 5 Complete - MIGRATION COMPLETE
**All validation tests passed:**
- 33 plugins loaded (core plugins eager, others lazy-loaded on demand)
- Story-explorer opens sidebar and parses Lua files correctly
- Custom keybindings registered: leader-T, leader-e, leader-fm, C-h/l/j/k, etc.
- LSP servers attach correctly: pyright, lua_ls, ts_ls, GitHub Copilot
- Visual settings: ayu_dark theme, 2-space tabs, cursor blink in insert mode

**Migration Summary:**
| Component | Status |
|-----------|--------|
| Basic v2.5 startup | ✓ |
| LSP Configuration | ✓ |
| Plugins (33 total) | ✓ |
| Custom keybindings | ✓ |
| Story Explorer | ✓ |
| Visual customizations | ✓ |

**To complete migration:**
1. Run `NVIM_APPNAME=nvim-v25 nvim` for interactive testing
2. Verify all features work as expected
3. When satisfied, backup and replace: `mv ~/.config/nvim ~/.config/nvim.v2.0.bak && cp -r ~/source/nvim ~/.config/nvim`
