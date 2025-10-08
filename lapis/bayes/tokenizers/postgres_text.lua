local db = require("lapis.db")
local PostgresTextTokenizer
do
  local _class_0
  local _parent_0 = require("lapis.bayes.tokenizers.base")
  local _base_0 = {
    filter_tokens = function(self, tokens)
      local opts = self.opts
      local min_len = opts and opts.min_token_length or 2
      local max_len = opts and opts.max_token_length or 12
      local strip_numbers = opts and opts.strip_numbers
      if strip_numbers == nil then
        strip_numbers = true
      end
      return (function()
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #tokens do
          local _continue_0 = false
          repeat
            local t = tokens[_index_0]
            local t_len = #t
            if t_len > max_len then
              _continue_0 = true
              break
            end
            if t_len < min_len then
              _continue_0 = true
              break
            end
            if strip_numbers and t:match("^[%d%.%/%-]+$") then
              _continue_0 = true
              break
            end
            if self.opts and self.opts.ignore_words and self.opts.ignore_words[t] then
              _continue_0 = true
              break
            end
            local _value_0 = t
            _accum_0[_len_0] = _value_0
            _len_0 = _len_0 + 1
            _continue_0 = true
          until true
          if not _continue_0 then
            break
          end
        end
        return _accum_0
      end)()
    end,
    slow_pg_tokenize = function(self, text)
      local regconfig = self.opts.regconfig or "english"
      return db.query([[SELECT unnest(lexemes) AS word FROM ts_debug(?, ?)]], regconfig, text)
    end,
    pg_tokenize = function(self, text)
      local regconfig = self.opts.regconfig or "english"
      return db.query([[SELECT unnest(tsvector_to_array(to_tsvector(?, ?))) AS word]], regconfig, text)
    end,
    tokenize_text = function(self, text)
      do
        local pre_filter = self.opts.filter_text
        if pre_filter then
          text = pre_filter(text)
        end
      end
      if self.opts.strip_tags then
        local extract_text
        extract_text = require("web_sanitize").extract_text
        text = extract_text(text)
      end
      if self.opts.symbols_split_tokens then
        text = text:gsub("[%!%@%#%$%%%^%&%*%(%)%[%]%{%}%|%\\%/%`%~%-%_%<%>%,%.]", " ")
      end
      local res
      if self.opts.legacy_tokenizer then
        res = self:slow_pg_tokenize(text)
      else
        res = self:pg_tokenize(text)
      end
      local tokens = self:filter_tokens((function()
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #res do
          local r = res[_index_0]
          _accum_0[_len_0] = r.word
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)())
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
    __name = "PostgresTextTokenizer",
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
  PostgresTextTokenizer = _class_0
  return _class_0
end
