
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

    it "increments words", ->
      c = Categories\find_or_create "hello"

      WordClassifications\create {
        word: "color"
        category_id: c.id
        count: 2
      }

      c\increment_words {
        color: 55
        height: 12
        green: 8
      }

      wc_by_name = {wc.word, wc for wc in *WordClassifications\select!}

      assert.same 57, wc_by_name.color.count
      assert.same 12, wc_by_name.height.count
      assert.same 8, wc_by_name.green.count

  describe "tokenize_text", ->
    import tokenize_text from require "lapis.bayes"

    it "gets tokens for empty string", ->
      assert.same {}, tokenize_text ""

    it "gets tokens for basic string", ->
      assert.same {"hello", "world"}, tokenize_text "hello world"

    it "gets tokens with stems and no stop words", ->
      assert.same {"eat", "burger"}, tokenize_text "i am eating burgers"

    it "gets tokens keeping dupes", ->
      assert.same {"burger", "burger"}, tokenize_text "burgers are burgers"

  describe "classify_text", ->
    import classify_text from require "lapis.bayes"

    before_each ->
      truncate_tables Categories, WordClassifications

    it "classifies a single string", ->
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
        { category_id: c.id, count: 2, word: "spam" }
      }, words


    it "classifies multiple strings", ->
      classify_text "hello this is spam, I love spam", "spam"
      classify_text "there is ham here", "ham"
      classify_text "eating spamming the regular stuff", "spam"
      classify_text "pigs create too much jam", "ham"

