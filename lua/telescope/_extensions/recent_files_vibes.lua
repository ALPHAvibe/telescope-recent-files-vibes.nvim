-- telescope/_extensions/recent_files_vibes.lua
-- Extension loader for telescope-recent-files-vibes.nvim

local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  error("telescope-recent-files-vibes.nvim requires telescope.nvim - https://github.com/nvim-telescope/telescope.nvim")
end

return telescope.register_extension({
  setup = function(ext_config, config)
    -- Extension configuration can go here if needed in the future
    -- For now, the extension works with defaults
  end,
  exports = {
    -- Export the main function
    recent_files_vibes = require("telescope_recent_files_vibes").recent_files,
  },
})
