local config = require("java-deps.config")
local DataProvider = require("java-deps.views.data_provider")
local writer = require("java-deps.views.writer")
local mappings = require("java-deps.views.mappings")
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
  vim.api.nvim_set_option_value("bufhidden", "delete", { buf = self.bufnr })
  -- create a split
  vim.cmd(config.get_split_command())
  -- resize to a % of the current window size
  vim.cmd("vertical resize " .. config.get_window_width())

  -- get current (outline) window and attach our buffer to it
  self.winnr = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(self.winnr, self.bufnr)

  -- window stuff
  vim.api.nvim_set_option_value("spell", false, { win = self.winnr })
  vim.api.nvim_set_option_value("signcolumn", "no", { win = self.winnr })
  vim.api.nvim_set_option_value("foldcolumn", "0", { win = self.winnr })
  vim.api.nvim_set_option_value("number", false, { win = self.winnr })
  vim.api.nvim_set_option_value("relativenumber", false, { win = self.winnr })
  vim.api.nvim_set_option_value("winfixwidth", true, { win = self.winnr })
  vim.api.nvim_set_option_value("list", false, { win = self.winnr })
  vim.api.nvim_set_option_value("wrap", config.options.wrap, { win = self.winnr })
  vim.api.nvim_set_option_value("linebreak", true, { win = self.winnr }) -- only has effect when wrap=true
  vim.api.nvim_set_option_value("breakindent", true, { win = self.winnr }) -- only has effect when wrap=true
  --  Would be nice to use ui.markers.vertical as part of showbreak to keep
  --  continuity of the tree UI, but there's currently no way to style the
  --  color, apart from globally overriding hl-NonText, which will potentially
  --  mess with other theme/user settings. So just use empty spaces for now.
  vim.api.nvim_set_option_value("showbreak", "      ", { win = self.winnr }) -- only has effect when wrap=true.
  -- buffer stuff
  vim.api.nvim_buf_set_name(self.bufnr, "JavaProjects")
  vim.api.nvim_set_option_value("filetype", "JavaProjects", { buf = self.bufnr })
  vim.api.nvim_set_option_value("modifiable", false, { buf = self.bufnr })

  if config.options.show_numbers or config.options.show_relative_numbers then
    vim.api.nvim_set_option_value("nu", true, { win = self.winnr })
  end

  if config.options.show_relative_numbers then
    vim.api.nvim_set_option_value("rnu", true, { win = self.winnr })
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
  self.data_provider = DataProvider:new(uri)
end

function View:fold_toggle()
  local item = self:cursor_node()
  if item then
    item:fold_toggle()
    self:refresh()
    if item:can_open() then
      self:open_file(item)
    end
  end
end

---@return TreeItem?
function View:cursor_node()
  local c = vim.api.nvim_win_get_cursor(self.winnr)
  if self._flatten_tree and self._flatten_tree[c[1]] then
    local item = self._flatten_tree[c[1]]
    self._cursor_item = item
  end
  return self._cursor_item
end

function View:reveal_cursor()
  local idx, item = self.data_provider:find_reveal_node(self._flatten_tree)
  if idx and item then
    vim.api.nvim_win_set_cursor(self.winnr, { idx, 0 })
  end
end

function View:flatten_tree()
  self._flatten_tree = self.data_provider:flatten_tree()
end

function View:_write()
  if self._flatten_tree then
    writer.parse_and_write(self.bufnr, self._flatten_tree)
  end
end
---refresh the outline window
function View:refresh()
  self:flatten_tree()
  self:_write()
end

function View:reveal_paths()
  writer.write_outline(self.bufnr, { "Loading..." })
  self.data_provider:reveal_paths(jdtls.resolve_path(vim.uri_from_bufnr(self.code_buf)))
  self:refresh()
  self:reveal_cursor()
end

function View:is_open()
  return self.winnr and self.bufnr and vim.api.nvim_buf_is_valid(self.bufnr) and vim.api.nvim_win_is_valid(self.winnr)
end

---@param node TreeItem?
function View:open_file(node)
  node = node or self:cursor_node()
  if not node then
    return
  end
  -- open_file
  local fname = node.resourceUri
  if not fname or not node:can_open() then
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
