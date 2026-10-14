local config = require("java-deps.config")
local enums = require("java-deps.java.enums")
local NodeKind = enums.NodeKind
local TypeKind = enums.TypeKind
local PackageRootKind = enums.PackageRootKind
local has_devicons, devicons = pcall(require, "nvim-web-devicons")

---@class Icon
---@field icon string
---@field hl string?

-- 默认图标与 vscode-java-dependency 一致, 使用 codicon (nf-cod-*)
local defaults = {
  NodeKind = {
    [NodeKind.Workspace] = { icon = "", hl = "Directory" },
    [NodeKind.Project] = { icon = "", hl = "Directory" },
    [NodeKind.PackageRoot] = { icon = "", hl = "Directory" },
    [NodeKind.Package] = { icon = "", hl = "Include" },
    [NodeKind.PrimaryType] = { icon = "", hl = "Type" },
    [NodeKind.CompilationUnit] = { icon = "", hl = "Normal" },
    [NodeKind.ClassFile] = { icon = "", hl = "Type" },
    [NodeKind.Container] = { icon = "", hl = "Special" },
    [NodeKind.Folder] = { icon = "", hl = "Directory" },
    [NodeKind.File] = { icon = "", hl = "Normal" },
  },
  TypeKind = {
    [TypeKind.Class] = { icon = "", hl = "Type" },
    [TypeKind.Interface] = { icon = "", hl = "Function" },
    [TypeKind.Enum] = { icon = "", hl = "Constant" },
  },
  EntryKind = {
    [PackageRootKind.K_SOURCE] = { icon = "", hl = "Directory" },
    [PackageRootKind.K_BINARY] = { icon = "", hl = "DiagnosticWarn" },
  },
  -- 项目统一使用 project 图标, 需要区分时可在 symbols.icons.ProjectKind 中覆盖
  ProjectKind = {
    MavenParent = { icon = "", hl = "Directory" },
    Maven = { icon = "", hl = "Directory" },
    GradleRoot = { icon = "", hl = "Directory" },
    Gradle = { icon = "", hl = "Directory" },
    UnmanagedFolder = { icon = "", hl = "Directory" },
    Java = { icon = "", hl = "Directory" },
  },
  -- 依赖容器统一使用 folder-library 图标, 用颜色区分 JDK / Maven / Gradle
  ContainerKind = {
    JRE = { icon = "", hl = "DiagnosticWarn" },
    Maven = { icon = "", hl = "DiagnosticError" },
    Gradle = { icon = "", hl = "DiagnosticInfo" },
    ReferencedLibrary = { icon = "", hl = "Special" },
  },
}

local M = {}
local enum_names = {
  NodeKind = NodeKind,
  TypeKind = TypeKind,
  EntryKind = PackageRootKind,
}

local file_like_extensions = {
  [NodeKind.CompilationUnit] = "java",
}

-- 只有普通文件使用 devicons, 类型节点保留 class/interface/enum 各自的图标
local file_like_kinds = {
  [NodeKind.CompilationUnit] = true,
  [NodeKind.File] = true,
}

-- 按优先级匹配项目的 nature
local project_natures = {
  { enums.NatureId.Maven, "Maven" },
  { enums.NatureId.Gradle, "Gradle" },
  { enums.NatureId.BspGradle, "Gradle" },
  { enums.NatureId.UnmanagedFolder, "UnmanagedFolder" },
}

local container_paths = {
  { enums.ContainerPath.JRE, "JRE" },
  { enums.ContainerPath.Maven, "Maven" },
  { enums.ContainerPath.Gradle, "Gradle" },
  { enums.ContainerPath.ReferencedLibrary, "ReferencedLibrary" },
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

---@alias IconCategory "NodeKind"|"TypeKind"|"EntryKind"|"ProjectKind"|"ContainerKind"

---@param category IconCategory
---@param overrides table
---@param key integer|string
local function get_override_value(category, overrides, key)
  if overrides[key] ~= nil then
    return overrides[key]
  end

  for name, value in pairs(enum_names[category] or {}) do
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

-- 项目类型完全由 jdtls 返回的 nature 判断:
-- 聚合父工程(packaging=pom)/gradle 根工程没有 java 代码, 只有构建工具 nature, 没有 javanature
---@param node DataNode
---@return string
local function get_project_kind(node)
  local meta_data = node._nodeData:get_meta_data() or {}
  local nature_ids = meta_data[enums.NATURE_ID]
  if type(nature_ids) == "string" then
    nature_ids = { nature_ids }
  end
  if type(nature_ids) ~= "table" then
    return "Java"
  end

  local is_java = vim.tbl_contains(nature_ids, enums.NatureId.Java)
  for _, item in ipairs(project_natures) do
    if vim.tbl_contains(nature_ids, item[1]) then
      local kind = item[2]
      if not is_java and kind == "Maven" then
        return "MavenParent"
      elseif not is_java and kind == "Gradle" then
        return "GradleRoot"
      end
      return kind
    end
  end
  return "Java"
end

---@param node DataNode
---@return string?
local function get_container_kind(node)
  local path = node._nodeData:get_path()
  if type(path) ~= "string" then
    return nil
  end
  for _, item in ipairs(container_paths) do
    if vim.startswith(path, item[1]) then
      return item[2]
    end
  end
end

---@param category IconCategory
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
  local category, key
  if kind == NodeKind.PrimaryType then
    category, key = "TypeKind", node:type_kind()
  elseif kind == NodeKind.Project then
    category, key = "ProjectKind", get_project_kind(node)
  elseif kind == NodeKind.Container then
    category, key = "ContainerKind", get_container_kind(node)
  elseif kind == NodeKind.PackageRoot then
    -- 与 vscode 一致: jdk 模块(如 java.base)虽然是二进制, 也按源码根显示
    local entry_kind = node._nodeData:get_module_name() and PackageRootKind.K_SOURCE or node._nodeData:get_entry_kind()
    category, key = "EntryKind", entry_kind
  end

  if category ~= nil and key ~= nil then
    local icon = resolve_icon(category, key, node)
    if icon.icon ~= nil then
      return icon
    end
  end
  return resolve_icon("NodeKind", kind, node)
end

return M
