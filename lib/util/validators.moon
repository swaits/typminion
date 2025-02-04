---
-- Determines if the provided timer value is valid.
--
-- A valid timer is defined as a number greater than zero.
--
-- @param x number: The timer value to validate.
-- @return boolean: Returns `true` if `x` is a positive number; otherwise, returns `false` or `nil`.
export is_valid_timer = (x) ->
  type(x) == "number" and x > 0

---
-- Checks whether the given string is a valid symbol.
--
-- A valid symbol is defined as a non-empty string that contains only
-- alphabetic characters (A-Z and a-z). If the input is not a string,
-- the function returns `false`.
--
-- @param s string: The string to be validated as a symbol.
-- @return boolean: Returns `true` if `s` contains only letters; otherwise, returns `false`.
export is_valid_symbol = (s) ->
  if type(s) == "string" and string.match s, "^[A-Za-z][A-Za-z0-9_]*$"
    true
  else
    false
