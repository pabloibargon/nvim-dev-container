-- debug.lua

return {
  'mfussenegger/nvim-dap',
  event = 'VeryLazy',
  dependencies = {
    'igorlfs/nvim-dap-view',
  },
  keys = {
    -- Core Debugging
    {
      '<leader>db',
      function()
        require('dap').toggle_breakpoint()
      end,
      desc = 'toggle breakpoint',
    },
    {
      '<leader>dc',
      function()
        require('dap').continue()
      end,
      desc = 'start/continue debugger',
    },
    {
      '<leader>dt',
      function()
        require('dap').terminate()
      end,
      desc = 'terminate debugger',
    },

    -- Stepping
    {
      '<leader>dn',
      function()
        require('dap').step_over()
      end,
      desc = 'step over (next)',
    },
    {
      '<leader>di',
      function()
        require('dap').step_into()
      end,
      desc = 'step into',
    },
    {
      '<leader>do',
      function()
        require('dap').step_out()
      end,
      desc = 'step out',
    },

    -- DAP View
    {
      '<leader>dvv',
      '<cmd>DapViewToggle<CR>',
      desc = 'toggle dap view',
    },
    {
      '<leader>dvw',
      '<cmd>DapViewShow watches<CR>',
      desc = 'show dap watches view',
    },
    {
      '<leader>dvb',
      '<cmd>DapViewShow breakpoints<CR>',
      desc = 'show dap breakpoints view',
    },
    {
      '<leader>dvs',
      '<cmd>DapViewShow scopes<CR>',
      desc = 'show dap scopes view',
    },
    {
      '<leader>dve',
      '<cmd>DapViewShow exceptions<CR>',
      desc = 'show dap exceptions view',
    },
    {
      '<leader>dvt',
      '<cmd>DapViewShow threads<CR>',
      desc = 'show dap threads view',
    },
    {
      '<leader>dvr',
      '<cmd>DapViewShow repl<CR>',
      desc = 'show dap repl view',
    },
    {
      '<leader>dr',
      '<cmd>DapViewJump repl<CR>',
      desc = 'focus on dap repl',
    },

    -- Watches
    {
      '<leader>dw',
      '<cmd>DapViewWatch<CR>',
      mode = 'n',
      desc = 'add expression under cursor to watch',
    },
    {
      '<leader>dw',
      '<cmd>DapViewWatch<CR>',
      mode = 'v',
      desc = 'add selected expression to watch',
    },
  },
  config = function()
    local dap = require 'dap'
    dap.configurations.python = {
      {
        -- The first three options are required by nvim-dap
        type = 'python', -- the type here established the link to the adapter definition: `dap.adapters.python`
        request = 'launch',
        name = 'Launch file',

        -- Options below are for debugpy, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for supported options

        program = '${file}',
        pythonPath = function()
          return vim.fn.systemlist('which python')[1]
        end,
      },
    }
    dap.adapters.python = {
      type = 'executable',
      command = vim.g.python3_host_prog,
      args = { '-m', 'debugpy.adapter' },
    }
    dap.defaults.fallback.switchbuf = 'usevisible,usetab,newtab'

    -- Change breakpoint icons
    local breakpoint_icons = { Breakpoint = '●', BreakpointCondition = '⊜', BreakpointRejected = '⊘', LogPoint = '◆', Stopped = '⭔' }
    for type, icon in pairs(breakpoint_icons) do
      local tp = 'Dap' .. type
      local hl = (type == 'Stopped') and 'DapStop' or 'DapBreak'
      vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
    end
  end,
}

