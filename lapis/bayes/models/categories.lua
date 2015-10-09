local db = require("lapis.db")
local Model, encode_tuples
do
  local _obj_0 = require("lapis.bayes.model")
  Model, encode_tuples = _obj_0.Model, _obj_0.encode_tuples
end
local Categories
do
  local category_cache
  local _parent_0 = Model
  local _base_0 = {
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
      local tokenize_text
      tokenize_text = require("lapis.bayes.tokenizer").tokenize_text
      if opts.strip_tags then
        local extract_text
        extract_text = require("web_sanitize").extract_text
        text = extract_text(text)
        if text:match("^%s*$") then
          return 0
        end
      end
      local words_by_counts = { }
      local total_words = 0
      local tokens = tokenize_text(text, opts)
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
      local WordClassifications
      WordClassifications = require("lapis.bayes.models").WordClassifications
      local category_words
      do
        local _accum_0 = { }
        local _len_0 = 1
        for word in pairs(counts) do
          _accum_0[_len_0] = {
            self.id,
            word
          }
          _len_0 = _len_0 + 1
        end
        category_words = _accum_0
      end
      category_words = encode_tuples(category_words)
      local tbl = db.escape_identifier(WordClassifications:table_name())
      db.query("\n      insert into " .. tostring(tbl) .. "\n      (category_id, word)\n      (\n        select * from (" .. tostring(category_words) .. ") foo(category_id, word)\n          where not exists(select 1 from " .. tostring(tbl) .. " as bar\n            where bar.word = foo.word and bar.category_id = foo.category_id)\n      )\n    ")
      local total_count = 0
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
        counts = _accum_0
      end
      counts = encode_tuples(counts)
      db.query("\n      update " .. tostring(tbl) .. "\n      set count = " .. tostring(tbl) .. ".count + foo.count\n      from (" .. tostring(counts) .. ") foo(category_id, word, count)\n      where foo.category_id = " .. tostring(tbl) .. ".category_id and foo.word = " .. tostring(tbl) .. ".word\n    ")
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
  category_cache = setmetatable({ }, {
    mode = "v"
  })
  self.find_or_create = function(self, name)
    do
      local cached = category_cache[name]
      if cached then
        return cached
      end
    end
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
