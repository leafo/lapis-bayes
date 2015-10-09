db = require "lapis.db"

filter_tokens = (tokens, opts) ->
  min_len = opts and opts.min_token_length or 2
  max_len = opts and opts.max_token_length or 12

  strip_numbers = opts and opts.strip_number_tokens or nil
  strip_numbers = true if strip_numbers == nil

  return for t in *tokens
    t_len = #t
    continue if t_len > max_len
    continue if t_len < min_len

    if strip_numbers and t\match "^[%d%.]+$"
      continue

    t

-- {
--   tokenize_text: function -- custom tokeniaze function
-- 
--   -- the rest of the options only apply to the default tokenizer
--   filter_text: function -- function to pre-filter text, returns new text
--   strip_tags: bool -- remove html tags from input in default
--   symbols_split_tokens: bool -- symbols split apart tokens
--   min_len: number -- min length of token (default 2)
--   max_len: number -- max length of token (default 12)
--   strip_numbers: bool -- remove tokens that are a number (including decimal)
-- 
-- }
tokenize_text = (text, opts) ->
  if opts and opts.tokenize_text
    return opts.tokenize_text text, opts

  pre_filter = opts and opts.filter_text

  if pre_filter
    text = pre_filter text

  if opts and opts.strip_tags
    import extract_text from require "web_sanitize"
    text = extract_text text

  if opts and opts.symbols_split_tokens
    text = text\gsub "[%!%@%#%$%%%^%&%*%(%)%[%]%{%}%|%\\%/%`%~%-%_%<%>%,%.]", " "

  res = db.query [[
    select unnest(lexemes) as word
    from ts_debug('english', ?);
  ]], text

  tokens = [r.word for r in *res]
  filter = opts and opts.filter_tokens or filter_tokens
  tokens = filter tokens, opts
  tokens


{ :tokenize_text, :filter_tokens }
