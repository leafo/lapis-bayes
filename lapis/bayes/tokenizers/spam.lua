local unpack_fn = table.unpack or unpack
local punycode = require("lapis.bayes.text.punycode")
local Extractor
Extractor = require("web_sanitize.html").Extractor
local types = require("lapis.validate.types")
local cjk_character
cjk_character = require("lapis.bayes.text.utf8").cjk_character
local extract_text = Extractor({
  escape_html = false
})
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
local handle_invalid_byte
handle_invalid_byte = function(byte)
  return {
    tag = "invalid_byte",
    value = tostring(string.byte(byte))
  }
end
local dithered
do
  local gn
  gn = function(sd, mean, r)
    if sd == nil then
      sd = 1
    end
    if mean == nil then
      mean = 0
    end
    if r == nil then
      r = math.random
    end
    local x1, x2, w, y1, y2
    while true do
      x1 = 2 * r() - 1
      x2 = 2 * r() - 1
      w = x1 ^ 2 + x2 ^ 2
      if w < 1 then
        break
      end
    end
    w = math.sqrt(-2 * math.log(w) / 2)
    y1 = x1 * w
    y2 = x2 * w
    return y1 * sd + mean
  end
  local dither_score
  dither_score = function(rank, e)
    return math.log(rank) + gn(math.log(e))
  end
  dithered = function(items, e)
    if e == nil then
      e = 1.5
    end
    local rows
    do
      local _accum_0 = { }
      local _len_0 = 1
      for i, item in ipairs(items) do
        _accum_0[_len_0] = {
          dither_score(i, e),
          item
        }
        _len_0 = _len_0 + 1
      end
      rows = _accum_0
    end
    table.sort(rows, function(a, b)
      return a[1] < b[1]
    end)
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #rows do
      local row = rows[_index_0]
      _accum_0[_len_0] = row[2]
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end
end
local SpamTokenizer
do
  local _class_0
  local _parent_0 = require("lapis.bayes.tokenizers.base")
  local _base_0 = {
    tagged_token_to_string = function(self, token)
      return tostring(token.tag) .. ":" .. tostring(token.value)
    end,
    normalize_domain_string = function(self, domain)
      if not (domain and domain ~= "") then
        return 
      end
      domain = tostring(domain)
      domain = domain:gsub("^%s+", ""):gsub("%s+$", "")
      domain = domain:gsub("%.+$", "")
      if domain == "" then
        return 
      end
      local labels = { }
      for label in domain:gmatch("[^%.]+") do
        if label == "" then
          return 
        end
        local encoded = punycode.punycode_encode(label)
        encoded = encoded or label
        table.insert(labels, encoded:lower())
      end
      if not (next(labels)) then
        return 
      end
      return table.concat(labels, ".")
    end,
    build_ignored_domains = function(self)
      local entries = self.opts.ignore_domains
      if not (entries and #entries > 0) then
        return false
      end
      local exact = { }
      local suffix = { }
      for _index_0 = 1, #entries do
        local _continue_0 = false
        repeat
          local domain = entries[_index_0]
          if not (type(domain) == "string") then
            _continue_0 = true
            break
          end
          domain = domain:gsub("^%s+", ""):gsub("%s+$", "")
          if domain == "" then
            _continue_0 = true
            break
          end
          local is_suffix = domain:sub(1, 1) == "."
          if is_suffix then
            domain = domain:sub(2)
          end
          if domain == "" then
            _continue_0 = true
            break
          end
          local normalized = self:normalize_domain_string(domain)
          if not (normalized) then
            _continue_0 = true
            break
          end
          if is_suffix then
            suffix[normalized] = true
          else
            exact[normalized] = true
          end
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      if not (next(exact) or next(suffix)) then
        return false
      end
      return {
        exact = exact,
        suffix = suffix
      }
    end,
    should_ignore_domain = function(self, domain)
      if not (self.opts.ignore_domains) then
        return false
      end
      if self.ignored_domains == nil then
        self.ignored_domains = self:build_ignored_domains()
      end
      if not (self.ignored_domains) then
        return false
      end
      local normalized = self:normalize_domain_string(domain)
      if not (normalized) then
        return false
      end
      if self.ignored_domains.exact[normalized] then
        return true
      end
      for suffix in pairs(self.ignored_domains.suffix) do
        if normalized == suffix then
          return true
        end
        if #normalized > #suffix then
          if normalized:sub(-(#suffix + 1)) == "." .. tostring(suffix) then
            return true
          end
        end
      end
      return false
    end,
    build_grammar = function(self)
      local P, S, R, C, Cg, Ct
      do
        local _obj_0 = require("lpeg")
        P, S, R, C, Cg, Ct = _obj_0.P, _obj_0.S, _obj_0.R, _obj_0.C, _obj_0.Cg, _obj_0.Ct
      end
      local utf8 = require("lapis.util.utf8")
      local min_len = self.opts.min_word_length or 2
      local max_len = self.opts.max_word_length or 32
      local ignore_words = self.opts.ignore_words
      local truncate = types.truncated_text(max_len)
      local stem
      if self.opts.stem_words then
        stem = require("lapis.bayes.text.stem").stem_word
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
          word = truncate:transform(word)
        end
        if ignore_words and ignore_words[word] then
          return 
        end
        return word
      end
      local handle_domain_token
      handle_domain_token = function(domain)
        local labels
        do
          local _accum_0 = { }
          local _len_0 = 1
          for label in domain:gmatch("[^%.]+") do
            local encoded = punycode.punycode_encode(label)
            local _value_0
            if #encoded > max_len then
              _value_0 = truncate:transform(encoded)
            else
              _value_0 = encoded
            end
            _accum_0[_len_0] = _value_0
            _len_0 = _len_0 + 1
          end
          labels = _accum_0
        end
        local tokens = {
          {
            tag = "domain",
            value = truncate:transform(table.concat(labels, "."):lower())
          }
        }
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
              value = truncate:transform("." .. tostring(suffix:lower()))
            })
          end
        end
        return unpack_fn(tokens)
      end
      local extract_url_words
      extract_url_words = function(...)
        local out = { }
        local _list_0 = {
          ...
        }
        for _index_0 = 1, #_list_0 do
          local _continue_0 = false
          repeat
            local part = _list_0[_index_0]
            if not (part and #part > 0) then
              _continue_0 = true
              break
            end
            part = part:gsub("^[:/?#]+", "")
            if part == "" then
              _continue_0 = true
              break
            end
            part = part:gsub("_", " ")
            part = part:gsub("[^%w']+", " ")
            for raw in part:gmatch("%S+") do
              local normalized = normalize_word(raw)
              if normalized then
                table.insert(out, normalized)
              end
            end
            _continue_0 = true
          until true
          if not _continue_0 then
            break
          end
        end
        return out
      end
      local handle_url
      handle_url = function(t)
        if self:should_ignore_domain(t.domain) then
          return 
        end
        local tokens = { }
        if t.userinfo and t.userinfo ~= "" then
          table.insert(tokens, t.userinfo:lower())
        end
        local _list_0 = extract_url_words(t.path, t.query, t.fragment)
        for _index_0 = 1, #_list_0 do
          local word = _list_0[_index_0]
          table.insert(tokens, word)
        end
        local _list_1 = {
          handle_domain_token(t.domain)
        }
        for _index_0 = 1, #_list_1 do
          local token = _list_1[_index_0]
          table.insert(tokens, token)
        end
        return unpack_fn(tokens)
      end
      local handle_email
      handle_email = function(email)
        email = email:lower()
        local user, domain = email:match("^([^@]+)@(.+)$")
        local tokens = {
          {
            tag = "email",
            value = truncate:transform(email)
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
        local normalized = normalize_number(value)
        if not (normalized) then
          return 
        end
        if #normalized > max_len then
          return truncate:transform(normalized)
        else
          return normalized
        end
      end
      local handle_currency
      handle_currency = function(value)
        local symbol, rest = value:match("^([%$£€¥]+)%s*(.+)$")
        symbol = symbol or value:sub(1, 1)
        rest = rest or ""
        local normalized_number = normalize_number(rest)
        if normalized_number and #normalized_number > max_len then
          normalized_number = truncate:transform(normalized_number)
        end
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
        if #normalized > max_len - 1 then
          normalized = truncate:transform(normalized)
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
      local whitespace = utf8.whitespace
      local alpha = R("az", "AZ")
      local digit = R("09")
      local alphanum = alpha + digit
      local punct_chars = S("!?$#%")
      local other_punct = S("()[]{},.;:\"<>/@#")
      local word_char = utf8.printable_character - whitespace - punct_chars - other_punct
      local word_pattern = (word_char + P("'")) ^ 1
      local cjk_word
      if self.opts.split_cjk then
        word_char = word_char - cjk_character
        cjk_word = C(cjk_character) / handle_word
      end
      local caps_char = R("AZ")
      local caps_pattern = caps_char ^ 2 * (caps_char + digit) ^ 0
      local sign = S("+-") ^ -1
      local number_body = sign * digit ^ 1 * (P(",") * digit ^ 3) ^ 0 * (P(".") * digit ^ 1) ^ -1
      local percent_pattern = number_body * P("%")
      local currency_pattern = S("$£€¥") * whitespace ^ 0 * number_body
      local punct_pattern = punct_chars ^ 3 * punct_chars ^ 0
      local domain_char = utf8.printable_character - whitespace - S("./:@?#[](){}<>\"',;&")
      local domain_label = domain_char ^ 1
      local domain_pattern = domain_label * (P(".") * domain_label) ^ 1
      local not_path = S(" \t\r\n\"'<>()[\\]{}?#")
      local port_part = (P(":") * digit ^ 1) ^ -1
      local path_part = (P("/") * (1 - not_path) ^ 0) ^ 0
      local query_part = (P("?") * (1 - not_path) ^ 0) ^ -1
      local fragment_part = (P("#") * (1 - not_path) ^ 0) ^ -1
      local www_prefix = case_insensitive("www.")
      local scheme = (alpha + digit) ^ 1
      local userinfo_char = utf8.printable_character - whitespace - S("@/?#[](){}<>\"',;&")
      local url_rest = Cg(domain_pattern, "domain") * port_part * Cg(path_part, "path") * Cg(query_part, "query") * Cg(fragment_part, "fragment")
      local url_with_scheme = Ct(scheme * P("://") * (Cg(userinfo_char ^ 1, "userinfo") * P("@")) ^ -1 * www_prefix ^ -1 * url_rest)
      local url_without_scheme = Ct(www_prefix * url_rest)
      local email_pattern = C((alphanum + S(".%+_'-")) ^ 1 * P("@") * domain_pattern)
      local number_capture = C(number_body) * -(alpha)
      local token_patterns = {
        url_with_scheme / handle_url,
        url_without_scheme / handle_url,
        email_pattern / handle_email,
        C(currency_pattern) / handle_currency,
        C(percent_pattern) / handle_percent,
        number_capture / handle_number,
        C(caps_pattern) / handle_caps_word,
        C(word_pattern) / handle_word,
        C(punct_pattern) / handle_punct
      }
      if cjk_word then
        table.insert(token_patterns, 8, cjk_word)
      end
      local tokens = token_patterns[1]
      for i = 2, #token_patterns do
        tokens = tokens + token_patterns[i]
      end
      local printable = utf8.printable_character
      return Ct((tokens + printable + (C(P(1)) / handle_invalid_byte)) ^ 0)
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
      local out
      do
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #tokens do
          local _continue_0 = false
          repeat
            local token = tokens[_index_0]
            if not (type(token) == "table") then
              _continue_0 = true
              break
            end
            local _value_0
            local _exp_0 = token.tag
            if "domain" == _exp_0 or "email" == _exp_0 or "email_user" == _exp_0 then
              _value_0 = token
            else
              _continue_0 = true
              break
            end
            _accum_0[_len_0] = _value_0
            _len_0 = _len_0 + 1
            _continue_0 = true
          until true
          if not _continue_0 then
            break
          end
        end
        out = _accum_0
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
    generate_bigrams = function(self, tokens)
      if not (tokens) then
        return { }
      end
      local count = #tokens
      if count < 2 then
        return { }
      end
      local ignore_tokens = self.opts.ignore_tokens
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
      if limit == nil then
        limit = self.opts.sample_at_most
      end
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
      local tokens_to_sample
      if self.opts.dither == false then
        tokens_to_sample = tokens
      else
        tokens_to_sample = dithered(tokens)
      end
      local _accum_0 = { }
      local _len_0 = 1
      for idx = 1, limit do
        _accum_0[_len_0] = tokens_to_sample[idx]
        _len_0 = _len_0 + 1
      end
      return _accum_0
    end,
    lift_tokens = function(self, tokens, pattern)
      local lifted = { }
      local rest
      do
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #tokens do
          local _continue_0 = false
          repeat
            local t = tokens[_index_0]
            if t:match(pattern) then
              table.insert(lifted, t)
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
        rest = _accum_0
      end
      for _index_0 = 1, #rest do
        local r = rest[_index_0]
        table.insert(lifted, r)
      end
      return lifted
    end,
    tokenize_text = function(self, text)
      if not (text) then
        return { }
      end
      text = tostring(text)
      if self.opts.filter_text then
        text = self.opts.filter_text(text)
      end
      if not (self.opts.unaccent == false) then
        text = require("lapis.bayes.text.unaccent").unaccent_string(text) or text
      end
      local raw_domain_tokens = self:collect_url_tokens(text)
      text = extract_text(text)
      self.grammar = self.grammar or self:build_grammar()
      local tokens = self.grammar:match(text or { })
      local dedupe = true
      if self.opts.dedupe ~= nil then
        dedupe = self.opts.dedupe
      end
      local ignore_tokens = self.opts.ignore_tokens
      local sample_limit = self.opts.sample_at_most
      local generate_bigrams = self.opts.bigram_tokens
      local merged_tokens = { }
      local seen_tokens = { }
      local insert_token
      insert_token = function(t)
        if ignore_tokens and ignore_tokens[t] then
          return 
        end
        if dedupe and seen_tokens[t] then
          return 
        end
        seen_tokens[t] = true
        return table.insert(merged_tokens, t)
      end
      local prev_token = nil
      for idx = 1, #tokens do
        local token = tokens[idx]
        local _exp_0 = type(token)
        if "table" == _exp_0 then
          local _exp_1 = token.tag
          if "caps" == _exp_1 or "invalid_byte" == _exp_1 or "currency" == _exp_1 then
            local _ = nil
          else
            prev_token = nil
          end
          insert_token(self:tagged_token_to_string(token))
        elseif "string" == _exp_0 then
          insert_token(token)
          if prev_token and generate_bigrams then
            insert_token(tostring(prev_token) .. " " .. tostring(token))
          end
          prev_token = token
        end
      end
      if raw_domain_tokens then
        local original_tokens = merged_tokens
        merged_tokens = { }
        for _index_0 = 1, #raw_domain_tokens do
          local token = raw_domain_tokens[_index_0]
          insert_token(self:tagged_token_to_string(token))
        end
        for _index_0 = 1, #original_tokens do
          local t = original_tokens[_index_0]
          table.insert(merged_tokens, t)
        end
      end
      if self.opts.domain_tokens_first then
        merged_tokens = self:lift_tokens(merged_tokens, "^domain:")
      end
      if sample_limit then
        merged_tokens = self:sample_tokens(merged_tokens)
      end
      if self.opts.filter_tokens then
        merged_tokens = self.opts.filter_tokens(merged_tokens, self.opts)
      end
      return merged_tokens
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
