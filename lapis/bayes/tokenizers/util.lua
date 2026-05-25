local unescape
unescape = require("lapis.util").unescape
local strip_zero_width_string
strip_zero_width_string = require("lapis.bayes.text.utf8").strip_zero_width_string
local sanitize_token
sanitize_token = function(token)
  if not (token) then
    return 
  end
  token = strip_zero_width_string(token)
  if token == "" then
    return 
  end
  return token
end
local sanitize_tokens
sanitize_tokens = function(tokens)
  if not (tokens) then
    return { }
  end
  return (function()
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #tokens do
      local _continue_0 = false
      repeat
        local token = tokens[_index_0]
        token = sanitize_token(token)
        if not (token) then
          _continue_0 = true
          break
        end
        local _value_0 = token
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
end
local normalize_url_text
normalize_url_text = function(text)
  if not (text) then
    return text
  end
  return strip_zero_width_string(unescape(text)) or text
end
return {
  normalize_url_text = normalize_url_text,
  sanitize_token = sanitize_token,
  sanitize_tokens = sanitize_tokens
}
