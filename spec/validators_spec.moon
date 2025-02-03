require "src.util.validators"

describe "validators", ->
  describe "is_valid_timer", ->
    it "returns falsy when passed nil", ->
      result = is_valid_timer nil
      -- nil is falsy in Lua.
      assert.falsy result

    it "returns false when passed false", ->
      result = is_valid_timer false
      assert.is_false result

    it "returns false when passed 0", ->
      result = is_valid_timer 0
      assert.is_false result

    it "returns false when passed a negative number", ->
      result = is_valid_timer -1
      assert.is_false result

    it "returns true when passed a positive integer", ->
      result = is_valid_timer 1
      assert.is_true result

    it "returns true when passed a positive decimal", ->
      result = is_valid_timer 3.14
      assert.is_true result

    it "errors when passed a non-number (string)", ->
      assert.has_error => is_valid_timer "10"

    it "errors when passed a non-number (boolean true)", ->
      assert.has_error => is_valid_timer true

    it "errors when passed a non-number (table)", ->
      assert.has_error => is_valid_timer { foo: "bar" }

  describe "is_valid_symbol", ->
    -- When the input is not a string, it should immediately return false.
    it "returns false when passed nil", ->
      result = is_valid_symbol nil
      assert.is_false result

    it "returns false when passed a number", ->
      result = is_valid_symbol 123
      assert.is_false result

    it "returns false when passed a table", ->
      result = is_valid_symbol { }
      assert.is_false result

    it "returns false when passed a boolean", ->
      result = is_valid_symbol false
      assert.is_false result

    -- When the input is a string:
    it "returns false for an empty string", ->
      result = is_valid_symbol ""
      assert.is_false result

    it "returns true for a single lowercase letter", ->
      result = is_valid_symbol "a"
      assert.is_true result

    it "returns true for a single uppercase letter", ->
      result = is_valid_symbol "Z"
      assert.is_true result

    it "returns true for a string of only letters", ->
      result = is_valid_symbol "HelloWorld"
      assert.is_true result

    it "returns true for a string with mixed case letters", ->
      result = is_valid_symbol "AbCdEf"
      assert.is_true result

    it "returns false for a string with numbers", ->
      result = is_valid_symbol "abc123"
      assert.is_false result

    it "returns false for a string with punctuation", ->
      result = is_valid_symbol "hello!"
      assert.is_false result

    it "returns false for a string with an underscore", ->
      result = is_valid_symbol "a_b"
      assert.is_false result

    it "returns false for a string containing whitespace", ->
      result = is_valid_symbol "abc def"
      assert.is_false result

    it "returns false for a string with leading/trailing whitespace", ->
      result = is_valid_symbol " abc "
      assert.is_false result

    it "returns false for a string with non-ASCII letters", ->
      result = is_valid_symbol "éclair"
      assert.is_false result

    it "returns false for a string with a hyphen", ->
      result = is_valid_symbol "A-B"
      assert.is_false result
