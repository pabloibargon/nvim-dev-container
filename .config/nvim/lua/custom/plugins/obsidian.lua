return {
  'obsidian-nvim/obsidian.nvim',
  version = '*', -- latest stable release
  ft = 'markdown',
  init = function()
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'markdown',
      callback = function()
        vim.opt_local.conceallevel = 1
      end,
    })
  end,
  opts = {
    legacy_commands = false, -- recommended by current docs; removed in 4.0 later

    workspaces = {
      {
        name = 'work',
        path = '~/notes', -- change this
      },
    },

    notes_subdir = 'notes',

    daily_notes = {
      folder = 'daily',
      date_format = '%Y-%m-%d',
    },

    picker = {
      -- Use this only if you have telescope installed.
      name = 'telescope.nvim',
    },

    templates = {
      folder = 'templates',
      date_format = '%Y-%m-%d',
      time_format = '%H:%M',
    },

    attachments = {
      folder = 'assets',
    },
  },
  keys = {
    { '<leader>bn', '<cmd>Obsidian new<CR>', desc = 'Obsidian new note' },
    { '<leader>bt', '<cmd>Obsidian today<CR>', desc = 'Obsidian today' },
    { '<leader>bq', '<cmd>Obsidian quick_switch<CR>', desc = 'Obsidian quick switch' },
    { '<leader>bs', '<cmd>Obsidian search<CR>', desc = 'Obsidian search' },
    { '<leader>bl', '<cmd>Obsidian links<CR>', desc = 'Obsidian links' },
    { '<leader>bb', '<cmd>Obsidian backlinks<CR>', desc = 'Obsidian backlinks' },
  },
}
