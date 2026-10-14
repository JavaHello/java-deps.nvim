local NodeKind = require("java-deps.java.enums").NodeKind
local NodeData = require("java-deps.java.node_data")
local PackageRootNodeData = require("java-deps.java.package_root_node_data")
local ContainerNodeData = require("java-deps.java.container_node_data")

-- 根据 kind 把 jdtls 返回的原始数据包装成对应的 NodeData 子类
local M = {}

---@type table<NodeKind, NodeData>
local classes = {
  [NodeKind.PackageRoot] = PackageRootNodeData,
  [NodeKind.Container] = ContainerNodeData,
}

---@param data table
---@return NodeData
function M.create(data)
  local node = (classes[data.kind] or NodeData):new(data)
  if node.children then
    node.children = M.create_list(node.children)
  end
  return node
end

---@param list table[]?
---@return NodeData[]
function M.create_list(list)
  local nodes = {}
  for _, data in ipairs(list or {}) do
    table.insert(nodes, M.create(data))
  end
  return nodes
end

return M
