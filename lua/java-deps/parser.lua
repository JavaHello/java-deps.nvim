local config = require("java-deps.config")
local symbols = require("java-deps.symbols")
local folding = require("java-deps.folding")
local t_utils = require("java-deps.utils.table")
local ui = require("java-deps.ui")
local M = {}

local function parse_result(result, depth, hierarchy, parent)
	local ret = {}

	for index, value in pairs(result) do
		if not config.is_symbol_blacklisted(symbols.kinds[value.kind]) then
			-- the hierarchy is basically a table of booleans which tells whether
			-- the parent was the last in its group or not
			local hir = hierarchy or {}
			-- how many parents this node has, 1 is the lowest value because its
			-- easier to work it
			local level = depth or 1
			-- whether this node is the last in its group
			local isLast = index == #result

			local node = {
				entryKind = value.entryKind,
				metaData = value.metaData,
				handlerIdentifier = value.handlerIdentifier,
				kind = value.kind,
				uri = value.uri,
				path = value.path,
				name = value.name,
				icon = symbols.icon_from_kind(value),
				depth = level,
				isLast = isLast,
				hierarchy = hir,
				parent = parent,
			}

			table.insert(ret, node)

			local children = nil
			if value.children ~= nil then
				-- copy by value because we dont want it messing with the hir table
				local child_hir = t_utils.array_copy(hir)
				table.insert(child_hir, isLast)
				children = parse_result(value.children, level + 1, child_hir, node)
			end

			node.children = children
		end
	end
	return ret
end

local function sort_result(result)
	table.sort(result, function(a, b)
		if a.entryKind and b.entryKind then
			if a.kind == b.kind then
				return a.name:upper() < b.name:upper()
			end
			return a.entryKind < b.entryKind
		end
		if a.kind == b.kind then
			if
				a.kind == symbols.node_kind.PROJECT
				or a.kind == symbols.node_kind.PRIMARYTYPE
				or a.kind == symbols.node_kind.PACKAGEROOT
				or a.kind == symbols.node_kind.PACKAGE
			then
				if a.name ~= b.name then
					return a.name:upper() < b.name:upper()
				end
			end
		end
		return false
	end)
	return result
end

function M.parse(response, depth, hierarchy, parent)
	local sorted = sort_result(response)
	return parse_result(sorted, depth, hierarchy, parent)
end

function M.flatten(outline_items, ret, depth)
	depth = depth or 1
	ret = ret or {}
	for _, value in ipairs(outline_items) do
		table.insert(ret, value)
		value.line_in_outline = #ret
		if value.children ~= nil and not folding.is_folded(value) then
			M.flatten(value.children, ret, depth + 1)
		end
	end
	return ret
end

function M.get_lines(flattened_outline_items)
	local lines = {}
	local hl_info = {}

	for node_line, node in ipairs(flattened_outline_items) do
		local depth = node.depth
		local marker_space = (config.options.fold_markers and 1) or 0

		local line = t_utils.str_to_table(string.rep(" ", depth + marker_space))
		local running_length = 1

		local function add_guide_hl(from, to)
			table.insert(hl_info, {
				node_line,
				from,
				to,
				"JavaDespOutlineConnector",
			})
		end

		for index, _ in ipairs(line) do
			-- all items start with a space (or two)
			if config.options.show_guides then
				-- makes the guides
				if index == 1 then
					line[index] = " "
				-- i f index is last, add a bottom marker if current item is last,
				-- else add a middle marker
				elseif index == #line then
					-- add fold markers
					if config.options.fold_markers and folding.is_foldable(node) then
						if folding.is_folded(node) then
							line[index] = config.options.fold_markers[1]
						else
							line[index] = config.options.fold_markers[2]
						end

						add_guide_hl(running_length, running_length + vim.fn.strlen(line[index]) - 1)

					-- the root level has no vertical markers
					elseif depth > 1 then
						if node.isLast then
							line[index] = ui.markers.bottom
							add_guide_hl(running_length, running_length + vim.fn.strlen(ui.markers.bottom) - 1)
						else
							line[index] = ui.markers.middle
							add_guide_hl(running_length, running_length + vim.fn.strlen(ui.markers.middle) - 1)
						end
					end
				-- else if the parent was not the last in its group, add a
				-- vertical marker because there are items under us and we need
				-- to point to those
				elseif not node.hierarchy[index] and depth > 1 then
					line[index + marker_space] = ui.markers.vertical
					add_guide_hl(
						running_length - 1 + 2 * marker_space,
						running_length + vim.fn.strlen(ui.markers.vertical) - 1 + 2 * marker_space
					)
				end
			end

			line[index] = line[index] .. " "

			running_length = running_length + vim.fn.strlen(line[index])
		end

		local final_prefix = line

		local string_prefix = t_utils.table_to_str(final_prefix)

		table.insert(lines, string_prefix .. node.icon .. " " .. node.name)

		local hl_start = #string_prefix
		local hl_end = #string_prefix + #node.icon
		local hl_type = config.options.symbols[symbols.kinds[node.kind]].hl
		table.insert(hl_info, { node_line, hl_start, hl_end, hl_type })

		node.prefix_length = #string_prefix + #node.icon + 1
	end
	return lines, hl_info
end

function M.get_details(flattened_outline_items)
	local lines = {}
	for _, value in ipairs(flattened_outline_items) do
		local detail
		if symbols.type_kind(value) == symbols.node_kind.JAR then
			detail = value.path
		end
		table.insert(lines, detail or "")
	end
	return lines
end
return M
