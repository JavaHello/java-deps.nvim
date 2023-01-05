local utils = require("java-deps.utils")
local config = require("java-deps.config")
local M = {
	current_client = nil,
	root_dir = nil,
	root_uri = nil,
	client_configs = {
		[1] = {
			root_path = nil,
			root_uri = nil,
		},
	},
}
M.current_config = function()
	if M.current_client then
		return M.client_configs[M.current_client.id]
	else
		M.attach(utils.get_client(config.jdtls_name))
		return M.client_configs[M.current_client.id]
	end
end

M.attach = function(client, _, root_dir)
  M.current_client = client
	M.client_configs[M.current_client.id] = {
		root_path = utils.get_root_project_path(client),
		root_uri = utils.get_root_project_uri(client),
	}
	M.root_dir = root_dir
	M.root_uri = "file://" .. root_dir
	if not M.current_config().root_path then
		vim.notify(M.current_client .. " lsp client root_path is empty", vim.log.levels.ERROR)
	end
end

M.clear = function()
	M.current_client = nil
	M.client_configs = {}
end

return M
