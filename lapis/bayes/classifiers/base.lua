local BaseClassifier
do
  local _base_0 = {
    classify = function(self, ...)
      local probs, err = self:text_probabilities(...)
      return error("not yet")
    end,
    text_probabilities = function(self, category_names, text)
      local categories, err = self:find_categories(category_names)
      if not (categories) then
        return nil, err
      end
      local words
      if type(text) == "string" then
        local tokenize_text
        tokenize_text = require("lapis.bayes.tokenizer").tokenize_text
        words = tokenize_text(text, self.opts)
      else
        words = text
      end
      if not (words and next(words)) then
        return nil, "failed to generate tokens for text"
      end
      local available_words
      available_words, err = self:count_words(categories, words)
      if not (available_words) then
        return nil, err
      end
      local token_ratio = #available_words / #words
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
      local categories_by_name
      do
        local _tbl_0 = { }
        local _list_0 = Categories:find_all(category_names, {
          key = "name"
        })
        for _index_0 = 1, #_list_0 do
          local c = _list_0[_index_0]
          _tbl_0[c.name] = c
        end
        categories_by_name = _tbl_0
      end
      local categories
      do
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #category_names do
          local n = category_names[_index_0]
          if categories_by_name[n] then
            _accum_0[_len_0] = categories_by_name[n]
            _len_0 = _len_0 + 1
          end
        end
        categories = _accum_0
      end
      if not (#categories == #category_names) then
        return nil, "missing categories"
      end
      return categories
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
      local db = require("lapis.db")
      local WordClassifications
      WordClassifications = require("lapis.bayes.models").WordClassifications
      local categories_by_id
      do
        local _tbl_0 = { }
        for _index_0 = 1, #categories do
          local c = categories[_index_0]
          _tbl_0[c.id] = c
        end
        categories_by_id = _tbl_0
      end
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
        category.word_counts = category.word_counts or { }
        category.word_counts[wc.word] = wc.count
      end
      return available_words
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
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
