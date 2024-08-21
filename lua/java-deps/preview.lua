local config = require("java-deps.config")
local jd = require("java-deps")

local M = {}

local state = {
  preview_buf = nil,
  preview_win = nil,
  hover_buf = nil,
  hover_win = nil,
}

local function is_current_win_outline()
  local curwin = vim.api.nvim_get_current_win()
  return curwin == jd.view.winnr
end

local function has_code_win()
  if jd.state.code_win == nil then
    return false
  end
  local isWinValid = vim.api.nvim_win_is_valid(jd.state.code_win)
  if not isWinValid then
    return false
  end
  local bufnr = vim.api.nvim_win_get_buf(jd.state.code_win)
  local isBufValid = vim.api.nvim_buf_is_valid(bufnr)
  return isBufValid
end

local function get_offset()
  local outline_winnr = jd.view.winnr
  local width = 53
  local height = 0

  if config.has_numbers() then
    width = width + 4
  end

  if config.options.position == "right" then
    width = 0 - width
  else
    width = vim.api.nvim_win_get_width(outline_winnr) + 1
  end
  return { height, width }
end

local function get_height()
  local uis = vim.api.nvim_list_uis()
  return math.ceil(uis[1].height / 3)
end

local function get_hovered_node()
  local hovered_line = vim.api.nvim_win_get_cursor(jd.view.winnr)[1]
  local node = jd.state.flattened_outline_items[hovered_line]
  return node
end

local function update_preview(code_buf)
  code_buf = code_buf or vim.api.nvim_win_get_buf(jd.state.code_win)

  local node = get_hovered_node()
  if not node then
    return
  end
  local lines = vim.api.nvim_buf_get_lines(code_buf, 0, -1, false)

  if state.preview_buf ~= nil then
    vim.api.nvim_buf_set_lines(state.preview_buf, 0, -1, 0, lines)
    vim.api.nvim_win_set_cursor(state.preview_win, { node.line + 1, node.character })
  end
end

local function setup_preview_buf()
  local code_buf = vim.api.nvim_win_get_buf(jd.state.code_win)
  local ft = vim.api.nvim_buf_get_option(code_buf, "filetype")

  local function treesitter_attach()
    local ts_highlight = require("nvim-treesitter.highlight")

    ts_highlight.attach(state.preview_buf, ft)
  end

  -- user might not have tree sitter installed
  pcall(treesitter_attach)

  vim.api.nvim_buf_set_option(state.preview_buf, "syntax", ft)
  vim.api.nvim_buf_set_option(state.preview_buf, "bufhidden", "delete")
  vim.api.nvim_win_set_option(state.preview_win, "cursorline", true)
  update_preview(code_buf)
end

local function get_hover_params(node, winnr)
  local bufnr = vim.api.nvim_win_get_buf(winnr)
  -- local uri = vim.uri_from_bufnr(bufnr)
  return {
    node = node,
    bufnr = bufnr,
  }
end

local function update_hover()
  if not has_code_win() then
    return
  end

  local node = get_hovered_node()
  if not node then
    return
  end

  local content
  if node.metaData and node.metaData["maven.groupId"] then
    content = "```xml\n<dependency>\n"
      .. "\t<groupId>"
      .. node.metaData["maven.groupId"]
      .. "</groupId>\n"
      .. "\t<artifactId>"
      .. node.metaData["maven.artifactId"]
      .. "</artifactId>\n"
      .. "\t<version>"
      .. node.metaData["maven.version"]
      .. "</version>\n"

    if node.metaData["maven.scope"] then
      content = content .. "\t<scope>" .. node.metaData["maven.scope"] .. "</scope>\n"
    end
    if node.metaData["maven.optionaldependency"] then
      content = content .. "\t<options>" .. node.metaData["maven.optionaldependency"] .. "</options>\n"
    end
    content = content .. "</dependency>\n```"
  else
    return
  end

  local mdstring = {
    { kind = "markdown", value = content },
    { kind = "markdown", value = "[" .. node.name .. "](" .. node.path .. ")" },
  }
  local markdown_lines = vim.lsp.util.convert_input_to_markdown_lines(mdstring)
  markdown_lines = vim.lsp.util.trim_empty_lines(markdown_lines)
  if vim.tbl_isempty(markdown_lines) then
    markdown_lines = { "###No info available!" }
  end

  markdown_lines = vim.lsp.util.stylize_markdown(state.hover_buf, markdown_lines, {})

  if state.hover_buf ~= nil then
    vim.api.nvim_buf_set_lines(state.hover_buf, 0, -1, 0, markdown_lines)
  end
end

local function setup_hover_buf()
  if not has_code_win() then
    return
  end
  -- local code_buf = vim.api.nvim_win_get_buf(jd.state.code_win)
  -- local ft = vim.api.nvim_buf_get_option(code_buf, "filetype")
  -- vim.api.nvim_buf_set_option(state.hover_buf, "syntax", "xml")
  vim.api.nvim_buf_set_option(state.hover_buf, "bufhidden", "delete")
  vim.api.nvim_win_set_option(state.hover_win, "wrap", true)
  vim.api.nvim_win_set_option(state.hover_win, "cursorline", false)
  update_hover()
end

local function set_bg_hl()
  local winhi = "Normal:" .. config.options.preview_bg_highlight
  -- vim.api.nvim_win_set_option(state.preview_win, "winhighlight", winhi)
  vim.api.nvim_win_set_option(state.hover_win, "winhighlight", winhi)
  local winblend = config.options.winblend
  -- vim.api.nvim_win_set_option(state.preview_win, "winblend", winblend)
  vim.api.nvim_win_set_option(state.hover_win, "winblend", winblend)
end


local function show_hover()
  if state.hover_win == nil and state.hover_buf == nil then
    state.hover_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_attach(state.hover_buf, false, {
      on_detach = function()
        state.hover_buf = nil
        state.hover_win = nil
      end,
    })
    local offsets = get_offset()
    local height = get_height()
    state.hover_win = vim.api.nvim_open_win(state.hover_buf, false, {
      relative = "win",
      width = 50,
      height = height,
      bufpos = { 0, 0 },
      row = offsets[1] + height + 2,
      col = offsets[2],
      border = config.options.border,
    })
    setup_hover_buf()
  else
    update_hover()
  end
end

function M.show()
  if not is_current_win_outline() or #vim.api.nvim_list_wins() < 2 then
    return
  end

  -- show_preview()
  show_hover()
  set_bg_hl()
end

function M.close()
  if has_code_win() then
    if state.preview_win ~= nil and vim.api.nvim_win_is_valid(state.preview_win) then
      vim.api.nvim_win_close(state.preview_win, true)
    end
    if state.hover_win ~= nil and vim.api.nvim_win_is_valid(state.hover_win) then
      vim.api.nvim_win_close(state.hover_win, true)
    end
  end
end

function M.toggle()
  if state.preview_win ~= nil then
    M.close()
  else
    M.show()
  end
end

return M
