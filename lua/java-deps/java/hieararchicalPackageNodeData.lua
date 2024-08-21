local _n = require("java-deps.java.nodeData")
local _ipkg = require("java-deps.java.IPackageRootNodeData")
local INodeData = _n.INodeData
local IPackageRootNodeData = _ipkg.IPackageRootNodeData
local M = {}

---@class HierarchicalPackageNodeData: INodeData
---@field displayName string
---@field name string
---@field _nodeData? INodeData
---@field children HierarchicalPackageNodeData[]
local HierarchicalPackageNodeData = INodeData:new()
HierarchicalPackageNodeData.__index = HierarchicalPackageNodeData

---@param displayName string
---@param parentName? string
---@return HierarchicalPackageNodeData
function HierarchicalPackageNodeData:new(displayName, parentName)
  local name = (parentName == nil or parentName == "") and displayName or parentName .. "." .. displayName
  return setmetatable({
    displayName = displayName,
    name = name,
    children = {},
  }, self)
end

function HierarchicalPackageNodeData:compressTree()
  while self.name ~= "" and #self.children == 1 and not self:isPackage() do
    local child = self.children[1]
    self.name = self.name .. "." .. child.displayName
    self.displayName = self.displayName .. "." .. child.displayName
    self.children = child.children
    self._nodeData = child._nodeData
  end
  for _, child in ipairs(self.children) do
    child:compressTree()
  end
end
---@param packages string[]
---@param nodeData INodeData
function HierarchicalPackageNodeData:addSubPackage(packages, nodeData)
  if #packages == 0 then
    self._nodeData = nodeData
    return
  end
  local subPackageDisplayName = table.remove(packages, 1)
  ---@type HierarchicalPackageNodeData?
  local childNode
  for _, child in ipairs(self.children) do
    if child.displayName == subPackageDisplayName then
      childNode = child
      break
    end
  end
  if childNode then
    childNode:addSubPackage(packages, nodeData)
  else
    local newNode = HierarchicalPackageNodeData:new(subPackageDisplayName, self.name)
    newNode:addSubPackage(packages, nodeData)
    table.insert(self.children, newNode)
  end
end

function HierarchicalPackageNodeData:isPackage()
  return self._nodeData ~= nil
end

function HierarchicalPackageNodeData:getDisplayName()
  return self.displayName
end

function HierarchicalPackageNodeData:getName()
  return self.name
end
function HierarchicalPackageNodeData:getModuleName()
  return self._nodeData and self._nodeData.moduleName
end
function HierarchicalPackageNodeData:getPath()
  return self._nodeData and self._nodeData.path
end

function HierarchicalPackageNodeData:getHandlerIdentifier()
  return self._nodeData and self._nodeData.handlerIdentifier
end

function HierarchicalPackageNodeData:getUri()
  return self._nodeData and self._nodeData.uri
end

function HierarchicalPackageNodeData:getKind()
  return self._nodeData and self._nodeData.kind
end

function HierarchicalPackageNodeData:getChildren()
  return self.children
end

function HierarchicalPackageNodeData:getMetaData()
  return self._nodeData and self._nodeData.metaData
end

function HierarchicalPackageNodeData:getEntryKind()
  return self._nodeData and IPackageRootNodeData:form(self._nodeData):getEntryKind()
end

M.HierarchicalPackageNodeData = HierarchicalPackageNodeData

---@param packageList INodeData[]
---@return HierarchicalPackageNodeData
M.createHierarchicalNodeDataByPackageList = function(packageList)
  local result = HierarchicalPackageNodeData:new("", "")
  for _, nodeData in ipairs(packageList) do
    local packages = vim.split(nodeData.name, "%.")
    result:addSubPackage(packages, nodeData)
  end
  result:compressTree()
  return result
end

return M
