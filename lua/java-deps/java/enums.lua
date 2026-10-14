-- jdtls (vscode-java-dependency) 使用的枚举和常量
local M = {}

---@enum NodeKind
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
}

---@enum TypeKind
M.TypeKind = {
  Class = 1,
  Interface = 2,
  Enum = 3,
}

---@enum PackageRootKind
M.PackageRootKind = {
  K_SOURCE = 1,
  K_BINARY = 2,
}

---@enum ContainerEntryKind
M.ContainerEntryKind = {
  CPE_LIBRARY = 1,
  CPE_PROJECT = 2,
  CPE_SOURCE = 3,
  CPE_VARIABLE = 4,
  CPE_CONTAINER = 5,
}

-- metaData 中的 key
M.K_TYPE_KIND = "TypeKind"
M.NATURE_ID = "NatureId"

M.NatureId = {
  Maven = "org.eclipse.m2e.core.maven2Nature",
  Gradle = "org.eclipse.buildship.core.gradleprojectnature",
  BspGradle = "com.microsoft.gradle.bs.importer.GradleBuildServerProjectNature",
  UnmanagedFolder = "org.eclipse.jdt.ls.core.unmanagedFolder",
  Java = "org.eclipse.jdt.core.javanature",
}

M.ReadableNature = {
  Maven = "maven",
  Gradle = "gradle",
  BspGradle = "bsp-gradle",
  UnmanagedFolder = "unmanagedFolder",
  Java = "java",
}

M.NatureIdMap = {
  [M.NatureId.Maven] = M.ReadableNature.Maven,
  [M.NatureId.Gradle] = M.ReadableNature.Gradle,
  [M.NatureId.BspGradle] = M.ReadableNature.BspGradle,
  [M.NatureId.UnmanagedFolder] = M.ReadableNature.UnmanagedFolder,
  [M.NatureId.Java] = M.ReadableNature.Java,
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

return M
