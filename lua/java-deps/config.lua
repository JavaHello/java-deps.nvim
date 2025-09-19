local M = {
  jdtls_name = "jdtls",
  options = {
    show_guides = true,
    auto_close = false,
    width = 40,
    show_numbers = false,
    show_relative_numbers = false,
    preview_bg_highlight = "Pmenu",
    winblend = 0,
    fold_markers = { "", "" },
    position = "right",
    wrap = false,
    hierarchical_view = true,
    keymaps = {
      close = "q",
      toggle_fold = "o",
    },
    symbols = {
      icons = {},
    },
  },
}
M.setup = function(config)
  if config then
    local new_config = vim.tbl_deep_extend("force", M, config)
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
  return M.options.width
end
return M
