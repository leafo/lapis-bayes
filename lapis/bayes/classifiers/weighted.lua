local WeightedCassifier
do
  local _class_0
  local _parent_0 = require("lapis.bayes.classifiers.base")
  local _base_0 = {
    word_probabilities = function(self, categories, available_words)
      if not (#categories == 2) then
        return nil, "only two categories supported at once"
      end
      local a, b = unpack(categories)
      local expected = a.total_count / (a.total_count + b.total_count)
      local sum = 0
      local tuples
      do
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #available_words do
          local word = available_words[_index_0]
          local a_count = a.word_counts[word] or 0
          local b_count = b.word_counts[word] or 0
          local p = a_count / (a_count + b_count)
          local diff = math.abs((p - expected) / (p + expected))
          sum = sum + diff
          local _value_0 = {
            p,
            diff
          }
          _accum_0[_len_0] = _value_0
          _len_0 = _len_0 + 1
        end
        tuples = _accum_0
      end
      local tp = 0
      for _index_0 = 1, #tuples do
        local _des_0 = tuples[_index_0]
        local p, diff
        p, diff = _des_0[1], _des_0[2]
        tp = tp + (p * (diff / sum))
      end
      local out = {
        {
          a.name,
          tp
        },
        {
          b.name,
          1 - tp
        }
      }
      table.sort(out, function(a, b)
        return a[2] > b[2]
      end)
      return out
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "WeightedCassifier",
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
  WeightedCassifier = _class_0
  return _class_0
end
