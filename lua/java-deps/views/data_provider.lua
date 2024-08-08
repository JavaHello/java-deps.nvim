local M

---@class TreeItem
---@field label? string
---@field id? string
---@field icon? string
---@field level? number
---@field description? string
---@field resourceUri? string
---@field command? string
---@field collapsibleState? TreeItemCollapsibleState
---@field data? ExplorerNode
local TreeItem = {}

---@param nodes DataNode[]
---@return TreeItem[]
function M.flattenTree(nodes, _level)
  local level = _level or 0
  local result = {}
  for _, node in ipairs(nodes) do
    local c = node:getTreeItem()
    c.level = level
    table.insert(result, c)
    if node:hasChildren() then
      local children = M.flattenTree(node._childrenNodes, level + 1)
      for _, child in ipairs(children) do
        table.insert(result, child)
      end
    end
  end
  return result
end

return M
