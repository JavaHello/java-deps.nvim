local M = {}

local providers = {
	"java-deps/providers/nvim-lsp",
}

_G._java_deps_outline_current_provider = nil

function M.has_provider()
	local ret = false
	for _, value in ipairs(providers) do
		local provider = require(value)
		if provider.should_use_provider(0) then
			ret = true
			break
		end
	end
	return ret
end

function M.request_symbols(bufnr, node, on_symbols)
	for _, value in ipairs(providers) do
		local provider = require(value)
		if provider.should_use_provider(0) then
			_G._java_deps_outline_current_provider = provider
			provider.request_symbols(bufnr, node, on_symbols)
			break
		end
	end
end

return M
