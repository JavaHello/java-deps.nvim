local M = {}
local config = require("java-deps.config")
local node_kind = require("java-deps.symbols").node_kind

local is_pkg = function(node)
	if
		node_kind.WORKSPACE == node.kind
		or node_kind.CONTAINER == node.kind
		or node_kind.PROJECT == node.kind
		or node_kind.PACKAGEROOT == node.kind
		or node_kind.PACKAGE == node.kind
		or node_kind.FOLDER == node.kind
	then
		return true
	end
	return false
end
M.is_foldable = function(node)
	if node.children and #node.children > 0 then
		return true
	end
	return is_pkg(node)
end

local get_default_folded = function(depth)
	local fold_past = config.options.autofold_depth
	if not fold_past then
		return false
	else
		return depth >= fold_past
	end
end

M.is_folded = function(node)
	if node.folded ~= nil then
		return node.folded
	elseif node.hovered and config.options.auto_unfold_hover then
		return false
	else
		return get_default_folded(node.depth)
	end
end

return M
