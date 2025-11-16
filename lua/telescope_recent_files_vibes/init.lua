-- telescope_recent_files_vibes/init.lua
-- Main implementation for telescope-recent-files-vibes.nvim

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local Path = require("plenary.path")

local M = {}
local search_history = {}
local MAX_HISTORY = 50
local history_file = vim.fn.stdpath("data") .. "/telescope_recent_files_vibes_history.json"

local path_by_pwd = {}
local path_file = vim.fn.stdpath("data") .. "/telescope_recent_files_vibes_paths.json"

local ALL_FILES_MARKER = "__ALL_FILES__"

-- Load history from disk
local function load_history()
  local f = io.open(history_file, "r")
  if f then
    local content = f:read("*all")
    f:close()
    local ok, decoded = pcall(vim.json.decode, content)
    if ok and type(decoded) == "table" then
      search_history = decoded
      while #search_history > MAX_HISTORY do
        table.remove(search_history)
      end
    end
  end
end

-- Save history to disk
local function save_history()
  local f = io.open(history_file, "w")
  if f then
    f:write(vim.json.encode(search_history))
    f:close()
  end
end

-- Load path selections from disk
local function load_paths()
  local f = io.open(path_file, "r")
  if f then
    local content = f:read("*all")
    f:close()
    local ok, decoded = pcall(vim.json.decode, content)
    if ok and type(decoded) == "table" then
      path_by_pwd = decoded
    end
  end
end

-- Save path selections to disk
local function save_paths()
  local f = io.open(path_file, "w")
  if f then
    f:write(vim.json.encode(path_by_pwd))
    f:close()
  end
end

-- Add search query to history
local function add_to_history(query)
  if not query or query == "" then
    return
  end

  for i, q in ipairs(search_history) do
    if q == query then
      table.remove(search_history, i)
      break
    end
  end

  table.insert(search_history, 1, query)

  while #search_history > MAX_HISTORY do
    table.remove(search_history)
  end

  save_history()
end

-- Initialize history and paths on module load
load_history()
load_paths()

-- Show search history picker
local function show_history(current_picker, original_opts)
  if #search_history == 0 then
    vim.notify("No search history available", vim.log.levels.INFO)
    return
  end

  local history_picker = pickers.new({}, {
    prompt_title = "Search History (Last 50) | <Enter> Search Again | <Esc> Back",
    finder = finders.new_table({
      results = search_history,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry,
          ordinal = entry,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    layout_strategy = 'horizontal',
    layout_config = {
      horizontal = {
        preview_width = 0.5,
        results_width = 0.5,
      },
      width = 0.95,
      height = 0.95,
    },
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selection then
          M.recent_files(vim.tbl_extend("force", original_opts or {}, {
            default_text = selection.value
          }))
        end
      end)

      map("i", "<Esc>", function()
        actions.close(prompt_bufnr)
        M.recent_files(original_opts)
      end)

      map("n", "<Esc>", function()
        actions.close(prompt_bufnr)
        M.recent_files(original_opts)
      end)

      return true
    end,
  })

  actions.close(current_picker)
  history_picker:find()
end

-- Show path picker to select search scope
local function show_path_picker(current_picker, original_opts)
  local root_cwd = vim.loop.cwd()

  -- Get directories using fd
  local handle = io.popen('fd --type d --hidden --exclude .git --exclude node_modules . "' .. root_cwd .. '"')
  local result = handle:read("*a")
  handle:close()

  local dirs = {}
  for dir in result:gmatch("[^\r\n]+") do
    table.insert(dirs, dir)
  end

  table.insert(dirs, 1, root_cwd)
  table.insert(dirs, 1, ALL_FILES_MARKER)

  local path_picker = pickers.new({}, {
    prompt_title = "Select Path to Filter Recent Files | Fuzzy search enabled | <Enter> Select | <Esc> Back",
    finder = finders.new_table({
      results = dirs,
      entry_maker = function(entry)
        local display
        local ordinal

        if entry == ALL_FILES_MARKER then
          display = "[ALL] * (all recent files, everywhere)"
          ordinal = "all"
        elseif entry == root_cwd then
          display = "[CWD] . (current working directory)"
          ordinal = "cwd"
        else
          local relative = Path:new(entry):make_relative(root_cwd)
          display = relative == "" and "." or relative
          ordinal = relative
        end

        return {
          value = entry,
          display = display,
          ordinal = ordinal,
          path = entry,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    layout_strategy = 'horizontal',
    layout_config = {
      horizontal = {
        preview_width = 0.5,
        results_width = 0.5,
      },
      width = 0.95,
      height = 0.95,
    },
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selection then
          if selection.value == ALL_FILES_MARKER then
            path_by_pwd[root_cwd] = nil
          else
            path_by_pwd[root_cwd] = selection.value
          end
          save_paths()

          M.recent_files({ filter_path = selection.value == ALL_FILES_MARKER and nil or selection.value })
        end
      end)

      map("i", "<Esc>", function()
        actions.close(prompt_bufnr)
        M.recent_files(original_opts)
      end)

      map("n", "<Esc>", function()
        actions.close(prompt_bufnr)
        M.recent_files(original_opts)
      end)

      return true
    end,
  })

  actions.close(current_picker)
  path_picker:find()
end

-- Main recent files function
function M.recent_files(opts)
  opts = opts or {}
  local root_cwd = vim.loop.cwd()

  if opts.filter_path == nil and path_by_pwd[root_cwd] then
    opts.filter_path = path_by_pwd[root_cwd]
  end

  local filter_path = opts.filter_path

  local title = "Recent Files (All) | <C-S-P> Path Filter | <C-j/k> Search History"
  if filter_path then
    if filter_path == root_cwd then
      title = "Recent Files [CWD] | <C-S-P> Path Filter | <C-j/k> Search History"
    else
      local relative = Path:new(filter_path):make_relative(root_cwd)
      title = "Recent Files [" ..
          (relative == "" and "." or relative) .. "] | <C-S-P> Path Filter | <C-j/k> Search History"
    end
  end

  local recent_opts = {
    prompt_title = title,
    default_text = opts.default_text,
    layout_strategy = 'horizontal',
    layout_config = {
      horizontal = {
        preview_width = 0.5,
        results_width = 0.5,
      },
      width = 0.95,
      height = 0.95,
    },
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local query = picker:_get_prompt()

        actions.close(prompt_bufnr)

        if selection then
          add_to_history(query)
          local filepath = selection.path or selection.value
          vim.cmd("edit " .. vim.fn.fnameescape(filepath))
        end
      end)

      map("i", "<C-S-P>", function()
        show_path_picker(prompt_bufnr, opts)
      end)

      map("n", "<C-S-P>", function()
        show_path_picker(prompt_bufnr, opts)
      end)

      map("i", "<C-j>", function()
        show_history(prompt_bufnr, opts)
      end)

      map("n", "<C-j>", function()
        show_history(prompt_bufnr, opts)
      end)

      map("i", "<C-k>", function()
        show_history(prompt_bufnr, opts)
      end)

      map("n", "<C-k>", function()
        show_history(prompt_bufnr, opts)
      end)

      return true
    end,
  }

  if filter_path then
    local oldfiles = vim.v.oldfiles or {}
    local filtered_files = {}

    for _, file in ipairs(oldfiles) do
      if vim.startswith(file, filter_path) then
        table.insert(filtered_files, file)
      end
    end

    local custom_picker = pickers.new(recent_opts, {
      prompt_title = title,
      finder = finders.new_table({
        results = filtered_files,
        entry_maker = function(entry)
          return require('telescope.make_entry').gen_from_file()(entry)
        end,
      }),
      sorter = conf.file_sorter({}),
      previewer = conf.file_previewer({}),
    })

    custom_picker:find()
  else
    local builtin = require('telescope.builtin')
    builtin.oldfiles(recent_opts)
  end
end

return M
