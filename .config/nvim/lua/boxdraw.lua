-- ~/.config/nvim/lua/boxdraw.lua
-- Modal box/line drawing for Neovim (Unicode box drawing chars)
--
-- Commands:
--   :BoxDrawBoxMode   (anchor + hjkl preview; <CR> commit; <Esc> cancel)
--   :BoxDrawLineMode  (trace with hjkl; <Esc> exit; A = arrow+exit)
--
-- Default mappings (configurable in setup()):
--   <leader>mb  -> box mode
--   <leader>ml  -> line mode

local M = {}

local defaults = {
  keymaps = {
    enabled = true,
    box_mode = '<leader>mb',
    line_mode = '<leader>ml',
  },
  box_mode = {
    commit = '<CR>',
    cancel = '<Esc>',
  },
  line_mode = {
    exit = '<Esc>',
    arrow_exit = 'A',
  },
}

local state = {
  active = false,
  box_saved_lines = nil,
  mode = nil, -- "box" | "line"
  buf = nil,
  ns = vim.api.nvim_create_namespace 'boxdraw_preview',
  anchor = nil, -- {row, col} 0-based char col
  last = nil, -- {row, col}
  last_dir = nil, -- "h"|"j"|"k"|"l"
  keymaps = {},
}

-- ---------- UTF-8 safe column helpers (char-index based) ----------

local function cursor_pos()
  local r, c_byte = unpack(vim.api.nvim_win_get_cursor(0)) -- r 1-based, c_byte 0-based
  local row = r - 1
  local line = vim.api.nvim_buf_get_lines(0, row, row + 1, true)[1] or ''
  local col = vim.str_utfindex(line, c_byte) -- convert byte col -> char col
  return row, col
end

local function get_line(buf, row)
  return (vim.api.nvim_buf_get_lines(buf, row, row + 1, true)[1] or '')
end

local function set_char(buf, row, col, ch)
  local line = get_line(buf, row)
  local line_len = vim.fn.strchars(line)

  if col > line_len then
    line = line .. string.rep(' ', col - line_len)
  end

  local start_b = vim.str_byteindex(line, col)
  local end_b = vim.str_byteindex(line, col + 1)

  -- If replacing past end, end_b can be -1
  if end_b < 0 then
    end_b = #line
  end

  local new_line = line:sub(1, start_b) .. ch .. line:sub(end_b + 1)
  vim.api.nvim_buf_set_lines(buf, row, row + 1, true, { new_line })
end
-- -------- Box-mode helpers using screen columns (virtcol) --------
-- We track positions in *screen cells* (virtcol), not bytes/chars,
-- so UTF-8 box characters never corrupt coordinates.

local function cursor_pos_vcol()
  local row1, _ = unpack(vim.api.nvim_win_get_cursor(0)) -- row 1-based
  local vcol1 = vim.fn.virtcol '.' -- 1-based screen column
  return row1 - 1, vcol1 - 1 -- row 0-based, vcol 0-based
end

local function byte_col_at_vcol(line, target_vcol0)
  -- Convert a 0-based screen column into a 0-based byte index in `line`.
  -- Handles tabs using current 'tabstop'. Assumes no crazy double-width chars in the base text.
  local ts = vim.o.tabstop
  local v = 0
  local i = 0 -- 0-based byte index

  while i < #line and v < target_vcol0 do
    local b = line:byte(i + 1)
    if b == 9 then
      -- tab
      local spaces = ts - (v % ts)
      v = v + spaces
      i = i + 1
    else
      -- advance 1 UTF-8 codepoint (but count width as 1 cell)
      local adv
      if b < 0x80 then
        adv = 1
      elseif b < 0xE0 then
        adv = 2
      elseif b < 0xF0 then
        adv = 3
      else
        adv = 4
      end
      v = v + 1
      i = i + adv
    end
  end

  -- If we're past EOL, allow padding
  return i
end

local function set_char_vcol(buf, row, vcol0, ch)
  local line = get_line(buf, row)
  local byte_col = byte_col_at_vcol(line, vcol0)

  if byte_col > #line then
    line = line .. string.rep(' ', byte_col - #line)
    vim.api.nvim_buf_set_lines(buf, row, row + 1, true, { line })
  end

  line = get_line(buf, row)
  byte_col = byte_col_at_vcol(line, vcol0)

  -- Replace the codepoint starting at byte_col, or insert at EOL.
  local end_byte = byte_col
  if byte_col < #line then
    local b = line:byte(byte_col + 1)
    local adv
    if b < 0x80 then
      adv = 1
    elseif b < 0xE0 then
      adv = 2
    elseif b < 0xF0 then
      adv = 3
    else
      adv = 4
    end
    end_byte = byte_col + adv
  end

  vim.api.nvim_buf_set_text(buf, row, byte_col, row, end_byte, { ch })
end

local function draw_hline_v(buf, row, v1, v2, ch)
  local a, b = math.min(v1, v2), math.max(v1, v2)
  for v = a, b do
    set_char_vcol(buf, row, v, ch)
  end
end

local function draw_vline_v(buf, vcol0, r1, r2, ch)
  local a, b = math.min(r1, r2), math.max(r1, r2)
  for r = a, b do
    set_char_vcol(buf, r, vcol0, ch)
  end
end

local function draw_box_outline_v(buf, r1, v1, r2, v2)
  local top = math.min(r1, r2)
  local bot = math.max(r1, r2)
  local left = math.min(v1, v2)
  local right = math.max(v1, v2)

  -- top/bottom
  if right - left >= 2 then
    draw_hline_v(buf, top, left + 1, right - 1, '─')
    draw_hline_v(buf, bot, left + 1, right - 1, '─')
  end

  -- sides
  if bot - top >= 2 then
    draw_vline_v(buf, left, top + 1, bot - 1, '│')
    draw_vline_v(buf, right, top + 1, bot - 1, '│')
  end

  -- corners
  set_char_vcol(buf, top, left, '┌')
  set_char_vcol(buf, top, right, '┐')
  set_char_vcol(buf, bot, left, '└')
  set_char_vcol(buf, bot, right, '┘')
end
-- ---------- Drawing primitives (commit to buffer) ----------

local function draw_hline(buf, row, c1, c2, ch)
  local a, b = math.min(c1, c2), math.max(c1, c2)
  for c = a, b do
    set_char(buf, row, c, ch)
  end
end

local function draw_vline(buf, col, r1, r2, ch)
  local a, b = math.min(r1, r2), math.max(r1, r2)
  for r = a, b do
    set_char(buf, r, col, ch)
  end
end

local function draw_box_outline(buf, r1, c1, r2, c2)
  local top = math.min(r1, r2)
  local bot = math.max(r1, r2)
  local left = math.min(c1, c2)
  local right = math.max(c1, c2)

  -- top/bottom
  draw_hline(buf, top, left + 1, right - 1, '─')
  draw_hline(buf, bot, left + 1, right - 1, '─')

  -- sides
  draw_vline(buf, left, top + 1, bot - 1, '│')
  draw_vline(buf, right, top + 1, bot - 1, '│')

  -- corners
  set_char(buf, top, left, '┌')
  set_char(buf, top, right, '┐')
  set_char(buf, bot, left, '└')
  set_char(buf, bot, right, '┘')
end

-- helpers to restore and redraw in place preview
local function restore_box_preview()
  if not state.box_saved_lines then
    return
  end
  local buf = state.buf
  for row, line in pairs(state.box_saved_lines) do
    vim.api.nvim_buf_set_lines(buf, row, row + 1, true, { line })
  end
end

local function ensure_saved_row(row)
  state.box_saved_lines = state.box_saved_lines or {}
  if state.box_saved_lines[row] ~= nil then
    return
  end
  state.box_saved_lines[row] = get_line(state.buf, row)
end

local function preview_box_inplace(anchor, cur)
  -- Freeze cursor byte position during in-place edits to prevent drift
  local win = 0
  local curpos = vim.api.nvim_win_get_cursor(win) -- {row(1-based), col(byte, 0-based)}

  restore_box_preview()

  local ar, av = anchor[1], anchor[2]
  local cr, cv = cur[1], cur[2]

  local top = math.min(ar, cr)
  local bot = math.max(ar, cr)
  for r = top, bot do
    ensure_saved_row(r)
  end

  if ar == cr and av == cv then
    -- restore cursor and exit
    vim.api.nvim_win_set_cursor(win, curpos)
    return
  end

  if ar == cr then
    draw_hline_v(state.buf, ar, av, cv, '─')
  elseif av == cv then
    draw_vline_v(state.buf, av, ar, cr, '│')
  else
    draw_box_outline_v(state.buf, ar, av, cr, cv)
  end

  -- Put cursor back exactly where it was (byte-col), so hjkl feels normal
  vim.api.nvim_win_set_cursor(win, curpos)
end
-- ---------- Line-trace logic ----------
-- We assume movement is via hjkl so each step is adjacent.

local function arrow_for_dir(dir)
  if dir == 'l' then
    return '►'
  end
  if dir == 'h' then
    return '◄'
  end
  if dir == 'k' then
    return '▲'
  end
  if dir == 'j' then
    return '▼'
  end
  return '►'
end

local function corner_for(prev_dir, new_dir)
  -- prev_dir and new_dir are one of h/j/k/l
  -- Determine corner char at the turning cell.
  -- Think of lines meeting at that cell.
  local p, n = prev_dir, new_dir
  if (p == 'l' and n == 'j') or (p == 'k' and n == 'h') then
    return '┐'
  end
  if (p == 'h' and n == 'j') or (p == 'k' and n == 'l') then
    return '┌'
  end
  if (p == 'l' and n == 'k') or (p == 'j' and n == 'h') then
    return '┘'
  end
  if (p == 'h' and n == 'k') or (p == 'j' and n == 'l') then
    return '└'
  end
  return nil
end

local function segment_char(dir)
  if dir == 'h' or dir == 'l' then
    return '─'
  end
  return '│'
end

local function step_line_draw(dir)
  local buf = state.buf
  local r, c = cursor_pos()

  -- Move cursor first (normal motion), then draw based on new position
  local new_r, new_c = cursor_pos()
  local prev = state.last
  local prev_dir = state.last_dir

  if not prev then
    state.last = { new_r, new_c }
    state.last_dir = dir
    set_char(buf, new_r, new_c, segment_char(dir))
    return
  end

  local pr, pc = prev[1], prev[2]
  local nr, nc = new_r, new_c

  -- Update turning point (previous cell) if direction changed
  if prev_dir and prev_dir ~= dir then
    local corner = corner_for(prev_dir, dir)
    if corner then
      set_char(buf, pr, pc, corner)
    end
  else
    -- Otherwise ensure previous cell is correct segment
    set_char(buf, pr, pc, segment_char(dir))
  end

  -- Draw at new cell
  set_char(buf, nr, nc, segment_char(dir))

  state.last = { nr, nc }
  state.last_dir = dir
end

-- ---------- Mode management ----------

local function unmap_all()
  for _, m in ipairs(state.keymaps) do
    pcall(vim.keymap.del, m.mode, m.lhs, { buffer = state.buf })
  end
  state.keymaps = {}
end

local function map_buf(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { buffer = state.buf, nowait = true, silent = true, desc = desc })
  table.insert(state.keymaps, { mode = mode, lhs = lhs })
end

local function exit_mode()
  if not state.active then
    return
  end
  unmap_all()
  state.active = false
  state.mode = nil
  state.anchor = nil
  state.last = nil
  state.last_dir = nil
end

-- BOX MODE: anchor + preview + commit/cancel
function M.box_mode()
  if state.active then
    exit_mode()
  end

  state.active = true
  state.mode = 'box'
  state.buf = vim.api.nvim_get_current_buf()
  state.box_saved_lines = {} -- start saving originals from now

  local r, v = cursor_pos_vcol()
  state.anchor = { r, v }

  local function move_and_preview(key)
    return function()
      vim.cmd.normal { key, bang = true }
      local rr, vv = cursor_pos_vcol()
      preview_box_inplace(state.anchor, { rr, vv })
    end
  end

  map_buf('n', 'h', move_and_preview 'h', 'BoxDraw: move left')
  map_buf('n', 'j', move_and_preview 'j', 'BoxDraw: move down')
  map_buf('n', 'k', move_and_preview 'k', 'BoxDraw: move up')
  map_buf('n', 'l', move_and_preview 'l', 'BoxDraw: move right')

  -- Commit
  map_buf('n', M._opts.box_mode.commit, function()
    local win = 0
    local curpos = vim.api.nvim_win_get_cursor(win) -- {row(1-based), col(byte)}
    local ar, av = state.anchor[1], state.anchor[2]
    local cr, cv = cursor_pos_vcol()

    -- Restore originals first, then draw final committed shape
    restore_box_preview()

    if ar == cr and av == cv then
      state.box_saved_lines = nil
      vim.api.nvim_win_set_cursor(win, curpos)
      exit_mode()
      return
    end

    if ar == cr then
      draw_hline_v(state.buf, ar, av, cv, '─')
    elseif av == cv then
      draw_vline_v(state.buf, av, ar, cr, '│')
    else
      draw_box_outline_v(state.buf, ar, av, cr, cv)
    end

    state.box_saved_lines = nil

    -- Put cursor back where it was before commit edits
    vim.api.nvim_win_set_cursor(win, curpos)

    exit_mode()
  end, 'BoxDraw: commit')

  -- Cancel
  map_buf('n', M._opts.box_mode.cancel, function()
    restore_box_preview()
    state.box_saved_lines = nil
    exit_mode()
  end, 'BoxDraw: cancel')

  -- initial in-place preview (optional; shows nothing unless you move)
  preview_box_inplace(state.anchor, state.anchor)
end

-- LINE MODE: trace with hjkl, exit or arrow-exit
function M.line_mode()
  if state.active then
    exit_mode()
  end

  state.active = true
  state.mode = 'line'
  state.buf = vim.api.nvim_get_current_buf()
  local r, c = cursor_pos()
  state.last = { r, c }
  state.last_dir = 'l' -- default; will be replaced on first move

  local function move_draw(key, dir)
    return function()
      vim.cmd.normal { key, bang = true }
      step_line_draw(dir)
    end
  end

  map_buf('n', 'h', move_draw('h', 'h'), 'LineDraw: left')
  map_buf('n', 'j', move_draw('j', 'j'), 'LineDraw: down')
  map_buf('n', 'k', move_draw('k', 'k'), 'LineDraw: up')
  map_buf('n', 'l', move_draw('l', 'l'), 'LineDraw: right')

  map_buf('n', M._opts.line_mode.exit, function()
    exit_mode()
  end, 'LineDraw: exit')

  map_buf('n', M._opts.line_mode.arrow_exit, function()
    -- place arrow at current cell
    local r2, c2 = cursor_pos()
    set_char(state.buf, r2, c2, arrow_for_dir(state.last_dir))
    exit_mode()
  end, 'LineDraw: arrow + exit')

  -- mark start cell so you see something immediately
  set_char(state.buf, r, c, '•')
end

local function create_commands()
  vim.api.nvim_create_user_command('BoxDrawBoxMode', function()
    M.box_mode()
  end, { desc = 'Enter BoxDraw mode' })
  vim.api.nvim_create_user_command('BoxDrawLineMode', function()
    M.line_mode()
  end, { desc = 'Enter LineDraw mode' })
end

function M.setup(opts)
  M._opts = vim.tbl_deep_extend('force', defaults, opts or {})
  create_commands()

  if M._opts.keymaps.enabled then
    vim.keymap.set('n', M._opts.keymaps.box_mode, function()
      M.box_mode()
    end, { desc = 'BoxDraw: box mode' })
    vim.keymap.set('n', M._opts.keymaps.line_mode, function()
      M.line_mode()
    end, { desc = 'BoxDraw: line mode' })
  end
end

return M

