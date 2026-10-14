local config = require("java-deps.config")
local enums = require("java-deps.java.enums")
local NodeKind = enums.NodeKind
local jdtls = require("java-deps.java.jdtls")
local ExplorerNode = require("java-deps.views.explorer_node")
local HierarchicalPackageNodeData = require("java-deps.java.hierarchical_package_node_data")
local TreeItem = require("java-deps.views.tree_item")
local icons = require("java-deps.views.icons")

local CollapsibleState = TreeItem.CollapsibleState
-- 每次调用时读取, 因为 setup() 通常在模块加载之后执行
---@return boolean
local function is_hierarchical_view()
  return config.options.hierarchical_view ~= false
end

---@class DataNode: ExplorerNode
---@field _childrenNodes DataNode[]
---@field _nodeData NodeData
---@field _parent DataNode?
---@field _project DataNode?
---@field _rootNode DataNode?
---@field _hierarchicalPackageNode boolean
---@field _hierarchicalPackageRootNode boolean
---@field _collapsibleState TreeItemCollapsibleState
local DataNode = setmetatable({}, { __index = ExplorerNode })
DataNode.__index = DataNode
DataNode._hierarchicalPackageNode = false
DataNode._hierarchicalPackageRootNode = false

---@param nodeData NodeData
---@param parent DataNode?
---@param project DataNode?
---@param rootNode DataNode?
---@return DataNode
function DataNode:new(nodeData, parent, project, rootNode)
  return setmetatable({
    _nodeData = nodeData,
    _parent = parent,
    _project = project,
    _rootNode = rootNode,
  }, self)
end

---@param natureId string
---@return string
function DataNode.get_project_type(natureId)
  return enums.NatureIdMap[natureId] or ""
end

---@return DataNode[]
function DataNode:create_hierarchical_package_root_node()
  local result = {}
  local packageData = {}
  if self._nodeData.children then
    for _, child in ipairs(self._nodeData.children) do
      if child:get_kind() == NodeKind.Package then
        table.insert(packageData, child)
      else
        table.insert(result, DataNode.create(child, self, self._project, self))
      end
    end
    if #packageData > 0 then
      local data = HierarchicalPackageNodeData.from_package_list(packageData)
      if data and data.children then
        for _, child in ipairs(data.children) do
          local node = DataNode.create(child, self, self._project, self)
          table.insert(result, node)
        end
      end
    end
  end
  return result
end

---@return DataNode[]
function DataNode:create_hierarchical_package_node()
  local result = {}
  if self._nodeData.children then
    for _, child in ipairs(self._nodeData.children) do
      table.insert(result, DataNode.create(child, self, self._project, self._rootNode))
    end
  end
  return result
end

function DataNode:create_child_node_list()
  local kind = self:kind()
  if kind == NodeKind.Workspace then
    local result = {}
    if self._nodeData.children then
      for _, child in ipairs(self._nodeData.children) do
        table.insert(result, DataNode.create(child, self, nil, nil))
      end
    end
    return result
  elseif kind == NodeKind.Project then
    local result = {}
    local packageData = {}
    if self._nodeData.children then
      for _, child in ipairs(self._nodeData.children) do
        if child:get_kind() == NodeKind.Package then
          table.insert(packageData, child)
        else
          table.insert(result, DataNode.create(child, self, self, nil))
        end
      end

      if #packageData > 0 then
        if is_hierarchical_view() then
          local data = HierarchicalPackageNodeData.from_package_list(packageData)
          if data and data.children then
            for _, child in ipairs(data.children) do
              table.insert(result, DataNode.create(child, self, self, self))
            end
          end
        else
          for _, child in ipairs(packageData) do
            table.insert(result, DataNode.create(child, self, self, self))
          end
        end
      end
    end
    return result
  elseif kind == NodeKind.Container then
    local result = {}
    if self._nodeData.children then
      for _, child in ipairs(self._nodeData.children) do
        table.insert(result, DataNode.create(child, self, self._project, nil))
      end
    end
    return result
  elseif kind == NodeKind.PackageRoot then
    if is_hierarchical_view() then
      return self:create_hierarchical_package_root_node()
    else
      local result = {}
      if self._nodeData.children then
        for _, child in ipairs(self._nodeData.children) do
          table.insert(result, DataNode.create(child, self, self._project, self))
        end
      end
      return result
    end
  elseif kind == NodeKind.Package then
    if is_hierarchical_view() then
      return self:create_hierarchical_package_node()
    else
      local result = {}
      if self._nodeData.children then
        for _, child in ipairs(self._nodeData.children) do
          table.insert(result, DataNode.create(child, self, self._project, self._rootNode))
        end
      end
      return result
    end
  elseif kind == NodeKind.Folder then
    local result = {}
    if self._nodeData.children then
      for _, child in ipairs(self._nodeData.children) do
        table.insert(result, DataNode.create(child, self, self._project, self._rootNode))
      end
    end
    return result
  elseif kind == NodeKind.PrimaryType then
    return nil
  else
    return nil
  end
end
function DataNode:load_data()
  local kind = self:kind()
  if kind == NodeKind.Workspace then
    return jdtls.get_projects(self._nodeData:get_uri())
  elseif kind == NodeKind.Project then
    return jdtls.get_package_data({
      kind = NodeKind.Project,
      projectUri = self._nodeData:get_uri(),
    })
  elseif kind == NodeKind.Container then
    return jdtls.get_package_data({
      kind = NodeKind.Container,
      projectUri = self._project._nodeData:get_uri(),
      path = self._nodeData:get_path(),
    })
  elseif kind == NodeKind.PackageRoot then
    return jdtls.get_package_data({
      kind = NodeKind.PackageRoot,
      projectUri = self._project._nodeData:get_uri(),
      rootPath = self._nodeData:get_path(),
      handlerIdentifier = self._nodeData:get_handler_identifier(),
      isHierarchicalView = is_hierarchical_view(),
    })
  elseif kind == NodeKind.Package then
    -- 层级视图的中间层(如 com.example)不是真实的包, 子节点已在 children 中
    if self._nodeData.is_package and not self._nodeData:is_package() then
      return {}
    end
    return jdtls.get_package_data({
      kind = NodeKind.Package,
      projectUri = self._project._nodeData:get_uri(),
      path = self._nodeData:get_name(),
      handlerIdentifier = self._nodeData:get_handler_identifier(),
    })
  elseif kind == NodeKind.Folder then
    return jdtls.get_package_data({
      kind = NodeKind.Folder,
      projectUri = self._project._nodeData:get_uri(),
      path = self._nodeData:get_path(),
      rootPath = self._rootNode and self._rootNode._nodeData:get_path() or nil,
      handlerIdentifier = self._rootNode and self._rootNode._nodeData:get_handler_identifier(),
    })
  elseif kind == NodeKind.PrimaryType then
    return nil
  else
    return nil
  end
end

function DataNode:icon()
  return icons.get_icon(self)
end
function DataNode:kind()
  return self._nodeData:get_kind()
end
function DataNode:type_kind()
  return self._nodeData:get_meta_data() and self._nodeData:get_meta_data()[enums.K_TYPE_KIND] or nil
end

function DataNode:sort()
  table.sort(self._childrenNodes, function(a, b)
    ---@diagnostic disable: undefined-field
    if a._nodeData:get_kind() and b._nodeData:get_kind() and a._nodeData:get_name() and b._nodeData:get_name() then
      if a._nodeData:get_kind() == b._nodeData:get_kind() then
        return a._nodeData:get_name() < b._nodeData:get_name()
      else
        return a._nodeData:get_kind() < b._nodeData:get_kind()
      end
    end
    return false
  end)
end

---@param paths NodeData[]
function DataNode:base_reveal_paths(paths)
  if #paths == 0 then
    return self
  end
  ---@type DataNode[]
  local childNodeData = table.remove(paths, 1)
  ---@type DataNode[]
  local children = self:get_children()
  ---@type DataNode[]?
  local childNode = vim.tbl_filter(function(child)
    return childNodeData:get_name() == child._nodeData:get_name()
      and childNodeData:get_path() == child._nodeData:get_path()
  end, children)
  childNode = (childNode and #childNode > 0) and childNode[1] or nil
  return (childNode and #paths > 0) and childNode:reveal_paths(paths) or childNode
end

---@param uri string
---@return boolean
local function is_workspace_file(uri)
  local rootPath = jdtls.root_dir()
  if vim.startswith(uri, "file:/") then
    local path = vim.uri_to_fname(uri)
    return path == rootPath or vim.startswith(path, rootPath)
  end
  return false
end

---@param paths NodeData[]
function DataNode:reveal_paths(paths)
  if #paths == 0 then
    return self
  end
  self._collapsibleState = CollapsibleState.Expanded
  local kind = self:kind()
  if kind == NodeKind.Project then
    if not self._nodeData:get_uri() then
      return
    end

    if is_workspace_file(self._nodeData:get_uri()) then
      return self:base_reveal_paths(paths)
    end

    local childNodeData = paths[1]
    ---@type DataNode[]
    local children = self:get_children()
    ---@type DataNode[]?
    local childNode = vim.tbl_filter(function(child)
      return vim.startswith(childNodeData:get_name(), child._nodeData:get_name() .. ".")
        or childNodeData:get_name() == child._nodeData:get_name()
    end, children)
    ---@type DataNode?
    childNode = (childNode and #childNode > 0) and childNode[1] or nil
    if childNode and childNode._hierarchicalPackageNode then
      table.remove(paths, 1)
    end
    return (childNode and #paths > 0) and childNode:reveal_paths(paths) or childNode
  elseif kind == NodeKind.PackageRoot then
    if self._hierarchicalPackageRootNode then
      local hierarchicalNodeData = paths[1]

      ---@type DataNode[]
      local children = self:get_children()
      ---@type DataNode[]?
      local childNode = vim.tbl_filter(function(child)
        return vim.startswith(hierarchicalNodeData:get_name(), child._nodeData:get_name() .. ".")
          or hierarchicalNodeData:get_name() == child._nodeData:get_name()
      end, children)
      ---@type DataNode?
      childNode = (childNode and #childNode > 0) and childNode[1] or nil
      if childNode and not childNode._hierarchicalPackageNode then
        table.remove(paths, 1)
      end
      return (childNode and #paths > 0) and childNode:reveal_paths(paths) or childNode
    else
      return self:base_reveal_paths(paths)
    end
  elseif kind == NodeKind.Package and self._hierarchicalPackageNode then
    local hierarchicalNodeData = paths[1]
    if hierarchicalNodeData:get_name() == self._nodeData:get_name() then
      table.remove(paths, 1)
      return self:base_reveal_paths(paths)
    else
      ---@type DataNode[]
      local children = self:get_children()
      ---@type DataNode[]?
      local childNode = vim.tbl_filter(function(child)
        return vim.startswith(hierarchicalNodeData:get_name(), child._nodeData:get_name() .. ".")
          or hierarchicalNodeData:get_name() == child._nodeData:get_name()
      end, children)
      ---@type DataNode?
      childNode = (childNode and #childNode > 0) and childNode[1] or nil
      return (childNode and #paths > 0) and childNode:reveal_paths(paths) or nil
    end
  else
    return self:base_reveal_paths(paths)
  end
end

local function uniq_by(arr, fn)
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
function DataNode:get_children()
  if self:kind() == NodeKind.Package then
    local data = self:load_data()
    if data then
      if self._nodeData.children then
        for _, child in ipairs(data) do
          table.insert(self._nodeData.children, child)
        end
        self._nodeData.children = uniq_by(self._nodeData.children, function(child)
          return (child:get_path() or "") .. "/" .. child:get_name()
        end)
      else
        self._nodeData.children = data
      end
      self._childrenNodes = self:create_child_node_list() or {}
      self:sort()
    end
    return self._childrenNodes
  else
    if not self._nodeData.children then
      local data = self:load_data()
      self._nodeData.children = data
      self._childrenNodes = self:create_child_node_list() or {}
      self:sort()
    end
    return self._childrenNodes
  end
end

---@param nodeData NodeData
---@param parent DataNode?
---@param project DataNode?
---@param rootNode DataNode?
function DataNode.create(nodeData, parent, project, rootNode)
  local kind = nodeData:get_kind()
  if kind == NodeKind.Workspace then
    return DataNode:new(nodeData, parent, project, rootNode)
  elseif kind == NodeKind.Project then
    return DataNode:new(nodeData, parent, project, rootNode)
  elseif kind == NodeKind.Container then
    if not parent or not project then
      vim.notify("Container node must have parent and project", vim.log.levels.ERROR)
      return nil
    end
    return DataNode:new(nodeData, parent, project, rootNode)
  elseif kind == NodeKind.PackageRoot then
    if not parent or not project then
      vim.notify("Package root node must have parent and project", vim.log.levels.ERROR)
      return nil
    end
    local data = DataNode:new(nodeData, parent, project, rootNode)
    if is_hierarchical_view() then
      data._hierarchicalPackageRootNode = true
    end
    return data
  elseif kind == NodeKind.Package then
    if not parent or not project or not rootNode then
      vim.notify("Package node must have parent, project and root node", vim.log.levels.ERROR)
      return nil
    end
    local data = DataNode:new(nodeData, parent, project, rootNode)
    if is_hierarchical_view() then
      data._hierarchicalPackageNode = true
    end
    return data
  elseif kind == NodeKind.PrimaryType then
    if nodeData:get_meta_data() and nodeData:get_meta_data()[enums.K_TYPE_KIND] then
      if not parent then
        vim.notify("Primary type node must have parent", vim.log.levels.ERROR)
        return nil
      end
      return DataNode:new(nodeData, parent, project, rootNode)
    end
  elseif kind == NodeKind.Folder then
    if not parent or not project then
      vim.notify("Folder node must have parent and project.", vim.log.levels.ERROR)
      return nil
    end
    return DataNode:new(nodeData, parent, project, rootNode)
  elseif kind == NodeKind.CompilationUnit or kind == NodeKind.ClassFile or kind == NodeKind.File then
    if not parent then
      vim.notify("File node must have parent", vim.log.levels.ERROR)
      return nil
    end
    return DataNode:new(nodeData, parent, project, rootNode)
  end
end

function DataNode:is_unmanaged_folder()
  local natureIds = self._nodeData:get_meta_data() and self._nodeData:get_meta_data()[enums.NATURE_ID] or {}
  for _, natureId in ipairs(natureIds) do
    if natureId == enums.NatureId.UnmanagedFolder then
      return true
    end
  end
  return false
end

function DataNode:get_container_type()
  local containerPath = self._nodeData:get_path() or ""
  if vim.startswith(containerPath, enums.ContainerPath.JRE) then
    return enums.ContainerType.JRE
  elseif vim.startswith(containerPath, enums.ContainerPath.Maven) then
    return enums.ContainerType.Maven
  elseif vim.startswith(containerPath, enums.ContainerPath.Gradle) then
    return enums.ContainerType.Gradle
  elseif
    vim.startswith(containerPath, enums.ContainerPath.ReferencedLibrary) and self._project:is_unmanaged_folder()
  then
    return enums.ContainerType.ReferencedLibrary
  end
  return enums.ContainerType.Unknown
end

function DataNode:description()
  --TODO
end
function DataNode:command()
  --TODO
end

---@return boolean
function DataNode:has_children()
  local kind = self:kind()
  if
    kind == NodeKind.CompilationUnit
    or kind == NodeKind.ClassFile
    or kind == NodeKind.File
    or kind == NodeKind.PrimaryType
  then
    return false
  end
  return true
end

---@return TreeItemCollapsibleState
function DataNode:collapsible_state()
  if not self._collapsibleState then
    if self:has_children() then
      self._collapsibleState = CollapsibleState.Collapsed
    end
  end
  return self._collapsibleState
end

function DataNode:get_tree_item()
  local item = TreeItem:new(self)
  item.label = self._nodeData:get_display_name() or self._nodeData:get_name()
  item.description = self:description()
  -- item.icon = self:icon()
  item.command = self:command()
  if self._nodeData:get_uri() then
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
      item.resourceUri = self._nodeData:get_uri()
    end
  end
  return item
end

return DataNode
