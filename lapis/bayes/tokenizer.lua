local db = require("lapis.db")
local filter_tokens
filter_tokens = function(tokens, opts)
  local min_len = opts and opts.min_token_length or 2
  local max_len = opts and opts.max_token_length or 12
  local strip_numbers = opts and opts.strip_number_tokens or nil
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
        if strip_numbers and t:match("^[%d%.]+$") then
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
end
local tokenize_text
tokenize_text = function(text, opts)
  if opts and opts.tokenize_text then
    return opts.tokenize_text(text, opts)
  end
  local pre_filter = opts and opts.filter_text
  if pre_filter then
    text = pre_filter(text)
  end
  if opts and opts.strip_tags then
    local extract_text
    extract_text = require("web_sanitize").extract_text
    text = extract_text(text)
  end
  if opts and opts.symbols_split_tokens then
    text = text:gsub("[%!%@%#%$%%%^%&%*%(%)%[%]%{%}%|%\\%/%`%~%-%_%<%>%,%.]", " ")
  end
  local res = db.query([[    select unnest(lexemes) as word
    from ts_debug('english', ?);
  ]], text)
  local tokens
  do
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #res do
      local r = res[_index_0]
      _accum_0[_len_0] = r.word
      _len_0 = _len_0 + 1
    end
    tokens = _accum_0
  end
  local filter = opts and opts.filter_tokens or filter_tokens
  tokens = filter(tokens, opts)
  return tokens
end
return {
  tokenize_text = tokenize_text,
  filter_tokens = filter_tokens
}
