local NodeKind = require("java-deps.java.nodeData").NodeKind
local jdtls = require("java-deps.java.jdtls")
local ExplorerNode = require("java-deps.view.explorer_node").ExplorerNode

local util = require("java-deps.utils")
local M = {}

M.K_TYPE_KIND = "TypeKind"
---@class DataNode: ExplorerNode
---@field _childrenNodes ExplorerNode[]
---@field _nodeData INodeData
---@field _parent DataNode?
---@field _project DataNode?
---@field _rootNode DataNode?
local DataNode = ExplorerNode:new()
DataNode.__index = DataNode

---@param nodeData INodeData
---@param parent DataNode?
---@param project DataNode?
---@param rootNode DataNode?
function DataNode:new(nodeData, parent, project, rootNode)
  local data = setmetatable(ExplorerNode:new(), self)
  data._nodeData = nodeData
  data._parent = parent
  data._project = project
  data._rootNode = rootNode
end

function DataNode:createChildNodeList()
  local kind = self:kind()
  if kind == NodeKind.Workspace then
    if self._nodeData.children then
      return vim.tbl_map(function(child)
        return M.createNode(child, self, nil, nil)
      end, self._nodeData.children)
    end
  elseif kind == NodeKind.Project then
    if self._nodeData.children then
      return vim.tbl_map(function(child)
        return M.createNode(child, self, self, nil)
      end, self._nodeData.children)
    end
  end
end

function DataNode:loadData()
  local kind = self:kind()
  if kind == NodeKind.Workspace then
    return jdtls.getProjects(self._nodeData.uri)
  elseif kind == NodeKind.Project then
    return jdtls.getPackageData({
      kind = NodeKind.Project,
      projectUri = self._nodeData.uri,
    })
  elseif kind == NodeKind.Container then
    return jdtls.getPackageData({
      kind = NodeKind.Container,
      projectUri = self._nodeData.uri,
      path = self._nodeData.path,
    })
  elseif kind == NodeKind.PackageRoot then
    return jdtls.getPackageData({
      kind = NodeKind.PackageRoot,
      projectUri = self._project._nodeData.uri,
      rootPath = self._nodeData.path,
      handlerIdentifier = self._nodeData.handlerIdentifier,
      isHierarchicalView = true,
    })
  elseif kind == NodeKind.Package then
    return jdtls.getPackageData({
      kind = NodeKind.Package,
      projectUri = self._project._nodeData.uri,
      path = self._nodeData.name,
      handlerIdentifier = self._nodeData.handlerIdentifier,
    })
  elseif kind == NodeKind.Folder then
    return jdtls.getPackageData({
      kind = NodeKind.Folder,
      projectUri = self._project._nodeData.uri,
      path = self._nodeData.path,
      rootPath = self._rootNode and self._rootNode._nodeData.path or nil,
      handlerIdentifier = self._rootNode and self._rootNode._nodeData.handlerIdentifier,
    })
  elseif kind == NodeKind.PrimaryType then
    return nil
  elseif kind == NodeKind.Folder then
    return jdtls.getPackageData({
      kind = NodeKind.Folder,
      projectUri = self._project._nodeData.uri,
      path = self._nodeData.path,
      rootPath = self._rootNode and self._rootNode._nodeData.path or nil,
      handlerIdentifier = self._rootNode and self._rootNode._nodeData.handlerIdentifier or nil,
    })
  else
    return nil
  end
end

function DataNode:icon() end
function DataNode:kind()
  return self._nodeData.kind
end

function DataNode:sort()
  table.sort(self._childrenNodes, function(a, b)
    ---@diagnostic disable: undefined-field
    if a._nodeData.kind and a._nodeData.kind then
      if a._nodeData.kind == b._nodeData.kind then
        return a._nodeData.name < b._nodeData.name and false or true
      else
        return a._nodeData.kind - b._nodeData.kind
      end
    end
    return false
  end)
end

---@param paths INodeData[]
function DataNode:revealPaths(paths)
  if #paths == 0 then
    return self
  end
  local childNodeData = table.remove(paths, 1)
  local children = self:getChildren()
  for _, child in ipairs(children) do
    if
      util.is_instance(child, DataNode)
      and child._nodeData.name == childNodeData.name
      and child.path == childNodeData.path
    then
      return #paths > 0 and child:revealPaths(paths) or child
    end
  end
end

function DataNode:getChildren()
  if not self._nodeData.children then
    local data = self:loadData()
    self._nodeData.children = data
    self._childrenNodes = self:createChildNodeList() or {}
    self:sort()
    return self._childrenNodes
  end
  return self._childrenNodes
end

M.DataNode = DataNode

---@param nodeData INodeData
---@param parent DataNode?
---@param project DataNode?
---@param rootNode DataNode?
M.createNode = function(nodeData, parent, project, rootNode)
  if nodeData.kind == NodeKind.Workspace then
    return DataNode:new(nodeData, parent, project, rootNode)
  elseif nodeData.kind == NodeKind.Project then
    return DataNode:new(nodeData, parent, project, rootNode)
  elseif nodeData.kind == NodeKind.Container then
    if not parent or not project then
      vim.notify("Container node must have parent and project", vim.log.levels.ERROR)
      return nil
    end
    return DataNode:new(nodeData, parent, project, rootNode)
  elseif nodeData.kind == NodeKind.PackageRoot then
    if not parent or not project then
      vim.notify("Package root node must have parent and project", vim.log.levels.ERROR)
      return nil
    end
    return DataNode:new(nodeData, parent, project, rootNode)
  elseif nodeData.kind == NodeKind.Package then
    if not parent or not project or not rootNode then
      vim.notify("Package node must have parent, project and root node", vim.log.levels.ERROR)
      return nil
    end
    return DataNode:new(nodeData, parent, project, rootNode)
  elseif nodeData.kind == NodeKind.PrimaryType then
    if nodeData.metaData and nodeData.metaData[M.K_TYPE_KIND] then
      if not parent then
        vim.notify("Primary type node must have parent", vim.log.levels.ERROR)
        return nil
      end
      return DataNode:new(nodeData, parent, project, rootNode)
    end
  elseif nodeData.kind == NodeKind.Folder then
    if not parent or not project or not rootNode then
      vim.notify("Folder node must have parent, project and root node", vim.log.levels.ERROR)
      return nil
    end
    return DataNode:new(nodeData, parent, project, rootNode)
  elseif
    nodeData.kind == NodeKind.CompilationUnit
    or nodeData.kind == NodeKind.ClassFile
    or nodeData.kind == NodeKind.File
  then
    if not parent then
      vim.notify("File node must have parent", vim.log.levels.ERROR)
      return nil
    end
    return DataNode:new(nodeData, parent, project, rootNode)
  end
end

return M
