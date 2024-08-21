local config = require("java-deps.config")
local icons = require("java-deps.views.icons")
local M = {}

local function str_to_table(str)
  local t = {}
  for i = 1, #str do
    t[i] = str:sub(i, i)
  end
  return t
end

local function table_to_str(t)
  local ret = ""
  for _, value in ipairs(t) do
    ret = ret .. tostring(value)
  end
  return ret
end

local guides = {
  markers = {
    bottom = "└",
    middle = "├",
    vertical = "│",
    horizontal = "─",
  },
}
---@param flattened_outline_items TreeItem
---@return table
---@return table
function M.get_lines(flattened_outline_items)
  local lines = {}
  local hl_info = {}

  for node_line, node in ipairs(flattened_outline_items) do
    local depth = node.depth
    local marker_space = config.options.fold_markers and 1 or 0

    local line = str_to_table(string.rep(" ", depth + marker_space))

    local folded = node:is_foldable()
    for index, _ in ipairs(line) do
      -- all items start with a space (or two)
      if config.options.show_guides then
        if index == #line then
          -- add fold markers
          if config.options.fold_markers and folded then
            if node:is_expanded() then
              line[index] = config.options.fold_markers[2]
            else
              line[index] = config.options.fold_markers[1]
            end
          elseif depth > 1 then
            if node.isLast then
              line[index] = guides.markers.bottom
            else
              line[index] = guides.markers.middle
            end
          end
        elseif not node.hierarchy[index] and depth > 1 then
          line[index + marker_space] = guides.markers.vertical
        end
      end

      line[index] = line[index] .. " "
    end

    local string_prefix = ""

    for _, value in ipairs(line) do
      string_prefix = string_prefix .. tostring(value)
    end

    local hl_icon = icons.get_icon(node.data)
    local icon = hl_icon.icon
    table.insert(lines, string_prefix .. icon .. " " .. node.label)

    local hl_start = #string_prefix
    local hl_end = #string_prefix + #icon
    local hl_type = hl_icon.hl or "Type"
    table.insert(hl_info, { node_line, hl_start, hl_end, hl_type })
    node.prefix_length = #string_prefix + #icon + 1
  end
  return lines, hl_info
end

return M
