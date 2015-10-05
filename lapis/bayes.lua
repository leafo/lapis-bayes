local db = require("lapis.db")
local Categories, WordClassifications
do
  local _obj_0 = require("lapis.bayes.models")
  Categories, WordClassifications = _obj_0.Categories, _obj_0.WordClassifications
end
local filter_tokens
filter_tokens = function(tokens, opts)
  local min_len = opts and opts.min_token_length or 2
  local max_len = opts and opts.max_token_length or 12
  local strip_numbers = opts and opts.strip_number_tokens or nil
  if strip_numbers == nil then
    strip_numbers = true
  end
  return (function()
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #tokens do
      local _continue_0 = false
      repeat
        local t = tokens[_index_0]
        local t_len = #t
        if t_len > max_len then
          _continue_0 = true
          break
        end
        if t_len < min_len then
          _continue_0 = true
          break
        end
        if strip_numbers and t:match("^[%d%.]+$") then
          _continue_0 = true
          break
        end
        local _value_0 = t
        _accum_0[_len_0] = _value_0
        _len_0 = _len_0 + 1
        _continue_0 = true
      until true
      if not _continue_0 then
        break
      end
    end
    return _accum_0
  end)()
end
local tokenize_text
tokenize_text = function(text, opts)
  local pre_filter = opts and opts.filter_text
  if pre_filter then
    text = pre_filter(text)
  end
  if opts and opts.symbols_split_tokens then
    text = text:gsub("[%!%@%#%$%%%^%&%*%(%)%[%]%{%}%|%\\%/%`%~%-%_%<%>%,%.]", " ")
  end
  local res = db.query([[    select unnest(lexemes) as word
    from ts_debug('english', ?);
  ]], text)
  local tokens
  do
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #res do
      local r = res[_index_0]
      _accum_0[_len_0] = r.word
      _len_0 = _len_0 + 1
    end
    tokens = _accum_0
  end
  local filter = opts and opts.filter_tokens or filter_tokens
  tokens = filter(tokens, opts)
  return tokens
end
local text_probabilities
text_probabilities = function(categories, text, opts)
  if opts == nil then
    opts = { }
  end
  local num_categories = #categories
  local assumed_prob = opts.assumed_prob or 0.1
  categories = Categories:find_all(categories, "name")
  assert(num_categories == #categories, "failed to find all categories for classify")
  local words = tokenize_text(text, opts)
  local categories_by_id
  do
    local _tbl_0 = { }
    for _index_0 = 1, #categories do
      local c = categories[_index_0]
      _tbl_0[c.id] = c
    end
    categories_by_id = _tbl_0
  end
  local by_category_by_words = { }
  local wcs = WordClassifications:find_all(words, {
    key = "word",
    where = {
      category_id = db.list((function()
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #categories do
          local c = categories[_index_0]
          _accum_0[_len_0] = c.id
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)())
    }
  })
  local available_words
  do
    local _accum_0 = { }
    local _len_0 = 1
    for word in pairs((function()
      local _tbl_0 = { }
      for _index_0 = 1, #wcs do
        local wc = wcs[_index_0]
        _tbl_0[wc.word] = true
      end
      return _tbl_0
    end)()) do
      _accum_0[_len_0] = word
      _len_0 = _len_0 + 1
    end
    available_words = _accum_0
  end
  if #available_words == 0 then
    return nil, "no words in text are classifyable"
  end
  for _index_0 = 1, #wcs do
    local wc = wcs[_index_0]
    local category = categories_by_id[wc.category_id]
    by_category_by_words[category.id] = by_category_by_words[category.id] or { }
    by_category_by_words[category.id][wc.word] = wc.count
  end
  local sum_counts = 0
  for _index_0 = 1, #categories do
    local c = categories[_index_0]
    sum_counts = sum_counts + c.total_count
  end
  local tuples
  do
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #categories do
      local c = categories[_index_0]
      local p = math.log(c.total_count / sum_counts)
      local word_counts = by_category_by_words[c.id]
      for _index_1 = 1, #available_words do
        local w = available_words[_index_1]
        local count = word_counts and word_counts[w] or 0
        local real_prob = count / c.total_count
        local adjusted_prob = (assumed_prob + sum_counts * real_prob) / sum_counts
        p = p + math.log(adjusted_prob)
      end
      local _value_0 = {
        c.name,
        p
      }
      _accum_0[_len_0] = _value_0
      _len_0 = _len_0 + 1
    end
    tuples = _accum_0
  end
  table.sort(tuples, function(a, b)
    return a[2] > b[2]
  end)
  return tuples, #available_words / #words
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
  tokenize_text = tokenize_text,
  text_probabilities = text_probabilities,
  filter_tokens = filter_tokens
}
