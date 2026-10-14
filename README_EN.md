# Java Projects

[简体中文](README.md) | English

Browse Java projects, packages and dependencies in a tree view inside Neovim, powered by [vscode-java-dependency](https://github.com/Microsoft/vscode-java-dependency).

![Java Projects](https://github.com/JavaHello/javahello.github.io/raw/refs/heads/master/static/nvim/nvim-java-deps-new.png)

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "JavaHello/java-deps.nvim",
  ft = "java",
  dependencies = "mfussenegger/nvim-jdtls",
  opts = {},
}
```

### Set up jdtls

1. Build `vscode-java-dependency`:

```sh
git clone https://github.com/microsoft/vscode-java-dependency.git
cd vscode-java-dependency
npm install
npm run build-server
```

2. Add the built jar to the jdtls `bundles` and register a command:

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

## Usage

```vim
:lua require('java-deps').toggle_outline()
:lua require('java-deps').open_outline()
:lua require('java-deps').close_outline()
```

## Configuration

```lua
require("java-deps").setup({
  hierarchical_view = true,       -- show packages hierarchically; false shows flat full package names
  show_non_java_resources = true, -- show non-Java resources (e.g. src/main/resources)
  symbols = {
    icons = {
      NodeKind = {
        Project = "󰉋",
        Workspace = { icon = "󱁐", hl = "Directory" }, -- override icon and highlight together
      },
      TypeKind = { Class = "󰌗" },
    },
    highlights = {
      default_icon = "Identifier",              -- fallback for icons without a highlight group
      NodeKind = { Package = "Directory" },     -- override only the highlight group
    },
  },
  highlights = {
    LineGuide = { link = "Comment" },          -- JavaDepsLineGuide highlight group
  },
})
```

Icon categories (`symbols.icons.<Category>.<Name>` / `symbols.highlights.<Category>.<Name>`):

| Category | Names |
| --- | --- |
| `NodeKind` | `Workspace` `Project` `PackageRoot` `Package` `PrimaryType` `CompilationUnit` `ClassFile` `Container` `Folder` `File` |
| `TypeKind` | `Class` `Interface` `Enum` |
| `EntryKind` | `K_SOURCE` (source folder) `K_BINARY` (jar) |
| `ProjectKind` | `MavenParent` `Maven` `GradleRoot` `Gradle` `UnmanagedFolder` `Java` |
| `ContainerKind` | `JRE` `Maven` `Gradle` `ReferencedLibrary` |

When `TypeKind` / `EntryKind` / `ProjectKind` / `ContainerKind` has no match, the corresponding `NodeKind` icon is used.

## Credits

- [symbols-outline.nvim](https://github.com/simrat39/symbols-outline.nvim): view implementation reference
- [vscode-java-dependency](https://github.com/Microsoft/vscode-java-dependency): data provider
