
import use_test_env from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

import Categories, WordClassifications from require "lapis.bayes.models"

describe "lapis.bayes", ->
  use_test_env!

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

    it "has the correct counts", ->
      c1_words = {c.word, c.count for c in *c1\get_word_classifications!}
      c2_words = {c.word, c.count for c in *c2\get_word_classifications!}

      assert.same {
        alpha: 17
        beta: 19
      }, c1_words

      assert.same {
        beta: 22
        triple: 27
      }, c2_words


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

    it "it increments an individual word", ->
      wc = assert WordClassifications\find category_id: c1.id, word: "beta"

      before_word_count = wc.count

      wc\_increment 1
      wc\refresh!
      assert.same before_word_count + 1, wc.count

    it "deletes word when being unincremented to 0", ->
      wc = assert WordClassifications\find category_id: c1.id, word: "beta"
      wc\_increment -wc.count

      assert.nil (WordClassifications\find {
        category_id: c1.id
        word: "beta"
      })

    it "clears out words when decremeitng them", ->
      words = c1\get_word_classifications!
      for word in *words
        c1\increment_word word.word, -word.count

      assert.same 0, c1.total_count
      c1\refresh!
      assert.same {}, c1\get_word_classifications!

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

    it "deletes category", ->
      c = Categories\find_or_create "hello"
      c\increment_words {
        color: 23
        height: 2
      }
      c\delete!

  describe "tokenize_text", ->
    import tokenize_text from require "lapis.bayes.tokenizer"

    it "gets tokens for empty string", ->
      assert.same {}, tokenize_text ""

    it "gets tokens for basic string", ->
      assert.same {"hello", "world"}, tokenize_text "hello world"

    it "gets tokens with stems and no stop words", ->
      assert.same {"burger", "eat"}, tokenize_text "i am eating burgers"

    it "doesn't keep dupes", ->
      assert.same {"burger"}, tokenize_text "burgers are burgers"

    it "skips tokens that are too long or short", ->
      assert.same {"great"}, tokenize_text "a b c d e f g great eatingthebigriceball "

    it "strips numbers", ->
      assert.same {"delisho", "hodoc"}, tokenize_text "12 delisho hodocs for $5.99"

    it "skips words in ignore list", ->
      assert.same {"delisho"}, tokenize_text "12 delisho hodocs for $5.99", {
        ignore_words: {
          hodoc: true
        }
      }

    it "uses custom tokenizer", ->
      tokenizer = require "lapis.bayes.tokenizers.url_domains"
      assert.same {"leafo.net"},
        tokenize_text "hello www.leafo.net website", :tokenizer

    it "splits on symbols with option", ->
      assert.same {
        "buttz"
        "com"
        "disgust"
        "power"
        "super"
        "wow"
      },
        tokenize_text "wow that was super-disgusting buttz.com power/up", symbols_split_tokens: true

    it "adds a custom prefilter", ->
      assert.same {"goodzoo", "greatzoo", "stuffzoo", "wowzoo"},
        tokenize_text "good great stuff wow", filter_text: (text) ->
          text\gsub "[%w]+", "%1zoo"

    it "adds a custom token filter", ->
      assert.same {"doog", "taerg", "ffuts", "wow"},
        tokenize_text "good great stuff wow", filter_tokens: (tokens) ->
          [t\reverse! for t in *tokens]

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
        { category_id: c.id, count: 1, word: "spam" }
      }, words


    it "classifies multiple strings", ->
      train_text "spam", "hello this is spam, I love spam"
      train_text "ham", "there is ham here"
      train_text "spam", "eating spamming the regular stuff"
      train_text "ham","pigs create too much jam"

    it "uses custom tokenizer", ->
      train_text "spam", "cat eat foot", {
        tokenize_text: (str, opts) ->
          [c for c in str\gmatch "[^%s]"]
      }

      assert.same {
        t: 3
        f: 1
        o: 2
        a: 2
        c: 1
        e: 1
      }, {c.word, c.count for c in *WordClassifications\select!}

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
      spam\increment_words {"hello", "world"}

      ham = Categories\create name: "ham"
      ham\increment_words {"butt", "world"}

      probs, rate = text_probabilities {"spam", "ham"}, "butt zone"
      assert.same 0.5, rate
      -- normalize probs for easy specs
      probs = for p in *probs
        {p[1], math.floor p[2] * 100 + 0.5}

      assert.same {
        {"ham", 95}
        {"spam", 5}
      }, probs

  describe "models", ->
    before_each ->
      truncate_tables Categories, WordClassifications

    it "increment_words", ->
      spam = Categories\create name: "spam"
      count = spam\increment_words {
        "first token"
        "hello.world"
        "http://leafo.net"
        "hello.world"
        zone: 77
      }

      assert.same 81, count

      words = WordClassifications\select "order by word asc", fields: "category_id, word, count"

      assert.same {
        {
          category_id: spam.id
          count: 1
          word: "first token"
        }
        {
          category_id: spam.id
          count: 2
          word: "hello.world"
        },
        {
          category_id: spam.id
          count: 1
          word: "http://leafo.net"
        },
        {
          category_id: spam.id
          count: 77
          word: "zone"
        }
      }, words


      count = spam\increment_words {
        "hello.world"
        "hello.world"
        "zone"
        "hello.world": 3
      }

      assert.same 6, count

      words = WordClassifications\select "order by word asc", fields: "category_id, word, count"


      assert.same {
        {
          category_id: spam.id
          count: 1
          word: "first token"
        }
        {
          category_id: spam.id
          count: 7
          word: "hello.world"
        },
        {
          category_id: spam.id
          count: 1
          word: "http://leafo.net"
        },
        {
          category_id: spam.id
          count: 78
          word: "zone"
        }
      }, words
