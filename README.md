# telescope-recent-files-vibes.nvim

A Telescope extension that enhances recent file navigation with path scoping and search history.

## ✨ Features

- 🎯 **Path Scoping** - Filter by all files, current directory, or subdirectories
- 📝 **Search History** - Last 50 searches saved and searchable
- 💾 **Persistent Preferences** - Remembers your path selection per project
- ⚡ **Fast Fuzzy Finding** - Powered by Telescope and fzf

Perfect for monorepos where you want to scope recent files to just the service you're working on!

## 📦 Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
  "ALPHAvibe/telescope-recent-files-vibes.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("telescope").load_extension("recent_files_vibes")
  end,
  keys = {
    {
      "<leader>fr",
      function()
        require("telescope").extensions.recent_files_vibes.recent_files_vibes()
      end,
      desc = "Recent Files (Vibes)",
    },
  },
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)
```lua
use {
  "ALPHAvibe/telescope-recent-files-vibes.nvim",
  requires = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("telescope").load_extension("recent_files_vibes")
  end
}
```

## 🚀 Usage

### Command
```vim
:Telescope recent_files_vibes
```

### Lua
```lua
require("telescope").extensions.recent_files_vibes.recent_files_vibes()
```

### Keybindings

Inside the picker:

- `<C-p>` - Open path filter picker
- `<C-j>` or `<C-k>` - Open search history
- `<Enter>` - Open file and save search to history
- `<Esc>` - Close picker or go back to previous picker

## 🎯 Path Filtering

Press `<C-p>` to filter recent files by:

- **[ALL]** - All recent files from everywhere (default)
- **[CWD]** - Current working directory only
- **Subdirectories** - Any folder within your project

Your selection is saved per project and persists across sessions!

## 📝 Search History

Press `<C-j>` or `<C-k>` to see your last 50 searches. Select one to instantly search again with that query.

## 💾 Persistent Storage

- Search history persists across Neovim sessions
- Path preferences are saved per working directory
- Data stored in `vim.fn.stdpath("data")`

## 📋 Requirements

- Neovim >= 0.9.0
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- `fd` - for fast directory scanning ([install guide](https://github.com/sharkdp/fd#installation))

## 🎨 Integration Examples

### With [snacks.nvim](https://github.com/folke/snacks.nvim) Dashboard
```lua
{
  icon = " ",
  key = "r",
  desc = "Recent Files",
  action = function()
    require("telescope").load_extension("recent_files_vibes")
    require("telescope").extensions.recent_files_vibes.recent_files_vibes()
  end,
}
```

### Custom Keybinding
```lua
vim.keymap.set("n", "<leader>fr", function()
  require("telescope").extensions.recent_files_vibes.recent_files_vibes()
end, { desc = "Recent Files (Vibes)" })
```


## 📄 License

MIT

