local context = require("java-deps.context")
local parser = require("java-deps.parser")
local providers = require("java-deps.providers.init")
local lsp_command = require("java-deps.lsp-command")
local ui = require("java-deps.ui")
local writer = require("java-deps.writer")
local config = require("java-deps.config")
local utils = require("java-deps.utils.init")
local View = require("java-deps.view")
local folding = require("java-deps.folding")
local node_kind = require("java-deps.symbols").node_kind
local t_utils = require("java-deps.utils.table")

local M = {
	view = nil,
	-------------------------
	-- STATE
	-------------------------
	state = {
		preview_buf = nil,
		preview_win = nil,
		hover_buf = nil,
		hover_win = nil,
		flattened_outline_items = {},
		code_buf = nil,
		code_win = nil,
		outline_items = nil,
	},
}

local function setup_global_autocmd()
	if config.options.highlight_hovered_item or config.options.auto_unfold_hover then
		vim.api.nvim_create_autocmd("CursorHold", {
			pattern = "*",
			callback = function()
				M._highlight_current_item(nil)
			end,
		})
	end

	vim.api.nvim_create_autocmd("WinEnter", {
		pattern = "*",
		callback = require("java-deps.preview").close,
	})
end

local function setup_buffer_autocmd(buf)
	if config.options.auto_preview then
		vim.api.nvim_create_autocmd("CursorHold", {
			buffer = buf,
			callback = require("java-deps.preview").show,
		})
	else
		vim.api.nvim_create_autocmd("CursorMoved", {
			buffer = buf,
			callback = require("java-deps.preview").close,
		})
	end
end

local function wipe_state()
	M.state = { outline_items = {}, flattened_outline_items = {}, code_win = 0, code_buf = 0 }
end

local function _update_lines()
	M.state.flattened_outline_items = parser.flatten(M.state.outline_items)
	writer.parse_and_write(M.view.bufnr, M.state.flattened_outline_items)
end

function M._current_node()
	local current_line = vim.api.nvim_win_get_cursor(M.view.winnr)[1]
	return M.state.flattened_outline_items[current_line]
end

local function goto_location(change_focus)
	local node = M._current_node()
	vim.api.nvim_win_set_cursor(M.state.code_win, { node.line + 1, node.character })
	if change_focus then
		vim.fn.win_gotoid(M.state.code_win)
	end
	if config.options.auto_close then
		M.close_outline()
	end
end

local function package_handler(node)
	if not folding.is_foldable(node) then
		return
	end
	if M.view:is_open() then
		local children = {}
		local response = lsp_command.get_package_data(M.state.code_buf, node)
		if response == nil or type(response) ~= "table" then
			return
		end
		for _, value in ipairs(response) do
			if node_kind.CONTAINER == value.kind then
				if value.entryKind == value.kind then
					value.parent = node
					local c = lsp_command.get_package_data(M.state.code_buf, value)
					if c and c[1] then
						table.insert(children, c[1])
					end
				else
					table.insert(children, value)
				end
			else
				table.insert(children, value)
			end
		end

		local child_hir = t_utils.array_copy(node.hierarchy)
		table.insert(child_hir, node.isLast)
		node.children = parser.parse(children, node.depth + 1, child_hir, node)
		return children
	end
end

local function open_file(node)
	node = node or M._current_node()
	-- open_file
	local fname = node.uri
	if vim.startswith(fname, "file:") then
		vim.fn.win_gotoid(M.state.code_win)
		fname = string.sub(node.path, 2)
		local cmd = "edit " .. fname
		vim.cmd(cmd)
		if config.options.auto_close then
			M.close_outline()
		end
	end
end

function M._set_folded_or_open(open, move_cursor, node_index)
	local node = M.state.flattened_outline_items[node_index] or M._current_node()
	local folded = false
	if node.folded ~= nil then
		folded = not node.folded
	end
	if node.kind == node_kind.FILE or node.kind == node_kind.PRIMARYTYPE then
		if move_cursor then
			vim.api.nvim_win_set_cursor(M.view.winnr, { node_index, 0 })
		end
		if open then
			open_file(node)
		end
	else
		M._set_folded(folded, move_cursor, node_index)
	end
end
function M._set_folded(folded, move_cursor, node_index)
	local node = M.state.flattened_outline_items[node_index] or M._current_node()
	if folding.is_foldable(node) then
		node.folded = folded

		if move_cursor then
			vim.api.nvim_win_set_cursor(M.view.winnr, { node_index, 0 })
		end

		package_handler(node)
		_update_lines()
	elseif node.parent then
		local parent_node = M.state.flattened_outline_items[node.parent.line_in_outline]

		if parent_node then
			M._set_folded(folded, not parent_node.folded and folded, parent_node.line_in_outline)
		end
	end
end

function M._set_all_folded(folded, nodes)
	nodes = nodes or M.state.outline_items

	for _, node in ipairs(nodes) do
		node.folded = folded
		if node.children then
			M._set_all_folded(folded, node.children)
		end
	end

	_update_lines()
end

function M._highlight_current_item(winnr)
	local has_provider = providers.has_provider()

	local is_current_buffer_the_outline = M.view.bufnr == vim.api.nvim_get_current_buf()

	local doesnt_have_outline_buf = not M.view.bufnr

	local should_exit = not has_provider or doesnt_have_outline_buf or is_current_buffer_the_outline

	-- Make a special case if we have a window number
	-- Because we might use this to manually focus so we dont want to quit this
	-- function
	if winnr then
		should_exit = false
	end

	if should_exit then
		return
	end

	local win = winnr or vim.api.nvim_get_current_win()

	local hovered_line = vim.api.nvim_win_get_cursor(win)[1] - 1

	local leaf_node = nil

	local cb = function(value)
		value.hovered = nil

		if value.line == hovered_line then
			value.hovered = true
			leaf_node = value
		end
	end

	utils.items_dfs(cb, M.state.outline_items)

	_update_lines()

	if leaf_node then
		for index, node in ipairs(M.state.flattened_outline_items) do
			if node == leaf_node then
				vim.api.nvim_win_set_cursor(M.view.winnr, { index, 1 })
				break
			end
		end
	end
end

local function setup_keymaps(bufnr)
	local map = function(...)
		utils.nmap(bufnr, ...)
	end
	-- show help
	map(config.options.keymaps.show_help, require("java-deps.config").show_help)
	-- close outline
	map(config.options.keymaps.close, function()
		M.view:close()
	end)
	-- open_file
	map(config.options.keymaps.open_file, function()
		M._set_folded_or_open(true)
	end)
	-- fold selection
	map(config.options.keymaps.fold, function()
		M._set_folded(true)
	end)
	-- unfold selection
	map(config.options.keymaps.unfold, function()
		M._set_folded(false)
	end)
	-- fold all
	map(config.options.keymaps.fold_all, function()
		M._set_all_folded(true)
	end)
	-- unfold all
	map(config.options.keymaps.unfold_all, function()
		M._set_all_folded(false)
	end)
	-- fold reset
	map(config.options.keymaps.fold_reset, function()
		M._set_all_folded(nil)
	end)
end

local function handler(response)
	if response == nil or type(response) ~= "table" then
		return
	end

	M.state.code_win = vim.api.nvim_get_current_win()

	M.view:setup_view()
	-- clear state when buffer is closed
	vim.api.nvim_buf_attach(M.view.bufnr, false, {
		on_detach = function(_, _)
			wipe_state()
		end,
	})

	setup_keymaps(M.view.bufnr)
	setup_buffer_autocmd(M.state.code_buf)

	local items = parser.parse(response)

	M.state.outline_items = items
	M.state.flattened_outline_items = parser.flatten(items)

	writer.parse_and_write(M.view.bufnr, M.state.flattened_outline_items)

	M._highlight_current_item(M.state.code_win)
end

function M.toggle_outline()
	if M.view:is_open() then
		M.close_outline()
	else
		M.open_outline()
	end
end

local function resolve_path(path)
	local resp = lsp_command.resolve_path(M.state.code_buf, path)
	local function find_root(node)
		for _, value in ipairs(M.state.flattened_outline_items) do
			if value.kind == node.kind then
				if node.kind == 5 then
					if value.name == node.name then
						return value
					end
				elseif node.kind == 6 then
					if value.uri == node.uri then
						return value
					end
				elseif node.path ~= nil and value.path == node.path then
					return value
				end
			end
		end
	end
	if resp ~= nil then
		for _, value in ipairs(resp) do
			local node = find_root(value)
			if node ~= nil then
				M._set_folded_or_open(false, true, node.line_in_outline)
			end
		end
	end
end

function M.open_outline()
	if not M.view:is_open() then
		M.state.code_buf = vim.api.nvim_get_current_buf()
		local resp = lsp_command.get_projects(M.state.code_buf, context.current_config().root_uri)
		local path = vim.uri_from_bufnr(M.state.code_buf)
		handler(resp)
		resolve_path(path)
	end
end

function M.close_outline()
	M.view:close()
end

function M.setup(opts)
	config.setup(opts)
	ui.setup_highlights()

	M.view = View:new()
	setup_global_autocmd()
end

M.attach = function(client, buf, root_dir)
	context.attach(client, buf, root_dir)
end

return M
