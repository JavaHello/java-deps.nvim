local M = {
  items = {
    nsid = vim.api.nvim_create_namespace("java-deps-items"),
    highlights = {
      LineGuide = { link = "Comment" },
    },
  },
}

M.init_hl = function()
  local ihlf = function(hls)
    for name, hl in pairs(hls.highlights) do
      if vim.fn.hlexists("JavaDeps" .. name) == 0 then
        vim.api.nvim_set_hl(0, "JavaDeps" .. name, { link = hl.link })
      end
    end
  end
  ihlf(M.items)
end
M.clear_all_ns = function(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, -1, 0, -1)
end

---@param bufnr number
---@param hl_info table
---@param nodes TreeItem[]
function M.add_item_highlights(bufnr, hl_info, nodes)
  for _, line_hl in ipairs(hl_info) do
    local line, hl_start, hl_end, hl_type = unpack(line_hl)
    vim.api.nvim_buf_add_highlight(bufnr, M.items.nsid, hl_type, line - 1, hl_start, hl_end)
  end
end

return M
