local BayesMultiClassifier
do
  local _class_0
  local _parent_0 = require("lapis.bayes.classifiers.base")
  local _base_0 = {
    candidate_words = function(self, categories, available_words, count)
      if not (count and count < #available_words) then
        return available_words
      end
      local tuples
      do
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #available_words do
          local word = available_words[_index_0]
          local totals = 0
          local counts = { }
          for _index_1 = 1, #categories do
            local category = categories[_index_1]
            local word_counts = category.word_counts
            local c = word_counts and word_counts[word] or 0
            table.insert(counts, c)
            totals = totals + c
          end
          local score
          if totals == 0 then
            score = 0
          else
            local mean = totals / #counts
            local variance = 0
            for _index_1 = 1, #counts do
              local c = counts[_index_1]
              variance = variance + ((c - mean) ^ 2)
            end
            score = variance / #counts
          end
          score = score + (math.random() / 1000)
          local _value_0 = {
            word,
            score
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
    word_probabilities = function(self, categories, available_words)
      if not (#categories >= 2) then
        return nil, "at least two categories required"
      end
      available_words = self:candidate_words(categories, available_words, self.opts.max_words)
      local vocab_size = #available_words
      if not (vocab_size > 0) then
        return nil, "no words to score"
      end
      local smoothing
      if self.opts.default_prob and self.opts.default_prob > 0 then
        smoothing = self.opts.default_prob
      else
        smoothing = 1e-6
      end
      local sum_counts = 0
      for _index_0 = 1, #categories do
        local category = categories[_index_0]
        sum_counts = sum_counts + (category.total_count or 0)
      end
      local prior_smoothing = smoothing * #categories
      local max_log
      local log_scores
      do
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #categories do
          local category = categories[_index_0]
          local cat_total = math.max((category.total_count or 0), 0)
          local prior = (cat_total + smoothing) / (sum_counts + prior_smoothing)
          local log_score = math.log(prior)
          local denominator = cat_total + (smoothing * vocab_size)
          if denominator <= 0 then
            denominator = smoothing * vocab_size
          end
          for _index_1 = 1, #available_words do
            local word = available_words[_index_1]
            local word_count = category.word_counts and category.word_counts[word] or 0
            log_score = log_score + math.log(((word_count + smoothing) / denominator))
          end
          if max_log then
            max_log = math.max(max_log, log_score)
          else
            max_log = log_score
          end
          local _value_0 = {
            category,
            log_score
          }
          _accum_0[_len_0] = _value_0
          _len_0 = _len_0 + 1
        end
        log_scores = _accum_0
      end
      local weights = { }
      local total_weight = 0
      for _index_0 = 1, #log_scores do
        local _des_0 = log_scores[_index_0]
        local category, log_score
        category, log_score = _des_0[1], _des_0[2]
        local weight = math.exp((log_score - max_log))
        total_weight = total_weight + weight
        table.insert(weights, {
          category.name,
          weight
        })
      end
      if not (total_weight > 0) then
        return nil, "unable to normalise probabilities"
      end
      for _index_0 = 1, #weights do
        local tuple = weights[_index_0]
        local _update_0 = 2
        tuple[_update_0] = tuple[_update_0] / total_weight
      end
      table.sort(weights, function(a, b)
        return a[2] > b[2]
      end)
      return weights
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "BayesMultiClassifier",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.default_options = {
    max_words = 40,
    default_prob = 0.1
  }
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  BayesMultiClassifier = _class_0
  return _class_0
end
