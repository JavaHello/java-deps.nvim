local M = {}
local logfile = vim.fn.stdpath("cache") .. "/java—deps.log"
local write_log = function(msg)
  local file = io.open(logfile, "a")
  if file then
    file:write(msg .. "\n")
    file:close()
  end
end

M.debug = function(msg)
  if type(msg) == "table" then
    msg = vim.inspect(msg)
  end
  write_log(msg)
end

return M
