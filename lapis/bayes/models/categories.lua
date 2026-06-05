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
      table.sort(tuples, function(a, b)
        return a[2] < b[2]
      end)
      if not (next(tuples)) then
        return total_count
      end
      local WordClassifications
      WordClassifications = require("lapis.bayes.models").WordClassifications
      local tbl = db.escape_identifier(WordClassifications:table_name())
      db.query("\n    INSERT INTO " .. tostring(tbl) .. " (category_id, word, count) " .. tostring(encode_tuples(tuples)) .. "\n    ON CONFLICT (category_id, word) DO UPDATE SET count = " .. tostring(tbl) .. ".count + EXCLUDED.count\n    ")
      self:increment(total_count)
      return total_count
    end,
    decrement_words = function(self, counts)
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
      local tuples
      do
        local _accum_0 = { }
        local _len_0 = 1
        for word, count in pairs(merged_counts) do
          _accum_0[_len_0] = {
            word,
            count
          }
          _len_0 = _len_0 + 1
        end
        tuples = _accum_0
      end
      table.sort(tuples, function(a, b)
        return a[1] < b[1]
      end)
      if not (next(tuples)) then
        return 0
      end
      local WordClassifications
      WordClassifications = require("lapis.bayes.models").WordClassifications
      local tbl = db.escape_identifier(WordClassifications:table_name())
      local cat_tbl = db.escape_identifier(self.__class:table_name())
      local cat_id = db.escape_literal(self.id)
      local res = db.query("\n    WITH input (word, amount) AS (" .. tostring(encode_tuples(tuples)) .. "),\n    upd AS (\n      UPDATE " .. tostring(tbl) .. " wc\n      SET count = wc.count - input.amount\n      FROM input\n      WHERE wc.category_id = " .. tostring(cat_id) .. " AND wc.word = input.word\n      RETURNING LEAST(wc.count + input.amount, input.amount) AS removed\n    ),\n    cat AS (\n      UPDATE " .. tostring(cat_tbl) .. "\n      SET total_count = total_count - (SELECT COALESCE(sum(removed), 0) FROM upd)\n      WHERE id = " .. tostring(cat_id) .. "\n      RETURNING 1\n    )\n    SELECT COALESCE(sum(removed), 0) AS total FROM upd\n    ")
      local words = table.concat((function()
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #tuples do
          local t = tuples[_index_0]
          _accum_0[_len_0] = db.escape_literal(t[1])
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)(), ", ")
      db.query("\n    DELETE FROM " .. tostring(tbl) .. "\n    WHERE category_id = " .. tostring(cat_id) .. " AND count <= 0 AND word IN (" .. tostring(words) .. ")\n    ")
      local total = res[1] and tonumber(res[1].total) or 0
      self.total_count = self.total_count - total
      return total
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
