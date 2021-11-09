db = require "lapis.db"
import Categories, WordClassifications from require "lapis.bayes.models"

VERSION = "1.2.0"

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

{ :classify_text, :train_text, :text_probabilities, :VERSION }
