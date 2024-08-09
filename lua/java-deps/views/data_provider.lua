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

---@param nodes DataNode[]
---@return TreeItem[]
function M.flattenTree(nodes, _level)
  local level = _level or 0
  local result = {}
  for idx, node in ipairs(nodes) do
    local c = node:getTreeItem()
    c.depth = level
    if idx == #nodes then
      c.isLast = true
    end
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
