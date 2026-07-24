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

    window = {
      mappings = {
        ['\\'] = 'close_window',
        ['E'] = {
          function(_)
            vim.api.nvim_exec2('Neotree focus filesystem left', { output = true })
          end,
          desc = 'Toggle File Explorer', -- Sets help in popup to "Toggle File Explorer"
        },
        ['G'] = {
          function(_)
            vim.api.nvim_exec2('Neotree focus git_status left', { output = true })
          end,
          desc = 'Toggle Git Status', -- Sets help in popup to "Toggle Git Status"
        },
        ['B'] = {
          function(_)
            vim.api.nvim_exec2('Neotree focus buffers left', { output = true })
          end,
          desc = 'Toggle Open Buffers', -- Sets help in popup to "Toggle Open Buffers"
        },
      },
    },

  },
}
