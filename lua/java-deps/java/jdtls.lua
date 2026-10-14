local config = require("java-deps.config")
local lsp_command = require("java-deps.java.lsp_command")
local node_data_factory = require("java-deps.java.node_data_factory")
local NodeKind = require("java-deps.java.enums").NodeKind
local M = {}

---@param params string
---@return NodeData[]
M.get_projects = function(params)
  local err, resp = lsp_command.execute_command({
    command = lsp_command.JAVA_PROJECT_LIST,
    arguments = params,
  })
  if err then
    vim.notify(err.message or vim.inspect(err), vim.log.levels.WARN)
    return {}
  end
  return node_data_factory.create_list(resp)
end
M.root_dir = function()
  return lsp_command.get_client().root_dir
end

M.get_project_uris = function()
  local err, resp = lsp_command.execute_command({
    command = lsp_command.GET_ALL_PROJECTS,
  })
  if err then
    vim.notify(err.message or vim.inspect(err), vim.log.levels.WARN)
    return {}
  end
  return resp or {}
end

---@return NodeData[]
M.get_package_data = function(params)
  local excludePatterns = nil
  local err, resp = lsp_command.execute_command({
    command = lsp_command.JAVA_GETPACKAGEDATA,
    arguments = params,
  })
  if err then
    vim.notify(err.message or vim.inspect(err), vim.log.levels.WARN)
    return {}
  end
  ---@type NodeData[]
  local nodeDatas = node_data_factory.create_list(resp)
  -- 与 vscode 的 java.project.explorer.showNonJavaResources 一致, 默认显示配置文件等非 java 资源
  if config.options.show_non_java_resources == false then
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

---@return NodeData[]
M.resolve_path = function(params)
  local err, resp = lsp_command.execute_command({
    command = lsp_command.JAVA_RESOLVEPATH,
    arguments = params,
  })
  if err then
    vim.notify(err.message or vim.inspect(err), vim.log.levels.WARN)
    return {}
  end
  return node_data_factory.create_list(resp)
end
return M
