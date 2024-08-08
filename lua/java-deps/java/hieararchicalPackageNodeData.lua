local _n = require("java-deps.java.nodeData")
local NodeKind = _n.NodeKind
local INodeData = _n.INodeData
local M = {}

---@class HierarchicalPackageNodeData: INodeData
---@field displayName string
---@field name string
---@field nodeData? INodeData
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
    self.children = self.children
    self.nodeData = self.nodeData
  end
  for _, child in ipairs(self.children) do
    child:compressTree()
  end
end
---@param packages string[]
---@param _nodeData INodeData
function HierarchicalPackageNodeData:addSubPackage(packages, _nodeData)
  if #packages == 0 then
    self.nodeData = _nodeData
    -- TODO
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
    local newNode = HierarchicalPackageNodeData:new(subPackageDisplayName, self.name)
    newNode:addSubPackage(packages, _nodeData)
    table.insert(self.children, newNode)
  end
end
function HierarchicalPackageNodeData:get_getUri()
  return self.nodeData and self.nodeData.uri
end
function HierarchicalPackageNodeData:get_moduleName()
  return self.nodeData and self.nodeData.moduleName
end

function HierarchicalPackageNodeData:get_path()
  return self.nodeData and self.nodeData.path
end

function HierarchicalPackageNodeData:get_kind()
  return self.nodeData and self.nodeData.kind or NodeKind.Package
end

function HierarchicalPackageNodeData:isPackage()
  return self.nodeData ~= nil
end

function HierarchicalPackageNodeData:handlerIdentifier()
  return self.nodeData and self.nodeData.handlerIdentifier
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
