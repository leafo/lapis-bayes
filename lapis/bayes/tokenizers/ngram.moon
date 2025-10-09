class NgramTokenizer extends require "lapis.bayes.tokenizers.base"
  new: (@opts = {}) =>

  build_grammar: =>
    import C, Ct from require "lpeg"
    utf8 = require "lapis.util.utf8"

    whitespace = utf8.whitespace
    printable = utf8.printable_character
    word_chars = printable - whitespace
    word = C word_chars^1

    Ct (word + whitespace^1)^0

  normalize_word: (word) =>
    return unless word and word != ""

    normalized = tostring(word)\lower!
    normalized = normalized\gsub("[%p]", "")
    normalized = normalized\gsub("%s+", "")

    return unless normalized != ""
    normalized

  ngram_size: =>
    n = tonumber(@opts.n) or 2
    n = math.floor n
    n = 1 if n < 1
    n

  word_ngrams: (word, n) =>
    -- Split word into UTF-8 characters using LPEG
    import C, Ct from require "lpeg"
    utf8 = require "lapis.util.utf8"
    printable = utf8.printable_character

    char_pattern = Ct (C printable)^0
    chars = char_pattern\match word

    return { word } unless chars

    len = #chars
    return { word } if len == 0
    return { word } if len < n

    out = {}
    for i = 1, len - n + 1
      ngram = table.concat chars, "", i, i + n - 1
      table.insert out, ngram

    out

  tokenize_text: (text) =>
    return {} unless text and text != ""

    if pre_filter = @opts.filter_text
      text = pre_filter text
      return {} unless text and text != ""

    @grammar or= @build_grammar!
    words = @grammar\match text
    return {} unless words

    n = @ngram_size!
    ignore_numbers = @opts.ignore_numbers
    ignore_numbers = true if ignore_numbers == nil

    tokens = {}
    for raw_word in *words
      cleaned = @normalize_word raw_word
      continue unless cleaned

      if ignore_numbers and cleaned\match "^%d+$"
        continue

      for token in *@word_ngrams cleaned, n
        table.insert tokens, token

    if @opts.filter_tokens
      tokens = @opts.filter_tokens tokens, @opts

    tokens
