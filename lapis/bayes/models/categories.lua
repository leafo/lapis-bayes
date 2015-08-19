local db = require("lapis.db")
local Model
Model = require("lapis.bayes.model").Model
local Categories
do
  local _parent_0 = Model
  local _base_0 = {
    increment = function(self, amount)
      amount = assert(tonumber(amount), "expecting number")
      return self:update({
        total_count = db.raw("total_count + " .. tostring(amount))
      })
    end,
    increment_text = function(self, text)
      local tokenize_text
      tokenize_text = require("lapis.bayes").tokenize_text
      local words_by_counts = { }
      local total_words = 0
      local tokens = tokenize_text(text)
      if #tokens == 0 then
        return 
      end
      for _index_0 = 1, #tokens do
        local word = tokens[_index_0]
        words_by_counts[word] = words_by_counts[word] or 0
        words_by_counts[word] = words_by_counts[word] + 1
        total_words = total_words + 1
      end
      self:increment_words(words_by_counts)
      return total_words
    end,
    increment_word = function(self, word, count)
      local WordClassifications
      WordClassifications = require("lapis.bayes.models").WordClassifications
      local w = WordClassifications:find_or_create({
        category_id = self.id,
        word = word
      })
      w:increment(count)
      return self:increment(count)
    end,
    increment_words = function(self, counts)
      local words
      do
        local _accum_0 = { }
        local _len_0 = 1
        for word, count in pairs(counts) do
          _accum_0[_len_0] = {
            word = word,
            count = count
          }
          _len_0 = _len_0 + 1
        end
        words = _accum_0
      end
      local WordClassifications
      WordClassifications = require("lapis.bayes.models").WordClassifications
      WordClassifications:include_in(words, "word", {
        flip = true,
        local_key = "word",
        where = {
          category_id = self.id
        }
      })
      local total_count = 0
      for _index_0 = 1, #words do
        local word = words[_index_0]
        word.word_classification = word.word_classification or WordClassifications:create({
          word = word.word,
          category_id = self.id
        })
        word.word_classification:increment(word.count)
        total_count = total_count + word.count
      end
      self:increment(total_count)
      return words
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Categories",
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
  local self = _class_0
  self.timestamp = true
  self.find_or_create = function(self, name)
    return self:find({
      name = name
    }) or self:create({
      name = name
    })
  end
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Categories = _class_0
  return _class_0
end
