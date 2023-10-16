local db = require("lapis.db")
local Categories, WordClassifications
do
  local _obj_0 = require("lapis.bayes.models")
  Categories, WordClassifications = _obj_0.Categories, _obj_0.WordClassifications
end
local VERSION = "1.2.0"
local text_probabilities
text_probabilities = function(categories, text, opts)
  if opts == nil then
    opts = { }
  end
  local DefaultClassifier = require("lapis.bayes.classifiers.default")
  return DefaultClassifier(opts):text_probabilities(categories, text)
end
local classify_text
classify_text = function(categories, text, ...)
  local counts, word_rate_or_err = text_probabilities(categories, text, ...)
  if not (counts) then
    return nil, word_rate_or_err
  end
  return counts[1][1], counts[1][2], word_rate_or_err
end
local train_text
train_text = function(category, text, opts)
  category = Categories:find_or_create(category)
  return category:increment_text(text, opts)
end
return {
  classify_text = classify_text,
  train_text = train_text,
  text_probabilities = text_probabilities,
  VERSION = VERSION
}
