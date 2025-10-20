local BayesClassifier
do
  local _class_0
  local _parent_0 = require("lapis.bayes.classifiers.base")
  local _base_0 = {
    get_token_weight = function(self, word)
      if not (self.opts.token_weight_patterns) then
        return 1.0
      end
      for pattern, weight in pairs(self.opts.token_weight_patterns) do
        if word:match(pattern) then
          return weight
        end
      end
      return 1.0
    end,
    word_probabilities = function(self, categories, available_words)
      if not (#categories == 2) then
        return nil, "only two categories supported at once"
      end
      local a, b = unpack(categories)
      local sum_counts = 0
      for _index_0 = 1, #categories do
        local c = categories[_index_0]
        sum_counts = sum_counts + c.total_count
      end
      available_words = self:candidate_words(categories, available_words, self.opts.max_words)
      local available_words_count = #available_words
      local default_prob = self.opts.default_prob / sum_counts
      local default_a = default_prob * a.total_count
      local default_b = default_prob * b.total_count
      local prob
      if self.opts.log then
        local ai_log_sum = 0
        local bi_log_sum = 0
        for _index_0 = 1, #available_words do
          local word = available_words[_index_0]
          local ai_count = (a.word_counts and a.word_counts[word] or 0) + default_a
          local bi_count = (b.word_counts and b.word_counts[word] or 0) + default_b
          local weight = self:get_token_weight(word)
          ai_log_sum = ai_log_sum + (weight * math.log(ai_count))
          bi_log_sum = bi_log_sum + (weight * math.log(bi_count))
        end
        ai_log_sum = ai_log_sum + math.log(a.total_count)
        bi_log_sum = bi_log_sum + math.log(b.total_count)
        ai_log_sum = ai_log_sum - math.log((default_a + a.total_count))
        bi_log_sum = bi_log_sum - math.log((default_b + b.total_count))
        ai_log_sum = ai_log_sum - math.log(available_words_count)
        bi_log_sum = bi_log_sum - math.log(available_words_count)
        local max_log_sum = math.max(ai_log_sum, bi_log_sum)
        local ai_prob = math.exp(ai_log_sum - max_log_sum)
        local bi_prob = math.exp(bi_log_sum - max_log_sum)
        prob = ai_prob / (ai_prob + bi_prob)
      else
        local ai_mul, bi_mul
        for _index_0 = 1, #available_words do
          local word = available_words[_index_0]
          local ai_count = (a.word_counts and a.word_counts[word] or 0) + default_a
          local bi_count = (b.word_counts and b.word_counts[word] or 0) + default_b
          local weight = self:get_token_weight(word)
          if ai_mul then
            ai_mul = ai_mul * (ai_count ^ weight)
          else
            ai_mul = ai_count ^ weight
          end
          if bi_mul then
            bi_mul = bi_mul * (bi_count ^ weight)
          else
            bi_mul = bi_count ^ weight
          end
        end
        local ai_prob = a.total_count * ai_mul / ((a.total_count + default_a) * available_words_count)
        local bi_prob = b.total_count * bi_mul / ((b.total_count + default_b) * available_words_count)
        if ai_prob ~= ai_prob then
          ai_prob = 0
        end
        if bi_prob ~= bi_prob then
          bi_prob = 0
        end
        prob = ai_prob / (ai_prob + bi_prob)
      end
      if prob ~= prob then
        return nil, "Got nan when calculating prob"
      end
      if prob == math.huge or prob == -math.huge then
        return nil, "Got inf when calculating prob"
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
      return tuples
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "BayesClassifier",
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
    default_prob = 0.1,
    log = false,
    token_weight_patterns = nil
  }
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  BayesClassifier = _class_0
  return _class_0
end
