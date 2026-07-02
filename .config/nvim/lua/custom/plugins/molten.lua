return {
  'benlubas/molten-nvim',
  version = '^1.0.0', -- use version <2.0.0 to avoid breaking changes
  build = ':UpdateRemotePlugins',
  init = function()
    vim.g.molten_image_provider = 'none'
    vim.g.molten_open_cmd = 'open'
    vim.g.molten_auto_init_behavior = 'init'
    vim.g.molten_auto_image_popup = false
    vim.g.molten_output_win_max_height = 15
    vim.g.molten_output_win_hide_on_leave = true
    vim.g.molten_virt_lines_off_by_1 = true
    vim.g.molten_virt_text_max_lines = 10000
    vim.g.molten_cover_empty_lines = false
    vim.g.molten_copy_output = false
    vim.g.molten_output_show_exec_time = true
    vim.g.molten_auto_open_output = false
  end,
  keys = {
    { '<localleader>mi', '<cmd>MoltenInit<CR>', mode = 'n', silent = true, desc = 'Initialize the plugin' },
    { '<localleader>e', '<cmd>MoltenEvaluateOperator<CR>', mode = 'n', silent = true, desc = 'Run operator selection' },
    { '<localleader>rl', '<cmd>MoltenEvaluateLine<CR>', mode = 'n', silent = true, desc = 'Evaluate line' },
    { '<localleader>rr', '<cmd>MoltenReevaluateCell<CR>', mode = 'n', silent = true, desc = 'Re-evaluate cell' },
    { '<localleader>r', ':<C-u>MoltenEvaluateVisual<CR>gv', mode = 'v', silent = true, desc = 'Evaluate visual selection' },
    { '<localleader>os', '<cmd>noautocmd MoltenEnterOutput<CR>', mode = 'n', silent = true, desc = 'Show/enter output' },
  },
}
