local config = require("java-deps.config")
local enums = require("java-deps.java.enums")
local NodeKind = enums.NodeKind
local TypeKind = enums.TypeKind
local PackageRootKind = enums.PackageRootKind
local has_devicons, devicons = pcall(require, "nvim-web-devicons")

---@class Icon
---@field icon string
---@field hl string?

local defaults = {
  NodeKind = {
    [NodeKind.Workspace] = { icon = "", hl = "Type" },
    [NodeKind.Project] = { icon = "" },
    [NodeKind.PackageRoot] = { icon = "" },
    [NodeKind.Package] = { icon = "" },
    [NodeKind.PrimaryType] = { icon = "󰠱" },
    [NodeKind.CompilationUnit] = { icon = "" },
    [NodeKind.ClassFile] = { icon = "" },
    [NodeKind.Container] = { icon = "" },
    [NodeKind.Folder] = { icon = "" },
    [NodeKind.File] = { icon = "󰈙" },
  },
  TypeKind = {
    [TypeKind.Class] = { icon = "󰠱" },
    [TypeKind.Interface] = { icon = "" },
    [TypeKind.Enum] = { icon = "" },
  },
  EntryKind = {
    [PackageRootKind.K_SOURCE] = { icon = "" },
    [PackageRootKind.K_BINARY] = { icon = "" },
  },
}

local M = {}
local enum_names = {
  NodeKind = NodeKind,
  TypeKind = TypeKind,
  EntryKind = PackageRootKind,
}

local file_like_extensions = {
  [NodeKind.PrimaryType] = "java",
  [NodeKind.CompilationUnit] = "java",
  [NodeKind.ClassFile] = "class",
}

local file_like_kinds = {
  [NodeKind.PrimaryType] = true,
  [NodeKind.CompilationUnit] = true,
  [NodeKind.ClassFile] = true,
  [NodeKind.File] = true,
}

---@param value string|Icon|nil
---@return Icon
local function normalize_icon(value)
  if type(value) == "string" then
    return { icon = value }
  end
  if type(value) == "table" then
    return vim.deepcopy(value)
  end
  return {}
end

---@param category "NodeKind"|"TypeKind"|"EntryKind"
---@param overrides table
---@param key integer|string
local function get_override_value(category, overrides, key)
  if overrides[key] ~= nil then
    return overrides[key]
  end

  for name, value in pairs(enum_names[category]) do
    if value == key then
      return overrides[name]
    end
  end
end

---@param node DataNode
---@return Icon
local function get_devicon_icon(node)
  if not has_devicons then
    return {}
  end

  local kind = node:kind()
  if not file_like_kinds[kind] then
    return {}
  end

  local name = node._nodeData:get_name()
  local path = node._nodeData:get_path()
  local filename = path or name
  local extension = file_like_extensions[kind]

  if type(filename) ~= "string" or filename == "" then
    return {}
  end

  local basename = vim.fs.basename(filename)

  if extension == nil then
    extension = basename:match("%.([^./\\]+)$")
  end

  local icon, hl = devicons.get_icon(basename, extension, { default = false })
  if icon == nil and hl == nil then
    return {}
  end
  return {
    icon = icon,
    hl = hl,
  }
end

---@param category "NodeKind"|"TypeKind"|"EntryKind"
---@param key integer|string
---@param node? DataNode
---@return Icon
local function resolve_icon(category, key, node)
  local symbol_config = config.options.symbols or {}
  local icon_overrides = (symbol_config.icons or {})[category] or {}
  local highlight_overrides = (symbol_config.highlights or {})[category] or {}
  local devicon = node ~= nil and get_devicon_icon(node) or {}

  local icon = vim.tbl_deep_extend(
    "force",
    defaults[category][key] or {},
    devicon,
    normalize_icon(get_override_value(category, icon_overrides, key))
  )
  local hl_override = get_override_value(category, highlight_overrides, key)
  if hl_override ~= nil then
    icon.hl = hl_override
  end

  return icon
end

---@param node DataNode
---@return Icon
M.get_icon = function(node)
  local kind = node:kind()
  if kind == NodeKind.PrimaryType then
    return resolve_icon("TypeKind", node:type_kind(), node)
  end
  if kind == NodeKind.PackageRoot then
    local entry_kind = node._nodeData:get_entry_kind()
    local entry_icon = resolve_icon("EntryKind", entry_kind, node)
    if entry_icon.icon ~= nil then
      return entry_icon
    end
  end
  return resolve_icon("NodeKind", kind, node)
end

return M
