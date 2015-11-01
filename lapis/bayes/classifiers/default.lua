local DefaultClassifier
do
  local _base_0 = {
    confidence = function(self, result)
      local hit, miss = unpack(result)
      return (hit[2] - miss[2]) / hit[2]
    end,
    candidate_tokens = function(self, categories, available_words, count)
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
    count_words = function(self, categories, text)
      local db = require("lapis.db")
      local Categories, WordClassifications
      do
        local _obj_0 = require("lapis.bayes.models")
        Categories, WordClassifications = _obj_0.Categories, _obj_0.WordClassifications
      end
      local num_categories = #categories
      local categories_by_name
      do
        local _tbl_0 = { }
        local _list_0 = Categories:find_all(categories, "name")
        for _index_0 = 1, #_list_0 do
          local c = _list_0[_index_0]
          _tbl_0[c.name] = c
        end
        categories_by_name = _tbl_0
      end
      do
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #categories do
          local name = categories[_index_0]
          _accum_0[_len_0] = categories_by_name[name]
          _len_0 = _len_0 + 1
        end
        categories = _accum_0
      end
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
      assert(#categories == 2, "only works with two categories")
      local token_ratio = #available_words / #words
      local a, b = unpack(categories)
      local sum_counts = 0
      for _index_0 = 1, #categories do
        local c = categories[_index_0]
        sum_counts = sum_counts + c.total_count
      end
      available_words = self:candidate_tokens(categories, available_words, 40)
      local available_words_count = #available_words
      local default_prob = (self.opts.default_prob or 0.1) / sum_counts
      local default_a = default_prob * a.total_count
      local default_b = default_prob * b.total_count
      local prob
      if false then
        local ai_log_sum = 0
        local bi_log_sum = 0
        for _index_0 = 1, #available_words do
          local word = available_words[_index_0]
          ai_log_sum = ai_log_sum + math.log((a.word_counts and a.word_counts[word] or 0) + default_a)
          bi_log_sum = bi_log_sum + math.log((b.word_counts and b.word_counts[word] or 0) + default_b)
        end
        ai_log_sum = ai_log_sum - math.log((default_a + a.total_count) * available_words_count)
        bi_log_sum = bi_log_sum - math.log((default_b + b.total_count) * available_words_count)
        ai_log_sum = ai_log_sum + math.log(a.total_count)
        bi_log_sum = bi_log_sum + math.log(b.total_count)
        local ai_prob = math.exp(ai_log_sum)
        local bi_prob = math.exp(bi_log_sum)
        prob = ai_prob / (ai_prob + bi_prob)
      else
        local ai_mul, bi_mul
        for _index_0 = 1, #available_words do
          local word = available_words[_index_0]
          local ai_count = (a.word_counts and a.word_counts[word] or 0) + default_a
          local bi_count = (b.word_counts and b.word_counts[word] or 0) + default_b
          if ai_mul then
            ai_mul = ai_mul * ai_count
          else
            ai_mul = ai_count
          end
          if bi_mul then
            bi_mul = bi_mul * bi_count
          else
            bi_mul = bi_count
          end
        end
        local ai_prob = a.total_count * ai_mul / ((a.total_count + default_a) * available_words_count)
        local bi_prob = b.total_count * bi_mul / ((b.total_count + default_b) * available_words_count)
        prob = ai_prob / (ai_prob + bi_prob)
      end
      if prob ~= prob then
        error("Got nan when calculating prob")
      end
      if prob == math.huge or prob == -math.huge then
        error("Got inf when calculating prob")
      end
      local tuples = {
        {
          a.name,
          prob
        },
        {
          b.name,
          1 - prob
        }
      }
      table.sort(tuples, function(a, b)
        return a[2] > b[2]
      end)
      for _index_0 = 1, #tuples do
        local _des_0 = tuples[_index_0]
        local c, p
        c, p = _des_0[1], _des_0[2]
        tuples[c] = p
      end
      return tuples, token_ratio
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
