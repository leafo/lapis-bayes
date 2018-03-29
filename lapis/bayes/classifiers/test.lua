local average
average = function(nums)
  local sum = 0
  for _index_0 = 1, #nums do
    local n = nums[_index_0]
    sum = sum + n
  end
  return sum / #nums
end
local weighted_avg
weighted_avg = function(tuples)
  local num_tuples = #tuples
  local sum = 0
  local sum_weight = 0
  for _index_0 = 1, #tuples do
    local _des_0 = tuples[_index_0]
    local num, weight
    num, weight = _des_0[1], _des_0[2]
    sum = sum + num
    sum_weight = sum_weight + weight
  end
  local avg_weight = sum_weight / num_tuples
  local avg = 0
  for _index_0 = 1, #tuples do
    local _des_0 = tuples[_index_0]
    local num, weight
    num, weight = _des_0[1], _des_0[2]
    avg = avg + ((num / num_tuples) * (weight / avg_weight))
  end
  return avg
end
local TestClassifier
do
  local _class_0
  local _parent_0 = require("lapis.bayes.classifiers.base")
  local _base_0 = {
    word_probabilities = function(self, categories, available_words)
      local total_counts = { }
      for _index_0 = 1, #categories do
        local _continue_0 = false
        repeat
          local c = categories[_index_0]
          if not (c.word_counts) then
            _continue_0 = true
            break
          end
          for word, count in pairs(c.word_counts) do
            local _update_0 = word
            total_counts[_update_0] = total_counts[_update_0] or 0
            local _update_1 = word
            total_counts[_update_1] = total_counts[_update_1] + count
          end
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      local probs
      do
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #categories do
          local c = categories[_index_0]
          local tuples
          do
            local _accum_1 = { }
            local _len_1 = 1
            for _index_1 = 1, #available_words do
              local word = available_words[_index_1]
              local total_count = total_counts[word]
              local cat_count = c.word_counts and c.word_counts[word] or 0
              local _value_0 = {
                cat_count / total_count,
                total_count
              }
              _accum_1[_len_1] = _value_0
              _len_1 = _len_1 + 1
            end
            tuples = _accum_1
          end
          local _value_0 = {
            c.name,
            weighted_avg(tuples)
          }
          _accum_0[_len_0] = _value_0
          _len_0 = _len_0 + 1
        end
        probs = _accum_0
      end
      table.sort(probs, function(a, b)
        return a[2] > b[2]
      end)
      return probs
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "TestClassifier",
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
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  TestClassifier = _class_0
  return _class_0
end
