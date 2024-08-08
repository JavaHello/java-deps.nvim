local jdtls = require("java-deps.java.jdtls")
local config = require("java-deps.config")
local View = require("java-deps.view")
local data_node = require("java-deps.views.data_node")

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

local function handle_projects(projects)
  if not projects or #projects < 1 then
    return
  end
  local project_nodes = {}
  for _, project in ipairs(projects) do
    if project then
      local root = data_node.createNode(project)
      table.insert(project_nodes, root)
    end
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
    vim.defer_fn(function()
      local resp = jdtls.getProjects(uri)
      handle_projects(resp)
    end, 0)
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
