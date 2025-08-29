-- lua/lsp/vue_ts.lua
return {
  volar = {
    filetypes = { "vue", "typescript", "javascript", "typescriptreact", "javascriptreact" },
    init_options = {
      vue = {
        -- Use Hybrid Mode (template/CSS handled by Volar; TS by ts_ls + plugin)
        hybridMode = true,
      },
    },
  },

  ts_ls = {
    filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact", "vue" },
    init_options = {
      plugins = {
        {
          name = "@vue/typescript-plugin",
          location = vim.fn.expand("$MASON/packages/vue-language-server") .. "/node_modules/@vue/language-server",
          languages = { "vue" },
        },
      },
    },
  },
}

