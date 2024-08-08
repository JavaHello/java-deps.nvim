---@class ExplorerNode
---@field _parent? ExplorerNode

local M = {}

local ExplorerNode = {}
ExplorerNode.__index = ExplorerNode

function ExplorerNode:new()
  return setmetatable({}, self)
end

---@param node ExplorerNode
---@param levelToCheck number
function ExplorerNode:isItselfOrAncestorOf(node, levelToCheck)
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

M.ExplorerNode = ExplorerNode
return M
