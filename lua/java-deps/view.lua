local config = require("java-deps.config")
local provider = require("java-deps.views.data_provider")
local writer = require("java-deps.writer")
local mappings = require("java-deps.mappings")
local jdtls = require("java-deps.java.jdtls")

---@class View
---@field bufnr number
---@field winnr number
---@field code_buf number
---@field code_win number
---@field data_provider DataProvider
---@field _flatten_tree TreeItem[]
---@field _cursor_item TreeItem?
local View = {}
View.__index = View

function View:new()
  return setmetatable({ bufnr = nil, winnr = nil }, self)
end

---creates the outline window and sets it up
function View:setup_view()
  -- create a scratch unlisted buffer
  self.bufnr = vim.api.nvim_create_buf(false, true)

  -- delete buffer when window is closed / buffer is hidden
  vim.api.nvim_buf_set_option(self.bufnr, "bufhidden", "delete")
  -- create a split
  vim.cmd(config.get_split_command())
  -- resize to a % of the current window size
  vim.cmd("vertical resize " .. config.get_window_width())

  -- get current (outline) window and attach our buffer to it
  self.winnr = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(self.winnr, self.bufnr)

  -- window stuff
  vim.api.nvim_win_set_option(self.winnr, "spell", false)
  vim.api.nvim_win_set_option(self.winnr, "signcolumn", "no")
  vim.api.nvim_win_set_option(self.winnr, "foldcolumn", "0")
  vim.api.nvim_win_set_option(self.winnr, "number", false)
  vim.api.nvim_win_set_option(self.winnr, "relativenumber", false)
  vim.api.nvim_win_set_option(self.winnr, "winfixwidth", true)
  vim.api.nvim_win_set_option(self.winnr, "list", false)
  vim.api.nvim_win_set_option(self.winnr, "wrap", config.options.wrap)
  vim.api.nvim_win_set_option(self.winnr, "linebreak", true) -- only has effect when wrap=true
  vim.api.nvim_win_set_option(self.winnr, "breakindent", true) -- only has effect when wrap=true
  --  Would be nice to use ui.markers.vertical as part of showbreak to keep
  --  continuity of the tree UI, but there's currently no way to style the
  --  color, apart from globally overriding hl-NonText, which will potentially
  --  mess with other theme/user settings. So just use empty spaces for now.
  vim.api.nvim_win_set_option(self.winnr, "showbreak", "      ") -- only has effect when wrap=true.
  -- buffer stuff
  vim.api.nvim_buf_set_name(self.bufnr, "JavaProjects")
  vim.api.nvim_buf_set_option(self.bufnr, "filetype", "JavaProjects")
  vim.api.nvim_buf_set_option(self.bufnr, "modifiable", false)

  if config.options.show_numbers or config.options.show_relative_numbers then
    vim.api.nvim_win_set_option(self.winnr, "nu", true)
  end

  if config.options.show_relative_numbers then
    vim.api.nvim_win_set_option(self.winnr, "rnu", true)
  end
end

function View:close()
  vim.api.nvim_win_close(self.winnr, true)
  self.winnr = nil
  self.bufnr = nil
  self.data_provider = nil
  self._flatten_tree = nil
  self.code_buf = nil
  self.code_win = nil
end

function View:open()
  self.code_buf = vim.api.nvim_get_current_buf()
  self.code_win = vim.api.nvim_get_current_win()
  self:setup_view()
  mappings.init_mappings(self)
  local uri = vim.uri_from_fname(jdtls.root_dir())
  self.data_provider = provider.DataProvider:new(uri)
end

function View:foldToggle()
  local item = self:cursorNode()
  if item then
    item:foldToggle()
    self:refresh()
    if item:canOpen() then
      self:open_file(item)
    end
  end
end

---@return TreeItem?
function View:cursorNode()
  local c = vim.api.nvim_win_get_cursor(self.winnr)
  if self._flatten_tree and self._flatten_tree[c[1]] then
    local item = self._flatten_tree[c[1]]
    self._cursor_item = item
  end
  return self._cursor_item
end

function View:revealCursor()
  local idx, item = self.data_provider:findRevealNode(self._flatten_tree)
  if idx and item then
    vim.api.nvim_win_set_cursor(self.winnr, { idx, 0 })
  end
end

function View:flattenTree()
  self._flatten_tree = self.data_provider:flattenTree()
end

function View:_write()
  if self._flatten_tree then
    writer.parse_and_write(self.bufnr, self._flatten_tree)
  end
end
---refresh the outline window
function View:refresh()
  self:flattenTree()
  self:_write()
end

function View:revealPaths()
  writer.write_outline(self.bufnr, { "Loading..." })
  self.data_provider:revealPaths(jdtls.resolvePath(vim.uri_from_bufnr(self.code_buf)))
  self:refresh()
  self:revealCursor()
end

function View:is_open()
  return self.winnr and self.bufnr and vim.api.nvim_buf_is_valid(self.bufnr) and vim.api.nvim_win_is_valid(self.winnr)
end

---@param node TreeItem?
function View:open_file(node)
  node = node or self:cursorNode()
  if not node then
    return
  end
  -- open_file
  local fname = node.resourceUri
  if not fname or not node:canOpen() then
    return
  end
  if vim.startswith(fname, "file:/") or vim.startswith(fname, "jdt:/") then
    vim.fn.win_gotoid(self.code_win)
    local bufnr = vim.uri_to_bufnr(fname)
    vim.bo[bufnr].buflisted = true
    vim.api.nvim_win_set_buf(self.code_win, bufnr)
    if config.options.auto_close then
      self:close()
    end
  end
end

return View
