local M = {
  jdtls_name = "jdtls",
  options = {
    show_guides = true,
    auto_close = false,
    width = "30%",
    show_numbers = false,
    show_relative_numbers = false,
    preview_bg_highlight = "Pmenu",
    winblend = 0,
    fold_markers = { "", "" },
    position = "right",
    wrap = false,
    hierarchical_view = true,
    show_non_java_resources = true,
    keymaps = {
      close = "q",
      toggle_fold = "o",
    },
    symbols = {
      icons = {
        NodeKind = {},
        TypeKind = {},
        EntryKind = {},
        ProjectKind = {},
        ContainerKind = {},
      },
      highlights = {
        default_icon = "Type",
        NodeKind = {},
        TypeKind = {},
        EntryKind = {},
        ProjectKind = {},
        ContainerKind = {},
      },
    },
    highlights = {
      LineGuide = { link = "Comment" },
    },
  },
}
M.setup = function(config)
  if config then
    local normalized = vim.deepcopy(config)
    local option_keys = vim.tbl_keys(M.options)

    for _, key in ipairs(option_keys) do
      if normalized[key] ~= nil then
        normalized.options = normalized.options or {}
        if type(normalized[key]) == "table" then
          normalized.options[key] = vim.tbl_deep_extend("force", normalized.options[key] or {}, normalized[key])
        else
          normalized.options[key] = normalized[key]
        end
        normalized[key] = nil
      end
    end

    local new_config = vim.tbl_deep_extend("force", M, normalized)
    for key, value in pairs(new_config) do
      M[key] = value
    end
  end
end

function M.has_numbers()
  return M.options.show_numbers or M.options.show_relative_numbers
end

function M.show_help()
  print("Current keymaps:")
  print(vim.inspect(M.options.keymaps))
end

function M.get_split_command()
  if M.options.position == "left" then
    return "topleft vs"
  else
    return "botright vs"
  end
end
function M.get_window_width()
  local width = M.options.width
  if type(width) == "string" then
    local percent = tonumber(width:match("^%s*(%d+)%%%s*$"))
    if percent ~= nil then
      return math.max(1, math.floor(vim.o.columns * percent / 100))
    end
  end
  if type(width) == "number" then
    return math.max(1, math.floor(width))
  end
  return math.max(1, math.floor(vim.o.columns * 0.3))
end
return M
