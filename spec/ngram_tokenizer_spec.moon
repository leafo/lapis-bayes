NgramTokenizer = require "lapis.bayes.tokenizers.ngram"

it_tokenizes = (label, input, expected_tokens, opts=nil) ->
  it "tokenizes #{label}", ->
    tokenizer = NgramTokenizer opts
    tokens = tokenizer\tokenize_text input
    assert.same expected_tokens, tokens, "Tokens for #{input\sub 1, 80}"

describe "lapis.bayes.tokenizers.ngram", ->
  describe "basic tokenization", ->
    it_tokenizes "simple text with default bigrams", "hello world", {
      "he"
      "el"
      "ll"
      "lo"
      "wo"
      "or"
      "rl"
      "ld"
    }

    it_tokenizes "single word", "test", {
      "te"
      "es"
      "st"
    }

    it_tokenizes "multiple words", "cat dog fox", {
      "ca"
      "at"
      "do"
      "og"
      "fo"
      "ox"
    }

  describe "different n values", ->
    it_tokenizes "with unigrams (n=1)", "hello", {
      "h"
      "e"
      "l"
      "l"
      "o"
    }, { n: 1 }

    it_tokenizes "with trigrams (n=3)", "hello", {
      "hel"
      "ell"
      "llo"
    }, { n: 3 }

    it_tokenizes "with 4-grams (n=4)", "hello", {
      "hell"
      "ello"
    }, { n: 4 }

    it_tokenizes "with n=5 exact word length", "hello", {
      "hello"
    }, { n: 5 }

    it_tokenizes "with n=0 defaults to 1", "hi", {
      "h"
      "i"
    }, { n: 0 }

    it_tokenizes "with negative n defaults to 1", "hi", {
      "h"
      "i"
    }, { n: -5 }

    it_tokenizes "with fractional n gets floored", "test", {
      "te"
      "es"
      "st"
    }, { n: 2.7 }

  describe "word normalization", ->
    it_tokenizes "converts to lowercase", "Hello WORLD", {
      "he"
      "el"
      "ll"
      "lo"
      "wo"
      "or"
      "rl"
      "ld"
    }

    it_tokenizes "removes punctuation", "hello, world!", {
      "he"
      "el"
      "ll"
      "lo"
      "wo"
      "or"
      "rl"
      "ld"
    }

    it_tokenizes "handles mixed case and punctuation", "Hello, World!", {
      "he"
      "el"
      "ll"
      "lo"
      "wo"
      "or"
      "rl"
      "ld"
    }

    it_tokenizes "removes multiple spaces", "hello    world", {
      "he"
      "el"
      "ll"
      "lo"
      "wo"
      "or"
      "rl"
      "ld"
    }

    it_tokenizes "strips punctuation from words", "don't can't won't", {
      "do"
      "on"
      "nt"
      "ca"
      "an"
      "nt"
      "wo"
      "on"
      "nt"
    }

  describe "ngram_size method", ->
    it "returns default n=2", ->
      tokenizer = NgramTokenizer!
      assert.equal 2, tokenizer\ngram_size!

    it "returns configured n", ->
      tokenizer = NgramTokenizer n: 3
      assert.equal 3, tokenizer\ngram_size!

    it "handles string n", ->
      tokenizer = NgramTokenizer n: "4"
      assert.equal 4, tokenizer\ngram_size!

    it "floors fractional n", ->
      tokenizer = NgramTokenizer n: 3.9
      assert.equal 3, tokenizer\ngram_size!

    it "returns 1 for invalid n", ->
      tokenizer = NgramTokenizer n: 0
      assert.equal 1, tokenizer\ngram_size!

  describe "normalize_word method", ->
    local tokenizer
    before_each ->
      tokenizer = NgramTokenizer!

    it "normalizes to lowercase", ->
      assert.equal "hello", tokenizer\normalize_word "HELLO"
      assert.equal "hello", tokenizer\normalize_word "Hello"

    it "removes punctuation", ->
      assert.equal "hello", tokenizer\normalize_word "hello!"
      assert.equal "hello", tokenizer\normalize_word "hello,"
      assert.equal "hello", tokenizer\normalize_word "hello..."

    it "removes whitespace", ->
      assert.equal "hello", tokenizer\normalize_word "hello "
      assert.equal "hello", tokenizer\normalize_word " hello"
      assert.equal "hello", tokenizer\normalize_word " hello "

    it "removes all punctuation and whitespace", ->
      assert.equal "hello", tokenizer\normalize_word "  hello!!! "

    it "returns nil for empty string", ->
      assert.is_nil tokenizer\normalize_word ""

    it "returns nil for nil input", ->
      assert.is_nil tokenizer\normalize_word nil

    it "returns nil for whitespace only", ->
      assert.is_nil tokenizer\normalize_word "   "

    it "returns nil for punctuation only", ->
      assert.is_nil tokenizer\normalize_word "!!!"

  describe "word_ngrams method", ->
    local tokenizer
    before_each ->
      tokenizer = NgramTokenizer!

    it "generates bigrams from word", ->
      ngrams = tokenizer\word_ngrams "hello", 2
      assert.same {"he", "el", "ll", "lo"}, ngrams

    it "generates trigrams from word", ->
      ngrams = tokenizer\word_ngrams "hello", 3
      assert.same {"hel", "ell", "llo"}, ngrams

    it "returns full word when length < n", ->
      ngrams = tokenizer\word_ngrams "hi", 3
      assert.same {"hi"}, ngrams

    it "returns full word when length == n", ->
      ngrams = tokenizer\word_ngrams "hi", 2
      assert.same {"hi"}, ngrams

    it "returns full word for empty string", ->
      ngrams = tokenizer\word_ngrams "", 2
      assert.same {""}, ngrams

    it "generates unigrams", ->
      ngrams = tokenizer\word_ngrams "cat", 1
      assert.same {"c", "a", "t"}, ngrams

  describe "number handling", ->
    it_tokenizes "ignores numbers by default", "hello 123 world 456", {
      "he"
      "el"
      "ll"
      "lo"
      "wo"
      "or"
      "rl"
      "ld"
    }

    it_tokenizes "includes numbers when ignore_numbers is false", "hello 123 world", {
      "he"
      "el"
      "ll"
      "lo"
      "12"
      "23"
      "wo"
      "or"
      "rl"
      "ld"
    }, { ignore_numbers: false }

    it_tokenizes "handles mixed alphanumeric", "abc123 def456", {
      "ab"
      "bc"
      "c1"
      "12"
      "23"
      "de"
      "ef"
      "f4"
      "45"
      "56"
    }, { ignore_numbers: false }

  describe "edge cases", ->
    it_tokenizes "empty string", "", {}

    it_tokenizes "only whitespace", "     ", {}

    it_tokenizes "only punctuation", "!!???..", {}

    it_tokenizes "single character", "a", {
      "a"
    }

    it_tokenizes "two characters with bigrams", "ab", {
      "ab"
    }

    it_tokenizes "word longer than n", "testing", {
      "te"
      "es"
      "st"
      "ti"
      "in"
      "ng"
    }

  describe "unicode and international characters", ->
    it_tokenizes "accented characters", "café résumé", {
      "ca"
      "af"
      "fé"
      "ré"
      "és"
      "su"
      "um"
      "mé"
    }

    it_tokenizes "spanish text", "español niño", {
      "es"
      "sp"
      "pa"
      "añ"
      "ño"
      "ol"
      "ni"
      "iñ"
      "ño"
    }

    it_tokenizes "german umlauts", "über schön", {
      "üb"
      "be"
      "er"
      "sc"
      "ch"
      "hö"
      "ön"
    }

    it_tokenizes "french accents", "élève être", {
      "él"
      "lè"
      "èv"
      "ve"
      "êt"
      "tr"
      "re"
    }

    it_tokenizes "chinese characters", "你好世界", {
      "你好"
      "好世"
      "世界"
    }

    it_tokenizes "mixed english and chinese", "hello 世界 world", {
      "he"
      "el"
      "ll"
      "lo"
      "世界"
      "wo"
      "or"
      "rl"
      "ld"
    }

  describe "filter_text option", ->
    it_tokenizes "with custom text filter", "hello KEEP world", {
      "he"
      "el"
      "ll"
      "lo"
      "ke"
      "ee"
      "ep"
      "wo"
      "or"
      "rl"
      "ld"
    }, {
      filter_text: (text) -> text\gsub("KEEP", "keep")
    }

    it_tokenizes "filter that removes text", "hello remove world", {
      "he"
      "el"
      "ll"
      "lo"
      "wo"
      "or"
      "rl"
      "ld"
    }, {
      filter_text: (text) -> text\gsub("remove", "")
    }

    it "returns empty when filter returns empty", ->
      tokenizer = NgramTokenizer {
        filter_text: (text) -> ""
      }
      tokens = tokenizer\tokenize_text "hello world"
      assert.same {}, tokens

    it "returns empty when filter returns nil", ->
      tokenizer = NgramTokenizer {
        filter_text: (text) -> nil
      }
      tokens = tokenizer\tokenize_text "hello world"
      assert.same {}, tokens

  describe "filter_tokens option", ->
    it "with custom token filter", ->
      tokenizer = NgramTokenizer {
        filter_tokens: (tokens, opts) ->
          filtered = {}
          for token in *tokens
            if token != "el"
              table.insert filtered, token
          filtered
      }
      tokens = tokenizer\tokenize_text "hello"
      assert.same {"he", "ll", "lo"}, tokens

    it "filter can modify tokens", ->
      tokenizer = NgramTokenizer {
        filter_tokens: (tokens, opts) ->
          modified = {}
          for token in *tokens
            table.insert modified, "prefix:#{token}"
          modified
      }
      tokens = tokenizer\tokenize_text "hi"
      assert.same {"prefix:hi"}, tokens

    it "filter receives opts parameter", ->
      received_opts = nil
      tokenizer = NgramTokenizer {
        n: 3
        filter_tokens: (tokens, opts) ->
          received_opts = opts
          tokens
      }
      tokenizer\tokenize_text "test"
      assert.is_not_nil received_opts
      assert.equal 3, received_opts.n

  describe "comprehensive examples", ->
    it_tokenizes "sentence with mixed content", "The quick brown fox jumps!", {
      "th"
      "he"
      "qu"
      "ui"
      "ic"
      "ck"
      "br"
      "ro"
      "ow"
      "wn"
      "fo"
      "ox"
      "ju"
      "um"
      "mp"
      "ps"
    }

    it_tokenizes "with trigrams on real text", "testing ngrams", {
      "tes"
      "est"
      "sti"
      "tin"
      "ing"
      "ngr"
      "gra"
      "ram"
      "ams"
    }, { n: 3 }

    it_tokenizes "real world example", "Machine Learning is amazing!", {
      "ma"
      "ac"
      "ch"
      "hi"
      "in"
      "ne"
      "le"
      "ea"
      "ar"
      "rn"
      "ni"
      "in"
      "ng"
      "is"
      "am"
      "ma"
      "az"
      "zi"
      "in"
      "ng"
    }

  describe "build_grammar", ->
    it "grammar parses words", ->
      tokenizer = NgramTokenizer!
      grammar = tokenizer\build_grammar!
      words = grammar\match "hello world test"
      assert.same {"hello", "world", "test"}, words

    it "grammar handles punctuation", ->
      tokenizer = NgramTokenizer!
      grammar = tokenizer\build_grammar!
      words = grammar\match "hello, world! test?"
      assert.same {"hello,", "world!", "test?"}, words

    it "grammar handles multiple spaces", ->
      tokenizer = NgramTokenizer!
      grammar = tokenizer\build_grammar!
      words = grammar\match "hello    world"
      assert.same {"hello", "world"}, words

    it "grammar handles tabs and newlines", ->
      tokenizer = NgramTokenizer!
      grammar = tokenizer\build_grammar!
      words = grammar\match "hello\tworld\ntest"
      assert.same {"hello", "world", "test"}, words
