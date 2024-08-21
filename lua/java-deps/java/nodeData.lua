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

function INodeData:form(resp)
  return setmetatable(resp, self)
end
---@param resp table?
---@return INodeData[]
M.generateNodeList = function(resp)
  if not resp then
    return {}
  end
  local nodes = {}
  for _, node in ipairs(resp) do
    table.insert(nodes, INodeData:form(node))
  end
  return nodes
end
function INodeData:getDisplayName()
  return self.displayName
end

function INodeData:getName()
  return self.name
end
function INodeData:getModuleName()
  return self.moduleName
end
function INodeData:getPath()
  return self.path
end

function INodeData:getHandlerIdentifier()
  return self.handlerIdentifier
end

function INodeData:getUri()
  return self.uri
end

function INodeData:getKind()
  return self.kind
end

function INodeData:getChildren()
  return self.children
end

function INodeData:getMetaData()
  return self.metaData
end

M.INodeData = INodeData

return M
