local is_vowel
is_vowel = function(char)
  if not (char) then
    return false
  end
  char = char:lower()
  return char == 'a' or char == 'e' or char == 'i' or char == 'o' or char == 'u' or char == 'y'
end
local is_consonant
is_consonant = function(char)
  if not (char) then
    return false
  end
  return not is_vowel(char)
end
local is_vowel_wxy
is_vowel_wxy = function(char)
  if not (char) then
    return false
  end
  char = char:lower()
  return char == 'a' or char == 'e' or char == 'i' or char == 'o' or char == 'u' or char == 'y' or char == 'w' or char == 'x'
end
local is_valid_li
is_valid_li = function(char)
  if not (char) then
    return false
  end
  char = char:lower()
  return char == 'c' or char == 'd' or char == 'e' or char == 'g' or char == 'h' or char == 'k' or char == 'm' or char == 'n' or char == 'r' or char == 't'
end
local ends_with
ends_with = function(word, suffix)
  if #word < #suffix then
    return false
  end
  return word:sub(-#suffix) == suffix
end
local contains_vowel
contains_vowel = function(word)
  for i = 1, #word do
    if is_vowel(word:sub(i, i)) then
      return true
    end
  end
  return false
end
local replace_suffix
replace_suffix = function(word, suffix, replacement)
  if ends_with(word, suffix) then
    return word:sub(1, #word - #suffix) .. replacement
  else
    return word
  end
end
local get_suffix
get_suffix = function(word, pos)
  if pos > #word then
    return ""
  end
  return word:sub(pos)
end
local find_r1
find_r1 = function(word)
  if word:sub(1, 5) == "gener" then
    return 6
  elseif word:sub(1, 6) == "commun" then
    return 7
  elseif word:sub(1, 5) == "arsen" then
    return 6
  elseif word:sub(1, 4) == "past" then
    return 5
  elseif word:sub(1, 7) == "univers" then
    return 8
  elseif word:sub(1, 5) == "later" then
    return 6
  elseif word:sub(1, 5) == "emerg" then
    return 6
  elseif word:sub(1, 5) == "organ" then
    return 6
  end
  for i = 1, #word - 1 do
    if is_vowel(word:sub(i, i)) and is_consonant(word:sub(i + 1, i + 1)) then
      return i + 2
    end
  end
  return #word + 1
end
local find_r2
find_r2 = function(word)
  local r1_pos = find_r1(word)
  if r1_pos > #word then
    return #word + 1
  end
  for i = r1_pos, #word - 1 do
    if is_vowel(word:sub(i, i)) and is_consonant(word:sub(i + 1, i + 1)) then
      return i + 2
    end
  end
  return #word + 1
end
local in_r1
in_r1 = function(word, pos)
  local r1 = find_r1(word)
  return pos >= r1
end
local in_r2
in_r2 = function(word, pos)
  local r2 = find_r2(word)
  return pos >= r2
end
local is_short_syllable_at
is_short_syllable_at = function(word, pos)
  if pos < 1 or pos > #word then
    return false
  end
  local char = word:sub(pos, pos)
  if not (is_vowel(char)) then
    return false
  end
  if pos == 1 then
    if #word > 1 then
      local next_char = word:sub(2, 2)
      return is_consonant(next_char)
    end
    return false
  end
  if pos < #word then
    local prev_char = word:sub(pos - 1, pos - 1)
    local next_char = word:sub(pos + 1, pos + 1)
    if is_consonant(prev_char) and is_consonant(next_char) then
      local next_lower = next_char:lower()
      return next_lower ~= 'w' and next_lower ~= 'x' and next_char ~= 'Y'
    end
  end
  return false
end
local ends_with_short_syllable
ends_with_short_syllable = function(word)
  if #word < 2 then
    return false
  end
  if #word == 2 then
    return is_vowel(word:sub(1, 1)) and is_consonant(word:sub(2, 2))
  end
  if #word >= 3 then
    local c1 = word:sub(-3, -3)
    local c2 = word:sub(-2, -2)
    local c3 = word:sub(-1, -1)
    if is_consonant(c1) and is_vowel(c2) and is_consonant(c3) then
      local c3_lower = c3:lower()
      return c3_lower ~= 'w' and c3_lower ~= 'x' and c3 ~= 'Y'
    end
  end
  return false
end
local is_short_word
is_short_word = function(word)
  local r1 = find_r1(word)
  if r1 > #word then
    return true
  end
  if r1 == #word + 1 and ends_with_short_syllable(word) then
    return true
  end
  return false
end
local prelude
prelude = function(word)
  if #word == 0 then
    return word
  end
  if word:sub(1, 1) == "'" then
    word = word:sub(2)
  end
  local result = { }
  local y_found = false
  for i = 1, #word do
    local char = word:sub(i, i)
    if char == 'y' then
      if i == 1 then
        table.insert(result, 'Y')
        y_found = true
      elseif i > 1 and is_vowel(word:sub(i - 1, i - 1)) then
        table.insert(result, 'Y')
        y_found = true
      else
        table.insert(result, char)
      end
    else
      table.insert(result, char)
    end
  end
  return table.concat(result), y_found
end
local postlude
postlude = function(word, y_found)
  if not (y_found) then
    return word
  end
  return word:gsub('Y', 'y')
end
local exception1
exception1 = function(word)
  local exceptions = {
    skis = "ski",
    skies = "sky",
    idly = "idl",
    gently = "gentl",
    ugly = "ugli",
    early = "earli",
    only = "onli",
    singly = "singl",
    sky = "sky",
    news = "news",
    howe = "howe",
    atlas = "atlas",
    cosmos = "cosmos",
    bias = "bias",
    andes = "andes"
  }
  return exceptions[word]
end
local step_1a
step_1a = function(word)
  if ends_with(word, "'s'") then
    return word:sub(1, -4)
  elseif ends_with(word, "'s") then
    return word:sub(1, -3)
  elseif ends_with(word, "'") then
    return word:sub(1, -2)
  end
  if ends_with(word, "sses") then
    return replace_suffix(word, "sses", "ss")
  end
  if ends_with(word, "ied") then
    if #word > 4 then
      return replace_suffix(word, "ied", "i")
    else
      return replace_suffix(word, "ied", "ie")
    end
  end
  if ends_with(word, "ies") then
    if #word > 4 then
      return replace_suffix(word, "ies", "i")
    else
      return replace_suffix(word, "ies", "ie")
    end
  end
  if ends_with(word, "s") and not ends_with(word, "us") and not ends_with(word, "ss") then
    local stem = word:sub(1, -2)
    if contains_vowel(stem) then
      return stem
    end
  end
  return word
end
local step_1b
step_1b = function(word)
  if ends_with(word, "eedly") then
    local stem = word:sub(1, -6)
    if in_r1(word, #stem + 1) then
      if ends_with(stem, "proc") or ends_with(stem, "exc") or ends_with(stem, "succ") then
        return word
      end
      return stem .. "ee"
    end
    return word
  end
  if ends_with(word, "eed") then
    local stem = word:sub(1, -4)
    if in_r1(word, #stem + 1) then
      if ends_with(stem, "proc") or ends_with(stem, "exc") or ends_with(stem, "succ") then
        return word
      end
      return stem .. "ee"
    end
    return word
  end
  local suffix_removed = false
  local stem = word
  if ends_with(word, "ingly") then
    stem = word:sub(1, -6)
    suffix_removed = true
  elseif ends_with(word, "edly") then
    stem = word:sub(1, -5)
    suffix_removed = true
  elseif ends_with(word, "ing") then
    stem = word:sub(1, -4)
    suffix_removed = true
  elseif ends_with(word, "ed") then
    stem = word:sub(1, -3)
    suffix_removed = true
  end
  if suffix_removed then
    if not (contains_vowel(stem)) then
      return word
    end
    if ends_with(word, "ing") then
      if ends_with(stem, "y") and #stem > 1 then
        local prev = stem:sub(-2, -2)
        if is_consonant(prev) and #stem == 2 then
          return stem:sub(1, -2) .. "ie"
        end
      end
      if ends_with(stem, "inn") or ends_with(stem, "out") or ends_with(stem, "cann") or ends_with(stem, "herr") or ends_with(stem, "earr") or ends_with(stem, "even") then
        return word
      end
    end
    if ends_with(stem, "at") or ends_with(stem, "bl") or ends_with(stem, "iz") then
      return stem .. "e"
    end
    if #stem >= 2 then
      local last = stem:sub(-1, -1)
      local prev = stem:sub(-2, -2)
      if last == prev and is_consonant(last) then
        local last_lower = last:lower()
        if not (last_lower == 'a' or last_lower == 'e' or last_lower == 'o') then
          if last_lower == 'b' or last_lower == 'd' or last_lower == 'f' or last_lower == 'g' or last_lower == 'm' or last_lower == 'n' or last_lower == 'p' or last_lower == 'r' or last_lower == 't' then
            return stem:sub(1, -2)
          end
        end
      end
    end
    if in_r1(word, #stem + 1) and ends_with_short_syllable(stem) then
      return stem .. "e"
    end
    return stem
  end
  return word
end
local step_1c
step_1c = function(word)
  if #word > 2 then
    local last = word:sub(-1, -1)
    local prev = word:sub(-2, -2)
    if (last == 'y' or last == 'Y') and is_consonant(prev) then
      return word:sub(1, -2) .. "i"
    end
  end
  return word
end
local step_2
step_2 = function(word)
  local mappings = {
    {
      "ational",
      "ate"
    },
    {
      "tional",
      "tion"
    },
    {
      "enci",
      "ence"
    },
    {
      "anci",
      "ance"
    },
    {
      "abli",
      "able"
    },
    {
      "entli",
      "ent"
    },
    {
      "ization",
      "ize"
    },
    {
      "izer",
      "ize"
    },
    {
      "ation",
      "ate"
    },
    {
      "ator",
      "ate"
    },
    {
      "alism",
      "al"
    },
    {
      "aliti",
      "al"
    },
    {
      "alli",
      "al"
    },
    {
      "fulness",
      "ful"
    },
    {
      "ousli",
      "ous"
    },
    {
      "ousness",
      "ous"
    },
    {
      "iveness",
      "ive"
    },
    {
      "iviti",
      "ive"
    },
    {
      "biliti",
      "ble"
    },
    {
      "bli",
      "ble"
    },
    {
      "fulli",
      "ful"
    },
    {
      "lessli",
      "less"
    }
  }
  for _index_0 = 1, #mappings do
    local pair = mappings[_index_0]
    local suffix, replacement = pair[1], pair[2]
    if ends_with(word, suffix) then
      local stem = word:sub(1, #word - #suffix)
      if in_r1(word, #stem + 1) then
        return stem .. replacement
      end
    end
  end
  if ends_with(word, "ogi") then
    local stem = word:sub(1, -4)
    if in_r1(word, #stem + 1) and ends_with(stem, "l") then
      return stem .. "og"
    end
  end
  if ends_with(word, "li") then
    local stem = word:sub(1, -3)
    if in_r1(word, #stem + 1) and #stem > 0 then
      local last = stem:sub(-1, -1)
      if is_valid_li(last) then
        return stem
      end
    end
  end
  if ends_with(word, "ogist") then
    local stem = word:sub(1, -5)
    if in_r1(word, #stem + 1) then
      return stem .. "og"
    end
  end
  return word
end
local step_3
step_3 = function(word)
  local mappings = {
    {
      "ational",
      "ate"
    },
    {
      "tional",
      "tion"
    },
    {
      "alize",
      "al"
    },
    {
      "icate",
      "ic"
    },
    {
      "iciti",
      "ic"
    },
    {
      "ical",
      "ic"
    },
    {
      "ful",
      ""
    },
    {
      "ness",
      ""
    }
  }
  for _index_0 = 1, #mappings do
    local pair = mappings[_index_0]
    local suffix, replacement = pair[1], pair[2]
    if ends_with(word, suffix) then
      local stem = word:sub(1, #word - #suffix)
      if in_r1(word, #stem + 1) then
        return stem .. replacement
      end
    end
  end
  if ends_with(word, "ative") then
    local stem = word:sub(1, -6)
    if in_r2(word, #stem + 1) then
      return stem
    end
  end
  return word
end
local step_4
step_4 = function(word)
  local suffixes = {
    "al",
    "ance",
    "ence",
    "er",
    "ic",
    "able",
    "ible",
    "ant",
    "ement",
    "ment",
    "ent",
    "ism",
    "ate",
    "iti",
    "ous",
    "ive",
    "ize"
  }
  for _index_0 = 1, #suffixes do
    local suffix = suffixes[_index_0]
    if ends_with(word, suffix) then
      local stem = word:sub(1, #word - #suffix)
      if in_r2(word, #stem + 1) then
        return stem
      end
    end
  end
  if ends_with(word, "ion") then
    local stem = word:sub(1, -4)
    if in_r2(word, #stem + 1) and #stem > 0 then
      local last = stem:sub(-1, -1)
      if last == 's' or last == 't' then
        return stem
      end
    end
  end
  return word
end
local step_5
step_5 = function(word)
  if ends_with(word, "e") then
    local stem = word:sub(1, -2)
    if in_r2(word, #stem + 1) then
      return stem
    end
    if in_r1(word, #stem + 1) and not ends_with_short_syllable(stem) then
      return stem
    end
  end
  if ends_with(word, "ll") and in_r2(word, #word) then
    return word:sub(1, -2)
  end
  return word
end
local stem_word
stem_word = function(word)
  if not (word and type(word) == "string") then
    return word
  end
  if #word < 3 then
    return word
  end
  word = word:lower()
  local exception = exception1(word)
  if exception then
    return exception
  end
  if #word < 3 then
    return word
  end
  local y_found
  word, y_found = prelude(word)
  word = step_1a(word)
  word = step_1b(word)
  word = step_1c(word)
  word = step_2(word)
  word = step_3(word)
  word = step_4(word)
  word = step_5(word)
  word = postlude(word, y_found)
  return word
end
return {
  stem_word = stem_word
}
