return {
  {
    "sainnhe/everforest",
    lazy = false,
    priority = 1000,
    config = function()
      -- Enable transparency
      -- 1 = normal transparency, 2 = more UI components transparent (statusline, etc.)
      vim.g.everforest_transparent_background = 2

      -- Optional tweaks
      vim.g.everforest_background = "medium" -- or "medium", "hard"
      vim.g.everforest_enable_italic = true
      vim.g.everforest_better_performance = 1

      -- Apply colorscheme
      vim.cmd.colorscheme "everforest"
    end,
  },
}
