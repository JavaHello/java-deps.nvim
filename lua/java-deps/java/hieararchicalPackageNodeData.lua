local nodeData = require("java-deps.java.nodeData")
local NodeKind = nodeData.NodeKind
local INodeData = nodeData.INodeData

---@class HierarchicalPackageNodeData: INodeData
---@field displayName string
---@field name string
---@field nodeData? INodeData
---@field children HierarchicalPackageNodeData[]
local HieararchicalPackageNodeData = nodeData.INodeData:new()
HieararchicalPackageNodeData.__index = HieararchicalPackageNodeData

---@param displayName string
---@param parentName? string
function HieararchicalPackageNodeData:new(displayName, parentName)
  local name = (parentName == nil or parentName == "") and displayName or parentName .. "." .. displayName
  local base = INodeData:new()
  base.displayName = displayName
  base.name = name
  base.children = {}
  return setmetatable(base, self)
end

function HieararchicalPackageNodeData:compressTree()
  while self.name ~= "" and #self.children == 1 and not self:isPackage() do
    local child = self.children[1]
    self.name = self.name .. "." .. child.displayName
    self.displayName = self.displayName .. "." .. child.displayName
    self.children = self.children
    self.nodeData = self.nodeData
  end
  for _, child in ipairs(self.children) do
    child:compressTree()
  end
end
---@param packages string[]
---@param _nodeData INodeData
function HieararchicalPackageNodeData:addSubPackage(packages, _nodeData)
  if #packages == 0 then
    self.nodeData = _nodeData
    return
  end
  local subPackageDisplayName = table.remove(packages, 1)
  local childNode = nil
  for _, child in ipairs(self.children) do
    if child.displayName == subPackageDisplayName then
      childNode = child
      break
    end
  end
  if childNode then
    childNode:addSubPackage(packages, _nodeData)
  else
    local newNode = HieararchicalPackageNodeData:new(subPackageDisplayName, self.name)
    newNode:addSubPackage(packages, _nodeData)
    table.insert(self.children, newNode)
  end
end
function HieararchicalPackageNodeData:getUri()
  return self.nodeData and self.nodeData.uri
end
function HieararchicalPackageNodeData:moduleName()
  return self.nodeData and self.nodeData.moduleName
end

function HieararchicalPackageNodeData:path()
  return self.nodeData and self.nodeData.path
end

function HieararchicalPackageNodeData:kind()
  return self.nodeData and self.nodeData.kind or NodeKind.Package
end

function HieararchicalPackageNodeData:isPackage()
  return self.nodeData ~= nil
end

function HieararchicalPackageNodeData:handlerIdentifier()
  return self.nodeData and self.nodeData.handlerIdentifier
end

return HieararchicalPackageNodeData
