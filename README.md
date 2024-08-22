# Java Projects

## 安装

[English](https://github.com/JavaHello/java-deps.nvim/issues/2)

- lazy.nvim

```lua
{
    "JavaHello/java-deps.nvim",
    lazy = true,
    ft = "java",
    dependencies = "mfussenegger/nvim-jdtls",
    config = function()
      require("java-deps").setup({})
    end,
  }

```

- 手动编译 `vscode-java-dependency` (可选)

```sh
git clone https://github.com/microsoft/vscode-java-dependency.git
cd vscode-java-dependency
npm install
npm run build-server
```

- 将 `vscode-java-dependency` 的 `jar` 包添加到 jdtls_config["init_options"].bundles 中

```lua
local jdtls_config = {}
local bundles = {}
-- ...
local java_dependency_bundle = vim.split(
  vim.fn.glob(
    "/path?/vscode-java-dependency/jdtls.ext/com.microsoft.jdtls.ext.core/target/com.microsoft.jdtls.ext.core-*.jar"
  ),
  "\n"
)

if java_dependency_bundle[1] ~= "" then
  vim.list_extend(bundles, java_dependency_bundle)
end

jdtls_config["init_options"] = {
  bundles = bundles,
  extendedClientCapabilities = extendedClientCapabilities,
}
```

- 添加命令

```lua
jdtls_config["on_attach"] = function(client, buffer)
  -- 添加命令
  local create_command = vim.api.nvim_buf_create_user_command
  create_command(buffer, "JavaProjects", require("java-deps").toggle_outline, {
    nargs = 0,
  })
end
```

- Usage

```vim
:lua require('java-deps').toggle_outline()
:lua require('java-deps').open_outline()
:lua require('java-deps').close_outline()
```

## 参考实现

- 使用 [symbols-outline](https://github.com/simrat39/symbols-outline.nvim) 代码实现预览
- [vscode-java-dependency](https://github.com/Microsoft/vscode-java-dependency) 提供数据支持
