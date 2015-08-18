
import use_test_env from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

db = require "lapis.db"

import Categories, WordClassifications from require "lapis.bayes.models"

describe "lapis.bayes", ->
  use_test_env!

  describe "Categories", ->
    before_each ->
      truncate_tables Categories, WordClassifications

    it "finds or creates category", ->
      c = Categories\find_or_create "hello"
      c2 = Categories\find_or_create "hello"
      assert.same c.id, c2.id

  describe "tokenize_text", ->
    import tokenize_text from require "lapis.bayes"

    it "gets tokens for empty string", ->
      assert.same {}, tokenize_text ""

    it "gets tokens for basic string", ->
      assert.same {"hello", "world"}, tokenize_text "hello world"

    it "gets tokens with stems and no stop words", ->
      assert.same {"burger", "eat"}, tokenize_text "i am eating burgers"


  describe "classify_text #ddd", ->
    import classify_text from require "lapis.bayes"

    before_each ->
      truncate_tables Categories, WordClassifications

    it "classifies", ->
      classify_text "hello this is spam, I love spam", "spam"
      assert.same 1, Categories\count!
      c = unpack Categories\select!
      assert.same "spam", c.name
      assert.same 3, WordClassifications\count!
      words = WordClassifications\select!
      table.sort words, (a, b) ->
        a.word < b.word

      assert.same {
        { category_id: c.id, count: 1, word: "hello" }
        { category_id: c.id, count: 1, word: "love" }
        { category_id: c.id, count: 1, word: "spam" }
      }, words



