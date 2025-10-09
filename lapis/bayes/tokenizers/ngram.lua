local NgramTokenizer
do
  local _class_0
  local _parent_0 = require("lapis.bayes.tokenizers.base")
  local _base_0 = {
    build_grammar = function(self)
      local C, Ct
      do
        local _obj_0 = require("lpeg")
        C, Ct = _obj_0.C, _obj_0.Ct
      end
      local utf8 = require("lapis.util.utf8")
      local whitespace = utf8.whitespace
      local printable = utf8.printable_character
      local word_chars = printable - whitespace
      local word = C(word_chars ^ 1)
      return Ct((word + whitespace ^ 1) ^ 0)
    end,
    normalize_word = function(self, word)
      if not (word and word ~= "") then
        return 
      end
      local normalized = tostring(word):lower()
      normalized = normalized:gsub("[%p]", "")
      normalized = normalized:gsub("%s+", "")
      if not (normalized ~= "") then
        return 
      end
      return normalized
    end,
    ngram_size = function(self)
      local n = tonumber(self.opts.n) or 2
      n = math.floor(n)
      if n < 1 then
        n = 1
      end
      return n
    end,
    word_ngrams = function(self, word, n)
      local C, Ct
      do
        local _obj_0 = require("lpeg")
        C, Ct = _obj_0.C, _obj_0.Ct
      end
      local utf8 = require("lapis.util.utf8")
      local printable = utf8.printable_character
      local char_pattern = Ct((C(printable)) ^ 0)
      local chars = char_pattern:match(word)
      if not (chars) then
        return {
          word
        }
      end
      local len = #chars
      if len == 0 then
        return {
          word
        }
      end
      if len < n then
        return {
          word
        }
      end
      local out = { }
      for i = 1, len - n + 1 do
        local ngram = table.concat(chars, "", i, i + n - 1)
        table.insert(out, ngram)
      end
      return out
    end,
    tokenize_text = function(self, text)
      if not (text and text ~= "") then
        return { }
      end
      do
        local pre_filter = self.opts.filter_text
        if pre_filter then
          text = pre_filter(text)
          if not (text and text ~= "") then
            return { }
          end
        end
      end
      self.grammar = self.grammar or self:build_grammar()
      local words = self.grammar:match(text)
      if not (words) then
        return { }
      end
      local n = self:ngram_size()
      local ignore_numbers = self.opts.ignore_numbers
      if ignore_numbers == nil then
        ignore_numbers = true
      end
      local tokens = { }
      for _index_0 = 1, #words do
        local _continue_0 = false
        repeat
          local raw_word = words[_index_0]
          local cleaned = self:normalize_word(raw_word)
          if not (cleaned) then
            _continue_0 = true
            break
          end
          if ignore_numbers and cleaned:match("^%d+$") then
            _continue_0 = true
            break
          end
          local _list_0 = self:word_ngrams(cleaned, n)
          for _index_1 = 1, #_list_0 do
            local token = _list_0[_index_1]
            table.insert(tokens, token)
          end
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      if self.opts.filter_tokens then
        tokens = self.opts.filter_tokens(tokens, self.opts)
      end
      return tokens
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, opts)
      if opts == nil then
        opts = { }
      end
      self.opts = opts
    end,
    __base = _base_0,
    __name = "NgramTokenizer",
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
  NgramTokenizer = _class_0
  return _class_0
end
