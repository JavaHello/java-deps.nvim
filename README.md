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
      require("java-deps").setup({
        symbols = {
          icons = {
            NodeKind = {
              -- project 节点改成文件夹图标
              Project = "󰉋",
              -- 也支持同时覆盖 icon 和高亮
              Workspace = { icon = "󱁐", hl = "Directory" },
            },
            TypeKind = {
              Class = "󰌗",
              Interface = { icon = "", hl = "Function" },
            },
          },
          highlights = {
            default_icon = "Identifier",
            NodeKind = {
              File = "Directory",
              Package = "Directory",
            },
          },
        },
        highlights = {
          LineGuide = { link = "Comment" },
        },
      })
    end,
  }

```

可配置项说明：

- `symbols.icons.<分类>.<枚举名>`: 覆盖图标，值可以是字符串，或者 `{ icon = "...", hl = "..." }`
- `symbols.highlights.default_icon`: 图标没有高亮组时使用的兜底高亮组（内置默认图标都已自带高亮组）
- `symbols.highlights.<分类>.<枚举名>`: 仅覆盖某个图标的高亮组
- `highlights.LineGuide`: 定义 `JavaDepsLineGuide` 高亮组
- `hierarchical_view`: 包是否按层级展示，默认 `true`（`com.example.a` 显示为 `com.example` → `a`），设为 `false` 时平铺显示完整包名
- `show_non_java_resources`: 是否显示非 java 资源（如 `src/main/resources` 下的配置文件），默认 `true`

目前支持的分类：

- `symbols.icons.NodeKind`: `Workspace` `Project` `PackageRoot` `Package` `PrimaryType` `CompilationUnit` `ClassFile` `Container` `Folder` `File`
- `symbols.icons.TypeKind`: `Class` `Interface` `Enum`
- `symbols.icons.EntryKind`: `K_SOURCE`（源码目录）`K_BINARY`（jar 包）
- `symbols.icons.ProjectKind`: `MavenParent`（没有 java nature 的 Maven 父工程）`Maven` `GradleRoot`（没有 java nature 的 Gradle 根工程）`Gradle` `UnmanagedFolder` `Java`，按项目类型区分 Project 节点
- `symbols.icons.ContainerKind`: `JRE` `Maven` `Gradle` `ReferencedLibrary`，按依赖容器类型区分 Container 节点

`ProjectKind` / `ContainerKind` / `EntryKind` / `TypeKind` 未匹配时回退到 `NodeKind` 中对应的图标。

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
