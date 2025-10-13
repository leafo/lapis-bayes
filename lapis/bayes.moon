VERSION = "1.4.0"

-- calculate the probabilities of text using default classifier
-- categories: array of category names
-- text: the text to calculate probabilities for
text_probabilities = (categories, text, opts={}) ->
  DefaultClassifier = require "lapis.bayes.classifiers.default"
  DefaultClassifier(opts)\text_probabilities categories, text

-- return the best matching category for the given text using the default
-- classifier
classify_text = (categories, text, opts={}) ->
  DefaultClassifier = require "lapis.bayes.classifiers.default"
  DefaultClassifier(opts)\classify_text categories, text

-- train text using default classifier's tokenizer
-- category: string name of category
-- text: the text (or array of words) to train
-- opts: options to pass to the classifier
train_text = (category, text, opts) ->
  DefaultClassifier = require "lapis.bayes.classifiers.default"
  words = DefaultClassifier(opts)\tokenize_text text

  import Categories from require "lapis.bayes.models"
  category = Categories\find_or_create category
  category\increment_words words

{ :classify_text, :train_text, :text_probabilities, :VERSION }
