db = require "lapis.db"
import Categories, WordClassifications from require "lapis.bayes.models"

tokenize_text = (text) ->
  res = db.query [[
    select unnest(lexemes) as word
    from ts_debug('english', ?);
  ]], text
  [r.word for r in *res]

text_probabilities = (text, categories, opts={}) ->
  num_categories = #categories
  assumed_prob = opts.assumed_prob or 0.1

  categories = Categories\find_all categories, "name"
  assert num_categories == #categories,
    "failed to find all categories for classify"

  words = tokenize_text text

  categories_by_id = {c.id, c for c in *categories}
  by_category_by_words = {}

  wcs = WordClassifications\find_all words, {
    key: "word"
    where: {
      category_id: db.list [c.id for c in *categories]
    }
  }

  available_words = [word for word in pairs {wc.word, true for wc in *wcs}]

  if #available_words == 0
    return nil, "no words in text are classifyable"

  for wc in *wcs
    category = categories_by_id[wc.category_id]
    by_category_by_words[category.id] or= {}
    by_category_by_words[category.id][wc.word] = wc.count

  sum_counts = 0
  for c in *categories
    sum_counts += c.total_count

  tuples = for c in *categories
    p = math.log c.total_count / sum_counts
    word_counts = by_category_by_words[c.id]

    for w in *available_words
      -- total times word has appeared in this category
      count = word_counts and word_counts[w] or 0
      real_prob = count / c.total_count

      -- give a little extra to everything to prevent words that aren't in
      -- category from prevening a match
      adjusted_prob = (assumed_prob + sum_counts * real_prob) / sum_counts

      -- accumulate the probability
      p += math.log adjusted_prob

    {c.name, p}

  table.sort tuples, (a, b) ->
    a[2] > b[2]

  tuples, #available_words / #words

classify_text = (text, categories, ...) ->
  counts, word_rate_or_err = text_probabilities text, categories, ...
  unless counts
    return nil, word_rate_or_err

  counts[1][1], counts[1][2], word_rate_or_err

train_text = (text, category) ->
  category = Categories\find_or_create category
  category\increment_text text

{:classify_text, :train_text, :tokenize_text, :text_probabilities}
