
import use_test_env from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

import Categories, WordClassifications from require "lapis.bayes.models"

describe "lapis.bayes", ->
  use_test_env!

  setup ->
    -- remove the version that caches
    Categories.find_or_create = (name) =>
      @find(:name) or @create(:name)

  describe "WordClassifications", ->
    local c1, c2

    before_each ->
      truncate_tables Categories, WordClassifications

      c1 = Categories\find_or_create "hello"
      c1\increment_words {
        alpha: 17
        beta: 19
      }

      c2 = Categories\find_or_create "world"
      c2\increment_words {
        beta: 22
        triple: 27
      }

    it "deletes word from category", ->
      c1_count = c1.total_count
      c2_count = c2.total_count

      wc = assert WordClassifications\find category_id: c1.id, word: "beta"
      wc\delete!

      c1\refresh!
      c2\refresh!

      assert.same 19, c1_count - c1.total_count
      assert.same 0, c2_count - c2.total_count

    it "purges purges words from all categories", ->
      c1_count = c1.total_count
      c2_count = c2.total_count

      deleted, count = WordClassifications\purge_word "alpha", {"hello", "world"}
      assert.true deleted
      assert.same 1, count

      c1\refresh!
      c2\refresh!

      assert.same 17, c1_count - c1.total_count
      assert.same 0, c2_count - c2.total_count


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

  describe "train_text", ->
    import train_text from require "lapis.bayes"

    before_each ->
      truncate_tables Categories, WordClassifications

    it "classifies a single string", ->
      train_text "spam", "hello this is spam, I love spam"
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
      train_text "spam", "hello this is spam, I love spam"
      train_text "ham", "there is ham here"
      train_text "spam", "eating spamming the regular stuff"
      train_text "ham","pigs create too much jam"

  describe "text_probabilities", ->
    import text_probabilities from require "lapis.bayes"

    before_each ->
      truncate_tables Categories, WordClassifications

    it "works when there is no data", ->
      Categories\create name: "spam"
      Categories\create name: "ham"

      assert.same {
        nil, "no words in text are classifyable"
      }, {
        text_probabilities {"spam", "ham"}, "hello world"
      }

    it "works when there is some data", ->
      spam = Categories\create name: "spam"
      spam\increment_text "hello world"

      ham = Categories\create name: "ham"
      ham\increment_text "butt world"

      probs, rate = text_probabilities {"spam", "ham"}, "butt zone"
      assert.same 0.5, rate
      -- normalize probs for easy specs
      for p in *probs
        p[2] = math.floor p[2] * 100 + 0.5

      assert.same {
        {"ham", -134}
        {"spam", -438}
      }, probs

