# Java Projects

- 使用 [symbols-outline](https://github.com/simrat39/symbols-outline.nvim) 代码实现预览
- [vscode-java-dependency](https://github.com/Microsoft/vscode-java-dependency) 提供数据支持

![java-deps](https://javahello.github.io/dev/nvim-lean/images/java-deps.png)

## 使用说明

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

-- jdtls lsp attach
require("java-deps").attach(client, buffer, root_dir)
```
