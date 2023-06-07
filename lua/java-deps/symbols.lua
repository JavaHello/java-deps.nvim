local config = require("java-deps.config")
local M = {}
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

  -- metaData.TypeKind
  CLASS = 11,
  INTERFACE = 12,
  ENUM = 13,

  JAR = 24,
}

M.TypeKind = {
  Class = 1,
  Interface = 2,
  Enum = 3,
}

M.kinds = {
  "Workspace",
  "Project",
  "PackageRoot",
  "Package",
  "PrimaryType",
  "CompilationUnit",
  "ClassFile",
  "Container",
  "Folder",
  "File",

  -- metaData.TypeKind
  [M.NodeKind.CLASS] = "CLASS",
  [M.NodeKind.INTERFACE] = "INTERFACE",
  [M.NodeKind.ENUM] = "ENUM",

  [M.NodeKind.JAR] = "JAR",
}

M.ContainerEntryKind = {
  CPE_LIBRARY = 1,
  CPE_PROJECT = 2,
  CPE_SOURCE = 3,
  CPE_VARIABLE = 4,
  CPE_CONTAINER = 5,
}
M.PackageRootKind = {
  K_SOURCE = 1,
  K_BINARY = 2,
}

M.ContainerType = {
  JRE = "jre",
  Maven = "maven",
  Gradle = "gradle",
  ReferencedLibrary = "referencedLibrary",
  Unknown = "",
}

M.ContainerPath = {
  JRE = "org.eclipse.jdt.launching.JRE_CONTAINER",
  Maven = "org.eclipse.m2e.MAVEN2_CLASSPATH_CONTAINER",
  Gradle = "org.eclipse.buildship.core.gradleclasspathcontainer",
  ReferencedLibrary = "REFERENCED_LIBRARIES_PATH",
}

M.ContainerType = {
  JRE = "jre",
  Maven = "maven",
  Gradle = "gradle",
  ReferencedLibrary = "referencedLibrary",
  Unknown = "",
}

M.type_kind = function(node)
  if node.metaData and node.metaData.TypeKind then
    return node.metaData.TypeKind + 10
  end
  if node.name and vim.endswith(node.name, ".jar") then
    return M.NodeKind.JAR
  end
  return node.kind
end

function M.icon_from_kind(node)
  local symbols = config.options.symbols

  if type(node) == "string" then
    return symbols[node].icon
  end

  local kind = M.type_kind(node)
  return symbols[M.kinds[kind]].icon
end

function M.get_container_type(containerPath)
  if vim.startswith(containerPath, M.ContainerPath.JRE) then
    return M.ContainerType.JRE
  elseif vim.startswith(containerPath, M.ContainerPath.Maven) then
    return M.ContainerType.Maven
  elseif vim.startswith(containerPath, M.ContainerPath.Gradle) then
    return M.ContainerType.Gradle
  elseif vim.startswith(containerPath, M.ContainerPath.ReferencedLibrary) then
    return M.ContainerType.ReferencedLibrary
  end
  return M.ContainerType.Unknown
end

return M
