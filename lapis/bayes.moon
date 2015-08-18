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
  import Categories from require "lapis.bayes.models"
  category = Categories\find_or_create category

  words_by_counts = {}
  total_words = 0

  for word in *tokenize_text text
    words_by_counts[word] or= 0
    words_by_counts[word] += 1
    total_words += 1

  category\increment_words words_by_counts
  total_words

{:check_text, :classify_text, :tokenize_text}
