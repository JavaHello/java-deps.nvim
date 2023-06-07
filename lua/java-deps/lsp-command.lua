local config = require("java-deps.config")
local context = require("java-deps.context")
local symbols = require("java-deps.symbols")
local M = {}

local request = function(bufnr, method, params, handler)
  local client = context.current_client
  client.request(method, params, handler, bufnr)
end
local request_sync = function(bufnr, method, params, timeout)
  timeout = timeout or config.options.request_timeout
  local client = context.current_client
  return client.request_sync(method, params, timeout, bufnr)
end

M.command = function(buf, params, handler)
  request(buf, "workspace/executeCommand", params, function(err, projects)
    if err then
      vim.notify(err.message, vim.log.levels.WARN)
    elseif projects then
      handler(projects)
    end
  end)
end

M.command_sync = function(buf, command, arguments, timeout)
  local params0 = {}
  params0.command = command
  params0.arguments = arguments
  local resp, err = request_sync(buf, "workspace/executeCommand", params0, timeout)
  if err then
    vim.notify("executeCommand " .. command .. " error: " .. err)
    return
  end
  if resp.result ~= nil then
    return resp.result
  elseif resp.error ~= nil then
    vim.notify(vim.inspect(resp), vim.log.levels.WARN)
  end
end

local function root_project(node)
  local root = node
  while root ~= nil do
    if root.kind == symbols.NodeKind.Project then
      return root
    end
    root = root.parent
  end
end

M.get_package_data = function(buf, node)
  local arguments = {
    kind = node.kind,
  }
  if node.kind == symbols.NodeKind.Project then
    arguments.projectUri = node.uri
  elseif node.kind == symbols.NodeKind.Container then
    arguments.projectUri = root_project(node).uri
    arguments.path = node.path
  elseif node.kind == symbols.NodeKind.PackageRoot then
    arguments.projectUri = root_project(node).uri
    arguments.rootPath = node.path
    arguments.handlerIdentifier = node.handlerIdentifier
    arguments.isHierarchicalView = config.options.hierarchical_view
  elseif node.kind == symbols.NodeKind.Package then
    arguments.projectUri = root_project(node).uri
    arguments.path = node.name
    arguments.handlerIdentifier = node.handlerIdentifier
  else
    arguments.projectUri = root_project(node).uri
    arguments.path = node.path
  end
  return M.command_sync(buf, "java.getPackageData", arguments)
end

M.get_projects = function(buf, rootUri)
  rootUri = rootUri or context.root_uri
  local arguments = {
    rootUri,
  }
  return M.command_sync(buf, "java.project.list", arguments)
end

M.resolve_path = function(buf, uri)
  local arguments = {
    uri,
  }
  return M.command_sync(buf, "java.resolvePath", arguments)
end
return M
