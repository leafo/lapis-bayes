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
      return error("This method has been removed, use increment_words instead")
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
      if not (counts) then
        return nil, "missing counts"
      end
      local merged_counts = { }
      for k, v in pairs(counts) do
        local word, count
        if type(k) == "string" then
          word, count = k, v
        else
          word, count = v, 1
        end
        local _update_0 = word
        merged_counts[_update_0] = merged_counts[_update_0] or 0
        local _update_1 = word
        merged_counts[_update_1] = merged_counts[_update_1] + count
      end
      local total_count = 0
      local tuples
      do
        local _accum_0 = { }
        local _len_0 = 1
        for word, count in pairs(merged_counts) do
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
      local WordClassifications
      WordClassifications = require("lapis.bayes.models").WordClassifications
      local tbl = db.escape_identifier(WordClassifications:table_name())
      local res = db.query("\n    INSERT INTO " .. tostring(tbl) .. " (category_id, word, count) " .. tostring(encode_tuples(tuples)) .. "\n    ON CONFLICT (category_id, word) DO UPDATE SET count = " .. tostring(tbl) .. ".count + EXCLUDED.count\n    ")
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
