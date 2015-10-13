local UrlDomainsTokenizer
do
  local _base_0 = {
    filter_urls = function(self, urls)
      return urls
    end,
    build_grammer = function(self)
      local P, S, R, C
      do
        local _obj_0 = require("lpeg")
        P, S, R, C = _obj_0.P, _obj_0.S, _obj_0.R, _obj_0.C
      end
      local case_insensitive
      case_insensitive = function(text)
        local out = nil
        for char in text:gmatch(".") do
          local p = S(tostring(char:lower()) .. tostring(char:upper()))
          if out then
            out = out * p
          else
            out = p
          end
        end
        return out
      end
      local unescape_char = P("&gt;") / ">" + P("&lt;") / "<" + P("&amp;") / "&" + P("&nbsp;") / " " + P("&#x27;") / "'" + P("&#x2F;") / "/" + P("&quot;") / '"'
      local unescape_text = Cs((unescape_char + 1) ^ 1)
      local some_space = S(" \t\n")
      local space = some_space ^ 0
      local alphanum = R("az", "AZ", "09")
      local scheme = case_insensitive("http") * case_insensitive("s") ^ -1 * P("://")
      local raw_url = C(scheme * (P(1) - S(" \t\n")) ^ 1)
      local word = (alphanum + S("._-")) ^ 1
      local attr_value = C(word) + P('"') * C((1 - P('"')) ^ 0) * P('"') + P("'") * C((1 - P("'")) ^ 0) * P("'")
      local href = case_insensitive("href") * space * P("=") * space * attr_value / function(v)
        return unescape_char
      end
      local simple = C(case_insensitive("www") * (P(".") * (1 - (S("./") + some_space)) ^ 1) ^ 1)
      return Ct((raw_url + href + simple + 1) ^ 0)
    end,
    tokenize_text = function(self, text)
      self.grammar = self.grammar or self:build_grammer()
      local matches = self.grammar:match(text)
      if not (matches) then
        return 
      end
      return self:filter_urls(matches)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, opts)
      self.opts = opts
    end,
    __base = _base_0,
    __name = "UrlDomainsTokenizer"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  UrlDomainsTokenizer = _class_0
  return _class_0
end
