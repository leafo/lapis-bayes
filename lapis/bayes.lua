local db = require("lapis.db")
local Categories, WordClassifications
do
  local _obj_0 = require("lapis.bayes.models")
  Categories, WordClassifications = _obj_0.Categories, _obj_0.WordClassifications
end
local p2
p2 = function(categories, available_words, words, opts)
  local assumed_prob = opts.assumed_prob or 0.1
  local total_count = { }
  for _index_0 = 1, #categories do
    local c = categories[_index_0]
    for word, count in pairs(c.word_counts) do
      total_count[word] = total_count[word] or 0
      total_count[word] = total_count[word] + count
    end
  end
  for _index_0 = 1, #categories do
    local c = categories[_index_0]
    local tuples
    do
      local _accum_0 = { }
      local _len_0 = 1
      for _index_1 = 1, #available_words do
        local _continue_0 = false
        repeat
          local word = available_words[_index_1]
          local cat_count = c.word_counts[word]
          if not (cat_count) then
            _continue_0 = true
            break
          end
          local tot = total_words[available_words]
          local _value_0 = {
            word,
            cat_count / tot
          }
          _accum_0[_len_0] = _value_0
          _len_0 = _len_0 + 1
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      tuples = _accum_0
    end
    local by_importance
    do
      local _accum_0 = { }
      local _len_0 = 1
      for _index_1 = 1, #tuples do
        local t = tuples[_index_1]
        _accum_0[_len_0] = {
          math.abs(t[2] - 0.5, t)
        }
        _len_0 = _len_0 + 1
      end
      by_importance = _accum_0
    end
    table.sort(by_importance, function(a, b)
      return a[1] > b[1]
    end)
    do
      local _accum_0 = { }
      local _len_0 = 1
      for _index_1 = 1, #by_importance do
        local i = by_importance[_index_1]
        _accum_0[_len_0] = i[2]
        _len_0 = _len_0 + 1
      end
      tuples = _accum_0
    end
    require("moon").p(tuples)
    error("not yet")
  end
end
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
  text_probabilities = text_probabilities
}
