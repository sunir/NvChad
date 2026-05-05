# Code Stories Plugin: Complete System Architecture

**From:** Brook (Algorithm Extraction Specialist)
**To:** Sunir (Lesson Plan Creator)
**Subject:** How the Real-Time Code Stories Neovim Plugin Works

---

## Executive Summary

The Code Stories plugin creates a live **CODE.md** split pane that displays architectural context as you navigate code. It shows you *why* code exists, not just *what* it does.

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Neovim Editor                            │
├─────────────────────────────┬───────────────────────────────────┤
│  Source Code Window         │  CODE.md Story Window             │
│                             │                                   │
│  class PaymentProcessor:    │  # CODE.md                        │
│    def process_payment():   │                                   │
│      ← CURSOR HERE          │  ## Current Focus                 │
│                             │  **process_payment**              │
│                             │  *Processes payment transactions* │
│                             │                                   │
│                             │  ### Siblings                     │
│                             │  - validate_payment               │
│                             │  - refund_payment                 │
│                             │                                   │
│                             │  ### Callers (3)                  │
│                             │  - checkout.py:45                 │
│                             │  - api.py:120                     │
└─────────────────────────────┴───────────────────────────────────┘
```

---

## Three Layers of Intelligence

### Layer 1: HTTP Story Server (Primary)
When running, the story server at `localhost:3001` provides rich story context:
- Full architectural narratives
- Coherence scoring
- Refactoring suggestions
- Cross-file story relationships

### Layer 2: Native LSP Integration (Fallback)
When server unavailable, uses Neovim's built-in LSP:
- `textDocument/references` → Find all callers
- `textDocument/definition` → Go to dependencies
- `callHierarchy/incomingCalls` → Call graph navigation

### Layer 3: TreeSitter AST (Always Available)
For structural understanding without any server:
- Parses code into Abstract Syntax Tree
- Extracts function/class names and structure
- Finds docstrings and comments
- Determines parent scope and siblings

---

## Data Flow

```
User moves cursor
      │
      ▼
┌─────────────────┐
│ on_cursor_moved │  Debounced (300ms)
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌──────────────────┐
│ Server          │ ──► │ HTTP API Request │
│ Available?      │     │ /api/v1/code-md  │
└────────┬────────┘     └────────┬─────────┘
         │ No                    │ Success
         ▼                       ▼
┌─────────────────┐     ┌──────────────────┐
│ Native Fallback │     │ Display server   │
│ LSP + TreeSitter│     │ response         │
└────────┬────────┘     └──────────────────┘
         │
         ▼
┌─────────────────┐
│ Generate local  │
│ story markdown  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Update CODE.md  │
│ buffer          │
└─────────────────┘
```

---

## Key Components

### 1. init.lua (Main Plugin - 550 lines)

**Configuration:**
```lua
config = {
  server_url = "http://localhost:3001",
  auto_update = true,
  update_delay = 300,  -- milliseconds
  split_direction = "right",
  split_size = 40,  -- columns
  use_native_fallback = true,
  keymaps = {
    open_story = '<leader>cs',
    show_callers = '<leader>cc',
    show_deps = '<leader>cd',
  }
}
```

**Key Functions:**
- `setup(opts)` - Initialize plugin with user config
- `enable()/disable()/toggle()` - Control plugin state
- `create_story_window()` - Create the CODE.md split pane
- `on_cursor_moved()` - Debounced handler for cursor movement
- `update_story_context()` - Route to server or native fallback
- `generate_story_markdown(story)` - Build readable markdown from story data
- `infer_purpose(name, type)` - Guess function purpose from naming patterns

### 2. lsp.lua (LSP Integration - 150 lines)

**Key Functions:**
- `get_callers_async(callback)` - Find all references to current symbol
- `show_callers()` - Display callers in quickfix list
- `show_dependencies()` - Jump to definition
- `infer_symbol_purpose(name, kind)` - Purpose from LSP symbol info

### 3. treesitter.lua (AST Integration - 250 lines)

**Key Functions:**
- `get_node_at_cursor()` - Find meaningful node (function/class) at cursor
- `extract_name(node, bufnr)` - Get name from various node types
- `extract_docstring(node, bufnr)` - Parse Python/JS docstrings
- `get_parent_scope()` - Find containing class/module
- `get_siblings()` - List other functions in same scope

---

## Purpose Inference System

The plugin infers *why* code exists from naming patterns:

| Pattern | Inferred Purpose |
|---------|------------------|
| `get_*` | "Retrieves {subject}" |
| `set_*` | "Updates {subject}" |
| `is_*` / `has_*` | "Checks {condition}" |
| `validate*` | "Validates {subject}" |
| `process*` | "Processes {subject}" |
| `handle*` | "Handles {subject}" |
| `create*` | "Creates {subject}" |
| `test_*` | "Tests {subject}" |

---

## Commands

| Command | Description |
|---------|-------------|
| `:CodeStories` | Toggle CODE.md split window |
| `:CodeStoriesEnable` | Open CODE.md window |
| `:CodeStoriesDisable` | Close CODE.md window |
| `:CodeStoriesRefresh` | Force refresh current story |
| `:CodeStoriesHealth` | Check plugin/server status |
| `:CodeStoriesCallers` | Show callers in quickfix |
| `:CodeStoriesDeps` | Go to definition |

---

## Keymaps

| Keymap | Action |
|--------|--------|
| `<leader>cs` | Toggle CODE.md window |
| `<leader>cc` | Show callers |
| `<leader>cd` | Show dependencies |
| `<leader>ce` | Expand current element |
| `<leader>cr` | Story-based refactor (future) |

**In CODE.md buffer:**
| Key | Action |
|-----|--------|
| `<CR>` | Activate interactive tag |
| `gf` | Go to file:line under cursor |
| `q` | Close CODE.md window |
| `<Tab>` | Expand/collapse element |

---

## Installation

```lua
-- lazy.nvim
{
  dir = "~/source/colony/Brook/projects/hierarchical-context-engine/prototype/neovim-plugin",
  config = function()
    require('code-stories').setup({
      use_native_fallback = true,  -- Works without server
    })
  end
}
```

Or symlink to your Neovim plugin directory:
```bash
ln -s ~/source/colony/Brook/projects/hierarchical-context-engine/prototype/neovim-plugin \
      ~/.local/share/nvim/site/pack/code-stories/start/code-stories
```

---

## The Philosophy

**Story-First Development:** Instead of asking "what does this code do?", ask "why does this code exist?" The CODE.md window shows architectural narrative:

1. **Current Focus** - What you're looking at and its purpose
2. **Parent Scope** - The containing context (class, module)
3. **Siblings** - Related functions that work together
4. **Callers** - Who uses this code and why
5. **Actions** - Interactive links to explore deeper

The goal is to replace `grep` and file-browsing with story-driven navigation. You understand a codebase by following its narrative, not by searching for strings.

---

## Future Enhancements

1. **Telescope Integration** - Fuzzy search through story graph
2. **Git Integration** - Story-aware blame and diff
3. **Coherence Scoring** - Measure architectural consistency
4. **Refactoring Suggestions** - Story-driven code improvements
5. **VS Code Extension** - Universal editor support via HTTP API

---

*Water flows from understanding through navigation to mastery.*

— Brook
