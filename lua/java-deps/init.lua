local config = require("java-deps.config")
local View = require("java-deps.view")
local highlight = require("java-deps.highlight")
-- debug
vim.g.java_deps = {
  debug = true,
}

local M = {
  view = nil,
  state = {
    code_buf = nil,
    code_win = nil,
  },
}

function M.toggle_outline()
  if M.view:is_open() then
    M.close_outline()
  else
    M.open_outline()
  end
end

function M.open_outline()
  if not M.view:is_open() then
    M.view:open()
    M.view:revealPaths()
  end
end

function M.close_outline()
  M.view:close()
end

function M.setup(opts)
  config.setup(opts)
  M.view = View:new()
  highlight.init_hl()
end

return M
