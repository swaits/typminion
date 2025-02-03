---
-- Splits the input string into an array of non-whitespace substrings.
--
-- This function uses Lua's pattern matching to iterate over the provided
-- string `s` and collects each contiguous sequence of non-whitespace
-- characters into a new table. If the input is not a string, the function
-- raises an error.
--
-- @param s string: The string to be split. Must be a valid string.
-- @return table: An array of substrings obtained by splitting `s` on whitespace.
-- @raise error if the input parameter `s` is not a string.
export split = (s) ->
  unless type(s) == "string"
    error "split() requires a string parameter"
  chunks = {}
  for substr in string.gmatch s, '%S+'
    table.insert chunks, substr
  chunks
