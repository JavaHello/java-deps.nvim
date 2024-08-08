local M = {}
---@enum NodeKind
M.NodeKind = {
  Workspace = 1,
  Project = 2,
  PackageRoot = 3,
  Package = 4,
  PrimaryType = 5,
  CompilationUnit = 6,
  ClassFile = 7,
  Container = 8,
  Folder = 9,
  File = 10,
}

---@enum TypeKind
M.TypeKind = {
  Class = 1,
  Interface = 2,
  Enum = 3,
}

---@class INodeData
---@field displayName? string
---@field name string
---@field moduleName? string
---@field path? string
---@field handlerIdentifier? string
---@field uri? string
---@field kind NodeKind
---@field children? any[]
---@field metaData? table<string, any>
local INodeData = {}
INodeData.__index = INodeData
function INodeData:new()
  return setmetatable({}, self)
end

M.INodeData = INodeData

return M
