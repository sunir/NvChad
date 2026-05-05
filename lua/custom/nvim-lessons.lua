-- Neovim Lessons - Interactive Learning with Spaced Repetition
-- Learn one thing a day, review when due

local M = {}

-- Spaced repetition intervals (in days): 1, 3, 7, 14, 30, 60
local INTERVALS = { 1, 3, 7, 14, 30, 60 }

-- Lesson database
M.lessons = {
  {
    id = "code_actions",
    title = "Code Actions",
    key = "<leader>C",
    difficulty = 1,
    summary = "Fix errors, refactor, add imports with one keystroke",
    content = [[
## Code Actions - `<leader>C`

**What it does:** Shows available actions for the code under your cursor
(fix errors, refactor, add imports, etc.)

**How to use:**
1. Put cursor on any error/warning (red/yellow squiggle)
2. Press `<leader>C`
3. Choose an action from the menu

**Practice Challenge:**
Open a JavaScript or Python file with an error and use `<leader>C` to fix it.
Try it on an unused import - you can remove it with code actions!

**Tips:**
- Works on warnings too, not just errors
- Available actions depend on the language server
- Some actions work on whole file (organize imports)
]],
    quiz = {
      question = "What key shows code actions in this config?",
      answer = "<leader>C",
      hints = { "It's leader followed by a capital letter", "Think 'C' for Code" }
    },
    practice = {
      filetype = "python",
      filename = "practice_code_actions.py",
      code = [[
# Practice: Code Actions
# Put your cursor on the squiggly lines and press <leader>C

import os
import sys
import json  # <- unused import, try <leader>C here

def calculate_total(items):
    total = 0
    for item in items:
        total += item["price"]  # <- might show type hints
    return total

# Try these:
# 1. Put cursor on 'json' import -> <leader>C -> remove unused import
# 2. Put cursor on 'calculate_total' -> <leader>C -> see refactor options
# 3. Put cursor on any variable -> <leader>C -> extract to variable/function

users = [
    {"name": "Alice", "price": 100},
    {"name": "Bob", "price": 200},
]

result = calculate_total(users)
print(f"Total: {result}")
]]
    }
  },
  {
    id = "incremental_selection",
    title = "Incremental Selection",
    key = "Ctrl+Space",
    difficulty = 2,
    summary = "Smart text selection that expands by syntax scope",
    content = [[
## Incremental Selection - `Ctrl+Space`

**What it does:** Smart text selection that understands code structure.
Each press expands selection to the next syntax level.

**How to use:**
1. Put cursor inside a word
2. Press `Ctrl+Space` -> selects word
3. Press again -> selects parameter/expression
4. Press again -> selects statement
5. Press again -> selects function body
6. Press `Backspace` to shrink selection

**Practice Challenge:**
In a function like this:
```lua
function example(foo, bar)
  local result = foo + bar
  return result
end
```
Put cursor on `foo` in `foo + bar` and press Ctrl+Space repeatedly.
Watch it expand: word -> expression -> statement -> function body -> function

**Why it's powerful:**
- No more counting brackets or quotes
- Selects semantically meaningful chunks
- Works in any language with treesitter support
]],
    quiz = {
      question = "How do you SHRINK an incremental selection?",
      answer = "Backspace",
      hints = { "It's the opposite of expanding", "A common key for 'undo' or 'back'" }
    },
    practice = {
      filetype = "lua",
      filename = "practice_incremental_selection.lua",
      code = [[
-- Practice: Incremental Selection
-- Put cursor on marked spots and press Ctrl+Space repeatedly
-- Press Backspace to shrink selection

local function process_user_data(user_id, options)
  -- START HERE: Put cursor on 'user_id' below, then Ctrl+Space
  local result = fetch_user(user_id, options.include_metadata)
  --                        ^^^^^^^ start here

  -- Watch it expand:
  -- 1st Ctrl+Space: selects 'user_id'
  -- 2nd Ctrl+Space: selects 'user_id, options.include_metadata'
  -- 3rd Ctrl+Space: selects 'fetch_user(user_id, options.include_metadata)'
  -- 4th Ctrl+Space: selects entire local statement
  -- 5th Ctrl+Space: selects function body
  -- 6th Ctrl+Space: selects entire function

  if result.success then
    -- TRY HERE TOO: cursor on 'data' below
    local data = transform_response(result.payload, {
      format = "json",
      pretty = true,
    })
    return data
  end

  return nil
end

-- More practice: try on nested structures
local config = {
  server = {
    host = "localhost",  -- <- try Ctrl+Space on "localhost"
    port = 8080,
  },
  features = {
    auth = true,
    logging = {
      level = "debug",   -- <- try here too
      output = "file",
    },
  },
}
]]
    }
  },
  {
    id = "trouble",
    title = "Trouble.nvim",
    key = "<leader>xx",
    difficulty = 2,
    summary = "See all errors in an organized list, not one by one",
    content = [[
## Trouble.nvim - `<leader>xx`

**What it does:** Shows ALL errors/warnings in a pretty organized list
instead of jumping through them one at a time.

**Key bindings:**
- `<leader>xx` - Toggle trouble window (all diagnostics)
- `<leader>xd` - Document diagnostics only
- `<leader>xw` - Workspace diagnostics (all files)

**How to use:**
1. Open a file with multiple errors
2. Press `<leader>xx`
3. Navigate the list with `j/k`
4. Press `Enter` to jump to that error
5. Press `q` to close trouble window

**Practice Challenge:**
1. Open a TypeScript or Python file with several issues
2. Press `<leader>xx` to see the trouble list
3. Try `<leader>xd` vs `<leader>xw` - notice the difference?

**Why it's better than :cnext:**
- See ALL problems at once
- Group by file, severity, or source
- Preview without jumping
- Persists across file changes
]],
    quiz = {
      question = "What's the difference between <leader>xd and <leader>xw?",
      answer = "xd shows current document only, xw shows whole workspace",
      hints = { "d = document, w = workspace", "One is local, one is global" }
    },
    practice = {
      filetype = "typescript",
      filename = "practice_trouble.ts",
      code = [[
// Practice: Trouble.nvim
// This file has INTENTIONAL errors for you to practice with
// Press <leader>xx to see them all in the Trouble window

interface User {
  id: number;
  name: string;
  email: string;
}

// Error 1: Type mismatch
const user1: User = {
  id: "123",        // <- wrong type (string instead of number)
  name: "Alice",
  email: "alice@example.com",
};

// Error 2: Missing property
const user2: User = {
  id: 2,
  name: "Bob",
  // email is missing!
};

// Error 3: Unknown property
const user3: User = {
  id: 3,
  name: "Charlie",
  email: "charlie@example.com",
  age: 25,          // <- 'age' doesn't exist on type User
};

// Error 4: Undefined variable
function processUser(user: User) {
  console.log(userData.name);  // <- userData is not defined
  return user.id * 2;
}

// Error 5: Unreachable code
function getValue(): number {
  return 42;
  console.log("This will never run");  // <- unreachable
}

// NOW TRY:
// 1. Press <leader>xx to open Trouble - see all 5+ errors listed
// 2. Press j/k to navigate the error list
// 3. Press Enter to jump to an error
// 4. Press <leader>xd for just this document
// 5. Press q to close Trouble
]]
    }
  },
  {
    id = "multicursor",
    title = "Multi-cursor Editing",
    key = "Ctrl+N",
    difficulty = 3,
    summary = "Edit multiple identical words simultaneously",
    content = [[
## Multi-cursor Editing - `Ctrl+N`

**What it does:** Select and edit multiple occurrences of a word
simultaneously - like VS Code's Ctrl+D.

**Basic usage:**
1. Select a word (or put cursor on it)
2. Press `Ctrl+N` to select next occurrence
3. Keep pressing `Ctrl+N` to add more cursors
4. Type to edit ALL selected simultaneously
5. Press `Esc` to exit multi-cursor mode

**Other useful keys:**
- `Ctrl+Down/Up` - Add cursor below/above
- `Ctrl+S` - Skip current occurrence
- `\\A` - Select ALL occurrences at once

**Practice Challenge:**
Find a variable like `userName` used 5+ times in a file.
1. Select it
2. Press Ctrl+N to get all occurrences
3. Rename it to `displayName`
4. All instances change at once!

**Caution:**
- Can be confusing at first - practice in a test file
- If you get stuck, press `Esc` to exit
- The plugin loads on startup, so it's always available
]],
    quiz = {
      question = "How do you SKIP an occurrence when multi-selecting?",
      answer = "Ctrl+S",
      hints = { "S for Skip", "Not Ctrl+N - that ADDS" }
    },
    practice = {
      filetype = "javascript",
      filename = "practice_multicursor.js",
      code = [[
// Practice: Multi-cursor Editing
// Goal: Rename 'userName' to 'displayName' using multi-cursor

function formatUserProfile(userName) {
  // There are 8 occurrences of 'userName' in this file
  // Use Ctrl+N to select them all, then type the new name

  const greeting = "Hello, " + userName + "!";

  if (userName.length > 20) {
    console.log("userName is too long:", userName);
    return userName.substring(0, 20);
  }

  console.log("Processing userName:", userName);
  return userName.toUpperCase();
}

// EXERCISE 1: Basic multi-cursor
// 1. Put cursor on first 'userName' (line 5)
// 2. Press Ctrl+N repeatedly to select all occurrences
// 3. Type 'displayName' to replace all at once
// 4. Press Esc when done

// EXERCISE 2: Skip an occurrence
// Now try renaming 'item' to 'product' but SKIP the one in the comment
const items = [
  { item: "Apple", price: 1.00 },   // rename this 'item'
  { item: "Banana", price: 0.50 },  // rename this 'item'
  { item: "Cherry", price: 2.00 },  // rename this 'item'
];
// Don't rename 'item' in this comment!

// Steps:
// 1. Select first 'item' in the object
// 2. Ctrl+N to add next, Ctrl+N again
// 3. When you hit the comment one, press Ctrl+S to SKIP it
// 4. Continue with Ctrl+N for remaining ones
]]
    }
  },
  {
    id = "spectre",
    title = "Project-wide Search/Replace",
    key = "<leader>S",
    difficulty = 3,
    summary = "Find and replace across your entire project",
    content = [[
## Spectre - `<leader>S`

**What it does:** Search and replace text across ALL files in your project.
Think global find-replace but visual and safe.

**How to use:**
1. Press `<leader>S` to open Spectre panel
2. Type search term in the search field
3. Type replacement in the replace field
4. Review all matches shown below
5. Press `<leader>R` to replace all (or replace individually)

**Key bindings in Spectre:**
- `<leader>R` - Replace all
- `dd` - Toggle ignore for current match
- `Enter` - Jump to match
- `q` - Close Spectre

**Practice Challenge:**
1. Open Spectre with `<leader>S`
2. Search for a function name in your project
3. Look at the preview - see all files it appears in
4. Try replacing it (in a test project!)

**Power tips:**
- Use regex for complex patterns
- Toggle matches off before replacing to exclude some
- Great for renaming across files
- Shows preview BEFORE you commit to the change
]],
    quiz = {
      question = "What key opens the project-wide search/replace?",
      answer = "<leader>S",
      hints = { "Capital S", "Think 'S' for Search or Spectre" }
    },
    practice = {
      filetype = "markdown",
      filename = "practice_spectre.md",
      code = [[
# Practice: Spectre (Project-wide Search/Replace)

This lesson is best practiced in a REAL project, not this buffer.
But here's a guided exercise:

## Exercise

1. Press `<leader>S` to open Spectre
2. In the search field, type: `TODO`
3. In the replace field, type: `DONE`
4. Look at the results - you'll see all TODOs in your project

## Things to notice in Spectre:

- Each match shows the file path and line
- You can press `dd` on a match to EXCLUDE it from replacement
- Press `<leader>R` to replace ALL (or `r` for just current line)
- Press `q` to close without replacing

## Sample content with TODOs to find:

TODO: Implement user authentication
TODO: Add error handling
TODO: Write unit tests
TODO: Update documentation
TODO: Refactor database queries

## Advanced: Regex search

Try searching for: `TODO:.*test`
This finds only TODOs that mention "test"

## Warning!

Spectre replaces across your WHOLE project.
Always review matches before pressing `<leader>R`!
]]
    }
  },
  {
    id = "flash_jump",
    title = "Flash Jump",
    key = "s",
    difficulty = 2,
    summary = "Jump anywhere visible with 2 keystrokes",
    content = [[
## Flash.nvim - `s`

**What it does:** Jump to ANY visible text with just 2-3 keystrokes.
Way faster than searching or moving line by line.

**Basic usage:**
1. Press `s` in normal mode
2. Type 1-2 characters of where you want to go
3. Labels appear on all matches
4. Press the label letter to jump there

**Other modes:**
- `S` - Flash Treesitter (select by syntax)
- `r` - Remote flash (in operator-pending mode)
- `Ctrl+s` - Toggle flash in search mode

**Practice Challenge:**
1. Open a file with lots of text
2. Press `s`
3. Type `fu` to find all "function" keywords
4. Press the label to jump to one
5. Try again with different targets

**Why it's faster than /search:**
- No need to press Enter
- Labels are instant, no mental overhead
- Works for ANY visible text
- Great for jumping within visible code
]],
    quiz = {
      question = "What key initiates a flash jump?",
      answer = "s",
      hints = { "Just one lowercase letter", "Think 'snipe' or 'seek'" }
    },
    practice = {
      filetype = "lua",
      filename = "practice_flash.lua",
      code = [[
-- Practice: Flash Jump
-- Goal: Jump to any word on screen with just 2-3 keystrokes

-- EXERCISE 1: Basic flash jump
-- From anywhere, press 's' then type 'fu' to find all 'function' keywords
-- Labels will appear - press the label letter to jump there

local function validate_user(user_data)
  if not user_data then
    return false, "No user data provided"
  end

  if not user_data.email then
    return false, "Email is required"
  end

  return true, nil
end

local function process_order(order_id, customer)
  local valid, error_msg = validate_user(customer)
  if not valid then
    print("Validation failed:", error_msg)
    return nil
  end

  -- Process the order here
  local result = {
    order_id = order_id,
    status = "processed",
    customer_email = customer.email,
  }

  return result
end

local function generate_report(start_date, end_date)
  -- Fetch all orders in date range
  local orders = fetch_orders_between(start_date, end_date)

  local total_revenue = 0
  for _, order in ipairs(orders) do
    total_revenue = total_revenue + order.amount
  end

  return {
    period = start_date .. " to " .. end_date,
    order_count = #orders,
    revenue = total_revenue,
  }
end

-- EXERCISES:
-- 1. Press 's', type 'lo' -> jump to any 'local'
-- 2. Press 's', type 're' -> jump to 'return', 'result', 'report', 'revenue'
-- 3. Press 's', type 'or' -> jump to 'order' occurrences
-- 4. Try 'S' (capital) for treesitter-aware selection!
]]
    }
  },
  {
    id = "buffer_nav",
    title = "Buffer Navigation",
    key = "Ctrl+h/l",
    difficulty = 1,
    summary = "Navigate and reorder buffers with Ctrl keys",
    content = [[
## Buffer Navigation - `Ctrl+h/l/j/k`

**What it does:** Quick buffer switching and reordering,
replacing the default window navigation.

**Key bindings:**
- `Ctrl+h` - Go to previous buffer (left)
- `Ctrl+l` - Go to next buffer (right)
- `Ctrl+j` - Move current buffer left in tab bar
- `Ctrl+k` - Move current buffer right in tab bar
- `<leader>X` - Close ALL buffers

**Practice Challenge:**
1. Open 3+ files
2. Use `Ctrl+l` to cycle through them
3. Use `Ctrl+j` to reorder them in the tab bar
4. Try `<leader>X` to close all (careful!)

**Why this config:**
- Ctrl+h/l is faster than :bnext/:bprev
- Reordering lets you group related files
- Tab bar shows your buffer order
- Muscle memory transfers from other editors

**Note:** This REPLACES the default Ctrl+h/l/j/k
which normally moves between splits. Use <leader>h/l/j/k
or mouse for split navigation.
]],
    quiz = {
      question = "How do you REORDER a buffer to move it left?",
      answer = "Ctrl+j",
      hints = { "j/k for reorder, h/l for navigate", "j moves left, k moves right" }
    },
    practice = {
      filetype = "markdown",
      filename = "practice_buffer_nav.md",
      code = [[
# Practice: Buffer Navigation

This lesson needs MULTIPLE buffers open to practice properly.

## Setup

Open a few files first:
```
:e ~/.config/nvim/init.lua
:e ~/.config/nvim/lua/custom/init.lua
:e ~/.config/nvim/lua/custom/plugins.lua
```

Now you have 3+ buffers in the tab bar.

## Exercises

### 1. Navigate between buffers
- Press `Ctrl+l` to go to next buffer (right)
- Press `Ctrl+h` to go to previous buffer (left)
- Keep pressing to cycle through all buffers

### 2. Reorder buffers
- Press `Ctrl+j` to move current buffer LEFT in the tab bar
- Press `Ctrl+k` to move current buffer RIGHT in the tab bar
- Arrange them in your preferred order!

### 3. Close all buffers
- Press `<leader>X` (capital X) to close ALL buffers
- WARNING: This closes everything! Use carefully.

## Tips

- Watch the tab bar at the top as you press these keys
- The current buffer is highlighted
- Reordering helps group related files together
- Much faster than `:bnext` and `:bprev`!
]]
    }
  },
  {
    id = "primeagen",
    title = "ThePrimeagen Mappings",
    key = "J, Ctrl+d/u, n/N",
    difficulty = 2,
    summary = "Keep cursor centered and stable while navigating",
    content = [[
## ThePrimeagen Mappings

**What they do:** Keep your cursor centered and stable while
navigating, so you never lose your place.

**Mappings:**
- `J` - Join lines but cursor stays where it was
- `Ctrl+d` - Page down AND center screen
- `Ctrl+u` - Page up AND center screen
- `n` - Next search result AND center
- `N` - Previous search result AND center
- `<leader>d` - Delete without yanking
- `<leader>p` - Paste over selection without yanking deleted text

**Visual mode bonuses:**
- `J` - Move selection DOWN
- `K` - Move selection UP

**Practice Challenge:**
1. Search for something with `/pattern`
2. Press `n` to go to next - notice you stay centered!
3. Try `Ctrl+d` to page down - you stay centered!
4. Select some lines, press `J` to move them down

**Why these help:**
- Your eyes always look at screen center
- No more "where did my cursor go?"
- Moving code blocks is intuitive
- Delete/paste without messing up your clipboard
]],
    quiz = {
      question = "What does <leader>d do differently than regular d?",
      answer = "Deletes without yanking (doesn't affect clipboard)",
      hints = { "Regular d saves to register", "This one uses the black hole register" }
    },
    practice = {
      filetype = "lua",
      filename = "practice_primeagen.lua",
      code = [[
-- Practice: ThePrimeagen Mappings
-- These keep your cursor stable while navigating

-- ═══════════════════════════════════════════════════════════
-- EXERCISE 1: Centered scrolling
-- ═══════════════════════════════════════════════════════════
-- Press Ctrl+d to page DOWN - notice you stay CENTERED!
-- Press Ctrl+u to page UP - still centered!
-- Compare to regular scrolling where cursor stays at edge
--
-- Scroll down through this file to feel the difference...



















-- You're halfway down! Keep scrolling with Ctrl+d...



















-- Almost at the bottom! Try Ctrl+u to go back up...

-- ═══════════════════════════════════════════════════════════
-- EXERCISE 2: Centered search
-- ═══════════════════════════════════════════════════════════
-- Search for: /MARKER
-- Press 'n' to go to next - you stay centered!
-- Press 'N' to go to previous - still centered!

-- MARKER one - first occurrence
local x = 1

-- MARKER two - second occurrence
local y = 2

-- MARKER three - third occurrence
local z = 3

-- MARKER four - fourth occurrence
local w = 4

-- ═══════════════════════════════════════════════════════════
-- EXERCISE 3: Move lines in visual mode
-- ═══════════════════════════════════════════════════════════
-- Select these lines (V then j/k), then press J to move DOWN, K to move UP

local first_item = "Move me!"
local second_item = "Move me too!"
local third_item = "And me!"

-- ═══════════════════════════════════════════════════════════
-- EXERCISE 4: Delete without yanking
-- ═══════════════════════════════════════════════════════════
-- 1. Yank this line: yy on "KEEP THIS IN CLIPBOARD"
-- 2. Delete the line below with <leader>d (not regular dd)
-- 3. Paste with p - you get "KEEP THIS" not the deleted text!

-- KEEP THIS IN CLIPBOARD
-- DELETE THIS LINE WITH <leader>d
-- Now paste below this line to verify clipboard wasn't changed

-- ═══════════════════════════════════════════════════════════
-- EXERCISE 5: Paste over selection without losing clipboard
-- ═══════════════════════════════════════════════════════════
-- 1. Yank the word "CORRECT" below
-- 2. Select "WRONG" in visual mode
-- 3. Press <leader>p to replace (not regular p)
-- 4. Select another "WRONG" and <leader>p again - still works!

-- CORRECT
-- The answer is WRONG and also WRONG and also WRONG
]]
    }
  },
  {
    id = "inlay_hints",
    title = "Inlay Hints",
    key = "<leader>ih",
    difficulty = 2,
    summary = "See type annotations inline without cluttering your code",
    content = [[
## Inlay Hints - `<leader>ih`

**What it does:** Shows type information INLINE in your code.
Like having the type annotations visible without actually writing them.

**Toggle on/off:**
- `<leader>ih` - Toggle inlay hints for current buffer

**What you'll see:**
- Parameter names in function calls: `foo(name: "hello", age: 42)`
- Return types: `function getData()-> Promise<User>`
- Variable types: `const x: number = 5`

**Practice Challenge:**
1. Open a TypeScript or Python file
2. Press `<leader>ih` to enable hints
3. Look at function calls - you'll see parameter names!
4. Press `<leader>ih` again to disable

**When to use:**
- Understanding unfamiliar code
- Checking inferred types
- Debugging type mismatches

**When to disable:**
- When hints clutter the view
- On small screens
- When you know the code well

**Note:** Requires LSP support. Works great with TypeScript, Python (pyright), Rust, Go.
]],
    quiz = {
      question = "What key toggles inlay hints on/off?",
      answer = "<leader>ih",
      hints = { "i for inlay, h for hints", "It's a toggle, same key on/off" }
    },
    practice = {
      filetype = "typescript",
      filename = "practice_inlay_hints.ts",
      code = [[
// Practice: Inlay Hints
// Press <leader>ih to toggle hints ON, then see the magic!

interface User {
  id: number;
  name: string;
  email: string;
  isAdmin: boolean;
}

// With hints ON, you'll see parameter names appear:
function createUser(name: string, email: string, isAdmin: boolean): User {
  return {
    id: Math.random(),
    name,  // <- hint shows: name: string
    email, // <- hint shows: email: string
    isAdmin,
  };
}

// Look at this call - hints show what each argument means!
const alice = createUser("Alice", "alice@example.com", false);
//                       ^ name   ^ email              ^ isAdmin

// Without hints, you'd have to guess what 'false' means
// With hints, it's clear: isAdmin: false

// More examples - hints show inferred types
const numbers = [1, 2, 3, 4, 5];
const doubled = numbers.map(n => n * 2);
//    ^ hint: number[]        ^ hint: (n: number) => number

// Try these:
// 1. Press <leader>ih to enable hints
// 2. Look at the function call parameters
// 3. Look at the inferred types on variables
// 4. Press <leader>ih again to disable and compare
]]
    }
  },
  {
    id = "text_objects",
    title = "Treesitter Text Objects",
    key = "vaf, vif, vac, vic",
    difficulty = 3,
    summary = "Select functions, classes, arguments with smart motions",
    content = [[
## Treesitter Text Objects

**What it does:** Select code by MEANING, not just by brackets.
Like vim's `iw` (inner word) but for functions, classes, arguments.

**Selection text objects (use with v, d, c, y):**
- `af` / `if` - Around/inner function
- `ac` / `ic` - Around/inner class
- `aa` / `ia` - Around/inner argument/parameter
- `ai` / `ii` - Around/inner conditional (if statement)
- `al` / `il` - Around/inner loop

**Movement (jump between):**
- `]f` / `[f` - Next/previous function start
- `]c` / `[c` - Next/previous class start
- `]a` / `[a` - Next/previous argument

**Swap arguments:**
- `<leader>a` - Swap argument with next
- `<leader>A` - Swap argument with previous

**Practice Challenge:**
1. Put cursor inside a function body
2. Press `vif` to select inner function
3. Press `vaf` to select around function (includes signature)
4. Try `daf` to delete entire function!

**Power combos:**
- `daf` - Delete a function
- `yif` - Yank function body
- `caa` - Change an argument
- `]f]f]f` - Jump 3 functions forward
]],
    quiz = {
      question = "How do you select the INNER part of a function (body only)?",
      answer = "vif",
      hints = { "v for visual, i for inner, f for function", "Like viw but for functions" }
    },
    practice = {
      filetype = "python",
      filename = "practice_textobjects.py",
      code = [[
# Practice: Treesitter Text Objects
# These let you select/delete/yank by CODE STRUCTURE

class UserService:
    """Try: vac to select entire class, vic for just the body"""

    def __init__(self, database):
        # Try: vif to select this function body
        # Try: vaf to select entire function including 'def' line
        self.db = database
        self.cache = {}

    def get_user(self, user_id, include_metadata=False):
        # EXERCISE 1: Select function
        # Put cursor HERE and press:
        #   vif -> selects function body
        #   vaf -> selects entire function

        if user_id in self.cache:
            return self.cache[user_id]

        user = self.db.find(user_id)
        if include_metadata:
            user.metadata = self.db.get_metadata(user_id)

        self.cache[user_id] = user
        return user

    def delete_user(self, user_id, soft_delete=True, notify=False):
        # EXERCISE 2: Swap arguments
        # Put cursor on 'soft_delete' and press <leader>a
        # It swaps with 'notify'!
        # Press <leader>A to swap back

        if soft_delete:
            self.db.soft_delete(user_id)
        else:
            self.db.hard_delete(user_id)

        if notify:
            self.send_notification(user_id)


# EXERCISE 3: Navigate between functions
# Press ]f to jump to NEXT function
# Press [f to jump to PREVIOUS function

def helper_one():
    return 1

def helper_two():
    return 2

def helper_three():
    return 3

# EXERCISE 4: Delete a function
# Put cursor inside helper_two and press: daf
# The entire function disappears!
# Press 'u' to undo


# EXERCISE 5: Conditionals and loops
for item in [1, 2, 3]:
    # Try: vil to select inner loop
    # Try: val to select entire loop
    if item > 1:
        # Try: vii to select inner conditional
        # Try: vai to select entire if block
        print(item)
]]
    }
  },
  {
    id = "native_snippets",
    title = "Using Snippets",
    key = "Ctrl+y, Tab/Shift+Tab",
    difficulty = 2,
    summary = "Expand code templates with smart placeholders",
    content = [[
## Snippets - Code Templates

**What they do:** Type a short trigger, expand into full code.
Jump between placeholders to fill in the blanks.

**How to use:**
1. Type a snippet trigger (like `fn` or `if`)
2. Completion menu shows snippets (marked with icon)
3. Select and press `Ctrl+y` to expand
4. Press `Tab` to jump to next placeholder
5. Press `Shift+Tab` to jump back
6. Press `Ctrl+c` or `Esc` to exit snippet mode

**Navigation while in snippet:**
- `Tab` - Jump to next placeholder ($1 → $2 → $3...)
- `Shift+Tab` - Jump to previous placeholder
- Just type to replace placeholder text
- `$0` is the final cursor position

**Common snippet triggers:**
| Language   | Function      | Loop      | Condition |
|------------|---------------|-----------|-----------|
| JavaScript | `fn`, `af`    | `for`, `fore` | `if`, `ife` |
| Python     | `def`, `defs` | `for`, `forin` | `if`, `ife` |
| Lua        | `fn`, `func`  | `for`, `fori` | `if`, `ife` |
| TypeScript | `fn`, `af`    | `for`, `fore` | `if`, `ife` |

**Snippet sources:**
- LSP servers (language-specific)
- friendly-snippets (via blink.cmp)
- Custom snippets (see Custom Snippets lesson)

**Pro tips:**
- Watch for the snippet icon in completion menu
- Placeholders can have defaults - just Tab past them
- Some placeholders mirror (change one, others update)
]],
    quiz = {
      question = "After expanding a snippet, how do you jump to the next placeholder?",
      answer = "Tab",
      hints = { "Same key you might use to indent", "Very common key for 'next'" }
    },
    practice = {
      filetype = "javascript",
      filename = "practice_snippets.js",
      code = [[
// Practice: Using Snippets
// Type trigger words and expand them with Ctrl+y

// ═══════════════════════════════════════════════════════════
// EXERCISE 1: Function snippet
// ═══════════════════════════════════════════════════════════
// Type: fn
// Select from completion menu, press Ctrl+y to expand
// Tab through placeholders: name → params → body

// Type 'fn' on the next line:


// ═══════════════════════════════════════════════════════════
// EXERCISE 2: Arrow function snippet
// ═══════════════════════════════════════════════════════════
// Type: af (arrow function)
// Modern JS style function

// Type 'af' here:


// ═══════════════════════════════════════════════════════════
// EXERCISE 3: For loop snippet
// ═══════════════════════════════════════════════════════════
// Type: for or fore (for-each)
// Tab through: iterator, collection, body

const items = ["apple", "banana", "cherry"];

// Type 'fore' here to iterate:


// ═══════════════════════════════════════════════════════════
// EXERCISE 4: If-else snippet
// ═══════════════════════════════════════════════════════════
// Type: ife (if-else)
// Gives you both branches ready to fill

// Type 'ife' here:


// ═══════════════════════════════════════════════════════════
// EXERCISE 5: Try/catch snippet
// ═══════════════════════════════════════════════════════════
// Type: try or trycatch
// Error handling template

// Type 'try' here:


// ═══════════════════════════════════════════════════════════
// EXERCISE 6: Console.log snippet
// ═══════════════════════════════════════════════════════════
// Type: cl or log
// Quick debug output

// Type 'cl' here:


// ═══════════════════════════════════════════════════════════
// KEY INSIGHT: Watch the completion menu icons!
// ═══════════════════════════════════════════════════════════
// Snippets show a special icon (box/snippet symbol)
// This distinguishes them from regular completions
//
// After expanding:
//   Tab     = next placeholder
//   S-Tab   = previous placeholder
//   Esc     = exit snippet mode, keep what you typed
]]
    }
  },
  {
    id = "custom_snippets",
    title = "Custom Snippets",
    key = "vim.snippet.expand()",
    difficulty = 3,
    summary = "Create your own code templates with placeholders",
    content = [[
## Custom Snippets - Build Your Own Templates

**Why custom snippets?**
- Encode your patterns (logging, error handling, tests)
- Team conventions (file headers, function docs)
- Boilerplate you type repeatedly

**Snippet syntax (LSP/VSCode format):**
```
function ${1:name}(${2:params}) {
  ${3:// body}
  ${0}
}
```

- `${1}` - First placeholder (Tab stops here first)
- `${1:name}` - Placeholder with default text "name"
- `${2}` - Second placeholder
- `${0}` - Final cursor position (after all Tabs)
- `$1` - Same as ${1} (short form)

**Mirrored placeholders:**
```
for (let ${1:i} = 0; ${1} < ${2:arr}.length; ${1}++) {
  const item = ${2}[${1}];
  ${0}
}
```
Using `${1}` multiple times mirrors the text!

**Choice placeholders:**
```
console.${1|log,warn,error|}(${2:message});
```
Shows dropdown: log, warn, or error

**Adding snippets in Neovim:**
Create `~/.config/nvim/snippets/<filetype>.json`:
```json
{
  "Function": {
    "prefix": "fn",
    "body": [
      "function ${1:name}(${2:params}) {",
      "  ${0}",
      "}"
    ],
    "description": "Function declaration"
  }
}
```

**Using vim.snippet directly:**
```lua
vim.snippet.expand("Hello ${1:world}! $0")
```

**Pro tips:**
- Start with snippets for code you repeat often
- Use meaningful defaults in placeholders
- Mirror variables that appear multiple times
]],
    quiz = {
      question = "In snippet syntax, what does ${0} represent?",
      answer = "Final cursor position",
      hints = { "It's where you end up after all Tabs", "Zero is the last stop" }
    },
    practice = {
      filetype = "lua",
      filename = "practice_custom_snippets.lua",
      code = [[
-- Practice: Custom Snippets
-- Learn the snippet syntax by examining these examples

-- ═══════════════════════════════════════════════════════════
-- SNIPPET SYNTAX REFERENCE
-- ═══════════════════════════════════════════════════════════
--
-- ${1}         = First tab stop
-- ${1:default} = Tab stop with default text
-- ${2}         = Second tab stop (Tab jumps here after ${1})
-- ${0}         = Final cursor position
-- ${1} ${1}    = Mirrored - type once, appears twice

-- ═══════════════════════════════════════════════════════════
-- EXERCISE 1: Try vim.snippet.expand()
-- ═══════════════════════════════════════════════════════════
-- In command mode, run:
-- :lua vim.snippet.expand("local ${1:var} = ${2:value}$0")
--
-- Then Tab through the placeholders!

-- ═══════════════════════════════════════════════════════════
-- EXERCISE 2: Mirrored placeholders
-- ═══════════════════════════════════════════════════════════
-- Run this - notice how typing in ${1} updates both places:
-- :lua vim.snippet.expand("for ${1:i} = 1, ${2:10} do\\n  print(${1})\\nend$0")

-- ═══════════════════════════════════════════════════════════
-- EXERCISE 3: Creating a snippet file
-- ═══════════════════════════════════════════════════════════
-- Create: ~/.config/nvim/snippets/lua.json
--
-- {
--   "Module": {
--     "prefix": "mod",
--     "body": [
--       "local M = {}",
--       "",
--       "function M.${1:setup}(${2:opts})",
--       "  ${0}",
--       "end",
--       "",
--       "return M"
--     ],
--     "description": "Lua module template"
--   }
-- }

-- ═══════════════════════════════════════════════════════════
-- COMMON SNIPPET PATTERNS
-- ═══════════════════════════════════════════════════════════

-- Pattern: Function with docstring
-- "body": [
--   "--- ${1:Description}",
--   "-- @param ${2:param} ${3:type} ${4:description}",
--   "-- @return ${5:type}",
--   "function ${6:name}(${2})",
--   "  ${0}",
--   "end"
-- ]

-- Pattern: Error handling
-- "body": [
--   "local ok, ${1:result} = pcall(function()",
--   "  ${2:-- code that might fail}",
--   "end)",
--   "if not ok then",
--   "  ${3:-- handle error}",
--   "end",
--   "${0}"
-- ]

-- Pattern: Test case
-- "body": [
--   "describe('${1:feature}', function()",
--   "  it('${2:should do something}', function()",
--   "    ${0}",
--   "  end)",
--   "end)"
-- ]

-- ═══════════════════════════════════════════════════════════
-- TIP: Start with what you repeat!
-- ═══════════════════════════════════════════════════════════
-- Notice patterns in your code? Make them snippets!
-- - Logging statements with context
-- - API response handling
-- - Component boilerplate
-- - Test setup/teardown
]]
    }
  },
  {
    id = "snippet_jumping",
    title = "Snippet Navigation",
    key = "Tab, Shift+Tab, Ctrl+c",
    difficulty = 1,
    summary = "Master jumping between snippet placeholders",
    content = [[
## Snippet Navigation - Tab Like a Pro

**The snippet workflow:**
1. Type trigger → Completion shows snippet
2. `Ctrl+y` → Expands snippet, cursor at ${1}
3. Type replacement text
4. `Tab` → Jump to ${2}
5. Repeat until ${0} (final position)

**Navigation keys:**
| Key        | Action                          |
|------------|--------------------------------|
| `Tab`      | Jump to next placeholder        |
| `Shift+Tab`| Jump to previous placeholder    |
| `Ctrl+c`   | Exit snippet mode early         |
| `Esc`      | Also exits snippet mode         |

**Active snippet indicators:**
- Placeholders are highlighted
- Status line may show "snippet active"
- Tab behaves differently (jumps, not indents)

**Placeholder behaviors:**
- **Select mode:** Placeholder text is selected
- **Typing replaces:** Just start typing
- **Keep default:** Press Tab without typing

**Nested snippets:**
You CAN expand a snippet inside another snippet!
The inner snippet's tab stops are handled first.

**Common mistakes:**
- Pressing Tab before expanding (just indents)
- Forgetting you're in a snippet (Tab jumps weirdly)
- Not noticing mirrored placeholders

**Mental model:**
Think of it like filling out a form:
- Tab moves to next field
- Shift+Tab goes back
- Submit (Esc) when done

**Pro tip:** If Tab isn't jumping, you're not in
an active snippet. The snippet may have been
canceled or you reached ${0}.
]],
    quiz = {
      question = "How do you go BACK to a previous placeholder in a snippet?",
      answer = "Shift+Tab",
      hints = { "It's the opposite of Tab", "Shift reverses the direction" }
    },
    practice = {
      filetype = "python",
      filename = "practice_snippet_nav.py",
      code = [[
# Practice: Snippet Navigation
# Focus on smooth Tab/Shift+Tab movement

# ═══════════════════════════════════════════════════════════
# EXERCISE 1: Basic Tab jumping
# ═══════════════════════════════════════════════════════════
# Type: def
# Expand with Ctrl+y
# Tab through: name → params → body → ${0}

# Type 'def' here:


# ═══════════════════════════════════════════════════════════
# EXERCISE 2: Go back with Shift+Tab
# ═══════════════════════════════════════════════════════════
# Type: def
# Expand, Tab to params, then Shift+Tab back to name
# Edit the name, then Tab forward again

# Type 'def' here and practice going back:


# ═══════════════════════════════════════════════════════════
# EXERCISE 3: Keep defaults
# ═══════════════════════════════════════════════════════════
# Type: for
# Expand, but just press Tab to keep some defaults
# Only change the parts you need

items = [1, 2, 3, 4, 5]

# Type 'for' and Tab past the iterator name:


# ═══════════════════════════════════════════════════════════
# EXERCISE 4: Exit early with Ctrl+c
# ═══════════════════════════════════════════════════════════
# Type: class
# Expand, fill in class name
# Press Ctrl+c to exit before filling everything

# Type 'class' and exit early:


# ═══════════════════════════════════════════════════════════
# EXERCISE 5: Mirrored placeholders
# ═══════════════════════════════════════════════════════════
# Some snippets mirror text - typing once updates multiple places
# Try a for loop snippet and watch the iterator variable

# Type 'for' and notice mirrored variables:


# ═══════════════════════════════════════════════════════════
# RHYTHM: Expand → Type → Tab → Type → Tab → Done
# ═══════════════════════════════════════════════════════════
# Practice until Tab jumping feels automatic!
# The goal: never think about it, just flow
]]
    }
  },
  {
    id = "blink_cmp",
    title = "Blink.cmp Completion",
    key = "Ctrl+n/p, Ctrl+y, Ctrl+e",
    difficulty = 2,
    summary = "Lightning-fast autocompletion with fuzzy matching",
    content = [[
## Blink.cmp - Fast Completion

**What it does:** Shows completion suggestions as you type.
Blink.cmp is a newer, faster alternative to nvim-cmp.

**Key bindings:**
- Start typing - completions appear automatically
- `Ctrl+n` - Next item in menu
- `Ctrl+p` - Previous item in menu
- `Ctrl+y` - Accept selected completion
- `Ctrl+e` - Close menu without accepting
- `Tab` - Accept OR jump to next snippet placeholder

**Completion sources (what it suggests):**
- LSP - Smart completions from language server
- Buffer - Words from current file
- Path - File paths when typing paths
- Snippets - Code templates

**Practice Challenge:**
1. Open a Python or JS file
2. Start typing a variable or function name
3. Watch the menu appear
4. Use Ctrl+n/p to navigate
5. Ctrl+y to accept

**Tips:**
- Fuzzy matching: type `gtu` to match `getUserData`
- Keep typing to filter results
- LSP completions show type info
- Documentation appears in a floating window
]],
    quiz = {
      question = "What key ACCEPTS a completion from the menu?",
      answer = "Ctrl+y",
      hints = { "y for 'yes' or 'yank'", "Not Enter - that inserts a newline" }
    },
    practice = {
      filetype = "python",
      filename = "practice_completion.py",
      code = [[
# Practice: Blink.cmp Completion
# Type partial names and use Ctrl+n/p to navigate, Ctrl+y to accept

import os
import sys
import json

class UserManager:
    def __init__(self):
        self.users = {}
        self.admin_count = 0
        self.guest_count = 0

    def add_user(self, username, email, is_admin=False):
        self.users[username] = {"email": email, "is_admin": is_admin}
        if is_admin:
            self.admin_count += 1

    def get_user(self, username):
        return self.users.get(username)

    def delete_user(self, username):
        if username in self.users:
            del self.users[username]

# ═══════════════════════════════════════════════════════════
# EXERCISE 1: Complete variable names
# ═══════════════════════════════════════════════════════════
manager = UserManager()

# Type 'man' and see 'manager' suggested, Ctrl+y to accept
# Type: man


# ═══════════════════════════════════════════════════════════
# EXERCISE 2: Complete method names
# ═══════════════════════════════════════════════════════════
# After typing 'manager.', methods are suggested
# Type: manager.add  (then Ctrl+y to complete 'add_user')


# ═══════════════════════════════════════════════════════════
# EXERCISE 3: Fuzzy matching
# ═══════════════════════════════════════════════════════════
# Type 'gtu' - it matches 'get_user' even though letters aren't adjacent!
# Type: manager.gtu


# ═══════════════════════════════════════════════════════════
# EXERCISE 4: Path completion
# ═══════════════════════════════════════════════════════════
# When typing a string that looks like a path, file paths are suggested
# Type: path = "/Users/


# ═══════════════════════════════════════════════════════════
# EXERCISE 5: Import completion
# ═══════════════════════════════════════════════════════════
# LSP knows what modules are available
# Type: from collections import


# TIP: Look at the completion menu icons
# Different icons indicate: LSP, buffer word, snippet, path
]]
    }
  },
  {
    id = "lsp_rename",
    title = "LSP Rename",
    key = "<leader>ra",
    difficulty = 2,
    summary = "Rename a symbol across your entire project safely",
    content = [[
## LSP Rename - `<leader>ra`

**What it does:** Renames a variable/function/class EVERYWHERE it's used.
Not just find-replace - it understands code structure!

**How to use:**
1. Put cursor on the symbol to rename
2. Press `<leader>ra`
3. Type the new name
4. Press Enter

**Why it's better than search/replace:**
- Only renames the ACTUAL symbol, not text matches
- Works across files
- Won't rename `user` inside `username`
- Updates imports automatically
- Handles shadowed variables correctly

**Practice Challenge:**
1. Open a file with a function used in multiple places
2. Put cursor on the function name
3. Press `<leader>ra`
4. Rename it to something else
5. Check all usages - they all changed!

**When to use:**
- Renaming functions, variables, classes
- Refactoring code structure
- Making names more descriptive

**Note:** This uses NvChad's "NvRenamer" which gives a nice UI.
Requires LSP support for the language.
]],
    quiz = {
      question = "What key combination triggers LSP rename?",
      answer = "<leader>ra",
      hints = { "r for rename, a for action", "Leader followed by two letters" }
    },
    practice = {
      filetype = "typescript",
      filename = "practice_rename.ts",
      code = [[
// Practice: LSP Rename
// Put cursor on a symbol and press <leader>ra to rename it EVERYWHERE

// ═══════════════════════════════════════════════════════════
// EXERCISE 1: Rename a function
// ═══════════════════════════════════════════════════════════
// Put cursor on 'calculateTotal' and press <leader>ra
// Rename it to 'computeSum' - watch ALL usages change!

function calculateTotal(items: number[]): number {
  return items.reduce((sum, item) => sum + item, 0);
}

const prices = [10, 20, 30];
const total = calculateTotal(prices);  // <- This changes too!
console.log("Total:", calculateTotal([1, 2, 3]));  // <- And this!

// ═══════════════════════════════════════════════════════════
// EXERCISE 2: Rename a variable
// ═══════════════════════════════════════════════════════════
// Rename 'usr' to 'currentUser'

interface User {
  id: number;
  name: string;
}

const usr: User = { id: 1, name: "Alice" };
console.log(usr.name);
console.log(usr.id);

function greet(usr: User) {  // <- Different 'usr', LSP knows!
  return `Hello, ${usr.name}`;
}

// ═══════════════════════════════════════════════════════════
// EXERCISE 3: Rename an interface
// ═══════════════════════════════════════════════════════════
// Rename 'Config' to 'AppSettings'

interface Config {
  theme: string;
  language: string;
}

function loadConfig(): Config {
  return { theme: "dark", language: "en" };
}

const appConfig: Config = loadConfig();

// ═══════════════════════════════════════════════════════════
// WHY LSP RENAME IS BETTER:
// ═══════════════════════════════════════════════════════════
//
// Consider this: if you search/replace "user" with "person":
//   username -> personname  (WRONG!)
//   userAgent -> personAgent  (WRONG!)
//   getUser -> getPerson  (might want this?)
//
// LSP rename ONLY changes the actual symbol references,
// not random text matches. It's SAFE.
]]
    }
  },
  {
    id = "go_to_definition",
    title = "Go to Definition",
    key = "gd, gD",
    difficulty = 1,
    summary = "Jump to where a function or variable is defined",
    content = [[
## Go to Definition - `gd`

**What it does:** Jump to where a symbol is DEFINED.
Click on a function call, jump to the function body.

**Key bindings:**
- `gd` - Go to definition (most common)
- `gD` - Go to declaration
- `gi` - Go to implementation
- `gr` - Go to references (all places it's used)
- `K` - Show hover documentation

**How to use:**
1. Put cursor on any function/variable/class name
2. Press `gd`
3. You jump to its definition!
4. Press `Ctrl+o` to jump back

**Practice Challenge:**
1. Find a function CALL in your code
2. Put cursor on it
3. Press `gd` to jump to definition
4. Press `Ctrl+o` to jump back
5. Try `gr` to see all references

**Tips:**
- Works across files
- `Ctrl+o` = jump back, `Ctrl+i` = jump forward
- `K` (capital) shows docs in a floating window
- `gr` is great for "who calls this?"
]],
    quiz = {
      question = "What key jumps to where a function is defined?",
      answer = "gd",
      hints = { "g for 'go', d for 'definition'", "Two letters, no leader" }
    },
    practice = {
      filetype = "python",
      filename = "practice_goto.py",
      code = [[
# Practice: Go to Definition
# Put cursor on function CALLS and press gd to jump to their definition

# ═══════════════════════════════════════════════════════════
# DEFINITIONS (jump targets)
# ═══════════════════════════════════════════════════════════

def validate_email(email: str) -> bool:
    """Check if email is valid."""
    return "@" in email and "." in email

def format_name(first: str, last: str) -> str:
    """Format a full name."""
    return f"{first} {last}"

class UserService:
    def __init__(self, db_connection):
        self.db = db_connection

    def create_user(self, name: str, email: str):
        if not validate_email(email):
            raise ValueError("Invalid email")
        return {"name": name, "email": email}

    def get_user(self, user_id: int):
        return self.db.find(user_id)

# ═══════════════════════════════════════════════════════════
# EXERCISE 1: Jump to function definition
# ═══════════════════════════════════════════════════════════
# Put cursor on 'validate_email' below and press gd

email = "test@example.com"
is_valid = validate_email(email)  # <- gd here jumps to definition above

# ═══════════════════════════════════════════════════════════
# EXERCISE 2: Jump to class method
# ═══════════════════════════════════════════════════════════
# Put cursor on 'create_user' and press gd

service = UserService(None)
new_user = service.create_user("John", "john@example.com")  # <- gd here

# ═══════════════════════════════════════════════════════════
# EXERCISE 3: Jump back!
# ═══════════════════════════════════════════════════════════
# After jumping with gd, press Ctrl+o to jump BACK
# Press Ctrl+i to jump forward again

# ═══════════════════════════════════════════════════════════
# EXERCISE 4: Find all references
# ═══════════════════════════════════════════════════════════
# Put cursor on 'validate_email' and press gr
# You'll see ALL places it's used!

def process_signup(user_email):
    if validate_email(user_email):  # <- reference 1
        print("Email OK")
    else:
        print("Bad email")

def bulk_validate(emails):
    return [validate_email(e) for e in emails]  # <- reference 2

# ═══════════════════════════════════════════════════════════
# EXERCISE 5: Hover documentation
# ═══════════════════════════════════════════════════════════
# Put cursor on any function and press K (capital)
# A floating window shows the docstring!

formatted = format_name("John", "Doe")  # <- K here shows docstring
]]
    }
  },
  -- ══════════════════════════════════════════════════════════════════
  -- STORY EXPLORER LESSONS
  -- ══════════════════════════════════════════════════════════════════
  {
    id = "story_explorer_intro",
    title = "Story Explorer - Introduction",
    key = "<leader>\\",
    difficulty = 2,
    summary = "See WHY code exists, not just what it does",
    content = [[
## Story Explorer - `<leader>\`

**Philosophy:** Instead of asking "what does this code do?",
ask "WHY does this code exist?"

Story Explorer creates a sidebar showing architectural context:
- **Current Focus** - The function/class you're in
- **Parent Scope** - The containing class/module
- **Siblings** - Related functions in same scope
- **Callers** - Who uses this code
- **Calls** - What this code depends on

**Opening Story Explorer:**
- `<leader>\` - Toggle the sidebar

**The sidebar shows structure like:**
```
╭─ Story Explorer ─────────────────╮
│ File: user_service.py            │
│                                  │
│ class UserService                │
│   get_user()    <- YOU ARE HERE  │
│   create_user()                  │
│   delete_user()                  │
│                                  │
│ Called by:                       │
│   api.py:45 handle_request       │
│                                  │
│ Calls:                           │
│   database.find()                │
│   cache.get()                    │
╰──────────────────────────────────╯
```

**The goal:** Navigate by STORY, not by grep.
]],
    quiz = {
      question = "What key opens the Story Explorer sidebar?",
      answer = "<leader>\\",
      hints = { "Leader followed by backslash", "Think 'escape' from confusion" }
    },
    practice = {
      filetype = "python",
      filename = "practice_story_intro.py",
      code = [[
# Practice: Story Explorer Introduction
# Open the sidebar with <leader>\ and explore this structure

# ═══════════════════════════════════════════════════════════
# EXERCISE 1: Open Story Explorer
# ═══════════════════════════════════════════════════════════
# 1. Put cursor anywhere in this file
# 2. Press <leader>\ to open the sidebar
# 3. Look at the structure - classes, methods, relationships!

class PaymentProcessor:
    """Handles all payment operations."""

    def __init__(self, gateway, logger):
        self.gateway = gateway
        self.logger = logger
        self.transaction_count = 0

    def process_payment(self, amount, card):
        """Process a credit card payment."""
        # Story Explorer shows: this is a METHOD of PaymentProcessor
        # Siblings: validate_card, refund_payment
        self.logger.info(f"Processing ${amount}")

        if not self.validate_card(card):
            return {"success": False, "error": "Invalid card"}

        result = self.gateway.charge(amount, card)
        self.transaction_count += 1
        return result

    def validate_card(self, card):
        """Validate card number and expiry."""
        # SIBLING of process_payment
        # Called by: process_payment
        return card.is_valid() and not card.is_expired()

    def refund_payment(self, transaction_id, amount):
        """Refund a previous transaction."""
        # SIBLING of process_payment and validate_card
        self.logger.info(f"Refunding ${amount}")
        return self.gateway.refund(transaction_id, amount)


# ═══════════════════════════════════════════════════════════
# EXERCISE 2: Notice what the sidebar shows
# ═══════════════════════════════════════════════════════════
# With sidebar open, move cursor to different methods:
# - The sidebar updates to show current context
# - Notice "Siblings" section shows related methods
# - Notice "Calls" shows what each method depends on
]]
    }
  },
  {
    id = "story_explorer_navigation",
    title = "Story Explorer - Sidebar Navigation",
    key = "j/k, Enter, q",
    difficulty = 2,
    summary = "Navigate through code structure with keyboard",
    content = [[
## Story Explorer Navigation

**In the sidebar, use these keys:**

**Basic movement:**
- `j` or `Down` - Move down in structure
- `k` or `Up` - Move up in structure
- `Enter` - Jump to that location in code
- `q` or `Esc` - Close the sidebar

**Context navigation:**
- `Right` arrow - Expand/drill into item
- `Left` arrow - Collapse/go back up

**The workflow:**
1. `<leader>\` - Open sidebar
2. `j/k` - Find the function you want
3. `Enter` - Jump to it
4. Sidebar updates to show NEW context
5. Keep exploring!

**What you can navigate to:**
- Classes and their methods
- Functions (standalone or nested)
- Call sites ("who calls this?")
- Dependencies ("what does this call?")

**Pro tip:** The sidebar auto-updates as you move
your cursor in the main editor (after ~500ms).
Keep it open while exploring unfamiliar code!
]],
    quiz = {
      question = "How do you jump to a function shown in Story Explorer?",
      answer = "Enter",
      hints = { "The standard 'select' key", "Same as activating anything" }
    },
    practice = {
      filetype = "javascript",
      filename = "practice_story_nav.js",
      code = [[
// Practice: Story Explorer Navigation
// Open sidebar with <leader>\, then navigate with j/k and Enter

// ═══════════════════════════════════════════════════════════
// EXERCISE 1: Basic navigation
// ═══════════════════════════════════════════════════════════
// 1. Press <leader>\ to open Story Explorer
// 2. Press j to move DOWN through the structure
// 3. Press k to move UP
// 4. Find "UserManager" and press Enter to jump there!

class UserManager {
  constructor(database) {
    this.db = database;
    this.cache = new Map();
  }

  async getUser(userId) {
    // TRY: Navigate here from sidebar, then look at:
    // - Siblings: createUser, deleteUser, clearCache
    // - Calls: this.cache.has, this.db.findById, etc.
    if (this.cache.has(userId)) {
      return this.cache.get(userId);
    }
    const user = await this.db.findById(userId);
    this.cache.set(userId, user);
    return user;
  }

  async createUser(userData) {
    const user = await this.db.create(userData);
    this.cache.set(user.id, user);
    return user;
  }

  async deleteUser(userId) {
    await this.db.delete(userId);
    this.cache.delete(userId);
  }

  clearCache() {
    this.cache.clear();
  }
}

// ═══════════════════════════════════════════════════════════
// EXERCISE 2: Follow relationships
// ═══════════════════════════════════════════════════════════
// Navigate to a "Called by:" entry and press Enter
// You jump to the CALLER of that function!

class OrderService {
  constructor(userManager) {
    this.userManager = userManager;
  }

  async processOrder(userId, items) {
    // This CALLS userManager.getUser()
    // Story Explorer shows this relationship!
    const user = await this.userManager.getUser(userId);
    if (!user.isActive) {
      throw new Error("User not active");
    }
    return this.createOrder(user, items);
  }

  createOrder(user, items) {
    return { userId: user.id, items, total: this.calculateTotal(items) };
  }

  calculateTotal(items) {
    return items.reduce((sum, item) => sum + item.price, 0);
  }
}

// ═══════════════════════════════════════════════════════════
// EXERCISE 3: Expand/collapse with arrows
// ═══════════════════════════════════════════════════════════
// Use Right arrow to expand details of an item
// Use Left arrow to collapse and go back up
]]
    }
  },
  {
    id = "story_explorer_callers",
    title = "Story Explorer - Finding Callers",
    key = "F (in sidebar)",
    difficulty = 3,
    summary = "Discover who uses your code and why",
    content = [[
## Finding Callers - "Who Uses This?"

**Why callers matter:**
When you understand WHO calls your function, you understand:
- Why the function exists
- What contracts it must maintain
- What will break if you change it

**Story Explorer shows callers automatically:**
The sidebar displays "Called by:" for each function.

**The F key (Find Usages):**
In the sidebar, press `F` on any item to:
- Find ALL usages across your codebase
- Results appear in quickfix list
- Navigate with `<leader>lj` / `<leader>lk`

**Interpreting the call graph:**
```
Called by:
  api.py:45 handle_request
  cli.py:12 main
  tests/test_user.py:23
```

This tells you:
- 3 places call this function
- Used in API, CLI, and tests
- Changing it affects all three!

**Power insight:**
- NO callers = maybe dead code?
- MANY callers = change carefully!
- Test callers = good coverage!
]],
    quiz = {
      question = "What key finds all usages in Story Explorer?",
      answer = "F",
      hints = { "F for Find", "Capital letter" }
    },
    practice = {
      filetype = "python",
      filename = "practice_story_callers.py",
      code = [[
# Practice: Finding Callers
# Understand WHO depends on your code

# ═══════════════════════════════════════════════════════════
# EXERCISE 1: See callers in sidebar
# ═══════════════════════════════════════════════════════════
# 1. Open Story Explorer with <leader>\
# 2. Navigate to validate_email function
# 3. Look at "Called by:" section
# 4. Press F to find ALL usages!

def validate_email(email: str) -> bool:
    """Validate email format."""
    # WHO CALLS THIS? Story Explorer shows you!
    # Press F while on this in sidebar to find all usages
    return "@" in email and "." in email.split("@")[-1]


def validate_phone(phone: str) -> bool:
    """Validate phone number."""
    return phone.isdigit() and len(phone) >= 10


# ═══════════════════════════════════════════════════════════
# CALLERS - These functions USE the validators
# ═══════════════════════════════════════════════════════════

def register_user(name: str, email: str, phone: str) -> dict:
    """Register a new user."""
    # CALLS: validate_email, validate_phone
    if not validate_email(email):
        raise ValueError("Invalid email")
    if not validate_phone(phone):
        raise ValueError("Invalid phone")
    return {"name": name, "email": email, "phone": phone}


def update_contact_info(user_id: int, email: str = None, phone: str = None):
    """Update user's contact information."""
    # ALSO CALLS: validate_email, validate_phone
    if email and not validate_email(email):
        raise ValueError("Invalid email")
    if phone and not validate_phone(phone):
        raise ValueError("Invalid phone")


def bulk_validate_emails(emails: list) -> list:
    """Validate multiple emails at once."""
    # CALLS: validate_email (in a loop!)
    return [e for e in emails if validate_email(e)]


# ═══════════════════════════════════════════════════════════
# EXERCISE 2: Understand impact
# ═══════════════════════════════════════════════════════════
# validate_email has 3 callers:
#   - Changing its signature breaks 3 places
#   - Changing its behavior affects 3 features
#   - It's a CRITICAL function!
#
# validate_phone has 2 callers:
#   - Slightly less critical
#
# This is "impact analysis" made visual!
]]
    }
  },
  {
    id = "story_explorer_agents",
    title = "Story Explorer - Agent Actions",
    key = "R, D, J, T, E, F",
    difficulty = 3,
    summary = "Automated refactoring from the sidebar",
    content = [[
## Agent Actions - Automated Refactoring

Story Explorer includes "software agent" actions.
Press capital letters in sidebar for automated tasks.

**Agent keys (in sidebar):**

| Key | Action | Description |
|-----|--------|-------------|
| `R` | Rename | Rename the method/function |
| `D` | Debug | Add debug logging |
| `J` | JSDoc | Generate documentation |
| `F` | Find | Find all usages (quickfix) |
| `T` | Test | Generate test skeleton |
| `E` | Extract | Extract to a class |

**How to use:**
1. Open Story Explorer (`<leader>\`)
2. Navigate to a function with j/k
3. Press agent key (e.g., `J` for JSDoc)
4. Agent performs the action!

**Example: Press J to generate JSDoc:**
```javascript
// BEFORE:
function calculateTax(amount, rate) {
  return amount * rate;
}

// AFTER (agent adds):
/**
 * Calculates tax amount
 * @param {number} amount
 * @param {number} rate
 * @returns {number}
 */
function calculateTax(amount, rate) {
  return amount * rate;
}
```
]],
    quiz = {
      question = "What agent key generates documentation?",
      answer = "J",
      hints = { "J for JSDoc", "Capital letter" }
    },
    practice = {
      filetype = "javascript",
      filename = "practice_story_agents.js",
      code = [[
// Practice: Story Explorer Agent Actions
// Use capital letters for automated actions

// ═══════════════════════════════════════════════════════════
// EXERCISE 1: Generate JSDoc (J)
// ═══════════════════════════════════════════════════════════
// 1. Open Story Explorer with <leader>\
// 2. Navigate to calculateDiscount
// 3. Press J (capital) to generate JSDoc

function calculateDiscount(originalPrice, discountPercent) {
  const discount = originalPrice * (discountPercent / 100);
  return originalPrice - discount;
}

// ═══════════════════════════════════════════════════════════
// EXERCISE 2: Add Debug Logging (D)
// ═══════════════════════════════════════════════════════════
// Navigate to processOrder, press D

function processOrder(order) {
  const total = order.items.reduce((sum, item) => sum + item.price, 0);
  const tax = total * 0.13;
  return { total, tax, grandTotal: total + tax };
}

// ═══════════════════════════════════════════════════════════
// EXERCISE 3: Find Usages (F)
// ═══════════════════════════════════════════════════════════
// Navigate to validateInput, press F

function validateInput(input) {
  return input && input.trim().length > 0;
}

function submitForm(data) {
  if (!validateInput(data.name)) throw new Error("Name required");
  if (!validateInput(data.email)) throw new Error("Email required");
  return save(data);
}

function processComment(text) {
  if (!validateInput(text)) return null;
  return { text: text.trim(), timestamp: Date.now() };
}

// ═══════════════════════════════════════════════════════════
// EXERCISE 4: Generate Test (T)
// ═══════════════════════════════════════════════════════════
// Navigate to formatCurrency, press T

function formatCurrency(amount, currency = "USD") {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: currency,
  }).format(amount);
}

// AGENT REFERENCE:
// R = Rename    D = Debug    J = JSDoc
// F = Find      T = Test     E = Extract
]]
    }
  },
  {
    id = "story_explorer_live",
    title = "Story Explorer - Live Updates",
    key = "Automatic",
    difficulty = 2,
    summary = "Watch the sidebar follow your cursor",
    content = [[
## Live Updates - The Sidebar Follows You

**The magic:** Story Explorer updates AUTOMATICALLY
as you move your cursor through code!

**How it works:**
1. Open sidebar once with `<leader>\`
2. Move cursor in main code window
3. After ~500ms, sidebar refreshes to show:
   - Current function you're in
   - Its siblings, callers, dependencies
   - Parent class/module

**What triggers updates:**
- `CursorMoved` - Moving within a file
- `BufEnter` - Switching buffers

**The debounce:**
Updates throttled to 500ms to avoid flicker.

**Workflow for exploring unfamiliar code:**
1. Open sidebar
2. Navigate code (gd, gr, /, etc.)
3. Sidebar keeps you oriented
4. Never lose context!

**Pro tip:** Keep Story Explorer open during:
- Code review
- Debugging sessions
- Learning new codebases
- Refactoring planning
]],
    quiz = {
      question = "How often does Story Explorer update?",
      answer = "Every 500ms after cursor stops",
      hints = { "It's debounced", "Half second" }
    },
    practice = {
      filetype = "python",
      filename = "practice_story_live.py",
      code = [[
# Practice: Story Explorer Live Updates
# Keep sidebar open and move around!

# ═══════════════════════════════════════════════════════════
# EXERCISE: Navigate and watch sidebar update
# ═══════════════════════════════════════════════════════════
# 1. Press <leader>\ to open sidebar
# 2. Move cursor to different functions below
# 3. Wait ~500ms - sidebar refreshes!
# 4. Current function is highlighted

class ShoppingCart:
    def __init__(self):
        self.items = []
        self.discount_code = None

    # MOVE HERE - sidebar shows add_item context
    def add_item(self, product, quantity=1):
        existing = self.find_item(product.id)
        if existing:
            existing["quantity"] += quantity
        else:
            self.items.append({"product": product, "quantity": quantity})

    # NOW HERE - sidebar updates to show remove_item
    def remove_item(self, product_id):
        item = self.find_item(product_id)
        if item:
            self.items.remove(item)

    # AND HERE - see find_item context
    def find_item(self, product_id):
        for item in self.items:
            if item["product"].id == product_id:
                return item
        return None

    # MOVE HERE - see calculate_total and its calls
    def calculate_total(self):
        subtotal = sum(
            item["product"].price * item["quantity"]
            for item in self.items
        )
        return self.apply_discount(subtotal)

    def apply_discount(self, amount):
        if self.discount_code:
            return amount * (1 - self.discount_code.percentage / 100)
        return amount


# ═══════════════════════════════════════════════════════════
# BONUS: Use gd and watch sidebar follow
# ═══════════════════════════════════════════════════════════
# 1. Put cursor on "self.find_item" in add_item
# 2. Press gd to go to definition
# 3. Watch sidebar update to find_item context!
# 4. Press Ctrl+o to go back - sidebar updates again!
]]
    }
  },
  {
    id = "story_explorer_workflow",
    title = "Story Explorer - Complete Workflow",
    key = "All together",
    difficulty = 2,
    summary = "Put it all together for code understanding",
    content = [[
## The Story Explorer Workflow

**When to use Story Explorer:**
- Exploring unfamiliar code
- Understanding before refactoring
- Reviewing PRs
- Debugging "where is this called?"

**Complete workflow:**

**Step 1: Open and Orient**
```
<leader>\  -> Open sidebar
Look at: What classes? What functions?
         What's the structure?
```

**Step 2: Navigate to Interest**
```
j/k        -> Move through structure
Enter      -> Jump to that code
Right/Left -> Expand/collapse
```

**Step 3: Understand Context**
```
Called by: -> Who uses this?
Calls:     -> What does this need?
Siblings:  -> What's related?
```

**Step 4: Take Action**
```
F -> Find all usages
J -> Add documentation
T -> Generate test
R -> Rename safely
```

**Step 5: Continue Exploring**
```
gd      -> Go to definition
gr      -> Go to references
Ctrl+o  -> Jump back
Sidebar follows you!
```

**Philosophy:**
Stop grep-ing for strings.
Follow the STORY of the code.
Every function exists for a reason.
Story Explorer helps you find it.
]],
    quiz = {
      question = "First step to explore unfamiliar code?",
      answer = "Open sidebar with <leader>\\ and look at structure",
      hints = { "Get oriented first", "See the big picture" }
    },
    practice = {
      filetype = "javascript",
      filename = "practice_story_workflow.js",
      code = [[
// Practice: Complete Story Explorer Workflow
// SCENARIO: Debug why notifications aren't sent
// Use Story Explorer to understand the flow

// ═══════════════════════════════════════════════════════════
// STEP 1: Open sidebar and scan structure
// What classes exist? What's the hierarchy?
// ═══════════════════════════════════════════════════════════

class NotificationService {
  constructor(emailClient, smsClient, pushClient) {
    this.email = emailClient;
    this.sms = smsClient;
    this.push = pushClient;
  }

  // STEP 2: Navigate here - this looks important!
  async sendNotification(user, message, channels = ["email"]) {
    const results = [];
    for (const channel of channels) {
      const result = await this.sendViaChannel(channel, user, message);
      results.push(result);
    }
    return results;
  }

  // STEP 3: Look at "Called by:" - who triggers this?
  async sendViaChannel(channel, user, message) {
    switch (channel) {
      case "email": return this.sendEmail(user.email, message);
      case "sms": return this.sendSMS(user.phone, message);
      case "push": return this.sendPush(user.deviceToken, message);
      default: throw new Error(`Unknown channel: ${channel}`);
    }
  }

  async sendEmail(to, message) {
    // STEP 4: Press F - who calls sendEmail?
    return this.email.send({ to, subject: message.title, body: message.content });
  }

  async sendSMS(to, message) {
    return this.sms.send({ to, text: message.content });
  }

  async sendPush(token, message) {
    return this.push.send({ token, title: message.title, body: message.content });
  }

  // STEP 5: Does anyone call this? Maybe dead code?
  formatMessage(template, data) {
    return template.replace(/\{(\w+)\}/g, (_, key) => data[key] || _);
  }
}

// ═══════════════════════════════════════════════════════════
// THE CALLER - This triggers notifications
// ═══════════════════════════════════════════════════════════

class OrderProcessor {
  constructor(notificationService) {
    this.notifications = notificationService;
  }

  // STEP 6: Navigate here - see it calls sendNotification
  async completeOrder(order, user) {
    await this.notifications.sendNotification(
      user,
      { title: "Order Complete", content: `Order #${order.id} shipped!` },
      ["email", "push"]
    );
  }
}

// ═══════════════════════════════════════════════════════════
// WORKFLOW SUMMARY:
// ═══════════════════════════════════════════════════════════
// 1. <leader>\  - Open and see structure
// 2. j/k Enter  - Navigate to interesting code
// 3. "Called by:" - Understand entry points
// 4. F          - Find all usages
// 5. gd         - Go deeper into dependencies
// 6. Ctrl+o     - Come back up
//
// Now you understand the notification system!
]]
    }
  },
}

-- State file location
local function get_state_file()
  return vim.fn.stdpath('data') .. '/nvim-lessons-state.json'
end

-- Load learning state
local function load_state()
  local file = io.open(get_state_file(), 'r')
  if not file then
    return { lessons = {}, last_shown = nil, current_lesson_idx = 1 }
  end
  local content = file:read('*all')
  file:close()
  local ok, state = pcall(vim.json.decode, content)
  if ok and state then
    return state
  end
  return { lessons = {}, last_shown = nil, current_lesson_idx = 1 }
end

-- Save learning state
local function save_state(state)
  local file = io.open(get_state_file(), 'w')
  if file then
    file:write(vim.json.encode(state))
    file:close()
  end
end

-- Get today as YYYY-MM-DD
local function today()
  return os.date('%Y-%m-%d')
end

-- Calculate days between two date strings
local function days_between(date1, date2)
  local pattern = '(%d+)-(%d+)-(%d+)'
  local y1, m1, d1 = date1:match(pattern)
  local y2, m2, d2 = date2:match(pattern)
  local t1 = os.time({ year = y1, month = m1, day = d1 })
  local t2 = os.time({ year = y2, month = m2, day = d2 })
  return math.floor((t2 - t1) / 86400)
end

-- Get next review date based on interval level
local function get_next_review(level)
  local interval = INTERVALS[math.min(level, #INTERVALS)]
  local t = os.time() + (interval * 86400)
  return os.date('%Y-%m-%d', t)
end

-- Find lessons due for review
local function get_due_lessons(state)
  local due = {}
  local now = today()

  for _, lesson in ipairs(M.lessons) do
    local lesson_state = state.lessons[lesson.id]
    if not lesson_state then
      -- Never seen, it's due (but respect learning order)
      table.insert(due, { lesson = lesson, is_new = true, priority = 100 - lesson.difficulty })
    elseif lesson_state.next_review and lesson_state.next_review <= now then
      -- Review is due
      local days_overdue = days_between(lesson_state.next_review, now)
      table.insert(due, { lesson = lesson, is_new = false, priority = days_overdue })
    end
  end

  -- Sort by priority (most overdue first, then new lessons by difficulty)
  table.sort(due, function(a, b) return a.priority > b.priority end)

  return due
end

-- Get the next new lesson in sequence
local function get_next_new_lesson(state)
  for _, lesson in ipairs(M.lessons) do
    if not state.lessons[lesson.id] then
      return lesson
    end
  end
  return nil
end

-- Create the lesson buffer
local function create_lesson_buffer(content, title)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')
  vim.api.nvim_buf_set_name(buf, 'Lesson: ' .. title)

  local lines = vim.split(content, '\n')
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  return buf
end

-- Show a lesson in a floating window
function M.show_lesson(lesson, is_review)
  local state = load_state()

  local header = is_review and '# REVIEW: ' or '# NEW LESSON: '
  local status_line = ''

  local lesson_state = state.lessons[lesson.id]
  if lesson_state then
    status_line = string.format('\n> Level %d | Last seen: %s | Times reviewed: %d\n',
      lesson_state.level or 1,
      lesson_state.last_seen or 'never',
      lesson_state.times_reviewed or 0)
  else
    status_line = '\n> This is a NEW lesson!\n'
  end

  local content = header .. lesson.title .. '\n'
    .. '**Key:** `' .. lesson.key .. '`\n'
    .. status_line
    .. '\n---\n'
    .. lesson.content
    .. '\n---\n'
    .. '\n## Quiz\n'
    .. '**' .. lesson.quiz.question .. '**\n\n'
    .. 'Press `a` to reveal answer, `y` if you knew it, `n` if you didn\'t\n'
    .. 'Press `p` to open PRACTICE buffer, `q` to close, `]`/`[` for next/prev\n'

  local buf = create_lesson_buffer(content, lesson.title)

  -- Calculate window size
  local width = math.min(80, vim.o.columns - 10)
  local height = math.min(35, vim.o.lines - 6)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = ' Neovim Lessons ',
    title_pos = 'center',
  })

  -- Store current lesson for keybindings
  vim.b[buf].current_lesson = lesson
  vim.b[buf].answer_shown = false

  -- Keybindings for the lesson buffer
  local opts = { buffer = buf, silent = true }

  -- Show answer
  vim.keymap.set('n', 'a', function()
    if not vim.b[buf].answer_shown then
      vim.b[buf].answer_shown = true
      vim.api.nvim_buf_set_option(buf, 'modifiable', true)
      vim.api.nvim_buf_set_lines(buf, -1, -1, false, {
        '',
        '## Answer',
        '**' .. lesson.quiz.answer .. '**',
        '',
        'Did you know it? Press `y` (yes) or `n` (no)',
      })
      vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    end
  end, opts)

  -- Mark as known (advance spaced repetition)
  vim.keymap.set('n', 'y', function()
    local s = load_state()
    local ls = s.lessons[lesson.id] or { level = 0, times_reviewed = 0 }
    ls.level = (ls.level or 0) + 1
    ls.times_reviewed = (ls.times_reviewed or 0) + 1
    ls.last_seen = today()
    ls.next_review = get_next_review(ls.level)
    s.lessons[lesson.id] = ls
    save_state(s)
    vim.api.nvim_win_close(win, true)
    local interval = INTERVALS[math.min(ls.level, #INTERVALS)]
    vim.notify('Great! Next review in ' .. interval .. ' days', vim.log.levels.INFO)
  end, opts)

  -- Mark as not known (reset spaced repetition)
  vim.keymap.set('n', 'n', function()
    local s = load_state()
    local ls = s.lessons[lesson.id] or { level = 0, times_reviewed = 0 }
    ls.level = 1  -- Reset to level 1
    ls.times_reviewed = (ls.times_reviewed or 0) + 1
    ls.last_seen = today()
    ls.next_review = get_next_review(1)
    s.lessons[lesson.id] = ls
    save_state(s)
    vim.api.nvim_win_close(win, true)
    vim.notify('No problem! Review again tomorrow', vim.log.levels.INFO)
  end, opts)

  -- Close
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(win, true)
  end, opts)

  -- Next lesson
  vim.keymap.set('n', ']', function()
    vim.api.nvim_win_close(win, true)
    M.next_lesson()
  end, opts)

  -- Previous lesson
  vim.keymap.set('n', '[', function()
    vim.api.nvim_win_close(win, true)
    M.prev_lesson()
  end, opts)

  -- Open practice buffer
  vim.keymap.set('n', 'p', function()
    vim.api.nvim_win_close(win, true)
    M.open_practice(lesson)
  end, opts)
end

-- Open a practice buffer for hands-on learning
function M.open_practice(lesson)
  if not lesson.practice then
    vim.notify('No practice buffer for this lesson', vim.log.levels.WARN)
    return
  end

  local practice = lesson.practice

  -- Create a new buffer
  local buf = vim.api.nvim_create_buf(true, false)  -- listed, not scratch
  vim.api.nvim_buf_set_name(buf, practice.filename)
  vim.api.nvim_buf_set_option(buf, 'filetype', practice.filetype)

  -- Set the content
  local lines = vim.split(practice.code, '\n')
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Open in a new window (vertical split)
  vim.cmd('vsplit')
  vim.api.nvim_win_set_buf(0, buf)

  -- Position cursor at a good starting point
  vim.api.nvim_win_set_cursor(0, { 1, 0 })

  vim.notify('Practice buffer opened! Try the exercises.', vim.log.levels.INFO)
end

-- Show today's lesson (due review or next new)
function M.today()
  local state = load_state()
  local due = get_due_lessons(state)

  if #due > 0 then
    -- Show the most urgent due lesson
    local item = due[1]
    M.show_lesson(item.lesson, not item.is_new)
  else
    -- All caught up!
    vim.notify('All caught up! No lessons due today. Use :LessonList to browse.', vim.log.levels.INFO)
  end
end

-- Show specific lesson by index
function M.show_by_index(idx)
  if idx < 1 or idx > #M.lessons then
    vim.notify('Invalid lesson number. Range: 1-' .. #M.lessons, vim.log.levels.ERROR)
    return
  end
  local state = load_state()
  state.current_lesson_idx = idx
  save_state(state)
  M.show_lesson(M.lessons[idx], state.lessons[M.lessons[idx].id] ~= nil)
end

-- Next lesson
function M.next_lesson()
  local state = load_state()
  local idx = (state.current_lesson_idx or 0) + 1
  if idx > #M.lessons then idx = 1 end
  M.show_by_index(idx)
end

-- Previous lesson
function M.prev_lesson()
  local state = load_state()
  local idx = (state.current_lesson_idx or 2) - 1
  if idx < 1 then idx = #M.lessons end
  M.show_by_index(idx)
end

-- Show list of all lessons with status
function M.list()
  local state = load_state()
  local now = today()

  local lines = {
    '# Neovim Lessons',
    '',
    'Press number to open lesson, `q` to close',
    '',
    '| # | Status | Title | Key | Next Review |',
    '|---|--------|-------|-----|-------------|',
  }

  for i, lesson in ipairs(M.lessons) do
    local ls = state.lessons[lesson.id]
    local status, next_review

    if not ls then
      status = 'NEW'
      next_review = '-'
    elseif ls.next_review and ls.next_review <= now then
      status = 'DUE'
      next_review = ls.next_review
    else
      local level = ls.level or 1
      status = 'Lv' .. level
      next_review = ls.next_review or '-'
    end

    table.insert(lines, string.format('| %d | %s | %s | `%s` | %s |',
      i, status, lesson.title, lesson.key, next_review))
  end

  table.insert(lines, '')
  table.insert(lines, '**Status:** NEW = never seen, DUE = review due, Lv# = mastery level')

  local buf = create_lesson_buffer(table.concat(lines, '\n'), 'Lesson List')

  local width = math.min(90, vim.o.columns - 10)
  local height = math.min(25, vim.o.lines - 6)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = ' Lesson List ',
    title_pos = 'center',
  })

  local opts = { buffer = buf, silent = true }

  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(win, true)
  end, opts)

  -- Number keys to jump to lessons
  for i = 1, 9 do
    vim.keymap.set('n', tostring(i), function()
      vim.api.nvim_win_close(win, true)
      M.show_by_index(i)
    end, opts)
  end
end

-- Reset all progress
function M.reset()
  save_state({ lessons = {}, last_shown = nil, current_lesson_idx = 1 })
  vim.notify('Lesson progress reset!', vim.log.levels.INFO)
end

-- Setup function
function M.setup()
  -- Commands
  vim.api.nvim_create_user_command('Lesson', function() M.today() end, { desc = 'Show today\'s lesson' })
  vim.api.nvim_create_user_command('LessonList', function() M.list() end, { desc = 'List all lessons' })
  vim.api.nvim_create_user_command('LessonNext', function() M.next_lesson() end, { desc = 'Next lesson' })
  vim.api.nvim_create_user_command('LessonPrev', function() M.prev_lesson() end, { desc = 'Previous lesson' })
  vim.api.nvim_create_user_command('LessonReset', function() M.reset() end, { desc = 'Reset lesson progress' })
  vim.api.nvim_create_user_command('LessonShow', function(opts)
    M.show_by_index(tonumber(opts.args) or 1)
  end, { nargs = 1, desc = 'Show specific lesson by number' })

  vim.api.nvim_create_user_command('LessonPractice', function(opts)
    local idx = tonumber(opts.args)
    if idx and idx >= 1 and idx <= #M.lessons then
      M.open_practice(M.lessons[idx])
    else
      -- Open practice for current lesson
      local state = load_state()
      local current_idx = state.current_lesson_idx or 1
      M.open_practice(M.lessons[current_idx])
    end
  end, { nargs = '?', desc = 'Open practice buffer for lesson' })
end

return M
