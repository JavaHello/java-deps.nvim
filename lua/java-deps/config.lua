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
		request_timeout = 3000,
		autofold_depth = 0,
		fold_markers = { "", "" },
		position = "right",
		wrap = false,
		hierarchical_view = true,
		keymaps = { -- These keymaps can be a string or a table for multiple keys
			open_file = "o",
			close = { "<Esc>", "q" },
			show_help = "?",
			fold = "h",
			unfold = "l",
			fold_all = "W",
			unfold_all = "E",
			fold_reset = "R",
		},
		symbols = {
			WORKSPACE = { icon = "", hl = "@text.uri" },
			PROJECT = { icon = "", hl = "@text.uri" },
			CONTAINER = { icon = "", hl = "@text.uri" },
			PACKAGEROOT = { icon = "", hl = "@text.uri" },
			PACKAGE = { icon = "", hl = "@namespace" },
			PRIMARYTYPE = { icon = "ﴯ", hl = "@type" },
			FOLDER = { icon = "", hl = "@text.uri" },
			FILE = { icon = "", hl = "@text.uri" },
			CLASS = { icon = "ﴯ", hl = "@class" },
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
