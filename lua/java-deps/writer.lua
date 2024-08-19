local parser = require("java-deps.parser")
local config = require("java-deps.config")
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

function M.write_details(bufnr, lines)
  if not is_buffer_outline(bufnr) then
    return
  end

  for index, value in ipairs(lines) do
    vim.api.nvim_buf_set_extmark(bufnr, highlight.vt.nsid, index - 1, -1, {
      virt_text = { { value, "JavaDepsComment" } },
      virt_text_pos = "eol",
      hl_mode = "combine",
    })
  end
end

---@param bufnr integer
---@param flattened_outline_items TreeItem
function M.parse_and_write(bufnr, flattened_outline_items)
  local lines, hl_info = parser.get_lines(flattened_outline_items)
  M.write_outline(bufnr, lines)

  highlight.clear_virt_text(bufnr)
  highlight.add_icon_highlights(bufnr, hl_info, flattened_outline_items)
  if config.options.show_path_details then
    local details = parser.get_details(flattened_outline_items)
    M.write_details(bufnr, details)
  end
end

return M
