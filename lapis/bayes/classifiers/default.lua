local DefaultClassifier
do
  local _base_0 = {
    count_words = function(self, categories, text)
      local db = require("lapis.db")
      local Categories, WordClassifications
      do
        local _obj_0 = require("lapis.bayes.models")
        Categories, WordClassifications = _obj_0.Categories, _obj_0.WordClassifications
      end
      local num_categories = #categories
      categories = Categories:find_all(categories, "name")
      assert(num_categories == #categories, "failed to find all categories for classify")
      local tokenize_text
      tokenize_text = require("lapis.bayes.tokenizer").tokenize_text
      local words = tokenize_text(text, self.opts)
      if not (words and next(words)) then
        return nil, "failed to generate tokens"
      end
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
      return categories, available_words, words
    end,
    text_probabilities = function(self, ...)
      local categories, available_words, words = self:count_words(...)
      if not (categories) then
        return nil, available_words
      end
      local default_prob = self.opts.default_prob or 0.1
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
          local word_counts = c.word_counts
          for _index_1 = 1, #available_words do
            local w = available_words[_index_1]
            local count = word_counts and word_counts[w] or 0
            local real_prob = count / c.total_count
            local adjusted_prob = (default_prob + sum_counts * real_prob) / sum_counts
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
      for _index_0 = 1, #tuples do
        local _des_0 = tuples[_index_0]
        local c, p
        c, p = _des_0[1], _des_0[2]
        tuples[c] = p
      end
      return tuples, #available_words / #words
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, opts)
      if opts == nil then
        opts = { }
      end
      self.opts = opts
    end,
    __base = _base_0,
    __name = "DefaultClassifier"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  DefaultClassifier = _class_0
  return _class_0
end
