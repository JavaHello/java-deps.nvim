local jdtls = require("java-deps.java.jdtls")
local config = require("java-deps.config")
local View = require("java-deps.view")
local provider = require("java-deps.views.data_provider")
local writer = require("java-deps.writer")

local M = {
  view = nil,
  state = {
    root_uri = nil,
    flattened_outline_items = {},
    code_buf = nil,
    code_win = nil,
    root_items = nil,
    current_node = nil,
    current_path = nil,
  },
}

local function handle_projects()
  local uri = vim.uri_from_fname(jdtls.root_dir())
  local data = provider.DataProvider:new(uri, M.state.current_path)
  data:revealPaths()
  local result = data:flattenTree()
  vim.print(vim.inspect(result))
  writer.parse_and_write(M.view.bufnr, result)
end

function M.toggle_outline()
  if M.view:is_open() then
    M.close_outline()
  else
    M.open_outline()
  end
end

function M.open_outline()
  if not M.view:is_open() then
    M.state.code_buf = vim.api.nvim_get_current_buf()
    M.state.current_path = vim.uri_from_bufnr(M.state.code_buf)
    M.view:open()
    local wf = coroutine.wrap(function()
      handle_projects()
    end)
    local ok, err = pcall(wf)
    if not ok then
      print(err.message or vim.inspect(err))
    end
  end
end

function M.close_outline()
  M.view:close()
end

function M.setup(opts)
  config.setup(opts)
  M.view = View:new()
end

return M
