-- Reverse a list.
-- @param list (table) The array to reverse.
-- @return (table) A new array with the elements in reverse order.
export reverse = (list) ->
  [list[i] for i = #list, 1, -1]
