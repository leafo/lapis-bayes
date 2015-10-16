db = require "lapis.db"
import Categories, WordClassifications from require "lapis.bayes.models"

p2 = (categories, available_words, words, opts) ->
  assumed_prob = opts.assumed_prob or 0.1

  total_count = {}
  for c in *categories
    for word, count in pairs c.word_counts
      total_count[word] or= 0
      total_count[word] += count

  for c in *categories
    tuples = for word in *available_words
      cat_count = c.word_counts[word]
      continue unless cat_count
      tot = total_words[available_words]
      {word, cat_count/tot}

    by_importance = for t in *tuples
      {math.abs t[2] - 0.5, t}

    table.sort by_importance, (a,b) ->
      a[1] > b[1]

    tuples = [i[2] for i in *by_importance]
    require("moon").p tuples
    error "not yet"

text_probabilities = (categories, text, opts={}) ->
  DefaultClassifier = require "lapis.bayes.classifiers.default"
  DefaultClassifier(opts)\text_probabilities categories, text

classify_text = (categories, text, ...) ->
  counts, word_rate_or_err = text_probabilities categories, text, ...
  unless counts
    return nil, word_rate_or_err

  counts[1][1], counts[1][2], word_rate_or_err

train_text = (category, text, opts) ->
  category = Categories\find_or_create category
  category\increment_text text, opts

{ :classify_text, :train_text, :text_probabilities}
