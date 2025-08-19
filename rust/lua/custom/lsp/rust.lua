return {
  rust_analyzer = {
    settings = {
      ['rust-analyzer'] = {
        check = { command = 'clippy' },
        cargo = { allFeatures = true },
      },
    },
  },
}
