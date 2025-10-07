-- Punycode implementation for internationalized domain names
-- Based on RFC 3492: https://tools.ietf.org/html/rfc3492

-- Punycode parameters
base = 36
tmin = 1
tmax = 26
skew = 38
damp = 700
initial_bias = 72
initial_n = 128
delimiter = 0x2D  -- hyphen-minus

-- Adapt bias after each delta
adapt = (delta, numpoints, firsttime) ->
  delta = if firsttime
    math.floor delta / damp
  else
    math.floor delta / 2

  delta = delta + math.floor delta / numpoints
  k = 0

  while delta > math.floor((base - tmin) * tmax / 2)
    delta = math.floor delta / (base - tmin)
    k = k + base

  k + math.floor ((base - tmin + 1) * delta) / (delta + skew)

-- Encode a single digit (0-35) to character
encode_digit = (d) ->
  if d < 26
    string.char d + 0x61  -- a-z
  else
    string.char d - 26 + 0x30  -- 0-9

-- Calculate threshold for digit
threshold = (k, bias) ->
  if k <= bias + tmin
    tmin
  elseif k >= bias + tmax
    tmax
  else
    k - bias

-- Check if character is basic (ASCII)
is_basic = (cp) ->
  cp < 0x80

-- Get UTF8 codepoints from string
utf8_codepoints = (str) ->
  codepoints = {}
  i = 1
  while i <= #str
    b = string.byte str, i
    cp = nil
    len = 1

    if b < 0x80
      cp = b
      len = 1
    elseif b >= 0xC0 and b < 0xE0
      b2 = string.byte(str, i + 1) or 0
      cp = ((b - 0xC0) * 0x40) + (b2 - 0x80)
      len = 2
    elseif b >= 0xE0 and b < 0xF0
      b2 = string.byte(str, i + 1) or 0
      b3 = string.byte(str, i + 2) or 0
      cp = ((b - 0xE0) * 0x1000) + ((b2 - 0x80) * 0x40) + (b3 - 0x80)
      len = 3
    elseif b >= 0xF0 and b < 0xF8
      b2 = string.byte(str, i + 1) or 0
      b3 = string.byte(str, i + 2) or 0
      b4 = string.byte(str, i + 3) or 0
      cp = ((b - 0xF0) * 0x40000) + ((b2 - 0x80) * 0x1000) + ((b3 - 0x80) * 0x40) + (b4 - 0x80)
      len = 4
    else
      -- Invalid UTF8, skip
      cp = b
      len = 1

    table.insert codepoints, cp
    i = i + len

  codepoints

-- Encode a domain label using Punycode
punycode_encode = (label) ->
  return label unless label and label != ""

  -- short circuit
  if label\match "^[%w%-]+$"
    return label

  -- Get codepoints
  codepoints = utf8_codepoints label
  input_length = #codepoints

  -- Check if all characters are basic (ASCII)
  has_nonbasic = false
  for cp in *codepoints
    if not is_basic cp
      has_nonbasic = true
      break

  return label unless has_nonbasic

  -- Extract basic characters
  output = {}
  basic_length = 0

  for cp in *codepoints
    if is_basic cp
      table.insert output, string.char(cp)
      basic_length = basic_length + 1

  -- Add delimiter if we had basic characters
  handled = basic_length
  if basic_length > 0
    table.insert output, string.char(delimiter)

  -- Encode non-basic characters
  n = initial_n
  bias = initial_bias
  delta = 0

  while handled < input_length
    -- Find next unhandled codepoint
    m = 0x10FFFF + 1
    for cp in *codepoints
      if cp >= n and cp < m
        m = cp

    -- Increase delta
    delta = delta + (m - n) * (handled + 1)
    n = m

    -- Encode all codepoints up to m
    for cp in *codepoints
      if cp < n
        delta = delta + 1
      elseif cp == n
        -- Encode delta
        q = delta
        k = base

        while true
          t = threshold k, bias
          if q < t
            break

          table.insert output, encode_digit(t + ((q - t) % (base - t)))
          q = math.floor (q - t) / (base - t)
          k = k + base

        table.insert output, encode_digit(q)
        bias = adapt delta, handled + 1, handled == basic_length
        delta = 0
        handled = handled + 1

    delta = delta + 1
    n = n + 1

  "xn--" .. table.concat output

{
  :punycode_encode
}
