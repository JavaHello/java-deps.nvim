local NodeData = require("java-deps.java.node_data")

---@class ContainerNodeData: NodeData
---@field entryKind ContainerEntryKind
local ContainerNodeData = setmetatable({}, { __index = NodeData })
ContainerNodeData.__index = ContainerNodeData

---@return ContainerEntryKind
function ContainerNodeData:get_entry_kind()
  return self.entryKind
end

return ContainerNodeData
