---
-- Recursively prints the contents of a table in a human-readable format.
--
-- This function traverses the provided table `tbl` and prints each key-value
-- pair to the standard output. For nested tables, it calls itself recursively,
-- increasing the indentation level to visually represent the table hierarchy.
--
-- @param tbl table: The table whose contents are to be printed.
-- @param indent number: (Optional) The current indentation level. Defaults to 0.
-- @return nil
export print_table = (tbl, indent) ->
  -- Use the “?=” operator to give a default value.
  unless indent
    indent = 0
  -- Omit the extra “do” after the loop header.
  for k, v in pairs tbl
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table"
      print formatting
      print_table v, indent + 1
    elseif type(v) == "boolean"
      print formatting .. tostring(v)
    else
      print formatting .. v
