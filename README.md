# Java Projects

简体中文 | [English](README_EN.md)

在 Neovim 中以树形视图浏览 Java 项目、包和依赖，数据来自 [vscode-java-dependency](https://github.com/Microsoft/vscode-java-dependency)。

![Java Projects](https://github.com/JavaHello/javahello.github.io/raw/refs/heads/master/static/nvim/nvim-java-deps-new.png)

## 安装

使用 [lazy.nvim](https://github.com/folke/lazy.nvim)：

```lua
{
  "JavaHello/java-deps.nvim",
  ft = "java",
  dependencies = "mfussenegger/nvim-jdtls",
  opts = {},
}
```

### 配置 jdtls

1. 编译 `vscode-java-dependency`：

```sh
git clone https://github.com/microsoft/vscode-java-dependency.git
cd vscode-java-dependency
npm install
npm run build-server
```

2. 将生成的 jar 包加入 jdtls 的 `bundles`，并注册命令：

```lua
local bundles = {}
vim.list_extend(bundles, vim.split(vim.fn.glob(
  "/path/to/vscode-java-dependency/jdtls.ext/com.microsoft.jdtls.ext.core/target/com.microsoft.jdtls.ext.core-*.jar"
), "\n", { trimempty = true }))

jdtls_config.init_options = { bundles = bundles }

jdtls_config.on_attach = function(client, buffer)
  vim.api.nvim_buf_create_user_command(buffer, "JavaProjects", require("java-deps").toggle_outline, { nargs = 0 })
end
```

## 使用

```vim
:lua require('java-deps').toggle_outline()
:lua require('java-deps').open_outline()
:lua require('java-deps').close_outline()
```

## 配置

```lua
require("java-deps").setup({
  hierarchical_view = true,       -- 包按层级展示；false 时平铺完整包名
  show_non_java_resources = true, -- 显示非 java 资源（如 src/main/resources）
  symbols = {
    icons = {
      NodeKind = {
        Project = "󰉋",
        Workspace = { icon = "󱁐", hl = "Directory" }, -- 同时覆盖图标和高亮
      },
      TypeKind = { Class = "󰌗" },
    },
    highlights = {
      default_icon = "Identifier",              -- 图标无高亮组时的兜底
      NodeKind = { Package = "Directory" },     -- 仅覆盖高亮组
    },
  },
  highlights = {
    LineGuide = { link = "Comment" },          -- JavaDepsLineGuide 高亮组
  },
})
```

图标分类（`symbols.icons.<分类>.<名称>` / `symbols.highlights.<分类>.<名称>`）：

| 分类 | 名称 |
| --- | --- |
| `NodeKind` | `Workspace` `Project` `PackageRoot` `Package` `PrimaryType` `CompilationUnit` `ClassFile` `Container` `Folder` `File` |
| `TypeKind` | `Class` `Interface` `Enum` |
| `EntryKind` | `K_SOURCE`（源码目录）`K_BINARY`（jar 包） |
| `ProjectKind` | `MavenParent` `Maven` `GradleRoot` `Gradle` `UnmanagedFolder` `Java` |
| `ContainerKind` | `JRE` `Maven` `Gradle` `ReferencedLibrary` |

`TypeKind` / `EntryKind` / `ProjectKind` / `ContainerKind` 未匹配时回退到 `NodeKind` 中对应的图标。

## 致谢

- [symbols-outline.nvim](https://github.com/simrat39/symbols-outline.nvim)：视图实现参考
- [vscode-java-dependency](https://github.com/Microsoft/vscode-java-dependency)：数据支持
