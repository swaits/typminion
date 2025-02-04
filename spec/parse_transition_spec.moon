require "lib.util.parse_transition"

describe "parse_transition", ->

  -- ### Valid Cases ###
  it "parses a valid 'on' transition", ->
    result = parse_transition "stateA on eventX"
    assert.same {target: "stateA", type: "on", event: "eventX"}, result

  it "parses a valid 'after' transition", ->
    result = parse_transition "stateB after 3.14"
    assert.same {target: "stateB", type: "after", duration: 3.14}, result

  it "parses a valid 'every' transition", ->
    result = parse_transition "stateC every 42"
    assert.same {target: "stateC", type: "every", duration: 42}, result

  -- ### Basic Error Cases ###
  it "errors when input is not a string", ->
    assert.has_error (-> parse_transition 123), "Transition must be a string"

  it "errors when input does not have exactly three words", ->
    assert.has_error (-> parse_transition "two words"), "Transition must consist of three words"

  it "errors when transition type is unknown", ->
    assert.has_error (-> parse_transition "stateD unknown value"), "Unknown transition type"

  it "errors when number conversion fails for 'after/every' transition", ->
    assert.has_error (-> parse_transition "stateE after not_a_number"), "Invalid time value in 'after/every' transition type"

  it "errors when number conversion fails for 'after/every' transition", ->
    assert.has_error (-> parse_transition "stateF every not_a_number"), "Invalid time value in 'after/every' transition type"

  -- ### Additional Tests for Nil and Bad Numbers ###
  it "errors when nil is passed as transition", ->
    assert.has_error (-> parse_transition nil), "Transition must be a string"

  it "errors for a negative number in an 'after/every' transition", ->
    -- Assuming negative times are invalid.
    assert.has_error (-> parse_transition "stateNeg after -5"), "Invalid time value in 'after/every' transition type"

  it "errors for a negative number in an 'after/every' transition", ->
    assert.has_error (-> parse_transition "stateNeg every -5"), "Invalid time value in 'after/every' transition type"

  it "errors for zero in an 'after/every' transition", ->
    -- Zero is considered invalid.
    assert.has_error (-> parse_transition "stateZero after 0"), "Invalid time value in 'after/every' transition type"

  it "errors for zero in an 'after/every' transition", ->
    assert.has_error (-> parse_transition "stateZero every 0"), "Invalid time value in 'after/every' transition type"

  it "errors when the state name contains a space", ->
    -- e.g. "state A" is not a valid Lua identifier.
    assert.has_error (-> parse_transition "state A on eventX"), "Transition must consist of three words"

  it "errors when the event name contains a space", ->
    -- e.g. "event X" is not a valid Lua identifier.
    assert.has_error (-> parse_transition "stateA on event X"), "Transition must consist of three words"

  it "errors when the state name starts with a number", ->
    -- Lua identifiers cannot start with a digit.
    assert.has_error (-> parse_transition "1state on eventX"), "Invalid state name"

  it "errors when the event name contains an invalid character", ->
    -- For example, a dash is not allowed.
    assert.has_error (-> parse_transition "stateA on event-X"), "Invalid event name"
