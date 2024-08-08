local NodeKind = require("java-deps.java.nodeData").NodeKind
local jdtls = require("java-deps.java.jdtls")
local ExplorerNode = require("java-deps.views.explorer_node").ExplorerNode
local hieararchicalPackageNodeData = require("java-deps.java.hieararchicalPackageNodeData")

local M = {}

M.K_TYPE_KIND = "TypeKind"
M.NATURE_ID = "NatureId"

M.NatureId = {
  Maven = "org.eclipse.m2e.core.maven2Nature",
  Gradle = "org.eclipse.buildship.core.gradleprojectnature",
  BspGradle = "com.microsoft.gradle.bs.importer.GradleBuildServerProjectNature",
  UnmanagedFolder = "org.eclipse.jdt.ls.core.unmanagedFolder",
  Java = "org.eclipse.jdt.core.javanature",
}

M.ReadableNature = {
  Maven = "maven",
  Gradle = "gradle",
  BspGradle = "bsp-gradle",
  UnmanagedFolder = "unmanagedFolder",
  Java = "java",
}
M.NatureIdMap = {
  [M.NatureId.Maven] = M.ReadableNature.Maven,
  [M.NatureId.Gradle] = M.ReadableNature.Gradle,
  [M.NatureId.BspGradle] = M.ReadableNature.BspGradle,
  [M.NatureId.UnmanagedFolder] = M.ReadableNature.UnmanagedFolder,
  [M.NatureId.Java] = M.ReadableNature.Java,
}

M.ContainerType = {
  JRE = "jre",
  Maven = "maven",
  Gradle = "gradle",
  ReferencedLibrary = "referencedLibrary",
  Unknown = "",
}

M.ContainerPath = {
  JRE = "org.eclipse.jdt.launching.JRE_CONTAINER",
  Maven = "org.eclipse.m2e.MAVEN2_CLASSPATH_CONTAINER",
  Gradle = "org.eclipse.buildship.core.gradleclasspathcontainer",
  ReferencedLibrary = "REFERENCED_LIBRARIES_PATH",
}

---@enum TreeItemCollapsibleState
local TreeItemCollapsibleState = {
  None = 0,
  Collapsed = 1,
  Expanded = 2,
}

---@param natureId string
---@return string
M.getProjectType = function(natureId)
  return M.NatureIdMap[natureId] or ""
end

---@class DataNode: ExplorerNode
---@field _childrenNodes ExplorerNode[]
---@field _nodeData INodeData
---@field _parent DataNode?
---@field _project DataNode?
---@field _rootNode DataNode?
---@field _hierarchicalNode boolean
local DataNode = ExplorerNode:new()

DataNode.__index = DataNode
DataNode._hierarchicalNode = false

---@param nodeData INodeData
---@param parent DataNode?
---@param project DataNode?
---@param rootNode DataNode?
---@return DataNode
function DataNode:new(nodeData, parent, project, rootNode)
  local data = setmetatable(ExplorerNode:new(), self)
  data._nodeData = nodeData
  data._parent = parent
  data._project = project
  data._rootNode = rootNode
  return data
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
    local result = {}
    local packageData = {}
    if self._nodeData.children then
      for _, child in ipairs(self._nodeData.children) do
        if child.kind == NodeKind.Package then
          table.insert(packageData, child)
        else
          table.insert(result, M.createNode(child, self, self, nil))
        end
      end
      if #packageData > 0 then
        local data = hieararchicalPackageNodeData.createHierarchicalNodeDataByPackageList(packageData)
        if data and data.children then
          for _, child in ipairs(data.children) do
            table.insert(result, M.createNode(child, self, self, self))
          end
        end
      end
    end
    return result
  elseif kind == NodeKind.Container then
    local result = {}
    if self._nodeData.children then
      for _, child in ipairs(self._nodeData.children) do
        table.insert(result, M.createNode(child, self, self._project, nil))
      end
    end
    return result
  elseif kind == NodeKind.PackageRoot then
    local result = {}
    if self._nodeData.children then
      for _, child in ipairs(self._nodeData.children) do
        table.insert(result, M.createNode(child, self, self._project, self))
      end
    end
    return result
  elseif kind == NodeKind.Package then
    local result = {}
    if self._nodeData.children then
      for _, child in ipairs(self._nodeData.children) do
        table.insert(result, M.createNode(child, self, self._project, self._rootNode))
      end
    end
    return result
  elseif kind == NodeKind.Folder then
    local result = {}
    if self._nodeData.children then
      for _, child in ipairs(self._nodeData.children) do
        table.insert(result, M.createNode(child, self, self._project, self._rootNode))
      end
    end
    return result
  elseif kind == NodeKind.PrimaryType then
    return nil
  else
    return nil
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
  local kind = self:kind()
  if kind == NodeKind.PackageRoot then
    local hierarchicalNodeData = paths[1]
    local children = self:getChildren()
    ---@type DataNode?
    local childNode = vim.tbl_filter(function(child)
      return vim.startswith(hierarchicalNodeData.name, child._nodeData.name .. ".")
        or hierarchicalNodeData.name == child._nodeData.name
    end, children)
    childNode = childNode and #childNode > 0 and childNode[1] or nil
    if childNode and not childNode[1]._hierarchicalNode then
      table.remove(paths, 1)
    end
    return (childNode and #paths > 0) and childNode:revealPaths(paths) or childNode
  elseif kind == NodeKind.Package then
    local hierarchicalNodeData = paths[1]
    if hierarchicalNodeData.name == self._nodeData.name then
      table.remove(paths, 1)
      return self:revealPaths(paths)
    else
      local children = self:getChildren()
      ---@type DataNode?
      local childNode = vim.tbl_filter(function(child)
        return vim.startswith(hierarchicalNodeData.name, child._nodeData.name .. ".")
          or hierarchicalNodeData.name == child._nodeData.name
      end, children)
      childNode = childNode and #childNode > 0 and childNode[1] or nil
      return (childNode and #paths > 0) and childNode:revealPaths(paths) or nil
    end
  else
    local childNodeData = table.remove(paths, 1)
    local children = self:getChildren()
    ---@type DataNode?
    local childNode = vim.tbl_filter(function(child)
      return childNodeData.name == child._nodeData.name and childNodeData.path == child._nodeData.path
    end, children)
    childNode = childNode and #childNode > 0 and childNode[1] or nil
    return (childNode and #paths > 0) and childNode:revealPaths(paths) or childNode
  end
end

local function uniqBy(arr, fn)
  local seen = {}
  local result = {}
  for _, value in ipairs(arr) do
    local key = fn(value)
    if not seen[key] then
      seen[key] = true
      table.insert(result, value)
    end
  end
  return result
end
---@return ExplorerNode[]
function DataNode:getChildren()
  if self:kind() == NodeKind.Package then
    local data = self:loadData()
    if data then
      if self._nodeData.children then
        for _, child in ipairs(data) do
          table.insert(self._nodeData.children, child)
        end
        self._nodeData.children = uniqBy(self._nodeData.children, function(child)
          return child.path .. child.name
        end)
      else
        self._nodeData.children = data
      end
      self._childrenNodes = self:createChildNodeList() or {}
      self:sort()
      return self._childrenNodes
    end
  else
    if not self._nodeData.children then
      local data = self:loadData()
      self._nodeData.children = data
      self._childrenNodes = self:createChildNodeList() or {}
      self:sort()
      return self._childrenNodes
    end
    return self._childrenNodes
  end
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
    local data = DataNode:new(nodeData, parent, project, rootNode)
    data._hierarchicalNode = true
    return data
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

function DataNode:isUnmanagedFolder()
  local natureIds = self._nodeData.metaData and self._nodeData.metaData[M.NATURE_ID] or {}
  for _, natureId in ipairs(natureIds) do
    if natureId == M.NatureId.UnmanagedFolder then
      return true
    end
  end
  return false
end

function DataNode:getContainerType()
  local containerPath = self._nodeData.path or ""
  if containerPath.startsWith(M.ContainerPath.JRE) then
    return M.ContainerType.JRE
  elseif containerPath.startsWith(M.ContainerPath.Maven) then
    return M.ContainerType.Maven
  elseif containerPath.startsWith(M.ContainerPath.Gradle) then
    return M.ContainerType.Gradle
  elseif containerPath.startsWith(M.ContainerPath.ReferencedLibrary) and self._project:isUnmanagedFolder() then
    return M.ContainerType.ReferencedLibrary
  end
  return M.ContainerType.Unknown
end

function DataNode:description()
  --TODO
end
function DataNode:command()
  --TODO
end

function DataNode:hasChildren()
  return self._childrenNodes and #self._childrenNodes > 0
end

function DataNode:getTreeItem()
  ---@type TreeItem
  local item = {
    label = self._nodeData.displayName or self._nodeData.name,
    collapsible = self:hasChildren() and TreeItemCollapsibleState.Collapsed or TreeItemCollapsibleState.None,
  }
  item.description = self:description()
  item.icon = self:icon()
  item.command = self:command()
  if self._nodeData.uri then
    local kind = self:kind()
    if
      kind == NodeKind.Project
      or kind == NodeKind.PackageRoot
      or kind == NodeKind.Package
      or kind == NodeKind.PrimaryType
      or kind == NodeKind.CompilationUnit
      or kind == NodeKind.ClassFile
      or kind == NodeKind.Folder
      or kind == NodeKind.File
    then
      item.resourceUri = self._nodeData.uri
    end
  end
  return item
end

return M
