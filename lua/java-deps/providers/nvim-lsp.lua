local M = {}

function M.hover_info(bufnr, params, on_info)
	on_info(nil, {
		contents = {
			kind = "markdown",
			content = { "No extra information availaible!" },
		},
	})
end

-- probably change this
function M.should_use_provider(bufnr)
	return true
end

return M
