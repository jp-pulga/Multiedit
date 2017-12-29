--------------------------------------------------------------------------------
-- The MIT License
--
-- Copyright (c) 2015 Sebastian Neusser
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--------------------------------------------------------------------------------


local print = function(...)
  local tmp = ui.SILENT_PRINT
  ui.SILENT_PRINT = true
  ui.print(...)
  ui.SILENT_PRINT = tmp
end

local keys = _G.keys
local editing = _G.textadept.editing

local M = {}

local function get_next_pos(olpos)
  return buffer:position_relative(olpos, 1)
end

local function get_prev_pos(olpos)
  return buffer:position_relative(olpos, -1)
end

M.select_word = function(prevent_scrolling)

  local word = buffer:text_range(buffer.selection_start, buffer.selection_end)

  if word == '' then
    buffer:set_selection(
      buffer:word_start_position(buffer.current_pos, true),
      buffer:word_end_position(buffer.current_pos, true))
    return not buffer.selection_empty
  end

  buffer.search_flags = buffer.FIND_MATCHCASE
  if buffer.selection_n_end[buffer.selections - 1] > buffer.selection_n_start[buffer.main_selection] then
    buffer:set_target_range(buffer.selection_n_end[buffer.selections - 1], buffer.length - 1)
    -- wrap around if not found
    if buffer:search_in_target(word) == -1 then
      buffer:set_target_range(0, buffer.selection_n_start[buffer.main_selection])
    end
  else
    buffer:set_target_range(buffer.selection_n_end[buffer.selections - 1], buffer.selection_n_start[buffer.main_selection])
  end

  if buffer:search_in_target(word) ~= -1 then
    buffer:add_selection(buffer.target_start, buffer.target_end)
    buffer.main_selection = 0

    if buffer.selection_n_caret[buffer.main_selection] == buffer.selection_n_end[buffer.main_selection] then
      buffer.selection_n_caret[buffer.selections - 1] = buffer.target_end
      buffer.selection_n_anchor[buffer.selections - 1] =  buffer.target_start
    end

    if not prevent_scrolling then
      buffer:scroll_range(buffer.target_end, buffer.target_start)
    end

    ui.statusbar_text = buffer.selections .. " occurences"

    return true
  end

  return false
end

M.select_all_words = function()
  while M.select_word(true) == true do end

end

M.enclose = function(left, right)
  for i = 0, buffer.selections - 1, 1 do
    local s, e = buffer.selection_n_start[i], buffer.selection_n_end[i]

    buffer:set_target_range(s,e)

    local txt = left..buffer.target_text..right
    buffer:replace_target(txt)
--    buffer.selection_n_start[i] = buffer.selection_n_start[i] - #left
    if s ~= e then
      buffer.selection_n_end[i] = buffer:position_relative(buffer.selection_n_start[i], #txt)
    else
      buffer.selection_n_caret[i] = get_next_pos(buffer.selection_n_caret[i])
      buffer.selection_n_anchor[i] = buffer.selection_n_caret[i]
    end
  end
end

M.unenclose = function(left, right)
  -- move along, nothing to see here yet.
end

M.char_right = function()
  if buffer.selections < 2 then return false end
  for i = 0, buffer.selections - 1, 1 do
    buffer.selection_n_start[i] = get_next_pos(buffer.selection_n_end[i])
    buffer.selection_n_end[i] = buffer.selection_n_end[i]
  end
  return true
end
M.char_right_extend = function()
  if buffer.selections < 2 then return false end
  for i = 0, buffer.selections - 1, 1 do
    buffer.selection_n_caret[i] = get_next_pos(buffer.selection_n_caret[i])
  end
  return true
end
M.word_right = function()
  if buffer.selections < 2 then return false end

  for i = 0, buffer.selections - 1, 1 do
    local nupos = buffer:word_end_position(buffer.selection_n_start[i], true)
    if nupos == buffer.selection_n_start[i] then
      nupos = get_next_pos(nupos)
    end
    buffer.selection_n_start[i] = nupos
    buffer.selection_n_end[i] = nupos
  end
  return true
end
M.word_right_extend = function()
  if buffer.selections < 2 then return false end
  for i = 0, buffer.selections - 1, 1 do
    local nupos = buffer:word_end_position(buffer.selection_n_caret[i], true)
    if nupos == buffer.selection_n_caret[i] then
      nupos = get_next_pos(nupos)
    end
    buffer.selection_n_caret[i] = nupos
  end
  return true
end
M.char_left = function()
  if buffer.selections < 2 then return false end
  for i = 0, buffer.selections - 1, 1 do
    buffer.selection_n_start[i] = get_prev_pos(buffer.selection_n_start[i])
    buffer.selection_n_end[i] = buffer.selection_n_start[i]
  end
  return true
end
M.char_left_extend = function()
  if buffer.selections < 2 then return false end
  for i = 0, buffer.selections - 1, 1 do
    buffer.selection_n_caret[i] = get_prev_pos(buffer.selection_n_caret[i])
  end
  return true
end
M.word_left = function()
  if buffer.selections < 2 then return false end

  for i = 0, buffer.selections - 1, 1 do
    local nupos = buffer:word_start_position(buffer.selection_n_start[i], true)
    if nupos == buffer.selection_n_start[i] then
      nupos = get_prev_pos(nupos)
    end
    buffer.selection_n_start[i] = nupos
    buffer.selection_n_end[i] = nupos
  end
  return true
end
M.word_left_extend = function()
  if buffer.selections < 2 then return false end
  for i = 0, buffer.selections - 1, 1 do
    local nupos = buffer:word_start_position(buffer.selection_n_caret[i], true)
    if nupos == buffer.selection_n_caret[i] then
      nupos = get_prev_pos(nupos)
    end
    buffer.selection_n_caret[i] = nupos
  end
  return true
end
M.line_down = function()
  if buffer.selections < 2 then return false end
end
M.line_down_extend = function()
  if buffer.selections < 2 then return false end
end
M.line_up = function()
  if buffer.selections < 2 then return false end
end
M.line_up_extend = function()
  if buffer.selections < 2 then return false end
end
M.line_start = function()
  if buffer.selections < 2 then return false end
  for i = 0, buffer.selections - 1, 1 do
    local nupos = buffer:position_from_line(buffer:line_from_position(buffer.selection_n_caret[i]))
    buffer.selection_n_start[i] = nupos
    buffer.selection_n_end[i] = nupos
  end
  return true
end
M.line_start_extend = function()
  if buffer.selections < 2 then return false end
  for i = 0, buffer.selections - 1, 1 do
    local nupos = buffer:position_from_line(buffer:line_from_position(buffer.selection_n_caret[i]))
    buffer.selection_n_caret[i] = nupos
  end
  return true
end
M.line_end = function()
  if buffer.selections < 2 then return false end
  for i = 0, buffer.selections - 1, 1 do
    local nupos = buffer.line_end_position[buffer:line_from_position(buffer.selection_n_caret[i])]
    buffer.selection_n_start[i] = nupos
    buffer.selection_n_end[i] = nupos
  end
  return true
end
M.line_end_extend = function()
  if buffer.selections < 2 then return false end
  for i = 0, buffer.selections - 1, 1 do
    local nupos = buffer.line_end_position[buffer:line_from_position(buffer.selection_n_caret[i])]
    buffer.selection_n_caret[i] = nupos
  end
  return true
end
M.page_up_extend = function()
  if buffer.selections < 2 then return false end
end
M.page_down_extend = function()
  if buffer.selections < 2 then return false end
end


M.newline = function()
  if buffer.selections < 2 then return false end
  for i = 0, buffer.selections - 1, 1 do
    buffer:set_target_range(buffer.selection_n_start[i], buffer.selection_n_end[i])
    buffer:replace_target("\n")
    buffer.selection_n_start[i] = buffer:position_relative(buffer.selection_n_end[i], 1)
    buffer.selection_n_end[i] = buffer.selection_n_end[i]
  end
  return true
end


M.prevent_crap = function()
  if buffer.selections > 2 then return true end
end


return M
