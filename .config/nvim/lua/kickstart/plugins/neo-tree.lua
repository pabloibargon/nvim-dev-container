-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
  },
  lazy = false,
  keys = {
    { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
  },
  opts = {
    default_component_configs = {
      indent = {
        indent_marker = '│',
        last_indent_marker = '└',
        expander_collapsed = '▸',
        expander_expanded = '▾',
      },
      icon = {
        folder_closed = '▣',
        folder_open = '▢',
        folder_empty = '□',
        folder_empty_open = '□',
        default = '•',
        selected = '→',
      },
      modified = {
        symbol = '[+]',
      },
      git_status = {
        symbols = {
          added = '+',
          deleted = '-',
          modified = '~',
          renamed = '»',
          untracked = '?',
          ignored = '!',
          unstaged = '!',
          staged = '✓',
          conflict = 'x',
        },
      },
    },

    filesystem = {
      window = {
        mappings = {
          ['\\'] = 'close_window',
        },
      },
    },
  },
}
