db = require "lapis.db"

-- postgres based tokenizer
-- opts = {
--   filter_text: function -- function to pre-filter text, returns new text
--   strip_tags: bool -- remove html tags from input in default
--   symbols_split_tokens: bool -- symbols split apart tokens
--   min_len: number -- min length of token (default 2)
--   max_len: number -- max length of token (default 12)
--   strip_numbers: bool -- remove tokens that are a number (including decimal)
-- }
class PostgresTextTokenizer
  new: (@opts) =>

  filter_tokens: (tokens) =>
    opts = @opts
    min_len = opts and opts.min_token_length or 2
    max_len = opts and opts.max_token_length or 12

    strip_numbers = opts and opts.strip_number_tokens or nil
    strip_numbers = true if strip_numbers == nil

    return for t in *tokens
      t_len = #t
      continue if t_len > max_len
      continue if t_len < min_len

      if strip_numbers and t\match "^[%d%.%/%-]+$"
        continue

      continue if @opts and @opts.ignore_words and @opts.ignore_words[t]
      t

  slow_pg_tokenize: (text) =>
    -- this slower form will keep duplicate words
    db.query [[
      select unnest(lexemes) as word
      from ts_debug('english', ?);
    ]], text

  pg_tokenize: (text) =>
    -- much faster (50x), but loses duplicates
    db.query [[
      select unnest(tsvector_to_array(to_tsvector('english', ?))) as word
    ]], text

  tokenize_text: (text) =>
    opts = @opts
    pre_filter = opts and opts.filter_text

    if pre_filter
      text = pre_filter text

    if opts and opts.strip_tags
      import extract_text from require "web_sanitize"
      text = extract_text text

    if opts and opts.symbols_split_tokens
      text = text\gsub "[%!%@%#%$%%%^%&%*%(%)%[%]%{%}%|%\\%/%`%~%-%_%<%>%,%.]", " "

    res = @pg_tokenize text

    tokens = [r.word for r in *res]
    tokens = if opts and opts.filter_tokens
      opts.filter_tokens tokens, opts
    else
      @filter_tokens tokens

    tokens
