local BayesModClassifier
do
  local _parent_0 = require("lapis.bayes.classifiers.base")
  local _base_0 = {
    word_probabilities = function(self, categories, available_words)
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
          local cat = categories[_index_0]
          local prob = math.log(cat.total_count / sum_counts)
          for _index_1 = 1, #available_words do
            local word = available_words[_index_1]
            local word_count = cat.word_counts and cat.word_counts[word] or 0
            prob = prob + math.log((word_count + 1) / (cat.total_count + sum_counts))
          end
          local _value_0 = {
            cat.name,
            prob
          }
          _accum_0[_len_0] = _value_0
          _len_0 = _len_0 + 1
        end
        tuples = _accum_0
      end
      table.sort(tuples, function(a, b)
        return a[2] > b[2]
      end)
      return tuples
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "BayesModClassifier",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
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
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  BayesModClassifier = _class_0
  return _class_0
end
