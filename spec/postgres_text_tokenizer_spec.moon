import use_test_env from require "lapis.spec"

describe "lapis.bayes.tokenizers.postgres_text", ->
  use_test_env!

  it "skips words in ignore list", ->
    PostgresTextTokenizer = require "lapis.bayes.tokenizers.postgres_text"

    t = PostgresTextTokenizer {
      ignore_words: {
        hodoc: true
      }
    }

    assert.same {"delisho"}, t\tokenize_text "12 delisho hodocs for $5.99"


  it "splits on symbols with option", ->
    PostgresTextTokenizer = require "lapis.bayes.tokenizers.postgres_text"

    t = PostgresTextTokenizer {
      symbols_split_tokens: true
    }

    assert.same {
      "buttz"
      "com"
      "disgust"
      "power"
      "super"
      "wow"
    },
      t\tokenize_text "wow that was super-disgusting buttz.com power/up"

  it "adds a custom prefilter", ->
    PostgresTextTokenizer = require "lapis.bayes.tokenizers.postgres_text"

    t = PostgresTextTokenizer {
      filter_text: (text) ->
        text\gsub "[%w]+", "%1zoo"
    }

    assert.same {"goodzoo", "greatzoo", "stuffzoo", "wowzoo"},
      t\tokenize_text "good great stuff wow"

  it "adds a custom token filter", ->
    PostgresTextTokenizer = require "lapis.bayes.tokenizers.postgres_text"

    t = PostgresTextTokenizer {
      filter_tokens: (tokens) ->
        [t\reverse! for t in *tokens]
    }

    assert.same {"doog", "taerg", "ffuts", "wow"},
      t\tokenize_text "good great stuff wow"
