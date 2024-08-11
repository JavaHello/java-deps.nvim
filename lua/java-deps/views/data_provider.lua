local jdtls = require("java-deps.java.jdtls")
local data_node = require("java-deps.views.data_node")
local M = {}

---@class TreeItem
---@field label? string
---@field id? string
---@field icon? string
---@field depth? number
---@field description? string
---@field resourceUri? string
---@field command? string
---@field collapsibleState? TreeItemCollapsibleState
---@field isLast? boolean
---@field data? DataNode
---@field hierarchy? table
local TreeItem = {}

---@class DataProvider
---@field rootPath string
---@field currentPath string
---@field _rootItems DataNode[]?
local DataProvider = {}
DataProvider.__index = DataProvider

function DataProvider:new(rootPath, currentPath)
  return setmetatable({
    rootPath = rootPath,
    currentPath = currentPath,
    _rootItems = {},
  }, self)
end
---@return INodeData[]?
function DataProvider:getRootNodes()
  return jdtls.getProjects(self.rootPath)
end

---@param projects? INodeData[]
---@return DataNode[]?
function DataProvider:_revealPaths(projects)
  if not projects or #projects == 0 then
    return
  end

  ---@type DataNode[]
  local project_nodes = {}
  for _, project in ipairs(projects) do
    if project then
      local root = data_node.createNode(project)
      if root then
        table.insert(project_nodes, root)
      end
    end
  end
  ---@type INodeData[]
  local rpath = jdtls.resolvePath(self.currentPath)
  ---@type INodeData
  local cpath = (rpath and #rpath > 0) and table.remove(rpath, 1) or nil
  for _, root in ipairs(project_nodes) do
    if cpath and cpath.name == root._nodeData.name and cpath.path == root._nodeData.path then
      root:revealPaths(rpath)
      break
    end
  end
  self._rootItems = project_nodes
  return project_nodes
end

---@return DataNode[]?
function DataProvider:revealPaths()
  return self:_revealPaths(self:getRootNodes())
end

---@param nodes DataNode[]
---@return TreeItem[]
local function _flattenTree(nodes, _level, hierarchy)
  local level = _level or 0
  local result = {}
  for idx, node in ipairs(nodes) do
    local c = node:getTreeItem()
    local _hierarchy = hierarchy or {}
    c.depth = level
    if idx == #nodes then
      _hierarchy[level] = false
      c.isLast = true
    end
    c.hierarchy = vim.deepcopy(_hierarchy)
    table.insert(result, c)
    if node:hasChildren() then
      local children = _flattenTree(node._childrenNodes, level + 1, _hierarchy)
      for _, child in ipairs(children) do
        table.insert(result, child)
      end
    end
  end
  return result
end

---@return TreeItem[]
function DataProvider:flattenTree()
  return _flattenTree(self._rootItems, 0, nil)
end

M.DataProvider = DataProvider

return M
