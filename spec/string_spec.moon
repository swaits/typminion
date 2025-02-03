require "src.util.string"

describe "string.split", ->
  it "returns an empty table when given an empty string", ->
    result = split ""
    assert.is_table result
    assert.are.equal 0, #result

  it "returns an empty table when given a string containing only whitespace", ->
    result = split "   \t  \n"
    assert.is_table result
    assert.are.equal 0, #result

  it "splits a single word correctly", ->
    result = split "hello"
    assert.are.same { "hello" }, result

  it "splits two words separated by a single space", ->
    result = split "hello world"
    assert.are.same { "hello", "world" }, result

  it "handles multiple spaces between words", ->
    result = split "hello   world"
    assert.are.same { "hello", "world" }, result

  it "handles leading and trailing whitespace", ->
    result = split "   hello world   "
    assert.are.same { "hello", "world" }, result

  it "handles tabs and newline characters as whitespace", ->
    result = split "hello\tworld\nLua"
    assert.are.same { "hello", "world", "Lua" }, result

  it "treats punctuation as part of the word", ->
    result = split "hello, world!"
    assert.are.same { "hello,", "world!" }, result

  it "splits a string with various whitespace characters", ->
    result = split "  one \t two\n three  \n\t four"
    assert.are.same { "one", "two", "three", "four" }, result

  it "returns a new table on each call", ->
    result1 = split "a b c"
    result2 = split "a b c"
    assert.not_equal result1, result2

  it "errors when the input is not a string", ->
    assert.has_error => split nil
    assert.has_error => split 123

  it "does not modify the input string", ->
    s = " immutable test "
    original = s
    split s
    assert.are.equal original, s

