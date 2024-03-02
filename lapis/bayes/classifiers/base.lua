local uniquify
uniquify = require("lapis.util").uniquify
local BaseClassifier
do
  local _class_0
  local _base_0 = {
    default_tokenizer = "lapis.bayes.tokenizers.postgres_text",
    word_probabilities = function(self, categories, words)
      return error("word_probabilities: subclass must implement")
    end,
    classify_text = function(self, ...)
      local counts, word_rate_or_err = self:text_probabilities(...)
      if not (counts) then
        return nil, word_rate_or_err
      end
      return counts[1][1], counts[1][2], word_rate_or_err
    end,
    tokenize_text = function(self, text)
      assert(text, "missing text to tokenize")
      if not (type(text) == "string") then
        return text
      end
      if self.opts.tokenize_text then
        return self.opts.tokenize_text(text, self.opts)
      end
      local tokenizer
      if self.opts.tokenizer then
        tokenizer = self.opts.tokenizer
      else
        local Tokenizer = require(self.default_tokenizer)
        tokenizer = Tokenizer(self.opts)
      end
      return tokenizer:tokenize_text(text)
    end,
    text_probabilities = function(self, category_names, text)
      local categories, err = self:find_categories(category_names)
      if not (categories) then
        return nil, err
      end
      local words = self:tokenize_text(text)
      if not (words and next(words)) then
        return nil, "failed to generate tokens for text"
      end
      local available_words
      available_words, err = self:count_words(categories, words)
      if not (available_words) then
        return nil, err
      end
      local available_words_set
      do
        local _tbl_0 = { }
        for _index_0 = 1, #available_words do
          local word = available_words[_index_0]
          _tbl_0[word] = true
        end
        available_words_set = _tbl_0
      end
      local count = 0
      for _index_0 = 1, #words do
        local word = words[_index_0]
        if available_words_set[word] then
          count = count + 1
        end
      end
      local token_ratio = count / #words
      local probs
      probs, err = self:word_probabilities(categories, available_words)
      if not (probs) then
        return nil, err
      end
      for _index_0 = 1, #probs do
        local _des_0 = probs[_index_0]
        local c, p
        c, p = _des_0[1], _des_0[2]
        probs[c] = p
      end
      return probs, token_ratio
    end,
    find_categories = function(self, category_names)
      local Categories
      Categories = require("lapis.bayes.models").Categories
      local db = Categories.db
      local categories = Categories:select("where name in ?", db.list(category_names))
      local by_name
      do
        local _tbl_0 = { }
        for _index_0 = 1, #categories do
          local c = categories[_index_0]
          _tbl_0[c.name] = c
        end
        by_name = _tbl_0
      end
      local missing
      local result
      do
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #category_names do
          local _continue_0 = false
          repeat
            local name = category_names[_index_0]
            local c = by_name[name]
            if not (c) then
              missing = missing or { }
              table.insert(missing, name)
              _continue_0 = true
              break
            end
            local _value_0 = c
            _accum_0[_len_0] = _value_0
            _len_0 = _len_0 + 1
            _continue_0 = true
          until true
          if not _continue_0 then
            break
          end
        end
        result = _accum_0
      end
      if missing and next(missing) then
        return nil, "find_categories: missing categories (" .. tostring(table.concat(missing, ", ")) .. ")"
      end
      return result
    end,
    find_word_classifications = function(self, words, category_ids)
      if not (next(words) and next(category_ids)) then
        return { }
      end
      local WordClassifications
      WordClassifications = require("lapis.bayes.models").WordClassifications
      local db = WordClassifications.db
      return WordClassifications:select("where word in ? and category_id in ?", db.list(words), db.list(category_ids))
    end,
    candidate_words = function(self, categories, available_words, count)
      if #available_words <= count then
        return available_words
      end
      assert(#categories == 2, "can only do two categories")
      local a, b = unpack(categories)
      local tuples
      do
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #available_words do
          local word = available_words[_index_0]
          local a_count = a.word_counts and a.word_counts[word] or 0
          local b_count = b.word_counts and b.word_counts[word] or 0
          local _value_0 = {
            word,
            math.random() / 100 + math.abs((a_count - b_count) / math.sqrt(a_count + b_count)),
            a_count,
            b_count
          }
          _accum_0[_len_0] = _value_0
          _len_0 = _len_0 + 1
        end
        tuples = _accum_0
      end
      table.sort(tuples, function(a, b)
        return a[2] > b[2]
      end)
      local _accum_0 = { }
      local _len_0 = 1
      local _max_0 = count
      for _index_0 = 1, _max_0 < 0 and #tuples + _max_0 or _max_0 do
        local t = tuples[_index_0]
        _accum_0[_len_0] = t[1]
        _len_0 = _len_0 + 1
      end
      return _accum_0
    end,
    count_words = function(self, categories, words)
      local categories_by_id
      do
        local _tbl_0 = { }
        for _index_0 = 1, #categories do
          local c = categories[_index_0]
          _tbl_0[c.id] = c
        end
        categories_by_id = _tbl_0
      end
      words = uniquify(words)
      local wcs = self:find_word_classifications(words, (function()
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #categories do
          local c = categories[_index_0]
          _accum_0[_len_0] = c.id
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)())
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
        category.word_counts = category.word_counts or { }
        category.word_counts[wc.word] = wc.count
      end
      return available_words
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, opts)
      if opts == nil then
        opts = { }
      end
      self.opts = opts
      if self.__class.default_options then
        self.opts = setmetatable((function()
          local _tbl_0 = { }
          for k, v in pairs(self.opts) do
            _tbl_0[k] = v
          end
          return _tbl_0
        end)(), {
          __index = self.__class.default_options
        })
      end
    end,
    __base = _base_0,
    __name = "BaseClassifier"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  BaseClassifier = _class_0
  return _class_0
end
