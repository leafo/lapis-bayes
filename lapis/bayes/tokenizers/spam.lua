local unpack_fn = table.unpack or unpack
local unaccent = require("lapis.bayes.text.unaccent")
local extract_text
extract_text = require("web_sanitize").extract_text
local normalize_number
normalize_number = function(value)
  if not (value and value ~= "") then
    return 
  end
  local normalized = value:gsub("[,%s]", "")
  local digits_only = normalized:gsub("[^%d]", "")
  if digits_only == "" then
    return 
  end
  return normalized
end
local handle_punct
handle_punct = function(chars)
  local char = chars:sub(1, 1)
  return {
    tag = "punct",
    value = char .. tostring(#chars)
  }
end
local handle_domain_token
handle_domain_token = function(domain)
  domain = domain:lower()
  local tokens = {
    {
      tag = "domain",
      value = domain
    }
  }
  local labels = { }
  for label in domain:gmatch("[^%.]+") do
    table.insert(labels, label)
  end
  if #labels >= 2 then
    for i = 2, #labels do
      local suffix = table.concat((function()
        local _accum_0 = { }
        local _len_0 = 1
        for j = i, #labels do
          _accum_0[_len_0] = labels[j]
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)(), ".")
      table.insert(tokens, {
        tag = "domain",
        value = "." .. tostring(suffix)
      })
    end
  end
  return unpack_fn(tokens)
end
local SpamTokenizer
do
  local _class_0
  local _parent_0 = require("lapis.bayes.tokenizers.base")
  local _base_0 = {
    tagged_token_to_string = function(self, token)
      return tostring(token.tag) .. ":" .. tostring(token.value)
    end,
    build_grammar = function(self)
      local P, S, R, C, Ct
      do
        local _obj_0 = require("lpeg")
        P, S, R, C, Ct = _obj_0.P, _obj_0.S, _obj_0.R, _obj_0.C, _obj_0.Ct
      end
      local opts = self.opts or { }
      local min_len = opts.min_word_length or 2
      local max_len = opts.max_word_length or 32
      local ignore_words = opts.ignore_words
      local stem
      if opts.stem_words then
        stem = require("lapis.bayes.text.stem").stem_word
      else
        stem = nil
      end
      local case_insensitive
      case_insensitive = function(text)
        local out = nil
        for char in text:gmatch(".") do
          local lower = char:lower()
          local upper = char:upper()
          local pattern
          if lower == upper then
            pattern = P(char)
          else
            pattern = S(tostring(lower) .. tostring(upper))
          end
          if out then
            out = out * pattern
          else
            out = pattern
          end
        end
        return out or P(false)
      end
      local normalize_word
      normalize_word = function(word)
        if not (word and word ~= "") then
          return 
        end
        word = word:lower()
        word = word:gsub("'+", "")
        if #word < min_len then
          return 
        end
        if #word > max_len then
          return 
        end
        if not (word:match("%a")) then
          return 
        end
        if ignore_words and ignore_words[word] then
          return 
        end
        return word
      end
      local handle_email
      handle_email = function(email)
        email = email:lower()
        local user, domain = email:match("^([^@]+)@(.+)$")
        local tokens = {
          {
            tag = "email",
            value = email
          }
        }
        if user then
          local user_token = normalize_word(user)
          if user_token then
            table.insert(tokens, {
              tag = "email_user",
              value = user_token
            })
          end
        end
        if domain then
          local _list_0 = {
            handle_domain_token(domain)
          }
          for _index_0 = 1, #_list_0 do
            local token = _list_0[_index_0]
            table.insert(tokens, token)
          end
        end
        return unpack_fn(tokens)
      end
      local handle_number
      handle_number = function(value)
        return normalize_number(value)
      end
      local handle_currency
      handle_currency = function(value)
        local symbol, rest = value:match("^([%$£€¥]+)%s*(.+)$")
        symbol = symbol or value:sub(1, 1)
        rest = rest or ""
        local normalized_number = normalize_number(rest)
        if symbol and symbol ~= "" then
          if normalized_number then
            return {
              tag = "currency",
              value = symbol
            }, normalized_number
          else
            return {
              tag = "currency",
              value = symbol
            }
          end
        end
      end
      local handle_percent
      handle_percent = function(value)
        local number_part = value:sub(1, #value - 1)
        local normalized = normalize_number(number_part)
        if not (normalized) then
          return 
        end
        return tostring(normalized) .. "%"
      end
      local handle_caps_word
      handle_caps_word = function(word)
        if not (word:match("%u")) then
          return 
        end
        local normalized = normalize_word(word)
        if not (normalized) then
          return 
        end
        local stemmed
        if stem then
          stemmed = stem(normalized) or normalized
        else
          stemmed = normalized
        end
        return stemmed, {
          tag = "caps",
          value = stemmed
        }
      end
      local handle_word
      handle_word = function(word)
        local normalized = normalize_word(word)
        if not (normalized) then
          return 
        end
        if stem then
          return stem(normalized) or normalized
        else
          return normalized
        end
      end
      local whitespace = S(" \t\r\n")
      local alpha = R("az", "AZ")
      local digit = R("09")
      local alphanum = alpha + digit
      local word_pattern = (alphanum + P("'")) ^ 1
      local caps_char = R("AZ")
      local caps_pattern = caps_char ^ 2 * (caps_char + digit) ^ 0
      local sign = S("+-") ^ -1
      local number_body = sign * digit ^ 1 * (P(",") * digit ^ 3) ^ 0 * (P(".") * digit ^ 1) ^ -1
      local percent_pattern = number_body * P("%")
      local currency_pattern = S("$£€¥") * whitespace ^ 0 * number_body
      local punct_chars = S("!?$#%")
      local punct_pattern = punct_chars ^ 3 * punct_chars ^ 0
      local domain_label = (alphanum + P("-")) ^ 1
      local domain_pattern = domain_label * (P(".") * domain_label) ^ 1
      local not_path = S([[ \t\r\n\"'<>()[\]{}?#]])
      local port_part = (P(":") * digit ^ 1) ^ -1
      local path_part = (P("/") * (1 - not_path) ^ 0) ^ 0
      local query_part = (P("?") * (1 - not_path) ^ 0) ^ -1
      local fragment_part = (P("#") * (1 - not_path) ^ 0) ^ -1
      local www_prefix = case_insensitive("www.")
      local scheme = (alpha + digit) ^ 1
      local url_with_scheme = scheme * P("://") * www_prefix ^ -1 * C(domain_pattern) * port_part * path_part * query_part * fragment_part
      local url_without_scheme = www_prefix * C(domain_pattern) * port_part * path_part * query_part * fragment_part
      local email_pattern = C((alphanum + S(".%+_'-")) ^ 1 * P("@") * domain_pattern)
      local number_capture = C(number_body) * -(alpha)
      local token_patterns = {
        url_with_scheme / handle_domain_token,
        url_without_scheme / handle_domain_token,
        email_pattern / handle_email,
        C(currency_pattern) / handle_currency,
        C(percent_pattern) / handle_percent,
        number_capture / handle_number,
        C(caps_pattern) / handle_caps_word,
        C(word_pattern) / handle_word,
        C(punct_pattern) / handle_punct
      }
      local tokens = token_patterns[1]
      for i = 2, #token_patterns do
        tokens = tokens + token_patterns[i]
      end
      return Ct((tokens + P(1)) ^ 0)
    end,
    collect_url_tokens = function(self, text)
      if not (text and text ~= "") then
        return { }
      end
      self.grammar = self.grammar or self:build_grammar()
      local tokens = self.grammar:match(text)
      if not (tokens) then
        return { }
      end
      local out = { }
      for _index_0 = 1, #tokens do
        local _continue_0 = false
        repeat
          local token = tokens[_index_0]
          if not (type(token) == "table") then
            _continue_0 = true
            break
          end
          if token.tag == "domain" or token.tag == "email" or token.tag == "email_user" then
            table.insert(out, self:tagged_token_to_string(token))
          end
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      return out
    end,
    dedupe_tokens = function(self, tokens)
      if not (tokens) then
        return { }
      end
      local seen = { }
      local deduped = { }
      for _index_0 = 1, #tokens do
        local token = tokens[_index_0]
        local key
        if type(token) == "table" then
          key = self:tagged_token_to_string(token)
        else
          key = token
        end
        if not (seen[key]) then
          seen[key] = true
          table.insert(deduped, token)
        end
      end
      return deduped
    end,
    generate_bigrams = function(self, tokens, ignore_tokens)
      if not (tokens) then
        return { }
      end
      local count = #tokens
      if count < 2 then
        return { }
      end
      local bigrams = { }
      for i = 1, count - 1 do
        local _continue_0 = false
        repeat
          local first = tokens[i]
          local second = tokens[i + 1]
          if not (first and second) then
            _continue_0 = true
            break
          end
          local bigram = first .. " " .. second
          if ignore_tokens and ignore_tokens[bigram] then
            _continue_0 = true
            break
          end
          table.insert(bigrams, bigram)
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      return bigrams
    end,
    sample_tokens = function(self, tokens, limit)
      if not (tokens) then
        return { }
      end
      if not (limit) then
        return tokens
      end
      limit = math.floor(limit)
      if limit <= 0 then
        return { }
      end
      local count = #tokens
      if count <= limit then
        return tokens
      end
      local sampled = { }
      for i = 1, limit do
        sampled[#sampled + 1] = tokens[i]
      end
      return sampled
    end,
    tokenize_text = function(self, text)
      if not (text) then
        return { }
      end
      text = tostring(text)
      if self.opts and self.opts.filter_text then
        text = self.opts.filter_text(text)
      end
      local raw_text = text
      local raw_url_tokens = self:collect_url_tokens(raw_text)
      text = extract_text(text)
      if not (self.opts and self.opts.unaccent == false) then
        text = unaccent.unaccent_string(text)
      end
      self.grammar = self.grammar or self:build_grammar()
      local tokens = self.grammar:match(text or { })
      local existing = { }
      for _index_0 = 1, #tokens do
        local token = tokens[_index_0]
        local key
        if type(token) == "table" then
          key = self:tagged_token_to_string(token)
        else
          key = token
        end
        existing[key] = true
      end
      if raw_url_tokens and #raw_url_tokens > 0 then
        for _index_0 = 1, #raw_url_tokens do
          local _continue_0 = false
          repeat
            local token = raw_url_tokens[_index_0]
            if existing[token] then
              _continue_0 = true
              break
            end
            table.insert(tokens, token)
            existing[token] = true
            _continue_0 = true
          until true
          if not _continue_0 then
            break
          end
        end
      end
      local dedupe = true
      if self.opts and self.opts.dedupe ~= nil then
        dedupe = self.opts.dedupe
      end
      local ignore_tokens = self.opts and self.opts.ignore_tokens
      local sample_limit = self.opts and self.opts.sample_at_most
      local word_tokens = { }
      local tagged_tokens = { }
      for _index_0 = 1, #tokens do
        local _continue_0 = false
        repeat
          local token = tokens[_index_0]
          if not (token) then
            _continue_0 = true
            break
          end
          if token == "" then
            _continue_0 = true
            break
          end
          if ignore_tokens and ignore_tokens[token] then
            _continue_0 = true
            break
          end
          if type(token) == "table" then
            table.insert(tagged_tokens, token)
          else
            table.insert(word_tokens, token)
          end
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      local bigram_tokens = { }
      if self.opts and self.opts.bigram_tokens then
        bigram_tokens = self:generate_bigrams(word_tokens, ignore_tokens)
      end
      if dedupe then
        word_tokens = self:dedupe_tokens(word_tokens)
      end
      if sample_limit then
        word_tokens = self:sample_tokens(word_tokens, sample_limit)
      end
      if dedupe then
        bigram_tokens = self:dedupe_tokens(bigram_tokens)
      end
      if sample_limit then
        bigram_tokens = self:sample_tokens(bigram_tokens, sample_limit)
      end
      if dedupe then
        tagged_tokens = self:dedupe_tokens(tagged_tokens)
      end
      tokens = { }
      for _index_0 = 1, #word_tokens do
        local token = word_tokens[_index_0]
        table.insert(tokens, token)
      end
      for _index_0 = 1, #bigram_tokens do
        local token = bigram_tokens[_index_0]
        table.insert(tokens, token)
      end
      for _index_0 = 1, #tagged_tokens do
        local token = tagged_tokens[_index_0]
        table.insert(tokens, self:tagged_token_to_string(token))
      end
      if self.opts and self.opts.filter_tokens then
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
    __name = "SpamTokenizer",
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
  SpamTokenizer = _class_0
end
return SpamTokenizer
