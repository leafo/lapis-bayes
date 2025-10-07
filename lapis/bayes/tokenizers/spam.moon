unpack_fn = table.unpack or unpack

unaccent = require "lapis.bayes.text.unaccent"
import extract_text from require "web_sanitize"

class SpamTokenizer extends require "lapis.bayes.tokenizers.base"
  new: (@opts = {}) =>

  build_grammar: =>
    import P, S, R, C, Ct from require "lpeg"

    opts = @opts or {}

    min_len = opts.min_word_length or 2
    max_len = opts.max_word_length or 32
    ignore_words = opts.ignore_words

    stem = if opts.stem_words
      require("lapis.bayes.text.stem").stem_word
    else
      nil

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
      word = word\lower!
      word = word\gsub("'+", "")

      return if #word < min_len
      return if #word > max_len
      return unless word\match "%a"
      return if ignore_words and ignore_words[word]

      word

    emit_domain_tokens = (domain) ->
      domain = domain\lower!

      tokens = {"domain:" .. domain}
      labels = {}

      for label in domain\gmatch "[^%.]+"
        table.insert labels, label
        keep_label = normalize_word label
        table.insert tokens, "host_label:" .. keep_label if keep_label

      if #labels >= 2
        root = "#{labels[#labels - 1]}.#{labels[#labels]}"
        table.insert tokens, "root_domain:" .. root
        table.insert tokens, "tld:" .. labels[#labels]
      elseif #labels == 1
        table.insert tokens, "tld:" .. labels[1]

      tokens

    handle_domain_token = (domain, prefix = nil) ->
      domain = domain\lower!
      tokens = emit_domain_tokens domain
      if prefix
        table.insert tokens, 1, "#{prefix}:" .. domain
      unpack_fn tokens

    handle_email = (email) ->
      email = email\lower!
      user, domain = email\match "^([^@]+)@(.+)$"

      tokens = {"email:" .. email}

      if user
        user_token = normalize_word user
        table.insert tokens, "email_user:" .. user_token if user_token

      if domain
        for token in *emit_domain_tokens domain
          table.insert tokens, token

      unpack_fn tokens

    make_number_tokens = (value) ->
      return unless value and value != ""

      normalized = value\gsub("[,%s]", "")
      digits_only = normalized\gsub("[^%d]", "")
      return if digits_only == ""

      digit_count = #digits_only
      bucket = if digit_count <= 2
        "short"
      elseif digit_count <= 4
        "medium"
      else
        "long"

      {"number:" .. normalized, "number_bucket:" .. bucket}

    handle_number = (value) ->
      tokens = make_number_tokens value
      return unless tokens
      unpack_fn tokens

    handle_currency = (value) ->
      symbol, rest = value\match "^([%$£€¥]+)%s*(.+)$"
      symbol or= value\sub 1, 1
      rest or= ""

      number_tokens = make_number_tokens rest
      tokens = {}

      if symbol and symbol != ""
        table.insert tokens, "currency:" .. symbol

      if number_tokens
        for token in *number_tokens
          table.insert tokens, token

      unpack_fn tokens

    handle_percent = (value) ->
      number_part = value\sub 1, #value - 1
      number_tokens = make_number_tokens number_part
      return unless number_tokens
      normalized = number_part\gsub("[,%s]", "")
      tokens = {"percent:" .. normalized}
      for token in *number_tokens
        table.insert tokens, token
      unpack_fn tokens

    handle_caps_word = (word) ->
      return unless word\match "%u"
      normalized = normalize_word word
      return unless normalized
      stemmed = if stem
        stem(normalized) or normalized
      else
        normalized
      stemmed, "caps:" .. stemmed

    handle_word = (word) ->
      normalized = normalize_word word
      return unless normalized
      if stem
        stem(normalized) or normalized
      else
        normalized

    handle_punct = (chars) ->
      char = chars\sub 1, 1
      "punct:" .. char .. tostring(#chars)

    whitespace = S " \t\r\n"
    alpha = R "az", "AZ"
    digit = R "09"
    alphanum = alpha + digit

    word_pattern = (alphanum + P"'")^1

    caps_char = R"AZ"
    caps_pattern = caps_char^2 * (caps_char + digit)^0

    sign = S"+-"^-1
    number_body = sign * digit^1 * (P"," * digit^3)^0 * (P"." * digit^1)^-1

    percent_pattern = number_body * P"%"
    currency_pattern = S"$£€¥" * whitespace^0 * number_body

    punct_chars = S"!?$#%"
    punct_pattern = punct_chars^3 * punct_chars^0

    domain_label = (alphanum + P"-")^1
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
      url_with_scheme / (domain) -> handle_domain_token domain, "url"
      url_without_scheme / (domain) -> handle_domain_token domain, "url"
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

    Ct (tokens + P(1))^0

  collect_url_tokens: (text) =>
    return {} unless text and text != ""

    @grammar or= @build_grammar!
    tokens = @grammar\match text
    return {} unless tokens

    out = {}
    for token in *tokens
      continue unless type(token) == "string"
      if (token\match "^url:") or (token\match "^domain:") or (token\match "^host_label:") or (token\match "^root_domain:") or (token\match "^tld:") or (token\match "^email:") or (token\match "^email_user:")
        table.insert out, token

    out

  dedupe_tokens: (tokens) =>
    return {} unless tokens
    seen = {}
    deduped = {}
    for token in *tokens
      unless seen[token]
        seen[token] = true
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
      continue unless first\match "%a"
      continue unless second\match "%a"

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

    sampled = {}
    for i = 1, limit
      sampled[#sampled + 1] = tokens[i]

    sampled

  tokenize_text: (text) =>
    return {} unless text

    text = tostring text

    if @opts and @opts.filter_text
      text = @opts.filter_text text

    raw_text = text
    raw_url_tokens = @collect_url_tokens raw_text

    text = extract_text text

    if not (@opts and @opts.unaccent == false)
      text = unaccent.unaccent_string text

    @grammar or= @build_grammar!
    tokens = @grammar\match text or {}

    existing = {}
    for token in *tokens
      existing[token] = true

    if raw_url_tokens and #raw_url_tokens > 0
      for token in *raw_url_tokens
        continue if existing[token]
        table.insert tokens, token
        existing[token] = true

    -- Apply built-in token processing
    dedupe = true
    if @opts and @opts.dedupe != nil
      dedupe = @opts.dedupe
    ignore_tokens = @opts and @opts.ignore_tokens
    sample_limit = @opts and @opts.sample_at_most

    -- Split into word tokens and tagged tokens
    word_tokens = {}
    tagged_tokens = {}
    for token in *tokens
      continue unless token and token != ""
      continue if ignore_tokens and ignore_tokens[token]

      if token\find ":"
        table.insert tagged_tokens, token
      else
        table.insert word_tokens, token

    -- Generate bigrams from undeduped word tokens
    bigram_tokens = {}
    if @opts and @opts.bigram_tokens
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
      table.insert tokens, token

    -- Apply custom filter at the very end if provided
    if @opts and @opts.filter_tokens
      tokens = @opts.filter_tokens tokens, @opts

    tokens

return SpamTokenizer
