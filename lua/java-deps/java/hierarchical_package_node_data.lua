local NodeData = require("java-deps.java.node_data")
local NodeKind = require("java-deps.java.enums").NodeKind

-- 层级包视图的节点: 把 com.example.a 拆成 com -> example -> a 的树.
-- 中间层(如 com.example)不一定是真实存在的包, 此时 _nodeData 为 nil
---@class HierarchicalPackageNodeData: NodeData
---@field displayName string
---@field name string
---@field children HierarchicalPackageNodeData[]
---@field _nodeData? NodeData 对应的真实包数据
local HierarchicalPackageNodeData = setmetatable({}, { __index = NodeData })
HierarchicalPackageNodeData.__index = HierarchicalPackageNodeData

---@param display_name string
---@param parent_name? string
---@return HierarchicalPackageNodeData
function HierarchicalPackageNodeData:new(display_name, parent_name)
  local name = (parent_name == nil or parent_name == "") and display_name or parent_name .. "." .. display_name
  return setmetatable({
    displayName = display_name,
    name = name,
    children = {},
  }, self)
end

---@param package_list NodeData[]
---@return HierarchicalPackageNodeData
function HierarchicalPackageNodeData.from_package_list(package_list)
  local root = HierarchicalPackageNodeData:new("", "")
  for _, node_data in ipairs(package_list) do
    root:add_sub_package(vim.split(node_data.name, "%."), node_data)
  end
  root:compress_tree()
  return root
end

-- 合并只有一个子节点的中间层, 如 com -> example 合并为 com.example
function HierarchicalPackageNodeData:compress_tree()
  while self.name ~= "" and #self.children == 1 and not self:is_package() do
    local child = self.children[1]
    self.name = self.name .. "." .. child.displayName
    self.displayName = self.displayName .. "." .. child.displayName
    self.children = child.children
    self._nodeData = child._nodeData
  end
  for _, child in ipairs(self.children) do
    child:compress_tree()
  end
end

---@param packages string[]
---@param node_data NodeData
function HierarchicalPackageNodeData:add_sub_package(packages, node_data)
  if #packages == 0 then
    self._nodeData = node_data
    return
  end
  local sub_package_display_name = table.remove(packages, 1)
  for _, child in ipairs(self.children) do
    if child.displayName == sub_package_display_name then
      child:add_sub_package(packages, node_data)
      return
    end
  end
  local new_node = HierarchicalPackageNodeData:new(sub_package_display_name, self.name)
  new_node:add_sub_package(packages, node_data)
  table.insert(self.children, new_node)
end

---是否对应真实存在的包
---@return boolean
function HierarchicalPackageNodeData:is_package()
  return self._nodeData ~= nil
end

-- 中间层也按包处理, 否则会被当成未知节点丢弃
function HierarchicalPackageNodeData:get_kind()
  return NodeKind.Package
end

function HierarchicalPackageNodeData:get_module_name()
  return self._nodeData and self._nodeData.moduleName
end

function HierarchicalPackageNodeData:get_path()
  return self._nodeData and self._nodeData.path
end

function HierarchicalPackageNodeData:get_handler_identifier()
  return self._nodeData and self._nodeData.handlerIdentifier
end

function HierarchicalPackageNodeData:get_uri()
  return self._nodeData and self._nodeData.uri
end

function HierarchicalPackageNodeData:get_meta_data()
  return self._nodeData and self._nodeData.metaData
end

return HierarchicalPackageNodeData
