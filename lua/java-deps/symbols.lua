local config = require("java-deps.config")
local M = {}
M.node_kind = {
	WORKSPACE = 1,
	PROJECT = 2,
	CONTAINER = 3,
	PACKAGEROOT = 4,
	PACKAGE = 5,
	PRIMARYTYPE = 6,
	FOLDER = 7,
	FILE = 8,

	-- metaData.TypeKind
	CLASS = 11,
	INTERFACE = 12,
	ENUM = 13,

	JAR = 24,
}
M.kinds = {
	"WORKSPACE",
	"PROJECT",
	"CONTAINER",
	"PACKAGEROOT",
	"PACKAGE",
	"PRIMARYTYPE",
	"FOLDER",
	"FILE",

	-- metaData.TypeKind
	[M.node_kind.CLASS] = "CLASS",
	[M.node_kind.INTERFACE] = "INTERFACE",
	[M.node_kind.ENUM] = "ENUM",

	[M.node_kind.JAR] = "JAR",
}

M.ContainerEntryKind = {
	CPE_LIBRARY = 1,
	CPE_PROJECT = 2,
	CPE_SOURCE = 3,
	CPE_VARIABLE = 4,
	CPE_CONTAINER = 5,
}

M.type_kind = function(node)
	if node.metaData and node.metaData.TypeKind then
		return node.metaData.TypeKind + 10
	end
	if node.name and vim.endswith(node.name, ".jar") then
		return M.node_kind.JAR
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

return M
