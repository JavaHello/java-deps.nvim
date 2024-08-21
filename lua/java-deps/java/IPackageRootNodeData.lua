local INodeData = require("java-deps.java.nodeData").INodeData
local M = {}
---@enum PackageRootKind
M.PackageRootKind = {
  K_SOURCE = 1,
  K_BINARY = 2,
}

---@class IPackageRootNodeData:INodeData
---@field entryKind PackageRootKind
---@field attributes table<string, string>
local IPackageRootNodeData = INodeData:new()
IPackageRootNodeData.__index = IPackageRootNodeData
function IPackageRootNodeData:new()
  return setmetatable(INodeData:new(), self)
end

---@param node INodeData
---@return IPackageRootNodeData
function IPackageRootNodeData:form(node)
  return setmetatable(node, self)
end

function IPackageRootNodeData:getEntryKind()
  return self.entryKind
end

function IPackageRootNodeData:getAttributes()
  return self.attributes
end

M.IPackageRootNodeData = IPackageRootNodeData

return M
