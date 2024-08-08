local INodeData = require("java-deps.java.nodeData").INodeData
local M = {}

---@enum ContainerEntryKind
M.ContainerEntryKind = {
  CPE_LIBRARY = 1,
  CPE_PROJECT = 2,
  CPE_SOURCE = 3,
  CPE_VARIABLE = 4,
  CPE_CONTAINER = 5,
}
---@class IContainerNodeData: INodeData
---@field entryKind ContainerEntryKind
local IContainerNodeData = INodeData:new()
IContainerNodeData.__index = IContainerNodeData

function IContainerNodeData:new()
  return setmetatable(INodeData:new(), self)
end
M.IContainerNodeData = IContainerNodeData

return M
