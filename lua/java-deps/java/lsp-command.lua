local config = require("java-deps.config")
local M = {}

M.JAVA_PROJECT_LIST = "java.project.list"
M.GET_ALL_PROJECTS = "java.project.getAll"
M.JAVA_PROJECT_REFRESH_LIB_SERVER = "java.project.refreshLib"
M.JAVA_GETPACKAGEDATA = "java.getPackageData"
M.JAVA_RESOLVEPATH = "java.resolvePath"
M.JAVA_PROJECT_GETMAINCLASSES = "java.project.getMainClasses"

---@return vim.lsp.Client?
M.get_client = function()
  local clients = vim.lsp.get_clients({ name = config.jdtls_name or "jdtls" })
  if not clients or #clients == 0 then
    vim.notify("No jdtls client found", vim.log.levels.WARN)
    return
  end
  return clients[1]
end

-- 使用异步没有错误信输出
M.execute_command_async = function(command, callback, bufnr)
  local client = M.get_client()
  if not client then
    return
  end
  local co
  if not callback then
    co = coroutine.running()
    if co then
      callback = function(err, resp)
        coroutine.resume(co, err, resp)
      end
    end
  end
  client.request("workspace/executeCommand", command, callback, bufnr)
  if co then
    return coroutine.yield()
  end
end
M.execute_command = function(command, bufnr)
  local client = M.get_client()
  if not client then
    return
  end
  local resp = client.request_sync("workspace/executeCommand", command, 20000, bufnr)
  if not resp then
    return "No response"
  end
  return nil, resp.result
end

return M
