require "lib.util.string"
require "lib.util.validators"

---
-- parse_transition
-- Parses a transition string into a table with:
--   • target: the target state name,
--   • type:   "after" | "every" | "on",
--   • time:   number (if timer-based),
--   • event:  string (if event-based).
export parse_transition = (trans) ->
  unless type(trans) == "string"
    error "Transition must be a string"

  words = split trans
  unless #words == 3
    error "Transition must consist of three words"

  unless is_valid_symbol words[1]
    error "Invalid state name"

  switch words[2]
    when "on"
      unless is_valid_symbol words[3]
        error "Invalid event name"
      {target: words[1], type: words[2], event: words[3]}

    when "after", "every"
      num = tonumber words[3]
      unless is_valid_timer num
        error "Invalid time value in 'after/every' transition type"
      {target: words[1], type: words[2], duration: num}

    else
      error "Unknown transition type"
