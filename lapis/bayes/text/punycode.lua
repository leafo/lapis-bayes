local base = 36
local tmin = 1
local tmax = 26
local skew = 38
local damp = 700
local initial_bias = 72
local initial_n = 128
local delimiter = 0x2D
local adapt
adapt = function(delta, numpoints, firsttime)
  if firsttime then
    delta = math.floor(delta / damp)
  else
    delta = math.floor(delta / 2)
  end
  delta = delta + math.floor(delta / numpoints)
  local k = 0
  while delta > math.floor((base - tmin) * tmax / 2) do
    delta = math.floor(delta / (base - tmin))
    k = k + base
  end
  return k + math.floor(((base - tmin + 1) * delta) / (delta + skew))
end
local encode_digit
encode_digit = function(d)
  if d < 26 then
    return string.char(d + 0x61)
  else
    return string.char(d - 26 + 0x30)
  end
end
local threshold
threshold = function(k, bias)
  if k <= bias + tmin then
    return tmin
  elseif k >= bias + tmax then
    return tmax
  else
    return k - bias
  end
end
local is_basic
is_basic = function(cp)
  return cp < 0x80
end
local utf8_codepoints
utf8_codepoints = function(str)
  local codepoints = { }
  local i = 1
  while i <= #str do
    local b = string.byte(str, i)
    local cp = nil
    local len = 1
    if b < 0x80 then
      cp = b
      len = 1
    elseif b >= 0xC0 and b < 0xE0 then
      local b2 = string.byte(str, i + 1) or 0
      cp = ((b - 0xC0) * 0x40) + (b2 - 0x80)
      len = 2
    elseif b >= 0xE0 and b < 0xF0 then
      local b2 = string.byte(str, i + 1) or 0
      local b3 = string.byte(str, i + 2) or 0
      cp = ((b - 0xE0) * 0x1000) + ((b2 - 0x80) * 0x40) + (b3 - 0x80)
      len = 3
    elseif b >= 0xF0 and b < 0xF8 then
      local b2 = string.byte(str, i + 1) or 0
      local b3 = string.byte(str, i + 2) or 0
      local b4 = string.byte(str, i + 3) or 0
      cp = ((b - 0xF0) * 0x40000) + ((b2 - 0x80) * 0x1000) + ((b3 - 0x80) * 0x40) + (b4 - 0x80)
      len = 4
    else
      cp = b
      len = 1
    end
    table.insert(codepoints, cp)
    i = i + len
  end
  return codepoints
end
local punycode_encode
punycode_encode = function(label)
  if not (label and label ~= "") then
    return label
  end
  local codepoints = utf8_codepoints(label)
  local input_length = #codepoints
  local has_nonbasic = false
  for _index_0 = 1, #codepoints do
    local cp = codepoints[_index_0]
    if not is_basic(cp) then
      has_nonbasic = true
      break
    end
  end
  if not (has_nonbasic) then
    return label
  end
  local output = { }
  local basic_length = 0
  for _index_0 = 1, #codepoints do
    local cp = codepoints[_index_0]
    if is_basic(cp) then
      table.insert(output, string.char(cp))
      basic_length = basic_length + 1
    end
  end
  local handled = basic_length
  if basic_length > 0 then
    table.insert(output, string.char(delimiter))
  end
  local n = initial_n
  local bias = initial_bias
  local delta = 0
  while handled < input_length do
    local m = 0x10FFFF + 1
    for _index_0 = 1, #codepoints do
      local cp = codepoints[_index_0]
      if cp >= n and cp < m then
        m = cp
      end
    end
    delta = delta + (m - n) * (handled + 1)
    n = m
    for _index_0 = 1, #codepoints do
      local cp = codepoints[_index_0]
      if cp < n then
        delta = delta + 1
      elseif cp == n then
        local q = delta
        local k = base
        while true do
          local t = threshold(k, bias)
          if q < t then
            break
          end
          table.insert(output, encode_digit(t + ((q - t) % (base - t))))
          q = math.floor((q - t) / (base - t))
          k = k + base
        end
        table.insert(output, encode_digit(q))
        bias = adapt(delta, handled + 1, handled == basic_length)
        delta = 0
        handled = handled + 1
      end
    end
    delta = delta + 1
    n = n + 1
  end
  return "xn--" .. table.concat(output)
end
return {
  punycode_encode = punycode_encode
}
