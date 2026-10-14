---@class ExplorerNode
---@field _parent? ExplorerNode
local ExplorerNode = {}
ExplorerNode.__index = ExplorerNode

function ExplorerNode:new()
  return setmetatable({}, self)
end

---@param node ExplorerNode
---@param levelToCheck number
function ExplorerNode:is_itself_or_ancestor_of(node, levelToCheck)
  levelToCheck = levelToCheck or math.huge
  while node and levelToCheck >= 0 do
    if self == node then
      return true
    end
    node = node._parent
    levelToCheck = levelToCheck - 1
  end
  return false
end

return ExplorerNode
