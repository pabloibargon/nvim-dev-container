return {
  'georgeguimaraes/review.nvim',
  version = '*',
  event = 'VeryLazy', -- Show saved annotations when opening source files.
  dependencies = {
    'esmuellert/codediff.nvim',
    'MunifTanjim/nui.nvim',
  },
  keys = {
    -- <leader>r is already used by molten.nvim (leader == localleader).
    { '<leader>vr', '<cmd>Review<CR>', desc = 'Review working tree' },
    { '<leader>vc', '<cmd>Review commits<CR>', desc = 'Review commits' },
    { '<leader>vb', '<cmd>Review branch<CR>', desc = 'Review branch' },
    { '<leader>vn', ':Review note<CR>', mode = { 'n', 'v' }, desc = 'Review: annotate source line/range' },
    { '<leader>ve', '<cmd>Review edit<CR>', desc = 'Review: edit annotation' },
    { '<leader>vd', '<cmd>Review delete<CR>', desc = 'Review: delete annotation' },
    { '<leader>vx', '<cmd>Review export<CR>', desc = 'Review: export comments' },
  },
  opts = {},
}
