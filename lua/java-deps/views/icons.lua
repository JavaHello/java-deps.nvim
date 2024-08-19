local node_data = require("java-deps.java.nodeData")
local NodeKind = node_data.NodeKind
local TypeKind = node_data.TypeKind
local M = {
  NodeKind = {
    [NodeKind.Workspace] = { icon = "", hl = "@lsp.type.class" },
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
}

---comment
---@param node DataNode
---@return string
M.get_icon = function(node)
  local kind = node:kind()
  if kind == node_data.NodeKind.PrimaryType then
    return M.TypeKind[node:typeKind()].icon
  else
    return M.NodeKind[kind].icon
  end
end

return M
