vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight copied text",
  callback = function()
    vim.highlight.on_yank()
  end,
})
