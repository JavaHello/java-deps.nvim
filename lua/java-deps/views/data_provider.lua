local jdtls = require("java-deps.java.jdtls")
local DataNode = require("java-deps.views.data_node")

---@class DataProvider
---@field rootPath string
---@field revealNode NodeData?
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
function DataProvider:get_root_projects()
  if self._rootProjects and #self._rootProjects > 0 then
    return self._rootProjects
  end

  local rootProjects = {}
  for _, project in ipairs(jdtls.get_projects(self.rootPath)) do
    if project then
      local root = DataNode.create(project)
      if root then
        table.insert(rootProjects, root)
      end
    end
  end
  self._rootProjects = rootProjects
  return rootProjects
end

function DataProvider:reveal_paths(paths)
  ---@type NodeData[]
  local rpath = paths or {}
  self.revealNode = rpath and #rpath > 0 and rpath[#rpath] or nil
  ---@type NodeData
  local cpath = (rpath and #rpath > 0) and table.remove(rpath, 1) or nil

  local projects = self:get_root_projects()
  for _, root in ipairs(projects) do
    if cpath and cpath:get_name() == root._nodeData:get_name() and cpath:get_path() == root._nodeData:get_path() then
      root:reveal_paths(rpath)
      break
    end
  end
end

---@param nodes DataNode[]
local function flatten_tree_recursive(result, nodes, level, hierarchy)
  if not nodes or #nodes == 0 then
    return
  end
  for idx, node in ipairs(nodes) do
    local c = node:get_tree_item()
    c.hierarchy = vim.deepcopy(hierarchy)
    c.depth = level
    if idx == #nodes then
      -- 如果是最后一个节点, 子节点不需要再画竖线
      c.hierarchy[level] = true
      c.isLast = true
    end
    table.insert(result, c)
    if node._childrenNodes and #node._childrenNodes > 0 and c:is_expanded() then
      flatten_tree_recursive(result, node._childrenNodes, level + 1, c.hierarchy)
    end
  end
end

---@return TreeItem[]
function DataProvider:flatten_tree()
  ---@type TreeItem[]
  local result = {}
  flatten_tree_recursive(result, self:get_root_projects(), 0, {})
  return result
end

---获取当前节点位置
---@param treeItems TreeItem[]
function DataProvider:find_reveal_node(treeItems)
  if not treeItems or #treeItems == 0 then
    return
  end
  for idx, item in ipairs(treeItems) do
    if
      item.data
      and item.data._nodeData:get_name() == self.revealNode:get_name()
      and item.data._nodeData:get_path() == self.revealNode:get_path()
    then
      return idx, item
    end
  end
end

return DataProvider
