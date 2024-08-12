local lsp_command = require("java-deps.lsp-command")
local node_data = require("java-deps.java.nodeData")
local NodeKind = node_data.NodeKind
local M = {}

---@param params string
---@return INodeData[]
M.getProjects = function(params)
  local err, resp = lsp_command.execute_command({
    command = lsp_command.JAVA_PROJECT_LIST,
    arguments = params,
  })
  if err then
    vim.notify(err.message or vim.inspect(err), vim.log.levels.WARN)
    return {}
  end
  return resp or {}
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
  return resp or {}
end

---@return INodeData[]
M.getPackageData = function(params)
  local excludePatterns = nil
  local err, resp = lsp_command.execute_command({
    command = lsp_command.JAVA_GETPACKAGEDATA,
    arguments = params,
  })
  if err then
    vim.notify(err.message or vim.inspect(err), vim.log.levels.WARN)
    return {}
  end
  ---@type INodeData[]
  local nodeDatas = resp and resp or {}
  -- Filter out non java resources
  if true then
    nodeDatas = vim.tbl_filter(function(data)
      return data.kind ~= NodeKind.Folder and data.kind ~= NodeKind.File
    end, nodeDatas)
  end

  if excludePatterns and #nodeDatas > 0 then
    local uriOfChildren = vim.tbl_map(function(node)
      return node.uri
    end, nodeDatas)

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
      nodeDatas = vim.tbl_filter(function(node)
        if not node.uri then
          return true
        end
        return not vim.tbl_contains(urisToExclude, node.uri)
      end, nodeDatas)
    end
  end
  return nodeDatas
end

---@return INodeData[]
M.resolvePath = function(params)
  local err, resp = lsp_command.execute_command({
    command = lsp_command.JAVA_RESOLVEPATH,
    arguments = params,
  })
  if err then
    vim.notify(err.message or vim.inspect(err), vim.log.levels.WARN)
    return {}
  end
  return resp or {}
end
return M
