local jdtls = require("java-deps.java.jdtls")
local config = require("java-deps.config")
local View = require("java-deps.view")

local M = {
  view = nil,
  state = {
    root_uri = nil,
    flattened_outline_items = {},
    code_buf = nil,
    code_win = nil,
    root_items = nil,
    current_node = nil,
  },
}

function handle_projects(projects)
  if not projects or #projects < 1 then
    return
  end
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
    local uri = vim.uri_from_fname(jdtls.root_dir())
    local resp = jdtls.getProjects(uri)
    handle_projects(resp)
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
