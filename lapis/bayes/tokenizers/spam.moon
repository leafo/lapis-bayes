unpack_fn = table.unpack or unpack

punycode = require "lapis.bayes.text.punycode"
import Extractor from require "web_sanitize.html"
types = require "lapis.validate.types"

extract_text = Extractor {
  escape_html: false
}

normalize_number = (value) ->
  return unless value and value != ""

  normalized = value\gsub("[,%s]", "")
  digits_only = normalized\gsub("[^%d]", "")
  return if digits_only == ""

  normalized

handle_punct = (chars) ->
  char = chars\sub 1, 1
  {tag: "punct", value: char .. tostring(#chars)}

handle_invalid_byte = (byte) ->
  {tag: "invalid_byte", value: tostring(string.byte(byte))}

-- return new array with order shuffled by dithering
-- e: dither factor
-- https://buildingrecommenders.wordpress.com/2015/11/11/dithering/
dithered = do
  -- random normal box muller
  gn = (sd=1, mean=0, r=math.random) ->
    local x1, x2, w, y1, y2
    while true
      x1 = 2 * r! - 1
      x2 = 2 * r! - 1
      w = x1^2 + x2^2
      break if w < 1

    w = math.sqrt -2 * math.log(w) / 2
    y1 = x1 * w
    y2 = x2 * w

    y1 * sd + mean

  dither_score = (rank, e) ->
    math.log(rank) + gn(math.log(e))

  (items, e=1.5) ->
    rows = for i, item in ipairs items
      {dither_score(i, e), item}

    table.sort rows, (a, b) ->
      a[1] < b[1]

    [row[2] for row in *rows]


-- spam tokenizer with support for domains, emails, currencies, and more
-- opts = {
--   filter_text: function -- function to pre-filter text, returns new text
--   min_word_length: number -- minimum length of word (default 2)
--   max_word_length: number -- maximum length of word (default 32)
--   ignore_words: table -- table of words to ignore
--   stem_words: bool -- enable word stemming
--   unaccent: bool -- enable unaccenting (default true)
--   dedupe: bool -- enable deduplication (default true)
--   ignore_tokens: table -- table of tokens to ignore
--   sample_at_most: number -- limit number of sampled tokens
--   dither: bool -- enable dithering when sampling (default true)
--   bigram_tokens: bool -- enable bigram generation
--   filter_tokens: function -- function to filter tokens, called at end with (tokens, opts)
-- }
class SpamTokenizer extends require "lapis.bayes.tokenizers.base"
  new: (@opts = {}) =>

  tagged_token_to_string: (token) =>
    "#{token.tag}:#{token.value}"

  build_grammar: =>
    import P, S, R, C, Ct from require "lpeg"
    utf8 = require "lapis.util.utf8"

    opts = @opts

    min_len = @opts.min_word_length or 2
    max_len = @opts.max_word_length or 32
    ignore_words = @opts.ignore_words

    truncate = types.truncated_text max_len

    stem = if @opts.stem_words
      require("lapis.bayes.text.stem").stem_word

    unaccent = unless @opts.unaccent == false
      require("lapis.bayes.text.unaccent").unaccent_string

    case_insensitive = (text) ->
      out = nil
      for char in text\gmatch "."
        lower = char\lower!
        upper = char\upper!
        pattern = if lower == upper
          P char
        else
          S "#{lower}#{upper}"

        out = if out
          out * pattern
        else
          pattern

      out or P(false)

    normalize_word = (word) ->
      return unless word and word != ""

      if unaccent
        word = unaccent(word) or word

      word = word\lower!
      word = word\gsub("'+", "")

      return if #word < min_len
      if #word > max_len
        word = truncate\transform word
      return if ignore_words and ignore_words[word]

      word

    handle_domain_token = (domain) ->
      -- convert subdomains to punycode
      labels = for label in domain\gmatch "[^%.]+"
        encoded = punycode.punycode_encode label
        if #encoded > max_len
          truncate\transform encoded
        else
          encoded

      tokens = {
        {tag: "domain", value: truncate\transform table.concat(labels, ".")\lower!}
      }

      -- Generate hierarchical domain tokens with leading dots for subdomains
      if #labels >= 2
        for i = 2, #labels
          suffix = table.concat [labels[j] for j = i, #labels], "."
          table.insert tokens, {tag: "domain", value: truncate\transform ".#{suffix\lower!}"}

      unpack_fn tokens

    handle_email = (email) ->
      email = email\lower!
      user, domain = email\match "^([^@]+)@(.+)$"

      tokens = {{tag: "email", value: truncate\transform email}}

      if user
        user_token = normalize_word user
        table.insert tokens, {tag: "email_user", value: user_token} if user_token

      if domain
        for token in *{handle_domain_token domain}
          table.insert tokens, token

      unpack_fn tokens

    handle_number = (value) ->
      normalized = normalize_number value
      return unless normalized
      if #normalized > max_len
        truncate\transform normalized
      else
        normalized

    handle_currency = (value) ->
      symbol, rest = value\match "^([%$£€¥]+)%s*(.+)$"
      symbol or= value\sub 1, 1
      rest or= ""

      normalized_number = normalize_number rest
      if normalized_number and #normalized_number > max_len
        normalized_number = truncate\transform normalized_number

      if symbol and symbol != ""
        if normalized_number
          {tag: "currency", value: symbol}, normalized_number
        else
          {tag: "currency", value: symbol}

    handle_percent = (value) ->
      number_part = value\sub 1, #value - 1
      normalized = normalize_number number_part
      return unless normalized
      if #normalized > max_len - 1  -- reserve 1 char for %
        normalized = truncate\transform normalized
      "#{normalized}%"

    handle_caps_word = (word) ->
      return unless word\match "%u"


      normalized = normalize_word word
      return unless normalized
      stemmed = if stem
        stem(normalized) or normalized
      else
        normalized
      stemmed, {tag: "caps", value: stemmed}

    handle_word = (word) ->
      normalized = normalize_word word
      return unless normalized
      if stem
        stem(normalized) or normalized
      else
        normalized

    whitespace = utf8.whitespace
    alpha = R "az", "AZ"
    digit = R "09"
    alphanum = alpha + digit

    punct_chars = S"!?$#%"
    other_punct = S"()[]{},.;:\"<>/@#"
    word_char = utf8.printable_character - whitespace - punct_chars - other_punct
    word_pattern = (word_char + P"'")^1

    caps_char = R"AZ"
    caps_pattern = caps_char^2 * (caps_char + digit)^0

    sign = S"+-"^-1
    number_body = sign * digit^1 * (P"," * digit^3)^0 * (P"." * digit^1)^-1

    percent_pattern = number_body * P"%"
    currency_pattern = S"$£€¥" * whitespace^0 * number_body

    punct_pattern = punct_chars^3 * punct_chars^0

    domain_char = utf8.printable_character - whitespace - S"./:@?#[](){}<>\"',"
    domain_label = domain_char^1
    domain_pattern = domain_label * (P"." * domain_label)^1

    not_path = S[[ \t\r\n\"'<>()[\]{}?#]]
    port_part = (P":" * digit^1)^-1
    path_part = (P"/" * (1 - not_path)^0)^0
    query_part = (P"?" * (1 - not_path)^0)^-1
    fragment_part = (P"#" * (1 - not_path)^0)^-1

    www_prefix = case_insensitive "www."
    scheme = (alpha + digit)^1

    url_with_scheme = scheme * P"://" * www_prefix^-1 * C(domain_pattern) * port_part * path_part * query_part * fragment_part
    url_without_scheme = www_prefix * C(domain_pattern) * port_part * path_part * query_part * fragment_part

    email_pattern = C((alphanum + S".%+_'-")^1 * P"@" * domain_pattern)

    number_capture = C(number_body) * -(alpha)

    token_patterns = {
      url_with_scheme / handle_domain_token
      url_without_scheme / handle_domain_token
      email_pattern / handle_email
      C(currency_pattern) / handle_currency
      C(percent_pattern) / handle_percent
      number_capture / handle_number
      C(caps_pattern) / handle_caps_word
      C(word_pattern) / handle_word
      C(punct_pattern) / handle_punct
    }

    tokens = token_patterns[1]
    for i = 2, #token_patterns
      tokens = tokens + token_patterns[i]

    printable = utf8.printable_character
    Ct (tokens + printable + (C(P(1)) / handle_invalid_byte))^0

  collect_url_tokens: (text) =>
    return {} unless text and text != ""

    @grammar or= @build_grammar!
    tokens = @grammar\match text
    return {} unless tokens

    out = {}
    for token in *tokens
      continue unless type(token) == "table"
      if token.tag == "domain" or token.tag == "email" or token.tag == "email_user"
        table.insert out, @tagged_token_to_string token

    out

  dedupe_tokens: (tokens) =>
    return {} unless tokens
    seen = {}
    deduped = {}
    for token in *tokens
      -- For table tokens, use string representation as key
      key = if type(token) == "table"
        @tagged_token_to_string token
      else
        token

      unless seen[key]
        seen[key] = true
        table.insert deduped, token
    deduped

  generate_bigrams: (tokens, ignore_tokens) =>
    return {} unless tokens
    count = #tokens
    return {} if count < 2

    bigrams = {}
    for i = 1, count - 1
      first = tokens[i]
      second = tokens[i + 1]
      continue unless first and second

      bigram = first .. " " .. second
      continue if ignore_tokens and ignore_tokens[bigram]

      table.insert bigrams, bigram

    bigrams

  sample_tokens: (tokens, limit) =>
    return {} unless tokens
    return tokens unless limit
    limit = math.floor limit
    return {} if limit <= 0
    count = #tokens
    return tokens if count <= limit

    tokens_to_sample = if @opts.dither == false
      tokens
    else
      dithered tokens

    [tokens_to_sample[idx] for idx=1,limit]

  tokenize_text: (text) =>
    return {} unless text

    text = tostring text

    if @opts.filter_text
      text = @opts.filter_text text

    raw_text = text
    raw_url_tokens = @collect_url_tokens raw_text

    text = extract_text text

    @grammar or= @build_grammar!
    tokens = @grammar\match text or {}

    -- Build map of existing tokens (convert objects to strings for comparison)
    existing = {}
    for token in *tokens
      key = if type(token) == "table"
        @tagged_token_to_string token
      else
        token
      existing[key] = true

    -- Add raw URL tokens if they don't already exist
    if raw_url_tokens and #raw_url_tokens > 0
      for token in *raw_url_tokens
        continue if existing[token]
        table.insert tokens, token
        existing[token] = true

    -- Apply built-in token processing
    dedupe = true
    if @opts.dedupe != nil
      dedupe = @opts.dedupe
    ignore_tokens = @opts.ignore_tokens
    sample_limit = @opts.sample_at_most

    -- Split into word tokens and tagged tokens
    word_tokens = {}
    tagged_tokens = {}
    for token in *tokens
      continue unless token
      continue if token == ""
      continue if ignore_tokens and ignore_tokens[token]

      if type(token) == "table"
        table.insert tagged_tokens, token
      else
        table.insert word_tokens, token

    -- Generate bigrams from undeduped word tokens
    bigram_tokens = {}
    if @opts.bigram_tokens
      bigram_tokens = @generate_bigrams word_tokens, ignore_tokens

    -- Process word tokens: dedupe then sample
    if dedupe
      word_tokens = @dedupe_tokens word_tokens

    if sample_limit
      word_tokens = @sample_tokens word_tokens, sample_limit

    -- Process bigram tokens: dedupe then sample
    if dedupe
      bigram_tokens = @dedupe_tokens bigram_tokens

    if sample_limit
      bigram_tokens = @sample_tokens bigram_tokens, sample_limit

    -- Process tagged tokens: dedupe (but not sample - we want all tagged tokens)
    if dedupe
      tagged_tokens = @dedupe_tokens tagged_tokens

    -- Merge all token sets: words + bigrams + tagged tokens
    tokens = {}
    for token in *word_tokens
      table.insert tokens, token
    for token in *bigram_tokens
      table.insert tokens, token
    for token in *tagged_tokens
      table.insert tokens, @tagged_token_to_string token

    -- Apply custom filter at the very end if provided
    if @opts.filter_tokens
      tokens = @opts.filter_tokens tokens, @opts

    tokens

return SpamTokenizer
