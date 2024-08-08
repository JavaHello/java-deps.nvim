local lsp_command = require("java-deps.lsp-command")
local node_data = require("java-deps.java.nodeData")
local NodeKind = node_data.NodeKind
local M = {}

---@param params string
---@return INodeData[]
M.getProjects = function(params)
  local err, resp = lsp_command.execute_command({
    command = "java.project.list",
    arguments = params,
  }, nil, 0)
  if err then
    vim.notify(err.message or vim.inspect(err), vim.log.levels.WARN)
    return {}
  end
  return resp and resp.reslut or {}
end
M.root_dir = function()
  return lsp_command.get_client().root_dir
end

M.getProjectUris = function()
  local err, resp = lsp_command.execute_command({
    command = lsp_command.GET_ALL_PROJECTS,
  })
  if err then
    vim.notify(err.message or vim.inspect(err), vim.log.levels.WARN)
    return {}
  end
  return resp and resp.reslut or {}
end

-- interface IPackageDataParam {
--     projectUri: string | undefined;
--     [key: string]: any;
-- }

---@return INodeData[]
M.getPackageData = function(params)
  local excludePatterns = {}
  local err, resp = lsp_command.execute_command(lsp_command.JAVA_GETPACKAGEDATA, params)
  if err then
    vim.notify(err.message or vim.inspect(err), vim.log.levels.WARN)
    return {}
  end
  ---@type INodeData[]
  local nodeData = resp and resp.reslut or {}
  -- Filter out non java resources
  if true then
    nodeData = vim.tbl_filter(function(data)
      return data.kind ~= NodeKind.Folder and data.kind ~= NodeKind.File
    end, nodeData)
  end

  if excludePatterns and #nodeData > 0 then
    local uriOfChildren = vim.tbl_map(function(node)
      return node.uri
    end, nodeData)

    local urisToExclude = {}
    for _, pattern in pairs(excludePatterns) do
      if excludePatterns[pattern] then
        local toExclude = vim.tbl_filter(function(urio)
          return string.match(urio, pattern)
        end, uriOfChildren)
        for _, uriToExclude in ipairs(toExclude) do
          table.insert(urisToExclude, uriToExclude)
        end
      end
    end
    if #urisToExclude > 0 then
      nodeData = vim.tbl_filter(function(node)
        if not node.uri then
          return true
        end
        return not vim.tbl_contains(urisToExclude, node.uri)
      end, nodeData)
    end
  end
  return nodeData
end

return M
