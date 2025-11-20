-- Brook Story Explorer Plugin
-- Iteration 3: Real code structure tree

local M = {}

-- Debug logging (file only, no console spam)
local function debug_log(msg)
  local log_file = vim.fn.stdpath('cache') .. '/story-explorer-debug.log'
  local timestamp = os.date('%Y-%m-%d %H:%M:%S')
  local log_entry = '[' .. timestamp .. '] ' .. msg .. '\n'
  
  -- Append to log file only
  local file = io.open(log_file, 'a')
  if file then
    file:write(log_entry)
    file:close()
  end
end

-- Global state for the sidebar
local sidebar_bufnr = nil
local sidebar_winid = nil
local main_bufnr = nil  -- Store the main buffer we're analyzing
local current_state = 'structure'
local current_line = 1

-- Open or focus the story explorer sidebar  
function M.open_or_focus_sidebar()
  debug_log('open_or_focus_sidebar() called')
  
  if sidebar_winid and vim.api.nvim_win_is_valid(sidebar_winid) then
    -- Sidebar exists, focus it
    debug_log('Focusing existing sidebar')
    vim.api.nvim_set_current_win(sidebar_winid)
  else
    -- Clean up any stale references first
    M.cleanup_sidebar()
    
    -- Store current buffer before creating sidebar
    main_bufnr = vim.api.nvim_get_current_buf()
    local filename = vim.api.nvim_buf_get_name(main_bufnr)
    debug_log('Opening sidebar for buffer: ' .. main_bufnr .. ' (' .. filename .. ')')
    -- Create new sidebar
    M.create_sidebar()
  end
end

-- Clean up any stale sidebar references
function M.cleanup_sidebar()
  debug_log('Cleaning up sidebar references')
  
  -- Close any existing sidebar windows
  if sidebar_winid and vim.api.nvim_win_is_valid(sidebar_winid) then
    debug_log('Closing existing sidebar window')
    vim.api.nvim_win_close(sidebar_winid, true)
  end
  
  -- Clean up buffer if it exists  
  if sidebar_bufnr and vim.api.nvim_buf_is_valid(sidebar_bufnr) then
    debug_log('Cleaning up sidebar buffer')
    vim.api.nvim_buf_delete(sidebar_bufnr, {force = true})
  end
  
  sidebar_winid = nil
  sidebar_bufnr = nil
end

-- Close the sidebar (called from escape key)
function M.close_sidebar()
  debug_log('close_sidebar() called')
  M.cleanup_sidebar()
  main_bufnr = nil
end

-- Create the sidebar window and buffer
function M.create_sidebar()
  -- Create a new buffer
  sidebar_bufnr = vim.api.nvim_create_buf(false, true)
  
  -- Set buffer options (following nvim-tree pattern for tab hiding)
  vim.api.nvim_buf_set_option(sidebar_bufnr, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(sidebar_bufnr, 'buflisted', false)  -- Hide from buffer list/tabs
  vim.api.nvim_buf_set_option(sidebar_bufnr, 'swapfile', false)
  vim.api.nvim_buf_set_option(sidebar_bufnr, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(sidebar_bufnr, 'filetype', 'story-explorer')
  vim.api.nvim_buf_set_option(sidebar_bufnr, 'modifiable', false)
  
  -- Get current window width
  local width = vim.api.nvim_get_option('columns')
  local sidebar_width = math.floor(width * 0.33)  -- 33% of screen width (increased from 25%)
  
  -- Create the window
  sidebar_winid = vim.api.nvim_open_win(sidebar_bufnr, true, {
    relative = 'editor',
    width = sidebar_width,
    height = vim.api.nvim_get_option('lines') - 2, -- Full height minus statusline
    row = 0,
    col = width - sidebar_width,  -- Right side of screen
    style = 'minimal',
    border = 'single',
    title = ' Story Explorer ',
    title_pos = 'center'
  })
  
  -- Set window options
  vim.api.nvim_win_set_option(sidebar_winid, 'wrap', false)
  vim.api.nvim_win_set_option(sidebar_winid, 'cursorline', true)
  
  -- Set initial content (code structure)
  M.show_code_structure()
  
  -- Protect sidebar from buffer override using nvim-tree approach
  M.setup_buffer_protection()
  
  -- Set up buffer-specific keymaps
  local opts = { noremap = true, silent = true, buffer = sidebar_bufnr }
  vim.keymap.set('n', 'q', '<cmd>lua require("custom.story-explorer").close_sidebar()<CR>', opts)
  vim.keymap.set('n', '<Esc>', '<cmd>lua require("custom.story-explorer").close_sidebar()<CR>', opts)
  vim.keymap.set('n', 'j', '<cmd>lua require("custom.story-explorer").move_down()<CR>', opts)
  vim.keymap.set('n', 'k', '<cmd>lua require("custom.story-explorer").move_up()<CR>', opts)
  vim.keymap.set('n', '<CR>', '<cmd>lua require("custom.story-explorer").select_item()<CR>', opts)
  vim.keymap.set('n', '<Down>', '<cmd>lua require("custom.story-explorer").move_down()<CR>', opts)
  vim.keymap.set('n', '<Up>', '<cmd>lua require("custom.story-explorer").move_up()<CR>', opts)
  
  -- Context navigation
  vim.keymap.set('n', '<Right>', '<cmd>lua require("custom.story-explorer").expand_context()<CR>', opts)
  vim.keymap.set('n', '<Left>', '<cmd>lua require("custom.story-explorer").fold_context()<CR>', opts)
  
  -- Software Agent Actions (use uppercase to avoid conflicts)
  vim.keymap.set('n', 'R', '<cmd>lua require("custom.story-explorer").agent_rename_method()<CR>', opts)
  vim.keymap.set('n', 'D', '<cmd>lua require("custom.story-explorer").agent_add_debug()<CR>', opts)  
  vim.keymap.set('n', 'J', '<cmd>lua require("custom.story-explorer").agent_generate_jsdoc()<CR>', opts)
  vim.keymap.set('n', 'F', '<cmd>lua require("custom.story-explorer").agent_find_usages()<CR>', opts)
  vim.keymap.set('n', 'T', '<cmd>lua require("custom.story-explorer").agent_generate_test()<CR>', opts)
  vim.keymap.set('n', 'E', '<cmd>lua require("custom.story-explorer").agent_extract_class()<CR>', opts)
end

-- Extract story cards from JavaScript comments
function M.extract_story_cards(content, stories)
  debug_log('Extracting story cards')
  
  -- Match "* STORY CARD:", "* STORY:", and "* @story" patterns in comments
  local lines = vim.split(content, '\n')
  
  for i, line in ipairs(lines) do
    -- First, check for "* STORY CARD:" pattern
    local story_title = line:match('%*%s*STORY CARD:%s*(.+)')
    
    -- Also check for JSDoc @story directive
    local jsdoc_story = line:match('%*%s*@story%s+(.+)')
    
    if story_title or jsdoc_story then
      local title = story_title or (jsdoc_story and jsdoc_story:sub(1, 50) .. "..." or "JSDoc Story")
      debug_log('Found story: ' .. (story_title or "JSDoc @story"))
      
      -- Collect all content from this story card until end of comment or next story card  
      local story_content = {}
      
      -- If this is a @story directive, include the first line
      if jsdoc_story then
        table.insert(story_content, jsdoc_story)
      end
      
      for j = i + 1, math.min(i + 20, #lines) do
        local content_line = lines[j]
        
        -- Stop if we hit end of comment, another story card, or another JSDoc tag
        if content_line:match('%*/') or 
           content_line:match('%*%s*STORY CARD:') or
           content_line:match('%*%s*@story') or
           content_line:match('%*%s*@class') or
           content_line:match('%*%s*@method') then
          break
        end
        
        -- Extract comment content (remove * prefix)
        local clean_line = content_line:gsub('^%s*%*%s?', ''):gsub('%s+$', '')
        if clean_line ~= '' and not clean_line:match('^@') then
          table.insert(story_content, clean_line)
        end
      end
      
      local story = {
        title = title:gsub('^%s+', ''):gsub('%s+$', ''),
        content = table.concat(story_content, '\n'),  -- Preserve line breaks for readability
        line = i
      }
      
      table.insert(stories, story)
    end
    
    -- Extract practical JSDoc with technical descriptions
    local story_content_match = nil
    
    -- Look for class/component documentation pattern
    local potential_class = line:match('^%s*%*%s*([A-Z][a-zA-Z0-9_]*)%s*$')
    if potential_class and #potential_class >= 4 then
      -- Check if this is followed by technical description, not mystical fragments
      for peek = i + 1, math.min(i + 8, #lines) do
        local peek_line = lines[peek]
        if peek_line:match('%*/') then break end
        
        -- Look for practical technical patterns
        if peek_line:match('%*%s*PURPOSE:') or
           peek_line:match('%*%s*INPUTS:') or
           peek_line:match('%*%s*OUTPUTS:') or
           peek_line:match('%*%s*ACCESS BOUNDARY:') or
           peek_line:match('%*%s*RESPONSIBILITIES:') or
           peek_line:match('%*%s*[A-Z][a-z]+ [a-z]+ [a-z]+') then -- "Coordinates conversation lifecycle"
          story_content_match = potential_class
          break
        end
      end
    end
    if story_content_match then
      debug_log('Found JSDoc story: ' .. story_content_match)
      
      -- Collect the entire comment block for rich story content
      local story_lines = {story_content_match}  -- Start with STORY line
      local story_title = story_content_match  -- Use first line as title
      
      -- Look backward to get class/function name for title
      for k = i - 1, math.max(1, i - 5), -1 do
        local prev_line = lines[k]
        -- Check for class or export class
        local class_name = prev_line:match('class%s+(%w+)') or prev_line:match('export%s+class%s+(%w+)')
        if class_name then
          story_title = class_name .. ' - ' .. story_content_match
          break
        end
      end
      
      -- Collect following comment lines
      for j = i + 1, math.min(i + 15, #lines) do
        local content_line = lines[j]
        
        -- Stop if we hit end of comment
        if content_line:match('%*/') then
          break
        end
        
        -- Extract rich comment content
        local clean_line = content_line:gsub('^%s*%*%s?', ''):gsub('%s+$', '')
        if clean_line ~= '' and not clean_line:match('^@') then
          -- Add structured fields without extra newlines
          table.insert(story_lines, clean_line)
        end
      end
      
      local story = {
        title = story_title:gsub('^%s+', ''):gsub('%s+$', ''),
        content = table.concat(story_lines, '\n'),  -- Preserve JSDoc structure
        line = i
      }
      
      table.insert(stories, story)
    end
  end
  
  debug_log('Extracted ' .. #stories .. ' story cards')
end

-- Word wrap text to specified width
function M.word_wrap(text, width)
  if not text or text == '' then return {} end
  
  local lines = {}
  
  -- First, preserve existing line breaks by processing line by line
  for existing_line in text:gmatch('[^\n]*') do
    if existing_line == '' then
      table.insert(lines, '')  -- Preserve empty lines
    else
      local current_line = ''
      
      -- Split each line into words and wrap if needed
      for word in existing_line:gmatch('%S+') do
        -- Check if adding this word would exceed width
        local test_line = current_line == '' and word or (current_line .. ' ' .. word)
        if #test_line <= width then
          current_line = test_line
        else
          -- Start new line
          if current_line ~= '' then
            table.insert(lines, current_line)
          end
          current_line = word
        end
      end
      
      -- Add final line for this existing line
      if current_line ~= '' then
        table.insert(lines, current_line)
      end
    end
  end
  
  return lines
end

-- Extract JSDoc/docstring comments for functions
function M.extract_function_docs(lines, functions)
  debug_log('Extracting function documentation')
  
  for _, func in ipairs(functions) do
    local func_line = func.line
    local doc = ''
    
    -- Look backwards for JSDoc comment /** ... */
    for i = func_line - 1, math.max(1, func_line - 10), -1 do
      local line = lines[i]
      
      -- Check if this line ends a comment block
      if line:match('%*/') then
        -- Found end of comment block, collect backwards to start
        local doc_lines = {}
        local comment_start = i
        
        -- Find the start of the comment block
        for j = i, 1, -1 do
          local search_line = lines[j]
          if search_line:match('/%*') then
            comment_start = j
            break
          end
        end
        
        -- Collect comment content from start to end
        for j = comment_start, i do
          local comment_line = lines[j]
          -- Remove comment markers and extract content
          comment_line = comment_line:gsub('^%s*/%*%*?%s*', ''):gsub('^%s*%*%s?', ''):gsub('%s*%*/%s*$', '')
          
          -- Skip empty lines and pure markers
          if comment_line:gsub('^%s+', ''):gsub('%s+$', '') ~= '' and 
             not comment_line:match('^@') then -- Skip JSDoc tags like @param, @returns
            table.insert(doc_lines, comment_line)
          end
        end
        
        doc = table.concat(doc_lines, ' ')
        break
      elseif line:match('^%s*//') then
        -- Single line comment
        doc = line:gsub('^%s*//%s*', '')
        break
      elseif line:gsub('^%s+', ''):gsub('%s+$', '') == '' then
        -- Continue looking through empty lines
      else
        -- Hit non-comment, stop looking
        break
      end
    end
    
    -- Store doc with function (cleaned up)
    func.doc = doc:gsub('^%s+', ''):gsub('%s+$', ''):gsub('%s+', ' ')  -- Normalize whitespace
  end
  
  debug_log('Extracted documentation for ' .. #functions .. ' functions')
end

-- Extract constructor state assignments (this._prop = value patterns)
function M.extract_constructor_assignments(lines, constructor_line)
  debug_log('Extracting constructor assignments starting from line: ' .. constructor_line)
  
  local assignments = {}
  local brace_count = 0
  local in_constructor = false
  
  -- Start from constructor line and find assignments until closing brace
  for i = constructor_line, math.min(constructor_line + 200, #lines) do
    local line = lines[i]
    
    -- Track braces to know when constructor ends
    local open_braces = 0
    local close_braces = 0
    for char in line:gmatch('.') do
      if char == '{' then open_braces = open_braces + 1
      elseif char == '}' then close_braces = close_braces + 1
      end
    end
    
    brace_count = brace_count + open_braces - close_braces
    
    if brace_count > 0 then
      in_constructor = true
    elseif in_constructor and brace_count == 0 then
      -- Constructor ended
      break
    end
    
    if in_constructor then
      -- Match this._property = value patterns
      local property, value = line:match('this%.([_%w][_%w]*)%s*=%s*([^;]+)')
      if property then
        -- Clean up the value (remove trailing semicolon, whitespace)
        value = value:gsub(';%s*$', ''):gsub('%s*$', '')
        
        -- Try to infer type from value
        local type_info = 'unknown'
        if value:match('^new%s+(%w+)') then
          type_info = value:match('^new%s+(%w+)')
        elseif value:match('^null') then
          type_info = 'null'  
        elseif value:match('^%d+') then
          type_info = 'number'
        elseif value:match('^[\'"]') then
          type_info = 'string'
        elseif value:match('^%[') then
          type_info = 'Array'
        elseif value:match('^{') then
          type_info = 'Object'
        end
        
        table.insert(assignments, {
          property = property,
          value = value,
          type = type_info,
          line = i
        })
        debug_log('Found assignment: this.' .. property .. ' = ' .. value .. ' (' .. type_info .. ')')
      end
    end
  end
  
  debug_log('Extracted ' .. #assignments .. ' constructor assignments')
  return assignments
end

-- Extract function calls with caller context
function M.extract_function_calls(lines, calls, functions)
  debug_log('Extracting function calls with context')
  
  -- Build map of line numbers to functions for context
  local line_to_function = {}
  for _, func in ipairs(functions) do
    line_to_function[func.line] = func
  end
  
  for i, line in ipairs(lines) do
    -- Find which function this line belongs to (look for the closest function before this line)
    local current_function = nil
    for _, func in ipairs(functions) do
      -- Line must be after function start and before the next function (or end of file)
      if i > func.line then
        -- Find if there's a function closer to this line
        if not current_function or func.line > current_function.line then
          -- Check if this line is before the next function
          local is_before_next_function = true
          for _, next_func in ipairs(functions) do
            if next_func.line > func.line and i >= next_func.line then
              is_before_next_function = false
              break
            end
          end
          if is_before_next_function then
            current_function = func
          end
        end
      end
    end
    
    -- Match function calls: identifier.method(args) or method(args) (including private methods)
    for call_match in line:gmatch('([_%w][_%w%.]*[_%w])%(') do
      -- Filter out common control structures, constructors, and self-references
      if call_match ~= 'if' and call_match ~= 'for' and call_match ~= 'while' and 
         call_match ~= 'switch' and call_match ~= 'catch' and call_match ~= 'try' and
         call_match ~= 'function' and call_match ~= 'return' and
         call_match ~= (current_function and current_function.name) then -- Don't include self-calls
        
        local call_info = {
          name = call_match,
          line = i,
          caller = current_function and current_function.name or 'global',
          context = line:gsub('^%s+', ''):gsub('%s+$', '')
        }
        debug_log('Call detected: ' .. call_match .. ' at line ' .. i .. ' in function ' .. (current_function and current_function.name or 'global'))
        table.insert(calls, call_info)
      end
    end
    
    -- Enhanced: Match arrow function callback patterns like "onNotify: (e) => this.onNotify(e)"
    -- This handles callback patterns where the arrow function calls a method
    local callback_name, method_call = line:match('([_%w][_%w]*)%s*:%s*%(.-%)%s*=>%s*([_%w][_%w%.]*[_%w])%(')
    if callback_name and method_call then
      -- Filter out control structures
      if method_call ~= 'if' and method_call ~= 'for' and method_call ~= 'while' and 
         method_call ~= 'switch' and method_call ~= 'catch' and method_call ~= 'try' and
         method_call ~= 'function' and method_call ~= 'return' then
        
        local call_info = {
          name = method_call,
          line = i,
          caller = current_function and current_function.name or 'global',
          context = line:gsub('^%s+', ''):gsub('%s+$', '') .. ' [via ' .. callback_name .. ' callback]'
        }
        debug_log('Arrow callback call detected: ' .. method_call .. ' via ' .. callback_name .. ' callback at line ' .. i)
        table.insert(calls, call_info)
      end
    end
    
    -- Enhanced: Match function-style callback patterns like "onNotify: function(e) { return this.onNotify(e); }"
    -- This handles traditional function callbacks that call methods
    local func_callback = line:match('([_%w][_%w]*)%s*:%s*function%s*%(.-%)%s*{.*([_%w][_%w%.]*[_%w])%(')
    if func_callback then
      local func_callback_name, func_method_call = line:match('([_%w][_%w]*)%s*:%s*function%s*%(.-%)%s*{.*([_%w][_%w%.]*[_%w])%(')
      if func_callback_name and func_method_call then
        -- Filter out control structures
        if func_method_call ~= 'if' and func_method_call ~= 'for' and func_method_call ~= 'while' and 
           func_method_call ~= 'switch' and func_method_call ~= 'catch' and func_method_call ~= 'try' and
           func_method_call ~= 'function' and func_method_call ~= 'return' then
          
          local call_info = {
            name = func_method_call,
            line = i,
            caller = current_function and current_function.name or 'global',
            context = line:gsub('^%s+', ''):gsub('%s+$', '') .. ' [via ' .. func_callback_name .. ' function callback]'
          }
          debug_log('Function callback call detected: ' .. func_method_call .. ' via ' .. func_callback_name .. ' function callback at line ' .. i)
          table.insert(calls, call_info)
        end
      end
    end
  end
  
  debug_log('Extracted ' .. #calls .. ' function calls')
end

-- Parse JavaScript/TypeScript file structure
function M.parse_js_file(content, filename)
  local structure = {
    module = filename,
    classes = {},
    functions = {},
    stories = {},
    calls = {}
  }
  
  local lines = vim.split(content, '\n')
  local current_class = nil
  debug_log('Total lines to parse: ' .. #lines)
  
  -- Extract story cards first
  M.extract_story_cards(content, structure.stories)
  
  for i, line in ipairs(lines) do
    -- Match class declarations
    local class_match = line:match('^%s*export%s+class%s+(%w+)') or line:match('^%s*class%s+(%w+)')
    if class_match then
      debug_log('Found class: ' .. class_match .. ' at line ' .. i)
      current_class = {
        name = class_match,
        line = i,
        methods = {}
      }
      table.insert(structure.classes, current_class)
    end
    
    -- Match function/method declarations
    local func_match = nil
    local is_async = false
    local match_type = nil
    
    -- Check for async methods in class (including private methods with _ and __)
    func_match = line:match('^%s*async%s+([_%w][_%w]*)%s*%(.*%)%s*{')
    if func_match then 
      is_async = true 
      match_type = 'async method'
    end
    
    -- Regular methods in class (including private methods with _ and __)
    if not func_match then
      func_match = line:match('^%s*([_%w][_%w]*)%s*%(.*%)%s*{')
      if func_match then match_type = 'method' end
    end
    
    -- Async function declarations  
    if not func_match then
      func_match = line:match('^%s*async%s+function%s+([_%w][_%w]*)%s*%(')
      if func_match then 
        is_async = true
        match_type = 'async function'
      end
    end
    
    -- Regular function declarations (including private with _)
    if not func_match then
      func_match = line:match('^%s*function%s+([_%w][_%w]*)%s*%(')
      if func_match then match_type = 'function' end
    end
    
    -- Arrow functions and assignments (including private with _)
    if not func_match then
      func_match = line:match('^%s*([_%w][_%w]*)%s*=%s*async%s+function')
      if func_match then 
        is_async = true
        match_type = 'async assignment'
      end
    end
    
    if not func_match then
      func_match = line:match('^%s*([_%w][_%w]*)%s*=%s*function')
      if func_match then match_type = 'function assignment' end
    end
    
    if not func_match then
      func_match = line:match('^%s*([_%w][_%w]*)%s*=%s*%(.*%)%s*=>')
      if func_match then match_type = 'arrow function' end
    end
    
    if func_match and func_match ~= 'if' and func_match ~= 'for' and func_match ~= 'while' and func_match ~= 'switch' then
      local async_marker = is_async and ' [async]' or ''
      debug_log('Found ' .. match_type .. ': ' .. func_match .. async_marker .. ' at line ' .. i .. ' | Line: "' .. line .. '"')
      
      local func_info = {
        name = func_match .. async_marker,
        line = i
      }
      
      if current_class then
        table.insert(current_class.methods, func_info)
        debug_log('Added as method to class: ' .. current_class.name)
        
        -- Special handling for constructor - extract state assignments
        if func_match == 'constructor' then
          current_class.constructor = func_info
          current_class.state = M.extract_constructor_assignments(lines, i)
          debug_log('Extracted constructor state: ' .. #current_class.state .. ' assignments')
          for _, assignment in ipairs(current_class.state or {}) do
            debug_log('  State: this.' .. assignment.property .. ' = ' .. assignment.value .. ' (' .. assignment.type .. ')')
          end
        end
      else
        table.insert(structure.functions, func_info)
        debug_log('Added as standalone function')
      end
    end
  end
  
  -- Extract documentation for all functions
  local all_functions = {}
  for _, func in ipairs(structure.functions) do
    table.insert(all_functions, func)
  end
  for _, class in ipairs(structure.classes) do
    for _, method in ipairs(class.methods) do
      table.insert(all_functions, method)
    end
  end
  M.extract_function_docs(lines, all_functions)
  
  -- Extract function calls after we know all functions
  M.extract_function_calls(lines, structure.calls, all_functions)
  
  debug_log('=== PARSE RESULTS ===')
  debug_log('Classes: ' .. #structure.classes .. ', Functions: ' .. #structure.functions .. ', Calls: ' .. #structure.calls)
  
  -- Log all detected functions for debugging
  for _, func in ipairs(structure.functions) do
    debug_log('Function: ' .. func.name .. ' at line ' .. func.line)
  end
  for _, class in ipairs(structure.classes) do
    for _, method in ipairs(class.methods) do
      debug_log('Method: ' .. method.name .. ' at line ' .. method.line)
    end
  end
  
  debug_log('=== PARSING SESSION END ===')
  return structure
end

-- Show code structure of current file
function M.show_code_structure()
  current_state = 'structure'
  debug_log('=== PARSING SESSION START ===')
  debug_log('show_code_structure() called')
  
  -- Ensure sidebar exists first
  if not sidebar_bufnr or not vim.api.nvim_buf_is_valid(sidebar_bufnr) then
    debug_log('Creating sidebar as it does not exist')
    M.open_or_focus_sidebar()
  end
  
  -- Use the stored main buffer (don't override it here)
  if not main_bufnr or not vim.api.nvim_buf_is_valid(main_bufnr) then
    debug_log('No valid main buffer: main_bufnr=' .. tostring(main_bufnr))
    if sidebar_bufnr and vim.api.nvim_buf_is_valid(sidebar_bufnr) then
      vim.api.nvim_buf_set_lines(sidebar_bufnr, 0, -1, false, {"No valid buffer to analyze"})
    end
    return
  end
  
  local filename = vim.api.nvim_buf_get_name(main_bufnr)
  debug_log('Analyzing file: ' .. filename)
  local content = table.concat(vim.api.nvim_buf_get_lines(main_bufnr, 0, -1, false), '\n')
  debug_log('Content length: ' .. #content .. ' characters')
  
  -- Parse based on file extension
  local display_lines = {}
  
  if filename == '' then
    table.insert(display_lines, "No file open")
  else
    local basename = vim.fn.fnamemodify(filename, ':t')
    local extension = vim.fn.fnamemodify(filename, ':e')
    
    if extension == 'js' or extension == 'ts' or extension == 'jsx' or extension == 'tsx' then
      local structure = M.parse_js_file(content, basename)
      
      -- Get current cursor position to highlight active function
      local cursor_line = 1
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == main_bufnr then
          cursor_line = vim.api.nvim_win_get_cursor(win)[1]
          break
        end
      end
      debug_log('Current cursor line: ' .. cursor_line)
      
      -- Build list of all functions for cursor detection
      local all_functions = {}
      for _, func in ipairs(structure.functions) do
        table.insert(all_functions, func)
      end
      for _, class in ipairs(structure.classes) do
        for _, method in ipairs(class.methods) do
          method.class_name = class.name
          table.insert(all_functions, method)
        end
      end
      
      -- Find current function
      local current_function = M.find_current_function(cursor_line, all_functions)
      debug_log('Current function: ' .. (current_function and current_function.name or 'none'))
      
      -- Clean context header
      local context_info = basename
      if current_function then
        context_info = context_info .. " > " .. current_function.name .. "()"
      end
      -- Add line range if available  
      if current_function and current_function.line then
        context_info = context_info .. " [" .. basename .. ":" .. current_function.line .. "]"
      end
      table.insert(display_lines, "# " .. context_info)
      table.insert(display_lines, "----------------------------")
      
      -- Shape section
      table.insert(display_lines, "## Shape")
      for _, class in ipairs(structure.classes) do
        table.insert(display_lines, "class " .. class.name)
        
        -- Properties section
        if class.state and #class.state > 0 then
          table.insert(display_lines, "")
          table.insert(display_lines, "  ### PROPERTIES")
          for _, assignment in ipairs(class.state) do
            local state_line = string.format("  this.%s: %s", assignment.property, assignment.type)
            table.insert(display_lines, state_line)
            
            -- Show value for simple assignments
            if assignment.type == 'null' or assignment.type == 'number' or assignment.type == 'string' then
              table.insert(display_lines, "    = " .. assignment.value)
            end
          end
        end
        
        table.insert(display_lines, "")
        table.insert(display_lines, "  ### METHODS")
        
        -- Methods with proper indentation and current method marking
        for _, method in ipairs(class.methods) do
          -- Skip constructor as it's redundant with class shape
          if method.name == "constructor" then
            goto continue
          end
          
          local is_current = current_function and method.name == current_function.name
          local marker = is_current and "  ** " or "  "
          local method_line = marker .. method.name:gsub("%s%[async%]", "") .. (method.name:match("%[async%]") and " [async]" or "")
          
          table.insert(display_lines, method_line)
          
          ::continue::
        end
        
      end -- end class loop
      
      -- Standalone functions (if any)
      if #structure.functions > 0 then
        table.insert(display_lines, "")
        table.insert(display_lines, "⚙️ Functions:")
        for _, func in ipairs(structure.functions) do
          local is_current = current_function and func.name == current_function.name
          local marker = is_current and "** " or "   "
          table.insert(display_lines, marker .. func.name)
          
          -- Add documentation for current function
          if is_current and func.doc and func.doc ~= '' then
            local wrapped_lines = M.word_wrap(func.doc, 42)
            for _, wrapped_line in ipairs(wrapped_lines) do
              table.insert(display_lines, "     " .. wrapped_line)
            end
          end
        end
      end
      
      table.insert(display_lines, "")
      table.insert(display_lines, "---------------------------")
      table.insert(display_lines, "## Callers")
      table.insert(display_lines, "")
      
      if current_function then
        -- Use enhanced callgraph for cross-file caller analysis  
        local callers = M.get_function_callers(current_function.name, filename)
        if #callers > 0 then
          for _, caller in ipairs(callers) do
            -- Show Class.method format (no parentheses as requested)
            local caller_class = caller.callerFile:gsub('%.js$', '')
            local display_caller = caller_class .. "." .. caller.caller
            
            table.insert(display_lines, display_caller .. " (" .. caller.callerFile .. ":" .. caller.callerLocation .. ")")
            
            -- Show context if available
            if caller.context and caller.context ~= '' then
              table.insert(display_lines, "  " .. caller.context .. "...")
            end
          end
        else
          table.insert(display_lines, "(No callers found)")
        end
      else
        table.insert(display_lines, "(Select a method to see its callers)")
      end
      
      table.insert(display_lines, "")
      table.insert(display_lines, "---------------------------")
      table.insert(display_lines, "## Calls")
      table.insert(display_lines, "")
      
      if current_function then
        -- Show calls made by current function with enhanced type resolution
        local current_calls = {}
        for _, call in ipairs(structure.calls) do
          if call.caller == current_function.name then
            table.insert(current_calls, call.name)
          end
        end
        
        if #current_calls > 0 then
          local unique_calls = {}
          for _, call_name in ipairs(current_calls) do
            if not unique_calls[call_name] then
              unique_calls[call_name] = true
              -- Debug current function context
              debug_log('Resolving call: ' .. call_name .. ' for function: ' .. current_function.name .. 
                       ' in class: ' .. (current_function.class_name or 'nil'))
              -- Resolve to Class.method format with current function context
              local resolved_call = M.resolve_call_to_class_method_enhanced(call_name, current_function, filename)
              table.insert(display_lines, resolved_call)
            end
          end
        else
          table.insert(display_lines, "(no outgoing calls)")
        end
      else
        table.insert(display_lines, "(Select a method to see its calls)")
      end
      
      table.insert(display_lines, "")
      table.insert(display_lines, "---------------------------")
      table.insert(display_lines, "## Story path")
      table.insert(display_lines, "")
        
        -- 1. Subdir story card with context
        local subdir = vim.fn.fnamemodify(filename, ':h:t')  -- e.g., "content"
        table.insert(display_lines, "[[" .. subdir .. " card]]")
        table.insert(display_lines, "  Browser extension content scripts")
        table.insert(display_lines, "  Claude web app integration layer")
        table.insert(display_lines, "")
        
        -- 2. Module story card with context
        local module_name = vim.fn.fnamemodify(filename, ':t:r')  -- e.g., "App"
        table.insert(display_lines, "  [[" .. module_name .. " card]]")
        table.insert(display_lines, "    Main application coordinator")
        table.insert(display_lines, "    Orchestrates service relationships")
        table.insert(display_lines, "")
        
        -- 3. Class story card with actual extracted content
        if structure.classes and #structure.classes > 0 then
          for _, class in ipairs(structure.classes) do
            table.insert(display_lines, "    [[" .. class.name .. " card]]")
            
            -- Find and display class-level story content (JSDoc is source of truth)
            local class_story_found = false
            
            -- First priority: JSDoc stories from the actual source code
            if structure.stories and #structure.stories > 0 then
              for _, story in ipairs(structure.stories) do
                if story.title:lower():find(class.name:lower()) or 
                   story.line <= (class.line or 0) + 10 then -- Class story should be near class declaration
                  local wrapped_lines = M.word_wrap(story.content, 60)
                  for _, wrapped_line in ipairs(wrapped_lines) do
                    table.insert(display_lines, "      " .. wrapped_line)
                  end
                  class_story_found = true
                  break
                end
              end
            end
            
            -- Fallback to JSON stories if no JSDoc stories found
            if not class_story_found then
              local json_stories = M.get_relevant_story_cards(class.name, filename)
              if #json_stories > 0 then
                for _, story in ipairs(json_stories) do
                  if story.id:lower():find(class.name:lower()) or story.file == structure.module then
                    -- Extract rich story content
                    local story_content = ""
                    if story.purpose then
                      story_content = story.purpose
                      if story.evolution then
                        story_content = story_content .. "\n" .. story.evolution
                      end
                    end
                    
                    if story_content ~= "" then
                      local wrapped_lines = M.word_wrap(story_content, 35)
                      for _, wrapped_line in ipairs(wrapped_lines) do
                        table.insert(display_lines, "      " .. wrapped_line)
                      end
                      class_story_found = true
                      break
                    end
                  end
                end
              end
            end
            
            if not class_story_found then
              table.insert(display_lines, "      Conversation coordinator")
              table.insert(display_lines, "      Service lifecycle manager")
            end
            table.insert(display_lines, "")
            break -- Just take the first class for now
          end
        end
        
        -- 4. Method story card with method-specific content
        if current_function then
          table.insert(display_lines, "      [[" .. current_function.name .. " card]]")
          
          -- Show method documentation if available
          if current_function.doc and current_function.doc ~= '' then
            local wrapped_lines = M.word_wrap(current_function.doc, 30)
            for _, wrapped_line in ipairs(wrapped_lines) do
              table.insert(display_lines, "        " .. wrapped_line)
            end
          else
            -- Look for method-specific story cards from JSON
            local method_story_found = false
            local json_stories = M.get_relevant_story_cards(current_function.name, filename)
            if #json_stories > 0 then
              for _, story in ipairs(json_stories) do
                if story.id:lower():find(current_function.name:lower()) then
                  -- Extract rich story content for method
                  local story_content = ""
                  if story.purpose then
                    story_content = story.purpose
                    if story.user then
                      story_content = "USER: " .. story.user .. "\n" .. story_content
                    end
                  end
                  
                  if story_content ~= "" then
                    local wrapped_lines = M.word_wrap(story_content, 30)
                    for _, wrapped_line in ipairs(wrapped_lines) do
                      table.insert(display_lines, "        " .. wrapped_line)
                    end
                    method_story_found = true
                    break
                  end
                end
              end
            end
            
            -- Fallback to JSDoc stories if no JSON stories found
            if not method_story_found and structure.stories and #structure.stories > 0 then
              for _, story in ipairs(structure.stories) do
                if story.title:lower():find(current_function.name:lower()) then
                  local wrapped_lines = M.word_wrap(story.content, 60)
                  for _, wrapped_line in ipairs(wrapped_lines) do
                    table.insert(display_lines, "        " .. wrapped_line)
                  end
                  method_story_found = true
                  break
                end
              end
            end
            
            if not method_story_found then
              table.insert(display_lines, "        " .. current_function.name .. " method implementation")
            end
          end
        end
        
      table.insert(display_lines, "")
      table.insert(display_lines, "---------------------------")
      table.insert(display_lines, "## Actions")
      table.insert(display_lines, "")
      if current_function then
        table.insert(display_lines, "R - Rename method")
        table.insert(display_lines, "D - Add debug logging")
        table.insert(display_lines, "J - Generate JSDoc")
        table.insert(display_lines, "F - Find all usages")
        table.insert(display_lines, "T - Generate unit test")
        table.insert(display_lines, "E - Extract to class")
      else
        table.insert(display_lines, "(Select a method to see available actions)")
      end
      
      table.insert(display_lines, "")
      table.insert(display_lines, "---------------------------")
      table.insert(display_lines, "## Tests")
      table.insert(display_lines, "")
      
      if current_function then
        local test_info = M.get_test_coverage(current_function.name, filename)
        if test_info.covering_tests and #test_info.covering_tests > 0 then
          for _, test in ipairs(test_info.covering_tests) do
            local status_icon = test.passing and "✅" or "❌"
            table.insert(display_lines, string.format("%s %s:%d - %s", status_icon, test.file, test.line, test.name))
          end
        else
          table.insert(display_lines, "⚠️  No tests found covering this method")
        end
      else
        table.insert(display_lines, "(Select a method to see test coverage)")
      end
      
      table.insert(display_lines, "")
      table.insert(display_lines, "---------------------------")
      table.insert(display_lines, "## See also")
      table.insert(display_lines, "")
      
      if current_function then
        local similar_stories = M.get_similar_stories(current_function)
        if #similar_stories > 0 then
          for _, story in ipairs(similar_stories) do
            table.insert(display_lines, string.format("* %s (%.2f)", story.title, story.similarity))
            if story.purpose and story.purpose ~= '' then
              -- Wrap purpose text with proper indentation
              local wrapped_lines = M.word_wrap(story.purpose, 40)
              for _, wrapped_line in ipairs(wrapped_lines) do
                table.insert(display_lines, "  " .. wrapped_line)
              end
            end
          end
        else
          table.insert(display_lines, "(vector search not available)")
        end
      else
        table.insert(display_lines, "(Select a method to see related functions)")
      end
      
    else
      table.insert(display_lines, "📁 " .. basename)
      table.insert(display_lines, "  (Unsupported file type)")
    end
  end
  
  -- Validate sidebar buffer before using it
  if not sidebar_bufnr or not vim.api.nvim_buf_is_valid(sidebar_bufnr) then
    debug_log('Sidebar buffer is invalid, cannot update content')
    return
  end
  
  vim.api.nvim_buf_set_option(sidebar_bufnr, 'modifiable', true)
  vim.api.nvim_buf_set_lines(sidebar_bufnr, 0, -1, false, display_lines)
  vim.api.nvim_buf_set_option(sidebar_bufnr, 'modifiable', false)
  
  -- Position cursor on first line
  if vim.api.nvim_win_is_valid(sidebar_winid) then
    vim.api.nvim_win_set_cursor(sidebar_winid, {1, 0})
  end
end

-- Move cursor down
function M.move_down()
  if current_state == 'structure' and sidebar_bufnr and vim.api.nvim_buf_is_valid(sidebar_bufnr) and 
     sidebar_winid and vim.api.nvim_win_is_valid(sidebar_winid) then
    local line_count = vim.api.nvim_buf_line_count(sidebar_bufnr)
    local current_pos = vim.api.nvim_win_get_cursor(sidebar_winid)
    local new_line = math.min(current_pos[1] + 1, line_count)
    vim.api.nvim_win_set_cursor(sidebar_winid, {new_line, 0})
  end
end

-- Move cursor up  
function M.move_up()
  if current_state == 'structure' and sidebar_bufnr and vim.api.nvim_buf_is_valid(sidebar_bufnr) and 
     sidebar_winid and vim.api.nvim_win_is_valid(sidebar_winid) then
    local current_pos = vim.api.nvim_win_get_cursor(sidebar_winid)
    local new_line = math.max(current_pos[1] - 1, 1)
    vim.api.nvim_win_set_cursor(sidebar_winid, {new_line, 0})
  end
end

-- Enhanced navigation - <enter> should do something useful on every line
function M.select_item()
  if current_state == 'structure' and sidebar_bufnr and vim.api.nvim_buf_is_valid(sidebar_bufnr) and 
     sidebar_winid and vim.api.nvim_win_is_valid(sidebar_winid) then
    local current_pos = vim.api.nvim_win_get_cursor(sidebar_winid)
    local line = vim.api.nvim_buf_get_lines(sidebar_bufnr, current_pos[1] - 1, current_pos[1], false)[1]
    
    debug_log('Enter pressed on line: ' .. (line or 'nil'))
    
    if not line or line == '' then return end
    
    -- 1. Check for caller format: "SomeClass.method (SomeFile.js:123)"
    local file_name, line_num = line:match('%(([^:]+):(%d+)%)')
    if file_name and line_num then
      M.navigate_to_external_file(file_name, tonumber(line_num))
      return
    end
    
    -- 2. Check for story card line references: "(L123)" or "[filename:123]"
    line_num = line:match('%(L(%d+)%)')
    if not line_num then
      line_num = line:match('%[.-:(%d+)%]')
    end
    if line_num and main_bufnr then
      M.navigate_to_main_buffer_line(tonumber(line_num))
      return
    end
    
    -- 3. Check for story cards: "[[card name]]" - navigate to where story card is written
    local story_card_name = line:match('%[%[(.-)%]%]')
    if story_card_name then
      M.navigate_to_story_card_source(story_card_name)
      return
    end
    
    -- 4. Check for method names (including marked current method with **)
    local method_name = line:match('^%s*%*?%*?%s*([_%w][_%w]*)')
    if method_name and main_bufnr then
      M.navigate_to_method_definition(method_name)
      return
    end
    
    -- 5. Check for class names: "class ClassName"
    local class_name = line:match('^%s*class%s+([_%w][_%w]*)')
    if class_name and main_bufnr then
      M.navigate_to_class_definition(class_name)
      return
    end
    
    -- 6. Check for property lines: "this.property: type"
    local property_name = line:match('^%s*this%.([_%w][_%w]*):')
    if property_name and main_bufnr then
      M.navigate_to_property_assignment(property_name)
      return
    end
    
    -- 7. Check for call/action patterns: "R - Rename method"
    local action_key = line:match('^%s*([A-Z])%s*%-')
    if action_key then
      M.execute_sidebar_action(action_key)
      return
    end
    
    -- 8. Check for "see also" references with similarity scores
    local similar_story, similarity = line:match('^%s*%*%s*(.+)%s*%(([%d%.]+)%)$')
    if similar_story then
      M.navigate_to_similar_story(similar_story, similarity)
      return
    end
    
    -- 9. Check for test coverage lines: "✅ TestFile.js:123 - test description"
    -- Pattern matches the exact format from get_test_coverage display (line 1017)
    local test_match = line:match('^%s*(.-)%s*:(%d+)%s*%-%s*(.+)$')
    if test_match then
      local test_file, test_line, test_desc = line:match('^%s*(.-)%s*:(%d+)%s*%-%s*(.+)$')
      -- Check if this looks like a test file (contains common test patterns)
      if test_file and test_line and (
          test_file:match('%.test%.') or 
          test_file:match('%.spec%.') or 
          test_file:match('test') or 
          line:match('^%s*[✅❌⚠️]') -- Has test status emoji
        ) then
        debug_log('Test navigation: ' .. test_file .. ':' .. test_line)
        M.navigate_to_test_file(test_file, tonumber(test_line))
        return
      end
    end
    
    -- 10. Check for caller display lines: "ClaudeView.method (ClaudeView.js:123)"
    local caller_class, caller_method, caller_file, caller_line = line:match('^%s*(.-)%.(.-)%s+%((.-)%s*:(%d+)%)')
    if caller_class and caller_method and caller_file and caller_line then
      M.navigate_to_external_file(caller_file, tonumber(caller_line))
      return
    end
    
    -- 11. Fallback: If line contains useful text, show it or search for it
    local useful_text = line:match('^%s*(.-)%s*$') -- trim whitespace
    if useful_text and useful_text ~= '' and not useful_text:match('^%-+$') and not useful_text:match('^=+$') then
      -- If it looks like descriptive text, search for it in the current file
      if #useful_text > 10 and not useful_text:match('^#') then
        M.search_in_current_file(useful_text)
      else
        print('📋 ' .. useful_text)
      end
    end
  end
end

-- Navigate to external file and line
function M.navigate_to_external_file(file_name, line_num)
  debug_log('Navigating to external file: ' .. file_name .. ':' .. line_num)
  
  -- Try different path patterns
  local search_paths = {
    'src/content/' .. file_name,
    'src/' .. file_name,
    file_name,
    './' .. file_name
  }
  
  local file_path = nil
  for _, path in ipairs(search_paths) do
    if vim.fn.filereadable(path) == 1 then
      file_path = path
      break
    end
  end
  
  if not file_path then
    print('File not found: ' .. file_name)
    return
  end
  
  -- Find main window (not the sidebar)
  local main_win = M.find_main_window()
  if main_win then
    vim.api.nvim_set_current_win(main_win)
    vim.cmd('edit ' .. file_path)
    vim.api.nvim_win_set_cursor(0, {line_num, 0})
    vim.cmd('normal! zz')
  else
    -- Create a new split if no main window
    vim.cmd('wincmd p')
    vim.cmd('edit ' .. file_path)
    vim.api.nvim_win_set_cursor(0, {line_num, 0})
    vim.cmd('normal! zz')
  end
end

-- Navigate to line in main buffer
function M.navigate_to_main_buffer_line(line_num)
  debug_log('Navigating to main buffer line: ' .. line_num)
  
  local main_win = M.find_main_window()
  if main_win then
    vim.api.nvim_set_current_win(main_win)
    vim.api.nvim_win_set_cursor(main_win, {line_num, 0})
    vim.cmd('normal! zz')
  end
end

-- Navigate to where a story card is written in the source
function M.navigate_to_story_card_source(story_card_name)
  debug_log('Looking for story card source: ' .. story_card_name)
  
  if not main_bufnr or not vim.api.nvim_buf_is_valid(main_bufnr) then
    return
  end
  
  local main_lines = vim.api.nvim_buf_get_lines(main_bufnr, 0, -1, false)
  local clean_card_name = story_card_name:gsub('%s*card%s*$', '') -- Remove "card" suffix
  
  -- Look for story card patterns in comments
  for i, main_line in ipairs(main_lines) do
    -- Pattern 1: "* STORY CARD: CardName"
    if main_line:match('STORY CARD:%s*' .. clean_card_name) then
      M.navigate_to_main_buffer_line(i)
      return
    end
    
    -- Pattern 2: JSDoc with class/component name
    if main_line:match('%*%s*' .. clean_card_name .. '%s*$') and 
       (main_line:match('PURPOSE:') or main_line:match('INPUTS:') or main_line:match('OUTPUTS:')) then
      M.navigate_to_main_buffer_line(i)
      return
    end
    
    -- Pattern 3: Class definition line
    if main_line:match('class%s+' .. clean_card_name) or main_line:match('export%s+class%s+' .. clean_card_name) then
      M.navigate_to_main_buffer_line(i)
      return
    end
  end
  
  print('Story card source not found: ' .. story_card_name)
end

-- Navigate to method definition with enhanced pattern matching
function M.navigate_to_method_definition(method_name)
  debug_log('Navigating to method: ' .. method_name)
  
  if not main_bufnr or not vim.api.nvim_buf_is_valid(main_bufnr) then
    return
  end
  
  -- Clean up method name (remove async markers, etc.)
  local clean_method = method_name:gsub('%s*%[async%]', ''):gsub('^%*+%s*', '')
  
  local main_lines = vim.api.nvim_buf_get_lines(main_bufnr, 0, -1, false)
  local escaped_method_name = clean_method:gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])', '%%%1')
  
  for i, main_line in ipairs(main_lines) do
    local is_method_def = (
      main_line:match('^%s*async%s+' .. escaped_method_name .. '%s*%(') or  -- async methodName(
      (main_line:match('^%s+' .. escaped_method_name .. '%s*%(') and not main_line:match(':')) or  -- indented methodName(
      main_line:match('^%s*' .. escaped_method_name .. '%s*%(%s*%)%s*{') or -- methodName() {
      main_line:match('^%s*' .. escaped_method_name .. '%s*%(.-%)%s*{') -- methodName(args) {
    ) and not main_line:match('this%.' .. escaped_method_name) -- exclude this.methodName calls
    
    if is_method_def then
      debug_log('Found method definition at line: ' .. i)
      M.navigate_to_main_buffer_line(i)
      return
    end
  end
  
  print('Method definition not found: ' .. clean_method)
end

-- Navigate to class definition
function M.navigate_to_class_definition(class_name)
  debug_log('Navigating to class: ' .. class_name)
  
  if not main_bufnr or not vim.api.nvim_buf_is_valid(main_bufnr) then
    return
  end
  
  local main_lines = vim.api.nvim_buf_get_lines(main_bufnr, 0, -1, false)
  
  for i, main_line in ipairs(main_lines) do
    if main_line:match('^%s*class%s+' .. class_name) or 
       main_line:match('^%s*export%s+class%s+' .. class_name) then
      M.navigate_to_main_buffer_line(i)
      return
    end
  end
  
  print('Class definition not found: ' .. class_name)
end

-- Navigate to property assignment in constructor
function M.navigate_to_property_assignment(property_name)
  debug_log('Navigating to property: ' .. property_name)
  
  if not main_bufnr or not vim.api.nvim_buf_is_valid(main_bufnr) then
    return
  end
  
  local main_lines = vim.api.nvim_buf_get_lines(main_bufnr, 0, -1, false)
  
  for i, main_line in ipairs(main_lines) do
    if main_line:match('this%.' .. property_name .. '%s*=') then
      M.navigate_to_main_buffer_line(i)
      return
    end
  end
  
  print('Property assignment not found: ' .. property_name)
end

-- Execute sidebar action (R, D, J, F, T, E keys)
function M.execute_sidebar_action(action_key)
  debug_log('Executing sidebar action: ' .. action_key)
  
  if action_key == 'R' then
    M.agent_rename_method()
  elseif action_key == 'D' then
    M.agent_add_debug()
  elseif action_key == 'J' then
    M.agent_generate_jsdoc()
  elseif action_key == 'F' then
    M.agent_find_usages()
  elseif action_key == 'T' then
    M.agent_generate_test()
  elseif action_key == 'E' then
    M.agent_extract_class()
  else
    print('Unknown action: ' .. action_key)
  end
end

-- Search for text in current file with proper escaping
function M.search_in_current_file(search_text)
  debug_log('Searching in current file: ' .. search_text)
  
  local main_win = M.find_main_window()
  if main_win then
    vim.api.nvim_set_current_win(main_win)
    
    -- Clean and escape search text for vim search
    local clean_text = search_text:gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', '')
    
    -- Escape special regex characters for vim search
    local escaped_text = clean_text:gsub('([%^%$%(%)%%%.%[%]%*%+%-%?%\\%/])', '\\%1')
    
    -- Try search, but handle errors gracefully
    local ok, _ = pcall(function()
      vim.cmd('/' .. escaped_text)
    end)
    
    if ok then
      print('🔍 Searching: ' .. clean_text:sub(1, 40) .. (clean_text:len() > 40 and '...' or ''))
    else
      -- Fallback to simpler word search if complex search fails
      local first_word = clean_text:match('%w+')
      if first_word then
        vim.cmd('/' .. first_word)
        print('🔍 Searching (simplified): ' .. first_word)
      else
        print('⚠️ Cannot search for: ' .. clean_text:sub(1, 20) .. '...')
      end
    end
  end
end

-- Navigate to similar story by searching for it
function M.navigate_to_similar_story(story_name, similarity)
  debug_log('Navigating to similar story: ' .. story_name .. ' (similarity: ' .. similarity .. ')')
  
  -- Try to find the story in the current codebase by searching for the story name
  local search_term = story_name:gsub('%..*$', '') -- Remove file extension if present
  
  -- Search in current file first
  M.search_in_current_file(search_term)
end

-- Navigate to test file and line
function M.navigate_to_test_file(test_file, test_line)
  debug_log('Navigating to test: ' .. test_file .. ':' .. test_line)
  
  -- Clean up test file name (remove emoji and extra whitespace)
  local clean_test_file = test_file:gsub('^[✅❌⚠️%s]*', ''):gsub('%s+$', '')
  
  -- Try common test file paths relative to current directory  
  local current_dir = vim.fn.getcwd()
  local test_paths = {
    clean_test_file, -- Direct path
    'test/' .. clean_test_file,
    'tests/' .. clean_test_file,
    'tests/unit/' .. clean_test_file,
    'tests/integration/' .. clean_test_file,
    '__tests__/' .. clean_test_file,
    'spec/' .. clean_test_file,
    'src/test/' .. clean_test_file,
    'src/tests/' .. clean_test_file,
    '../test/' .. clean_test_file,
    '../tests/' .. clean_test_file,
  }
  
  -- Also try to find files with glob pattern
  local glob_pattern = '**/' .. clean_test_file
  local glob_results = vim.fn.glob(glob_pattern, false, true)
  for _, result in ipairs(glob_results) do
    table.insert(test_paths, result)
  end
  
  local found_path = nil
  for _, path in ipairs(test_paths) do
    debug_log('Checking test path: ' .. path)
    if vim.fn.filereadable(path) == 1 then
      found_path = path
      debug_log('Found test file at: ' .. path)
      break
    end
  end
  
  if found_path then
    local main_win = M.find_main_window()
    if main_win then
      vim.api.nvim_set_current_win(main_win)
      vim.cmd('edit ' .. found_path)
      vim.api.nvim_win_set_cursor(0, {test_line, 0})
      vim.cmd('normal! zz')
    end
  else
    print('❌ Test file not found: ' .. clean_test_file)
    debug_log('Searched paths: ' .. table.concat(test_paths, ', '))
  end
end

-- Helper: Find main window (not sidebar)
function M.find_main_window()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if win ~= sidebar_winid and vim.api.nvim_win_is_valid(win) then
      return win
    end
  end
  return nil
end

-- Expand story context (right arrow)
function M.expand_context()
  if current_state == 'structure' and sidebar_bufnr and vim.api.nvim_buf_is_valid(sidebar_bufnr) and 
     sidebar_winid and vim.api.nvim_win_is_valid(sidebar_winid) then
    
    local current_pos = vim.api.nvim_win_get_cursor(sidebar_winid)
    local line = vim.api.nvim_buf_get_lines(sidebar_bufnr, current_pos[1] - 1, current_pos[1], false)[1]
    
    debug_log('Expand context for line: ' .. (line or 'nil'))
    
    -- Enhanced context expansion based on current line
    if line then
      local method_name = line:match('^%s*%*?%*?%s*([_%w][_%w]*)')
      if method_name and main_bufnr then
        -- Show detailed method information
        print("📋 Method: " .. method_name)
        
        -- Search for method definition to show signature and context
        local main_lines = vim.api.nvim_buf_get_lines(main_bufnr, 0, -1, false)
        for i, main_line in ipairs(main_lines) do
          if main_line:match('%s*' .. method_name .. '%s*%(') or 
             main_line:match('%s*async%s+' .. method_name .. '%s*%(') then
            
            -- Show method signature
            local clean_line = main_line:gsub('^%s*', ''):gsub('%s*{.*', '')
            print("   Signature: " .. clean_line)
            
            -- Show next few lines as preview
            for j = 1, 3 do
              if main_lines[i + j] and main_lines[i + j]:gsub('^%s*', '') ~= '' then
                local preview = main_lines[i + j]:gsub('^%s*', '    ')
                if #preview < 60 then
                  print("   " .. preview)
                end
              end
            end
            break
          end
        end
      elseif line:match('📞.*%(.*%.js:%d+%)') then
        -- For caller lines, show the context
        local file_name, line_num = line:match('%(([^:]+):(%d+)%)')
        if file_name and line_num then
          print("📞 Caller context: " .. file_name .. ":" .. line_num)
        end
      else
        print("💡 Right arrow: Expand context | Left arrow: Fold context")
      end
    end
  end
end

-- Fold story context (left arrow)
function M.fold_context()
  if current_state == 'structure' and sidebar_bufnr and vim.api.nvim_buf_is_valid(sidebar_bufnr) and 
     sidebar_winid and vim.api.nvim_win_is_valid(sidebar_winid) then
    
    debug_log('Fold context request')
    print("Context folding - coming soon!")
  end
end

-- Reload plugin during development
function M.reload()
  package.loaded['custom.story-explorer'] = nil
  require('custom.story-explorer').setup()
  print('Story Explorer plugin reloaded!')
end

-- Software Agent Actions - Context-aware refactoring
function M.get_current_context()
  if not main_bufnr or not vim.api.nvim_buf_is_valid(main_bufnr) then
    return nil
  end
  
  local filename = vim.api.nvim_buf_get_name(main_bufnr)
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local current_line = cursor_pos[1]
  
  -- Parse the file to get current function context
  local content = table.concat(vim.api.nvim_buf_get_lines(main_bufnr, 0, -1, false), '\n')
  local structure = M.parse_js_file(content, filename)
  
  -- Find current function
  local current_function = nil
  for _, class in ipairs(structure.classes) do
    for _, method in ipairs(class.methods) do
      if current_line >= method.line and (not current_function or method.line > current_function.line) then
        current_function = {
          name = method.name,
          line = method.line,
          class_name = class.name,
          class_state = class.state
        }
      end
    end
  end
  
  return {
    filename = filename,
    current_line = current_line,
    current_function = current_function,
    structure = structure
  }
end

function M.agent_rename_method()
  local context = M.get_current_context()
  if not context or not context.current_function then
    print("No function context found")
    return
  end
  
  local old_name = context.current_function.name:gsub("%s%[async%]", "")
  local new_name = vim.fn.input("Rename '" .. old_name .. "' to: ")
  if new_name == "" then return end
  
  print("🔄 Agent: Renaming " .. old_name .. " → " .. new_name)
  print("Context: " .. context.current_function.class_name .. "." .. old_name)
  -- TODO: Implement actual rename with callgraph analysis
end

function M.agent_add_debug()
  local context = M.get_current_context()
  if not context or not context.current_function then
    print("No function context found")
    return
  end
  
  local func_name = context.current_function.name:gsub("%s%[async%]", "")
  print("🐛 Agent: Adding debug logging to " .. func_name)
  
  -- Smart debug logging based on class state
  if context.current_function.class_state then
    print("Suggested logs:")
    for _, state in ipairs(context.current_function.class_state) do
      print("  console.log('" .. func_name .. ": this." .. state.property .. "', this." .. state.property .. ")")
    end
  end
  -- TODO: Implement actual debug insertion
end

function M.agent_generate_jsdoc()
  local context = M.get_current_context()
  if not context or not context.current_function then
    print("No function context found")
    return
  end
  
  local func_name = context.current_function.name:gsub("%s%[async%]", "")
  print("📝 Agent: Generating JSDoc for " .. func_name)
  print("Context: " .. context.current_function.class_name .. " class")
  -- TODO: Implement JSDoc generation with class context
end

function M.agent_find_usages()
  local context = M.get_current_context()
  if not context or not context.current_function then
    print("No function context found")
    return
  end
  
  local func_name = context.current_function.name:gsub("%s%[async%]", "")
  print("🔍 Agent: Finding usages of " .. func_name)
  
  -- Use enhanced callgraph to find callers
  local callers = M.get_function_callers(func_name, context.filename)
  if #callers > 0 then
    print("Found " .. #callers .. " callers:")
    for _, caller in ipairs(callers) do
      print("  " .. caller.callerFile .. ":" .. caller.callerLocation .. " - " .. caller.caller)
    end
  else
    print("No callers found")
  end
end

function M.agent_generate_test()
  local context = M.get_current_context()
  if not context or not context.current_function then
    print("No function context found")
    return
  end
  
  local func_name = context.current_function.name:gsub("%s%[async%]", "")
  print("🧪 Agent: Generating test for " .. func_name)
  print("Class: " .. context.current_function.class_name)
  
  if context.current_function.class_state then
    print("Mock setup needed for:")
    for _, state in ipairs(context.current_function.class_state) do
      print("  this." .. state.property .. " (" .. state.type .. ")")
    end
  end
  -- TODO: Implement test generation with class context
end

function M.agent_extract_class()
  local context = M.get_current_context()
  if not context or not context.current_function then
    print("No function context found")
    return
  end
  
  local func_name = context.current_function.name:gsub("%s%[async%]", "")
  print("🏗️ Agent: Extract " .. func_name .. " to separate class")
  
  -- Analyze related methods that could be extracted together
  print("Analyzing related methods for extraction...")
  -- TODO: Implement class extraction analysis
end

-- Test Coverage Integration
function M.get_test_coverage(function_name, filename)
  debug_log('Getting test coverage for: ' .. function_name .. ' in ' .. filename)
  
  local test_info = {
    covering_tests = {},
    coverage = nil,
    uncovered_lines = {}
  }
  
  -- Look for Jest/Istanbul coverage files
  local coverage_paths = {
    'coverage/coverage-final.json',
    'coverage/lcov-report/index.html',
    '.nyc_output/coverage-final.json'
  }
  
  local coverage_data = nil
  for _, path in ipairs(coverage_paths) do
    if vim.fn.filereadable(path) == 1 then
      debug_log('Found coverage file: ' .. path)
      if path:match('%.json$') then
        local content = vim.fn.readfile(path)
        local json_str = table.concat(content, '\n')
        coverage_data = vim.fn.json_decode(json_str)
        break
      end
    end
  end
  
  if coverage_data then
    -- Find coverage for current file
    local file_key = filename
    for key, file_coverage in pairs(coverage_data) do
      if key:find(vim.fn.fnamemodify(filename, ':t'), 1, true) then
        file_key = key
        break
      end
    end
    
    if coverage_data[file_key] then
      local file_coverage = coverage_data[file_key]
      
      -- Calculate coverage stats
      if file_coverage.s then -- Statement coverage
        local covered = 0
        local total = 0
        for _, count in pairs(file_coverage.s) do
          total = total + 1
          if count > 0 then covered = covered + 1 end
        end
        
        test_info.coverage = {
          percentage = total > 0 and math.floor((covered / total) * 100) or 0,
          covered = covered,
          total = total
        }
      end
      
      -- Find uncovered lines
      if file_coverage.statementMap and file_coverage.s then
        for stmt_id, count in pairs(file_coverage.s) do
          if count == 0 and file_coverage.statementMap[stmt_id] then
            local line_num = file_coverage.statementMap[stmt_id].start.line
            table.insert(test_info.uncovered_lines, line_num)
          end
        end
        table.sort(test_info.uncovered_lines)
      end
    end
  end
  
  -- Look for test files that might cover this function
  local test_patterns = {
    'test/**/*.test.js',
    'tests/**/*.test.js', 
    '__tests__/**/*.js',
    '**/*.spec.js'
  }
  
  for _, pattern in ipairs(test_patterns) do
    local test_files = vim.fn.glob(pattern, false, true)
    for _, test_file in ipairs(test_files) do
      if vim.fn.filereadable(test_file) == 1 then
        local test_content = table.concat(vim.fn.readfile(test_file), '\n')
        
        -- Look for test cases that actually invoke this function
        M.find_tests_invoking_function(test_content, test_file, function_name, test_info.covering_tests)
      end
    end
  end
  
  debug_log('Found ' .. #test_info.covering_tests .. ' covering tests')
  return test_info
end

-- Find tests that actually invoke a specific function (not just mention it)
function M.find_tests_invoking_function(test_content, test_file, function_name, covering_tests)
  debug_log('Analyzing test file for actual invocations: ' .. test_file)
  
  local lines = vim.split(test_content, '\n')
  local current_test = nil
  local in_test_body = false
  local brace_count = 0
  
  for i, line in ipairs(lines) do
    -- Detect test case start: test(...) or it(...)
    local test_name = line:match('test%s*%(%s*["\']([^"\']+)["\']') or
                      line:match('it%s*%(%s*["\']([^"\']+)["\']')
    
    if test_name then
      current_test = {
        name = test_name,
        start_line = i,
        file = vim.fn.fnamemodify(test_file, ':t'),
        invokes_function = false
      }
      in_test_body = false
      brace_count = 0
    end
    
    -- Track braces to know when we're inside test body
    if current_test then
      for char in line:gmatch('.') do
        if char == '{' then
          brace_count = brace_count + 1
          if brace_count == 1 and not in_test_body then
            in_test_body = true
          end
        elseif char == '}' then
          brace_count = brace_count - 1
          if brace_count == 0 and in_test_body then
            -- Test ended - check if we found function invocation
            if current_test.invokes_function then
              table.insert(covering_tests, {
                file = current_test.file,
                line = current_test.start_line,
                name = current_test.name,
                passing = true -- TODO: Get actual test results from test runner
              })
            end
            current_test = nil
            in_test_body = false
          end
        end
      end
      
      -- Look for actual function invocations in test body
      if in_test_body and current_test then
        -- Handle constructor special case
        if function_name == 'constructor' then
          -- Extract class name from current_test.file or context
          local class_name = current_test.file:gsub('%.test%.js$', ''):gsub('%-.*$', '') -- FamilyTitle-serialization.test.js -> FamilyTitle
          
          -- Look for constructor invocations: new ClassName()
          if line:match('new%s+' .. class_name .. '%s*%(') then
            current_test.invokes_function = true
            debug_log('Found constructor invocation in test: ' .. current_test.name .. ' (new ' .. class_name .. '())')
          end
        else
          -- Pattern 1: direct method call: functionName()
          if line:match('%W' .. function_name .. '%s*%(') or line:match('^%s*' .. function_name .. '%s*%(') then
            current_test.invokes_function = true
            debug_log('Found direct invocation in test: ' .. current_test.name)
          end
          
          -- Pattern 2: object method call: obj.functionName() or this.functionName()
          if line:match('%w+%.' .. function_name .. '%s*%(') or line:match('this%.' .. function_name .. '%s*%(') then
            current_test.invokes_function = true
            debug_log('Found method invocation in test: ' .. current_test.name)
          end
          
          -- Pattern 3: spy/mock verification: expect(...).toHaveBeenCalled() patterns
          -- This covers cases where the function is called indirectly but verified
          if line:match('expect.*' .. function_name) and line:match('toHaveBeenCalled') then
            current_test.invokes_function = true
            debug_log('Found spy verification in test: ' .. current_test.name)
          end
          
          -- Pattern 4: async/await calls: await functionName()
          if line:match('await%s+' .. function_name .. '%s*%(') then
            current_test.invokes_function = true
            debug_log('Found async invocation in test: ' .. current_test.name)
          end
        end
      end
    end
  end
  
  debug_log('Found ' .. #covering_tests .. ' tests actually invoking ' .. function_name)
end

-- Test navigation pattern matching
function M.test_navigation_patterns()
  debug_log('=== TESTING NAVIGATION PATTERNS ===')
  print('Testing Story Explorer navigation patterns...')
  
  -- Test cases for various line formats
  local test_lines = {
    '✅ FamilyTitle-serialization.test.js:6 - test description',
    '❌ Mail.test.js:123 - another test',
    '⚠️  No tests found covering this method',
    '* Similar Story Name (0.85)',
    'ClaudeView.onViewMail (ClaudeView.js:45)',
    '[[ClaudeView card]]',
    'this.onViewMail: method'
  }
  
  for i, test_line in ipairs(test_lines) do
    print('Testing line ' .. i .. ': ' .. test_line)
    
    -- Test the same logic as select_item but without actions
    local similar_story, similarity = test_line:match('^%s*%*%s*(.+)%s*%(([%d%.]+)%)$')
    if similar_story then
      print('  → Similar story: ' .. similar_story)
    end
    
    local test_match = test_line:match('^%s*(.-)%s*:(%d+)%s*%-%s*(.+)$')
    if test_match then
      local test_file, test_line_num, test_desc = test_line:match('^%s*(.-)%s*:(%d+)%s*%-%s*(.+)$')
      if test_file and test_line_num and (
          test_file:match('%.test%.') or 
          test_file:match('%.spec%.') or 
          test_file:match('test') or 
          test_line:match('^%s*[✅❌⚠️]')
        ) then
        print('  → Test navigation: ' .. test_file .. ':' .. test_line_num)
      end
    end
    
    local story_card_name = test_line:match('%[%[(.-)%]%]')
    if story_card_name then
      print('  → Story card: ' .. story_card_name)
    end
  end
  
  print('Navigation pattern test complete!')
end

-- Test function for unified layout validation
function M.test_unified_layout()
  debug_log('=== TESTING UNIFIED LAYOUT ===')
  print('Testing Story Explorer unified layout...')
  
  -- Store current buffer as main buffer
  main_bufnr = vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(main_bufnr)
  print('Testing with file: ' .. filename)
  
  -- Open sidebar and show structure
  M.open_or_focus_sidebar()
  M.show_code_structure()
  print('Test complete - check sidebar for unified layout')
end

-- Get relevant story cards for current function context
function M.get_relevant_story_cards(function_name, current_file)
  debug_log('Getting relevant story cards for: ' .. function_name)
  
  -- Look for callgraph-stories.json file
  local search_dirs = {
    vim.fn.getcwd(),
    vim.fn.fnamemodify(vim.fn.getcwd(), ':h'),
    vim.fn.fnamemodify(vim.fn.getcwd(), ':h:h')
  }
  
  local stories = nil
  for _, dir in ipairs(search_dirs) do
    local stories_file = dir .. '/callgraph-stories.json'
    if vim.fn.filereadable(stories_file) == 1 then
      local content = vim.fn.readfile(stories_file)
      local json_str = table.concat(content, '\n')
      stories = vim.fn.json_decode(json_str)
      break
    end
  end
  
  if not stories then
    debug_log('Story cards file not found')
    return {}
  end
  
  local relevant_stories = {}
  local basename = vim.fn.fnamemodify(current_file, ':t')
  
  -- Filter stories relevant to current function or file
  local story_list = stories.stories or stories  -- Handle both formats
  for _, story in ipairs(story_list) do
    if story.file == basename or 
       (story.id and story.id:lower():find(function_name:lower())) or
       (story.purpose and story.purpose:lower():find(function_name:lower())) then
      table.insert(relevant_stories, story)
    end
  end
  
  debug_log('Found ' .. #relevant_stories .. ' relevant story cards')
  return relevant_stories
end

-- Enhanced call resolution with current function context
function M.resolve_call_to_class_method_enhanced(call_name, current_function, current_file)
  debug_log('Enhanced resolving call: ' .. call_name .. ' with context')
  
  -- Handle this.method calls - use current class context
  if call_name:match('^this%.') and not call_name:match('^this%._') then
    local method_name = call_name:gsub('^this%.', '')
    if current_function.class_name then
      return current_function.class_name .. '.' .. method_name
    else
      -- Fallback to file-based class name
      local file_class = vim.fn.fnamemodify(current_file, ':t:r')
      return file_class .. '.' .. method_name
    end
  end
  
  -- Handle this._privateProperty.method calls - these need special resolution
  if call_name:match('^this%._') then
    local property_and_method = call_name:gsub('^this%.', '')
    
    -- Pattern: this._view.onNewMail -> ClaudeView.onNewMail
    -- Pattern: this._familyClient.sendMail -> FamilyClient.sendMail
    local property, method = property_and_method:match('^_([^%.]+)%.(.+)$')
    if property and method then
      -- Try to resolve property type from constructor assignments or imports
      local resolved_class = M.resolve_property_to_class(property, current_file)
      if resolved_class then
        return resolved_class .. '.' .. method
      else
        -- Fallback: capitalize property name as class name
        local guessed_class = property:gsub('^.', string.upper):gsub('([a-z])([A-Z])', '%1%2')
        return guessed_class .. '.' .. method
      end
    else
      -- Simple private method call
      if current_function.class_name then
        return current_function.class_name .. '.' .. property_and_method
      else
        local file_class = vim.fn.fnamemodify(current_file, ':t:r')
        return file_class .. '.' .. property_and_method
      end
    end
  end
  
  -- Handle direct method calls - look them up in enhanced callgraph
  local enhanced_callgraph = M.get_enhanced_callgraph()
  if enhanced_callgraph then
    for _, call_entry in ipairs(enhanced_callgraph) do
      if call_entry.callName == call_name then
        -- Found a match - extract class information
        if call_entry.targetClass and call_entry.targetClass ~= '' then
          return call_entry.targetClass .. '.' .. call_name
        elseif call_entry.targetFile then
          -- Use target file name as class if no explicit class
          local target_class = call_entry.targetFile:gsub('%.js$', '')
          return target_class .. '.' .. call_name
        end
      end
    end
  end
  
  -- Fallback to original resolution method
  return M.resolve_call_to_class_method(call_name, current_file)
end

-- Helper: Resolve property name to class name by looking at constructor or imports
function M.resolve_property_to_class(property_name, current_file)
  if not main_bufnr or not vim.api.nvim_buf_is_valid(main_bufnr) then
    return nil
  end
  
  local main_lines = vim.api.nvim_buf_get_lines(main_bufnr, 0, -1, false)
  
  -- Look for constructor assignment: this._view = new ClaudeView(...)
  for _, line in ipairs(main_lines) do
    local class_name = line:match('this%._' .. property_name .. '%s*=%s*new%s+([%w_]+)')
    if class_name then
      debug_log('Resolved property ' .. property_name .. ' to class ' .. class_name .. ' via constructor')
      return class_name
    end
  end
  
  -- Look for import statements: import { ClaudeView } from './ClaudeView.js';
  local property_variants = {
    property_name,
    property_name:gsub('^.', string.upper), -- view -> View  
    property_name:gsub('([a-z])([A-Z])', '%1%2') -- autoModeManager -> AutoModeManager
  }
  
  for _, line in ipairs(main_lines) do
    if line:match('^import') then
      for _, variant in ipairs(property_variants) do
        -- Check if class name appears in import
        local class_from_import = line:match('import%s*{[^}]*(%w*' .. variant .. '%w*)[^}]*}')
        if class_from_import then
          debug_log('Resolved property ' .. property_name .. ' to class ' .. class_from_import .. ' via import')
          return class_from_import
        end
      end
    end
  end
  
  -- Fallback: heuristic transformation
  -- _view -> ClaudeView, _familyClient -> FamilyClient, _autoModeManager -> AutoModeManager
  local heuristic_class = property_name:gsub('^.', string.upper):gsub('([a-z])([A-Z])', '%1%2')
  if heuristic_class ~= property_name then
    debug_log('Resolved property ' .. property_name .. ' to class ' .. heuristic_class .. ' via heuristic')
    return heuristic_class
  end
  
  return nil
end

-- Helper to get enhanced callgraph data
function M.get_enhanced_callgraph()
  local search_dirs = {
    vim.fn.getcwd(),
    vim.fn.fnamemodify(vim.fn.getcwd(), ':h'),
    vim.fn.fnamemodify(vim.fn.getcwd(), ':h:h')
  }
  
  for _, dir in ipairs(search_dirs) do
    local callgraph_file = dir .. '/enhanced-callgraph-complete.json'
    if vim.fn.filereadable(callgraph_file) == 1 then
      local content = vim.fn.readfile(callgraph_file)
      local json_str = table.concat(content, '\n')
      local ok, callgraph_data = pcall(vim.fn.json_decode, json_str)
      if ok then
        return callgraph_data
      end
    end
  end
  return nil
end

-- Original resolve call name to Class.method format using enhanced callgraph
function M.resolve_call_to_class_method(call_name, current_file)
  debug_log('Resolving call: ' .. call_name .. ' to Class.method format')
  
  -- Look for enhanced callgraph file
  local search_dirs = {
    vim.fn.getcwd(),
    vim.fn.fnamemodify(vim.fn.getcwd(), ':h'),
    vim.fn.fnamemodify(vim.fn.getcwd(), ':h:h')
  }
  
  local enhanced_callgraph = nil
  for _, dir in ipairs(search_dirs) do
    local callgraph_file = dir .. '/enhanced-callgraph-complete.json'
    if vim.fn.filereadable(callgraph_file) == 1 then
      local content = vim.fn.readfile(callgraph_file)
      local json_str = table.concat(content, '\n')
      enhanced_callgraph = vim.fn.json_decode(json_str)
      break
    end
  end
  
  if not enhanced_callgraph then
    debug_log('Enhanced callgraph not found, returning raw call name')
    return call_name
  end
  
  -- Look for this call in the enhanced callgraph to get type information
  for _, call_entry in ipairs(enhanced_callgraph) do
    if call_entry.callName == call_name then
      -- Found a match - extract class information
      if call_entry.targetClass and call_entry.targetClass ~= '' then
        return call_entry.targetClass .. "." .. call_name
      elseif call_entry.callerFile then
        -- Use file name as class if no explicit class
        local file_class = call_entry.callerFile:gsub('%.js$', '')
        return file_class .. "." .. call_name
      end
    end
  end
  
  -- No enhanced info found, return raw call name
  return call_name
end

-- Get function callers using enhanced callgraph with type resolution
function M.get_function_callers(function_name, current_file)
  debug_log('Getting enhanced callers for function: ' .. function_name)
  
  -- Look for enhanced callgraph file
  local search_dirs = {
    vim.fn.getcwd(),
    vim.fn.fnamemodify(vim.fn.getcwd(), ':h'),
    vim.fn.fnamemodify(vim.fn.getcwd(), ':h:h')
  }
  
  local enhanced_callgraph = nil
  for _, dir in ipairs(search_dirs) do
    local callgraph_file = dir .. '/enhanced-callgraph-complete.json'
    if vim.fn.filereadable(callgraph_file) == 1 then
      enhanced_callgraph = callgraph_file
      debug_log('Found enhanced callgraph: ' .. callgraph_file)
      break
    end
  end
  
  if not enhanced_callgraph then
    debug_log('No enhanced callgraph found, falling back to original')
    return M.get_function_callers_legacy(function_name, current_file)
  end
  
  -- Load and parse enhanced callgraph
  local callgraph_content = vim.fn.readfile(enhanced_callgraph)
  local callgraph_json = table.concat(callgraph_content, '\n')
  
  -- Parse JSON (simple Lua approach)
  local ok, callgraph_data = pcall(vim.fn.json_decode, callgraph_json)
  if not ok then
    debug_log('Failed to parse enhanced callgraph JSON')
    return {}
  end
  
  -- Find callers for this function from callIndex
  -- Look for calls TO this function (not FROM this function)
  local current_class = current_file:gsub('%.js$', '')
  local target_patterns = {
    current_class .. '.' .. function_name,  -- ClassName.method
    'this.' .. function_name,               -- this.method (internal calls)
  }
  
  local callers = {}
  if callgraph_data.callIndex then
    for target, calls in pairs(callgraph_data.callIndex) do
      -- Check if this target matches our function
      local matches = false
      for _, pattern in ipairs(target_patterns) do
        if target == pattern or target:find(pattern, 1, true) then
          matches = true
          break
        end
      end
      
      if matches then
        debug_log('Found callers of ' .. target .. ': ' .. #calls .. ' calls')
        
        -- Add callers (include internal calls if they show method context)
        for _, call in ipairs(calls) do
          if #callers < 8 then
            table.insert(callers, {
              caller = call.caller,
              callerFile = call.callerFile,
              callerLocation = call.callerLine,
              target = target,
              context = call.context and call.context:sub(1, 60) or ''
            })
          end
        end
      end
    end
  end
  
  debug_log('Found ' .. #callers .. ' enhanced callers for ' .. function_name)
  return callers
end

-- Legacy callgraph fallback
function M.get_function_callers_legacy(function_name, current_file)
  -- Original implementation as fallback
  debug_log('Using legacy callgraph for: ' .. function_name)
  return {}  -- Simplified for now
end

-- Get semantically similar stories using vector search
function M.get_similar_stories(current_function)
  if not current_function or not current_function.name then
    return {}
  end
  
  debug_log('Getting similar stories for function: ' .. current_function.name)
  
  -- Get chrome extension directory (look for story-vectors.json)
  local search_dirs = {
    vim.fn.getcwd(),
    vim.fn.fnamemodify(vim.fn.getcwd(), ':h'),
    vim.fn.fnamemodify(vim.fn.getcwd(), ':h:h')
  }
  
  local chrome_ext_dir = nil
  for _, dir in ipairs(search_dirs) do
    local vector_file = dir .. '/story-vectors.json'
    if vim.fn.filereadable(vector_file) == 1 then
      chrome_ext_dir = dir
      debug_log('Found vector database at: ' .. vector_file)
      break
    end
  end
  
  if not chrome_ext_dir then
    debug_log('No vector database found')
    return {}
  end
  
  -- Prepare search query from current context
  local query_parts = {}
  
  -- Use function name (cleaned) and add semantic context
  local clean_name = current_function.name:gsub('%s%[async%]', ''):gsub('_+', ' ')
  table.insert(query_parts, clean_name)
  
  -- Add semantic context for common method patterns
  if clean_name:find('stop') then
    table.insert(query_parts, 'cleanup shutdown service management lifecycle')
  elseif clean_name:find('start') then
    table.insert(query_parts, 'initialization setup service startup lifecycle')
  elseif clean_name:find('send') or clean_name:find('mail') then
    table.insert(query_parts, 'communication message delivery mail')
  end
  
  -- Use function documentation if available
  if current_function.doc and current_function.doc ~= '' then
    table.insert(query_parts, current_function.doc)
  end
  
  local query = table.concat(query_parts, ' ')
  debug_log('Search query: ' .. query)
  
  if query == '' then
    return {}
  end
  
  -- Run Python search script
  local search_script = chrome_ext_dir .. '/search-stories.py'
  if vim.fn.filereadable(search_script) ~= 1 then
    debug_log('Search script not found: ' .. search_script)
    return {}
  end
  
  local cmd = {'python3', search_script, query}
  debug_log('Running: ' .. table.concat(cmd, ' '))
  
  local result = vim.fn.system(cmd)
  
  if vim.v.shell_error ~= 0 then
    debug_log('Search command failed: ' .. result)
    return {}
  end
  
  -- Parse the search results (simplified parsing)
  local similar_stories = {}
  local current_story = nil
  
  for line in result:gmatch('[^\r\n]+') do
    -- Match result header: "1. 📝 Story Name (similarity: 0.648)"
    local story_name, similarity = line:match('📝 (.+) %(similarity: ([%d%.]+)%)')
    if story_name and similarity then
      -- Skip the current function itself
      if not story_name:find(current_function.name:gsub('%s%[async%]', ''), 1, true) then
        current_story = {
          title = story_name,
          similarity = tonumber(similarity),
          purpose = ''
        }
      else
        current_story = nil
      end
    elseif current_story then
      -- Parse purpose
      local purpose = line:match('🎯 Purpose: (.+)')
      if purpose then
        current_story.purpose = purpose
        table.insert(similar_stories, current_story)
        current_story = nil
      end
    end
  end
  
  -- Return top 2 results to keep sidebar manageable
  local limited_results = {}
  for i = 1, math.min(#similar_stories, 2) do
    table.insert(limited_results, similar_stories[i])
  end
  
  debug_log('Found ' .. #limited_results .. ' similar stories')
  return limited_results
end

-- Get story cards relevant to current function
function M.get_relevant_stories(all_stories, current_function)
  if not current_function or not all_stories then
    return all_stories or {}  -- Show all if no current function
  end
  
  local relevant = {}
  local function_name = current_function.name:gsub('%s%[async%]', '')
  
  for _, story in ipairs(all_stories) do
    -- Check if story title mentions current function
    if story.title:find(function_name, 1, true) then
      table.insert(relevant, story)
    -- Also check for broader relevance (same class methods)
    elseif story.title:find('App%.', 1, true) and function_name ~= 'constructor' then
      table.insert(relevant, story)
    end
  end
  
  -- If no specific relevance found, show all stories for context
  if #relevant == 0 then
    return all_stories
  end
  
  return relevant
end

-- Test callgraph integration
function M.test_callgraph()
  print('Testing callgraph integration...')
  
  -- Test with a known method that has callers
  local test_functions = {'beginTransaction', 'start', 'toJSON'}
  
  for _, func_name in ipairs(test_functions) do
    print('Testing callers for: ' .. func_name)
    local callers = M.get_function_callers(func_name, 'test.js')
    
    if #callers > 0 then
      print('  Found ' .. #callers .. ' callers:')
      for _, caller in ipairs(callers) do
        print('    - ' .. caller.caller .. ' (' .. caller.callerFile .. ':' .. caller.callerLocation .. ')')
      end
    else
      print('  No callers found')
    end
    print('')
  end
  
  print('Callgraph test complete!')
end

-- Find which function contains the current cursor position
function M.find_current_function(cursor_line, all_functions)
  local current_function = nil
  for _, func in ipairs(all_functions) do
    if cursor_line >= func.line then
      -- Find if there's a function closer to cursor line
      if not current_function or func.line > current_function.line then
        -- Check if cursor is before the next function (or at end of file)
        local is_before_next_function = true
        for _, next_func in ipairs(all_functions) do
          if next_func.line > func.line and cursor_line >= next_func.line then
            is_before_next_function = false
            break
          end
        end
        if is_before_next_function then
          current_function = func
        end
      end
    end
  end
  return current_function
end

-- Auto-update sidebar when cursor moves or buffer changes
function M.auto_update_sidebar()
  -- Only update if sidebar is open and visible
  if sidebar_winid and vim.api.nvim_win_is_valid(sidebar_winid) and 
     sidebar_bufnr and vim.api.nvim_buf_is_valid(sidebar_bufnr) then
    local current_buf = vim.api.nvim_get_current_buf()
    
    -- Check if we switched to a different buffer
    if current_buf ~= main_bufnr and current_buf ~= sidebar_bufnr then
      debug_log('Buffer changed from ' .. (main_bufnr or 'nil') .. ' to ' .. current_buf)
      main_bufnr = current_buf
      M.show_code_structure()
    elseif current_buf == main_bufnr then
      -- Same buffer, just refresh (for cursor position changes later)
      M.show_code_structure()
    end
  end
end

-- Setup function to be called from init
function M.setup()
  -- Create the main keybinding - opens or focuses sidebar
  vim.keymap.set('n', '<leader>\\', '<cmd>lua require("custom.story-explorer").open_or_focus_sidebar()<CR>', 
    { noremap = true, silent = true, desc = 'Open/Focus Story Explorer' })
    
  -- Development reload keybinding
  vim.keymap.set('n', '<leader>rr', '<cmd>lua require("custom.story-explorer").reload()<CR>',
    { noremap = true, silent = true, desc = 'Reload Story Explorer' })
  
  -- Test command for the unified layout  
  vim.keymap.set('n', '<leader>st', '<cmd>lua require("custom.story-explorer").test_unified_layout()<CR>',
    { noremap = true, silent = true, desc = 'Test Story Explorer Unified Layout' })
  
  -- Test command for callgraph integration
  vim.keymap.set('n', '<leader>sc', '<cmd>lua require("custom.story-explorer").test_callgraph()<CR>',
    { noremap = true, silent = true, desc = 'Test Callgraph Integration' })
  
  -- Test command for navigation patterns
  vim.keymap.set('n', '<leader>sn', '<cmd>lua require("custom.story-explorer").test_navigation_patterns()<CR>',
    { noremap = true, silent = true, desc = 'Test Navigation Patterns' })
  
  -- Set up autocommands for live updates
  vim.api.nvim_create_augroup('StoryExplorerAuto', { clear = true })
  
  -- Update when buffer changes
  vim.api.nvim_create_autocmd('BufEnter', {
    group = 'StoryExplorerAuto',
    callback = function()
      debug_log('BufEnter triggered')
      M.auto_update_sidebar()
    end,
  })
  
  -- Update when cursor moves (throttled to avoid too many updates)
  local cursor_timer = nil
  vim.api.nvim_create_autocmd('CursorMoved', {
    group = 'StoryExplorerAuto',
    callback = function()
      -- Debounce cursor movements - only update after 500ms of no movement
      if cursor_timer then
        cursor_timer:stop()
      end
      cursor_timer = vim.loop.new_timer()
      local timer_ref = cursor_timer  -- Capture reference locally
      cursor_timer:start(500, 0, vim.schedule_wrap(function()
        debug_log('CursorMoved update triggered')
        M.auto_update_sidebar()
        if timer_ref and not timer_ref:is_closing() then
          timer_ref:close()
        end
        if cursor_timer == timer_ref then
          cursor_timer = nil
        end
      end))
    end,
  })
end

-- Buffer protection using simpler BufEnter approach with flash correction
function M.setup_buffer_protection()
  vim.api.nvim_create_autocmd('BufEnter', {
    group = vim.api.nvim_create_augroup('StoryExplorerProtection', { clear = true }),
    callback = function()
      debug_log('BufEnter triggered - checking for buffer override')
      M.prevent_buffer_override()
    end
  })
end

-- Prevent buffer override - check if wrong buffer loaded in sidebar window  
function M.prevent_buffer_override()
  -- Early exit if sidebar not valid
  if not sidebar_winid or not vim.api.nvim_win_is_valid(sidebar_winid) or
     not sidebar_bufnr or not vim.api.nvim_buf_is_valid(sidebar_bufnr) then
    debug_log('Sidebar not valid for protection check')
    return
  end
  
  local current_win = vim.api.nvim_get_current_win()
  local current_buf = vim.api.nvim_win_get_buf(current_win)
  local buf_name = vim.api.nvim_buf_get_name(current_buf)
  
  debug_log('Protection check: current_win=' .. current_win .. ' sidebar_winid=' .. (sidebar_winid or 'nil') .. 
           ' current_buf=' .. current_buf .. ' sidebar_bufnr=' .. (sidebar_bufnr or 'nil') .. 
           ' buf_name=' .. buf_name)
  
  -- If we're in the sidebar window but with the wrong buffer
  if current_win == sidebar_winid and current_buf ~= sidebar_bufnr then
    -- Skip empty buffers or already correct buffers
    if buf_name == '' or buf_name:match('story%-explorer') then
      debug_log('Skipping empty or story-explorer buffer')
      return
    end
    
    debug_log('Buffer override detected in sidebar: ' .. buf_name)
    
    -- Schedule the fix to avoid autocmd recursion
    vim.schedule(function()
      -- Remove window fix constraints
      pcall(function() vim.cmd('setlocal nowinfixwidth') end)
      pcall(function() vim.cmd('setlocal nowinfixheight') end)
      
      -- Find a main window for the intruding buffer  
      local main_win = nil
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if win ~= sidebar_winid and vim.api.nvim_win_is_valid(win) then
          main_win = win
          break
        end
      end
      
      if main_win then
        -- Move to main window and show buffer there
        vim.api.nvim_set_current_win(main_win)
        vim.api.nvim_win_set_buf(main_win, current_buf)
        debug_log('Moved buffer to existing main window: ' .. main_win)
      else
        -- Create new window for the buffer
        vim.cmd('split')
        vim.api.nvim_win_set_buf(vim.api.nvim_get_current_win(), current_buf)
        debug_log('Created new window for buffer')
      end
      
      -- Restore sidebar buffer to sidebar window
      if sidebar_winid and vim.api.nvim_win_is_valid(sidebar_winid) and
         sidebar_bufnr and vim.api.nvim_buf_is_valid(sidebar_bufnr) then
        vim.api.nvim_win_set_buf(sidebar_winid, sidebar_bufnr)
        debug_log('Restored sidebar buffer to sidebar window')
      end
      
      debug_log('Buffer override corrected - moved ' .. buf_name .. ' to proper window')
    end)
  else
    debug_log('No buffer override detected')
  end
end

-- Right arrow: expand/reveal story context  
function M.expand_context()
  debug_log('expand_context() called')
  local line = vim.api.nvim_get_current_line()
  
  -- If on a story card line, expand it
  if line:match('%[%[.*card%]%]') then
    print('Expanding story context...')
    -- TODO: Implement inline story expansion
  else
    print('Navigate to expand story context')
  end
end

-- Left arrow: fold/collapse context
function M.fold_context()
  debug_log('fold_context() called')
  print('Collapsing story context...')
  -- TODO: Implement inline story folding  
end

return M