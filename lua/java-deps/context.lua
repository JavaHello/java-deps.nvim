local utils = require("java-deps.utils")
local config = require("java-deps.config")
local M = {
  current_client = nil,
  root_dir = nil,
  root_uri = nil,
}
M.current_config = function()
  if M.root_dir == nil then
    M.attach(utils.get_client(config.jdtls_name))
  end
  return M
end

M.attach = function(client, _, root_dir)
  if client == nil then
    vim.notify(config.jdtls_name .. " client not found", vim.log.levels.ERROR)
    return
  end
  M.current_client = client
  M.root_dir = root_dir or client.config.root_dir
  M.root_uri = "file://" .. M.root_dir
  if M.current_config().root_dir == nil then
    vim.notify(config.jdtls_name .. " client root_dir is empty", vim.log.levels.ERROR)
  end
end

M.clear = function()
  M.current_client = nil
  M.client_configs = {}
end

return M
