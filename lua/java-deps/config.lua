local M = {
	debug = false,
	jdtls_name = "jdtls",
	options = {
		show_guides = true,
		show_path_details = true,
		auto_close = false,
		width = 32,
		relative_width = true,
		show_numbers = false,
		show_relative_numbers = false,
		preview_bg_highlight = "Pmenu",
		winblend = 0,
		request_timeout = 3000,
		autofold_depth = 99,
		fold_markers = { "", "" },
		position = "right",
		wrap = false,
		hierarchical_view = true,
		keymaps = { -- These keymaps can be a string or a table for multiple keys
			open_file = "o",
			close = { "<Esc>", "q" },
			show_help = "?",
			toggle_preview = "K",
			fold = "h",
			unfold = "l",
			fold_all = "W",
			unfold_all = "E",
			fold_reset = "R",
		},
		symbols = {
			Workspace = { icon = "", hl = "@text.uri" },
			Project = { icon = "", hl = "@text.uri" },
			PackageRoot = { icon = "", hl = "@text.uri" },
			Package = { icon = "", hl = "@namespace" },
			PrimaryType = { icon = "󰠱", hl = "@type" },
			CompilationUnit = { icon = "", hl = "@text.uri" },
			ClassFile = { icon = "", hl = "@text.uri" },
			Container = { icon = "󰆧", hl = "@text.uri" },
			Folder = { icon = "󰉋", hl = "@method" },
			File = { icon = "󰈙", hl = "@method" },

			CLASS = { icon = "󰠱", hl = "@class" },
			ENUM = { icon = "", hl = "@enum" },
			INTERFACE = { icon = "", hl = "@interface" },
			JAR = { icon = "", hl = "@conditional" },
		},
		symbol_blacklist = {},
	},
}
M.setup = function(config)
	if config then
		M = vim.tbl_extend("force", M, config)
	end
end

function M.has_numbers()
	return M.options.show_numbers or M.options.show_relative_numbers
end
local function has_value(tab, val)
	for _, value in ipairs(tab) do
		if value == val then
			return true
		end
	end

	return false
end

function M.is_symbol_blacklisted(kind)
	if kind == nil then
		return false
	end
	return has_value(M.options.symbol_blacklist, kind)
end

function M.show_help()
	print("Current keymaps:")
	print(vim.inspect(M.options.keymaps))
end

function M.get_split_command()
	if M.options.position == "left" then
		return "topleft vs"
	else
		return "botright vs"
	end
end
function M.get_window_width()
	if M.options.relative_width then
		return math.ceil(vim.o.columns * (M.options.width / 100))
	else
		return M.options.width
	end
end
return M
