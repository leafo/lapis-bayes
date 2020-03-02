local db = require("lapis.db")
local Model, encode_tuples
do
  local _obj_0 = require("lapis.bayes.model")
  Model, encode_tuples = _obj_0.Model, _obj_0.encode_tuples
end
local Categories
do
  local _class_0
  local _parent_0 = Model
  local _base_0 = {
    delete = function(self)
      if _class_0.__parent.__base.delete(self) then
        local WordClassifications
        WordClassifications = require("lapis.bayes.models").WordClassifications
        return db.delete(WordClassifications:table_name(), {
          category_id = self.id
        })
      end
    end,
    increment = function(self, amount)
      amount = assert(tonumber(amount), "expecting number")
      return self:update({
        total_count = db.raw("total_count + " .. tostring(amount))
      })
    end,
    increment_text = function(self, text, opts)
      if opts == nil then
        opts = { }
      end
      local words_by_counts = { }
      local total_words = 0
      local tokens
      local _exp_0 = type(text)
      if "string" == _exp_0 then
        local tokenize_text
        tokenize_text = require("lapis.bayes.tokenizer").tokenize_text
        tokens = tokenize_text(text, opts)
      elseif "table" == _exp_0 then
        tokens = text
      else
        tokens = error("unknown type for text: " .. tostring(type(text)))
      end
      if #tokens == 0 then
        return 0
      end
      for _index_0 = 1, #tokens do
        local word = tokens[_index_0]
        local _update_0 = word
        words_by_counts[_update_0] = words_by_counts[_update_0] or 0
        local _update_1 = word
        words_by_counts[_update_1] = words_by_counts[_update_1] + 1
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
      w:_increment(count)
      return self:increment(count)
    end,
    increment_words = function(self, counts)
      local WordClassifications
      WordClassifications = require("lapis.bayes.models").WordClassifications
      local total_count = 0
      local tuples
      do
        local _accum_0 = { }
        local _len_0 = 1
        for word, count in pairs(counts) do
          total_count = total_count + count
          local _value_0 = {
            self.id,
            word,
            count
          }
          _accum_0[_len_0] = _value_0
          _len_0 = _len_0 + 1
        end
        tuples = _accum_0
      end
      if not (next(tuples)) then
        return total_count
      end
      local tbl = db.escape_identifier(WordClassifications:table_name())
      local res = db.query("\n    insert into " .. tostring(tbl) .. " (category_id, word, count) " .. tostring(encode_tuples(tuples)) .. "\n    on conflict (category_id, word) do update set count = " .. tostring(tbl) .. ".count + EXCLUDED.count\n    ")
      self:increment(total_count)
      return total_count
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Categories",
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
  self.timestamp = true
  self.relations = {
    {
      "word_classifications",
      has_many = "WordClassifications"
    }
  }
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
