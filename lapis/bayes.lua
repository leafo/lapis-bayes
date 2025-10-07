local db = require("lapis.db")
local VERSION = "1.3.0"
local text_probabilities
text_probabilities = function(categories, text, opts)
  if opts == nil then
    opts = { }
  end
  local DefaultClassifier = require("lapis.bayes.classifiers.default")
  return DefaultClassifier(opts):text_probabilities(categories, text)
end
local classify_text
classify_text = function(categories, text, opts)
  if opts == nil then
    opts = { }
  end
  local DefaultClassifier = require("lapis.bayes.classifiers.default")
  return DefaultClassifier(opts):classify_text(categories, text)
end
local train_text
train_text = function(category, text, opts)
  local DefaultClassifier = require("lapis.bayes.classifiers.default")
  local words = DefaultClassifier(opts):tokenize_text(text)
  local Categories
  Categories = require("lapis.bayes.models").Categories
  category = Categories:find_or_create(category)
  return category:increment_words(words)
end
return {
  classify_text = classify_text,
  train_text = train_text,
  text_probabilities = text_probabilities,
  VERSION = VERSION
}
