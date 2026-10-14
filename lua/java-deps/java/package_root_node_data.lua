local NodeData = require("java-deps.java.node_data")

---@class PackageRootNodeData: NodeData
---@field entryKind PackageRootKind
---@field attributes? table<string, string>
local PackageRootNodeData = setmetatable({}, { __index = NodeData })
PackageRootNodeData.__index = PackageRootNodeData

---@return PackageRootKind
function PackageRootNodeData:get_entry_kind()
  return self.entryKind
end

---@return table<string, string>?
function PackageRootNodeData:get_attributes()
  return self.attributes
end

return PackageRootNodeData
