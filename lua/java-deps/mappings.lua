local config = require("java-deps.config")
local M = {}

---@param view View
M.init_mappings = function(view)
  vim.keymap.set("n", "h", function() end, { noremap = true, silent = true, buffer = view.bufnr })
  vim.keymap.set("n", "l", function() end, { noremap = true, silent = true, buffer = view.bufnr })
  vim.keymap.set("n", config.options.keymaps.toggle_fold or "o", function()
    view:foldToggle()
  end, { noremap = true, silent = true, buffer = view.bufnr })

  vim.keymap.set("n", config.options.keymaps.close or "q", function()
    view:close()
  end, { noremap = true, silent = true, buffer = view.bufnr })
end

return M
