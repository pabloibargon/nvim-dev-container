return {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-neotest/neotest-python',
    'nvim-neotest/nvim-nio',
    'nvim-lua/plenary.nvim',
    'antoinemadec/FixCursorHold.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  config = function()
    require('neotest').setup {
      icons = {
        child_indent = '│',
        child_prefix = '├',
        collapsed = '─',
        expanded = '╮',
        final_child_indent = ' ',
        final_child_prefix = '╰',
        non_collapsible = '─',

        passed = '✓',
        failed = '✗',
        running = '●',
        skipped = '○',
        unknown = '?',
        watching = '◉',
        notify = '!',
        test = '•',
	dir = '+',
        file = '+',
        namespace = '+',


        running_animated = {
          '/',
          '|',
          '\\',
          '-',
          '/',
          '|',
          '\\',
          '-',
        },
      },

      -- 2) Solarized-friendly highlight links (no hardcoded colors)
      -- These groups exist in basically all colorschemes, including Solarized variants.
      highlights = {
        adapter_name = 'Title',
        border = 'FloatBorder',

        -- status colors
        passed = 'DiagnosticOk', -- green-ish in most Solarized setups
        running = 'DiagnosticInfo', -- blue/cyan-ish
        failed = 'DiagnosticError', -- red
        skipped = 'DiagnosticWarn', -- yellow/orange

        -- tree / text
        dir = 'Directory',
        file = 'Normal',
        test = 'Normal',
        namespace = 'Comment',

        -- summary counts / positions
        focused = 'Visual',
      },

      summary = {
        enabled = true,
        animated = false, -- less “blinky” on minimalist themes
        follow = false,
        expand_errors = true,

        -- 3) Sensible key mappings inside the summary buffer
        mappings = {
          expand = { '<CR>', 'l' },
          collapse = { 'h' }, -- (some versions use expand only; if collapse isn't supported, harmless)
          run = 'r',
          debug = 'd',
          output = 'o',
          short = 'O',
          stop = 'S',
          attach = 'a',
          jumpto = 'i',

          mark = 'm',
          run_marked = 'R',
          debug_marked = 'D',
          clear_marked = 'M',

          next_failed = ']f',
          prev_failed = '[f',

          watch = 'w',
        },
      },

      output = {
        enabled = true,
        open_on_run = 'fail', -- open output automatically on failures
      },

      output_panel = {
        enabled = true,
        open = 'botright split | resize 12',
      },
      adapters = {
        require 'neotest-python' {
          runner = 'pytest',
          args = { '--override-ini=addopts=' },
          pytest_discover_instances = true,
        },
      },
      discovery = {
        enabled = true,
        filter_dir = function(name)
          return not vim.tbl_contains({
            'node_modules',
            '.git',
            '__pycache__',
            '.pytest_cache',
            'venv',
            '.venv',
            'build',
            'dist',
            '.tox',
          }, name)
        end,
      },
    }
  end,
  keys = {
    {
      '<leader>ts',
      function()
        require('neotest').summary.toggle()
      end,
      mode = 'n',
      desc = 'Neotest: Toggle test summary',
    },
  },
}
