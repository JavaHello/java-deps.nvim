local M = {}

---@param view View
M.init_mappings = function(view)
  vim.keymap.set("n", "h", function() end, { noremap = true, silent = true, buffer = view.bufnr })
  vim.keymap.set("n", "l", function() end, { noremap = true, silent = true, buffer = view.bufnr })
end

return M
