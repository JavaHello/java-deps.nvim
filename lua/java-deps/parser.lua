local config = require("java-deps.config")
local data_node = require("java-deps.views.data_node")
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
    local running_length = 1

    local function add_guide_hl(from, to)
      table.insert(hl_info, {
        node_line,
        from,
        to,
        "JavaDepsLineGuide",
      })
    end

    for index, _ in ipairs(line) do
      -- all items start with a space (or two)
      if config.options.show_guides then
        if index == #line then
          -- add fold markers
          local folded = data_node.is_folded(node)
          if config.options.fold_markers and folded then
            if data_node.is_expanded(node) then
              line[index] = config.options.fold_markers[2]
            else
              line[index] = config.options.fold_markers[1]
            end

            add_guide_hl(running_length, running_length + vim.fn.strlen(line[index]) - 1)

            -- the root level has no vertical markers
          elseif depth > 1 then
            if node.isLast then
              line[index] = guides.markers.bottom
              add_guide_hl(running_length, running_length + vim.fn.strlen(guides.markers.bottom) - 1)
            else
              line[index] = guides.markers.middle
              add_guide_hl(running_length, running_length + vim.fn.strlen(guides.markers.middle) - 1)
            end
          end
          -- else if the parent was not the last in its group, add a
          -- vertical marker because there are items under us and we need
          -- to point to those
        elseif not node.hierarchy[index] and depth > 1 then
          line[index + marker_space] = guides.markers.vertical
          add_guide_hl(
            running_length - 1 + 2 * marker_space,
            running_length + vim.fn.strlen(guides.markers.vertical) - 1 + 2 * marker_space
          )
        end
      end

      line[index] = line[index] .. " "

      running_length = running_length + vim.fn.strlen(line[index])
    end

    local final_prefix = line

    local string_prefix = table_to_str(final_prefix)

    table.insert(lines, string_prefix .. node.icon .. " " .. node.label)

    local hl_start = #string_prefix
    local hl_end = #string_prefix + #node.icon
    local hl = config.options.symbols[node.kind]
    local hl_type = hl and hl.hl or "@lsp.type.class"
    table.insert(hl_info, { node_line, hl_start, hl_end, hl_type })

    node.prefix_length = #string_prefix + #node.icon + 1
  end
  return lines, hl_info
end

function M.get_details(flattened_outline_items)
  local lines = {}
  for _, value in ipairs(flattened_outline_items) do
    local detail
    -- TODO
    table.insert(lines, detail or "")
  end
  return lines
end
return M
