local VERSION = "1.4.0"
local text_probabilities
text_probabilities = function(categories, text, opts)
  if opts == nil then
    opts = { }
  end
  local DefaultClassifier = require("lapis.bayes.classifiers.default")
  return DefaultClassifier(opts):text_probabilities(categories, text, opts)
end
local classify_text
classify_text = function(categories, text, opts)
  if opts == nil then
    opts = { }
  end
  local DefaultClassifier = require("lapis.bayes.classifiers.default")
  return DefaultClassifier(opts):classify_text(categories, text, opts)
end
local train_text
train_text = function(category, text, opts, ...)
  if opts == nil then
    opts = { }
  end
  local DefaultClassifier = require("lapis.bayes.classifiers.default")
  return DefaultClassifier(opts):train_text(category, text, ...)
end
return {
  classify_text = classify_text,
  train_text = train_text,
  text_probabilities = text_probabilities,
  VERSION = VERSION
}
