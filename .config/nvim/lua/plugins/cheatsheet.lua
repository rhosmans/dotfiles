-- Searchable cheatsheet of Vim and plugin keybindings (Telescope picker).
-- Open with <leader>s? or :Cheatsheet; add your own cheats with :CheatsheetEdit
-- (saved to ~/.config/nvim/cheatsheet.txt). The plugin's default <leader>? is
-- left to LazyVim, which uses it for which-key's buffer keymaps.
return {
  "sudormrfbin/cheatsheet.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
  },
  cmd = { "Cheatsheet", "CheatsheetEdit" },
  keys = {
    { "<leader>s?", "<cmd>Cheatsheet<cr>", desc = "Cheatsheet" },
  },
  opts = {},
}
