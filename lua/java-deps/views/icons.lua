local node_data = require("java-deps.java.nodeData")
local PackageRootKind = require("java-deps.java.IPackageRootNodeData").PackageRootKind
local NodeKind = node_data.NodeKind
local TypeKind = node_data.TypeKind

---@class Icon
---@field icon string
---@field hl string?

local M = {
  NodeKind = {
    [NodeKind.Workspace] = { icon = "", hl = "Type" },
    [NodeKind.Project] = { icon = "" },
    [NodeKind.PackageRoot] = { icon = "" },
    [NodeKind.Package] = { icon = "" },
    [NodeKind.PrimaryType] = { icon = "󰠱" },
    [NodeKind.CompilationUnit] = { icon = "" },
    [NodeKind.ClassFile] = { icon = "" },
    [NodeKind.Container] = { icon = "" },
    [NodeKind.Folder] = { icon = "󰉋" },
    [NodeKind.File] = { icon = "󰈙" },
  },
  TypeKind = {
    [TypeKind.Class] = { icon = "󰠱" },
    [TypeKind.Interface] = { icon = "" },
    [TypeKind.Enum] = { icon = "" },
  },
  EntryKind = {
    [PackageRootKind.K_SOURCE] = { icon = "" },
    [PackageRootKind.K_BINARY] = { icon = "" },
  },
}

---@param node DataNode
---@return Icon
M.get_icon = function(node)
  local kind = node:kind()
  if kind == node_data.NodeKind.PrimaryType then
    return M.TypeKind[node:typeKind()]
  else
    return M.NodeKind[kind]
  end
end

return M
