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
---@field currentNodeData INodeData?
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
  self.currentNodeData = rpath and #rpath > 0 and rpath[#rpath] or nil
  ---@type INodeData
  local cpath = (rpath and #rpath > 0) and table.remove(rpath, 1) or nil
  for _, root in ipairs(project_nodes) do
    if cpath and cpath:getName() == root._nodeData:getName() and cpath:getPath() == root._nodeData:getPath() then
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
local function _flattenTree(result, nodes, level, hierarchy)
  if not nodes or #nodes == 0 then
    return
  end
  for idx, node in ipairs(nodes) do
    local c = node:getTreeItem()
    c.depth = level
    if idx == #nodes then
      hierarchy[level] = false
      c.isLast = true
    end
    c.hierarchy = vim.deepcopy(hierarchy)
    table.insert(result, c)
    if node._childrenNodes and #node._childrenNodes > 0 then
      c.collapsibleState = data_node.TreeItemCollapsibleState.Expanded
      _flattenTree(result, node._childrenNodes, level + 1, hierarchy)
    end
  end
end

---@return TreeItem[]
function DataProvider:flattenTree()
  local result = {}
  _flattenTree(result, self._rootItems, 0, {})
  return result
end

---获取当前节点位置
---@param treeItems TreeItem[]
function DataProvider:findCurrentNode(treeItems)
  if not treeItems or #treeItems == 0 then
    return
  end
  for idx, item in ipairs(treeItems) do
    if
      item.data
      and item.data._nodeData:getName() == self.currentNodeData:getName()
      and item.data._nodeData:getPath() == self.currentNodeData:getPath()
    then
      return idx, item
    end
  end
end

M.DataProvider = DataProvider

return M
