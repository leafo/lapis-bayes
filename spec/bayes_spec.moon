
import use_test_env from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

db = require "lapis.db"

import Categories, WordClassifications from require "lapis.bayes.models"

describe "lapis.bayes", ->
  use_test_env!

  describe "tokenize_text", ->
    import tokenize_text from require "lapis.bayes"

    it "gets tokens for empty string", ->
      assert.same {}, tokenize_text ""

    it "gets tokens for basic string", ->
      assert.same {"hello", "world"}, tokenize_text "hello world"

    it "gets tokens with stems and no stop words", ->
      assert.same {"burger", "eat"}, tokenize_text "i am eating burgers"


  describe "Categories", ->
    before_each ->
      truncate_tables Categories, WordClassifications

    it "creates category", ->
      Categories\find_or_create "hello"

