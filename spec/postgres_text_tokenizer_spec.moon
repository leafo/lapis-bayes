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

  it "respects min_token_length", ->
    PostgresTextTokenizer = require "lapis.bayes.tokenizers.postgres_text"

    t = PostgresTextTokenizer {
      min_token_length: 5
    }

    assert.same {"great", "stuff"},
      t\tokenize_text "hi wow great stuff"

  it "respects max_token_length", ->
    PostgresTextTokenizer = require "lapis.bayes.tokenizers.postgres_text"

    t = PostgresTextTokenizer {
      max_token_length: 4
    }

    assert.same {"good", "wow"},
      t\tokenize_text "good great stuff wow"

  it "strips numbers by default", ->
    PostgresTextTokenizer = require "lapis.bayes.tokenizers.postgres_text"

    t = PostgresTextTokenizer!

    tokens = t\tokenize_text "cost 99 dollars 5.99"
    table.sort tokens
    assert.same {"cost", "dollar"},
      tokens

  it "keeps numbers when strip_numbers is false", ->
    PostgresTextTokenizer = require "lapis.bayes.tokenizers.postgres_text"

    t = PostgresTextTokenizer {
      strip_numbers: false
    }

    tokens = t\tokenize_text "cost 99 dollars 5.99"
    table.sort tokens
    assert.same {"5.99", "99", "cost", "dollar"},
      tokens

  it "strips HTML tags with strip_tags option", ->
    PostgresTextTokenizer = require "lapis.bayes.tokenizers.postgres_text"

    t = PostgresTextTokenizer {
      strip_tags: true
    }

    assert.same {"hello", "link", "world"},
      t\tokenize_text [[<div>hello world</div><a href="test">link</a>]]

  it "uses legacy tokenizer that keeps duplicates", ->
    PostgresTextTokenizer = require "lapis.bayes.tokenizers.postgres_text"

    t = PostgresTextTokenizer {
      legacy_tokenizer: true
    }

    tokens = t\tokenize_text "burgers are burgers"
    table.sort tokens
    assert.same {"burger", "burger"},
      tokens

  it "uses custom regconfig", ->
    PostgresTextTokenizer = require "lapis.bayes.tokenizers.postgres_text"

    -- Test with french config
    t = PostgresTextTokenizer {
      regconfig: "french"
    }

    -- This should tokenize using French rules
    tokens = t\tokenize_text "les maisons"
    assert.truthy tokens
    assert.truthy #tokens > 0
