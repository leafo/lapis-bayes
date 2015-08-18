db = require "lapis.db"

tokenize_text = (text) ->
  res = db.query [[
    select unnest(lexemes) as word
    from ts_debug('english', ?);
  ]], text
  tokens = {}
  [r.word for r in *res]






check_text = (text, categories) ->

classify_text = (text, category) ->
  category = Categories\find_or_create category
  category\increment_text text

{:check_text, :classify_text, :tokenize_text, :text_probabilities}
