local jdtls = require("java-deps.java.jdtls")
local data_node = require("java-deps.views.data_node")
local M = {}

---@class DataProvider
---@field rootPath string
---@field revealNode INodeData?
---@field _rootProjects DataNode[]?
local DataProvider = {}
DataProvider.__index = DataProvider

function DataProvider:new(rootPath)
  return setmetatable({
    rootPath = rootPath,
    _rootProjects = {},
  }, self)
end

---@return DataNode[]
function DataProvider:getRootProjects()
  if self._rootProjects and #self._rootProjects > 0 then
    return self._rootProjects
  end

  local rootProjects = {}
  for _, project in ipairs(jdtls.getProjects(self.rootPath)) do
    if project then
      local root = data_node.createNode(project)
      if root then
        table.insert(rootProjects, root)
      end
    end
  end
  self._rootProjects = rootProjects
  return rootProjects
end

function DataProvider:revealPaths(paths)
  ---@type INodeData[]
  local rpath = paths or {}
  self.revealNode = rpath and #rpath > 0 and rpath[#rpath] or nil
  ---@type INodeData
  local cpath = (rpath and #rpath > 0) and table.remove(rpath, 1) or nil

  local projects = self:getRootProjects()
  for _, root in ipairs(projects) do
    if cpath and cpath:getName() == root._nodeData:getName() and cpath:getPath() == root._nodeData:getPath() then
      root:revealPaths(rpath)
      break
    end
  end
end

---@param nodes DataNode[]
local function _flattenTree(result, nodes, level, hierarchy)
  if not nodes or #nodes == 0 then
    return
  end
  for idx, node in ipairs(nodes) do
    local c = node:getTreeItem()
    c.hierarchy = vim.deepcopy(hierarchy)
    c.depth = level
    if idx == #nodes then
      -- 如果是最后一个节点, 子节点不需要再画竖线
      c.hierarchy[level] = true
      c.isLast = true
    end
    table.insert(result, c)
    if node._childrenNodes and #node._childrenNodes > 0 and c:is_expanded() then
      _flattenTree(result, node._childrenNodes, level + 1, c.hierarchy)
    end
  end
end

---@return TreeItem[]
function DataProvider:flattenTree()
  ---@type TreeItem[]
  local result = {}
  _flattenTree(result, self:getRootProjects(), 0, {})
  return result
end

---获取当前节点位置
---@param treeItems TreeItem[]
function DataProvider:findRevealNode(treeItems)
  if not treeItems or #treeItems == 0 then
    return
  end
  for idx, item in ipairs(treeItems) do
    if
      item.data
      and item.data._nodeData:getName() == self.revealNode:getName()
      and item.data._nodeData:getPath() == self.revealNode:getPath()
    then
      return idx, item
    end
  end
end

M.DataProvider = DataProvider

return M
