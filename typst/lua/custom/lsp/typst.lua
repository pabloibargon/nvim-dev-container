return {
  tinymist = {
    settings = {
      formatterMode = "typstyle",
      exportPdf = "onType",        -- or "onSave" or "never", depending on preference
      semanticTokens = "disable",  -- optional: disable/enhance semantic tokens
      -- you can add other Tinymist-specific settings here
    },
    filetypes = { "typst" },      -- ensure it triggers on .typ or typst files
    -- optionally: root_dir, cmd, init_options, etc.
  },
  typstyle = {},
}

