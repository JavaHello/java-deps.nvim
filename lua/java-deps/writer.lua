local parser = require("java-deps.parser")
local highlight = require("java-deps.highlight")

local M = {}

local function is_buffer_outline(bufnr)
  local isValid = vim.api.nvim_buf_is_valid(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
  return string.match(name, "JavaProjects") ~= nil and ft == "JavaProjects" and isValid
end

function M.write_outline(bufnr, lines)
  if not is_buffer_outline(bufnr) then
    return
  end
  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
end

---@param bufnr integer
---@param flattened_outline_items TreeItem
function M.parse_and_write(bufnr, flattened_outline_items)
  local lines, hl_info = parser.get_lines(flattened_outline_items)
  highlight.clear_all_ns(bufnr)
  M.write_outline(bufnr, lines)
  highlight.add_item_highlights(bufnr, hl_info, flattened_outline_items)
end

return M
