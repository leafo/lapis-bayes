-- Porter Stemmer implementation in MoonScript
-- Based on the Snowball English stemmer algorithm
-- https://github.com/snowballstem/snowball/blob/master/algorithms/english.sbl
--
-- This implementation is derived from the Snowball stemming algorithms
-- Copyright (c) 2001, Dr Martin Porter
-- Copyright (c) 2004,2005, Richard Boulton
-- Copyright (c) 2013, Yoshiki Shibukawa
-- Copyright (c) 2006,2007,2009,2010,2011,2014-2019, Olly Betts
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions
-- are met:
--
--   1. Redistributions of source code must retain the above copyright notice,
--      this list of conditions and the following disclaimer.
--   2. Redistributions in binary form must reproduce the above copyright notice,
--      this list of conditions and the following disclaimer in the documentation
--      and/or other materials provided with the distribution.
--   3. Neither the name of the Snowball project nor the names of its contributors
--      may be used to endorse or promote products derived from this software
--      without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
-- ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
-- ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

-- Character group definitions
is_vowel = (char) ->
  return false unless char
  char = char\lower!
  char == 'a' or char == 'e' or char == 'i' or char == 'o' or char == 'u' or char == 'y'

is_consonant = (char) ->
  return false unless char
  not is_vowel char

is_vowel_wxy = (char) ->
  return false unless char
  char = char\lower!
  char == 'a' or char == 'e' or char == 'i' or char == 'o' or char == 'u' or char == 'y' or char == 'w' or char == 'x'

is_valid_li = (char) ->
  return false unless char
  char = char\lower!
  char == 'c' or char == 'd' or char == 'e' or char == 'g' or char == 'h' or char == 'k' or char == 'm' or char == 'n' or char == 'r' or char == 't'

-- String utility functions
ends_with = (word, suffix) ->
  return false if #word < #suffix
  word\sub(-#suffix) == suffix

contains_vowel = (word) ->
  for i = 1, #word
    return true if is_vowel word\sub(i, i)
  false

-- Replace suffix with replacement
replace_suffix = (word, suffix, replacement) ->
  if ends_with word, suffix
    word\sub(1, #word - #suffix) .. replacement
  else
    word

-- Get suffix starting at position
get_suffix = (word, pos) ->
  return "" if pos > #word
  word\sub pos

-- Region detection
-- Find R1: the region after the first non-vowel following a vowel
find_r1 = (word) ->
  -- Special handling for common prefixes
  if word\sub(1, 5) == "gener"
    return 6
  elseif word\sub(1, 6) == "commun"
    return 7
  elseif word\sub(1, 5) == "arsen"
    return 6
  elseif word\sub(1, 4) == "past"
    return 5
  elseif word\sub(1, 7) == "univers"
    return 8
  elseif word\sub(1, 5) == "later"
    return 6
  elseif word\sub(1, 5) == "emerg"
    return 6
  elseif word\sub(1, 5) == "organ"
    return 6

  -- Standard R1 detection: find first V followed by NV
  for i = 1, #word - 1
    if is_vowel(word\sub(i, i)) and is_consonant(word\sub(i + 1, i + 1))
      return i + 2

  #word + 1

-- Find R2: the region after the first non-vowel following a vowel in R1
find_r2 = (word) ->
  r1_pos = find_r1 word
  return #word + 1 if r1_pos > #word

  -- Find V followed by NV in R1
  for i = r1_pos, #word - 1
    if is_vowel(word\sub(i, i)) and is_consonant(word\sub(i + 1, i + 1))
      return i + 2

  #word + 1

-- Test if position is at R1
in_r1 = (word, pos) ->
  r1 = find_r1 word
  pos >= r1

-- Test if position is at R2
in_r2 = (word, pos) ->
  r2 = find_r2 word
  pos >= r2

-- Test for short syllable
-- A short syllable is either (a) a vowel followed by a non-vowel other than w, x or Y
-- and preceded by a non-vowel, or (b) a vowel at the beginning of the word followed
-- by a non-vowel.
is_short_syllable_at = (word, pos) ->
  return false if pos < 1 or pos > #word

  char = word\sub(pos, pos)
  return false unless is_vowel char

  if pos == 1
    -- Case (b): vowel at beginning followed by non-vowel
    if #word > 1
      next_char = word\sub(2, 2)
      return is_consonant next_char
    return false

  -- Case (a): non-vowel, vowel, non-vowel (not w,x,Y)
  if pos < #word
    prev_char = word\sub(pos - 1, pos - 1)
    next_char = word\sub(pos + 1, pos + 1)

    if is_consonant(prev_char) and is_consonant(next_char)
      next_lower = next_char\lower!
      return next_lower != 'w' and next_lower != 'x' and next_char != 'Y'

  false

-- Test if word ends with short syllable
ends_with_short_syllable = (word) ->
  return false if #word < 2

  -- Check last two characters for pattern
  if #word == 2
    return is_vowel(word\sub(1, 1)) and is_consonant(word\sub(2, 2))

  -- Check last three characters for non-vowel, vowel, non-vowel (not w,x,Y)
  if #word >= 3
    c1 = word\sub(-3, -3)
    c2 = word\sub(-2, -2)
    c3 = word\sub(-1, -1)

    if is_consonant(c1) and is_vowel(c2) and is_consonant(c3)
      c3_lower = c3\lower!
      return c3_lower != 'w' and c3_lower != 'x' and c3 != 'Y'

  false

-- Test for short word: word is short if it consists of a short syllable
-- and nothing else, or if R1 is null
is_short_word = (word) ->
  r1 = find_r1 word
  return true if r1 > #word

  -- Also check if ends with short syllable at beginning of R1
  if r1 == #word + 1 and ends_with_short_syllable word
    return true

  false

-- Prelude: handle initial Y and y after vowel
prelude = (word) ->
  return word if #word == 0

  -- Remove initial apostrophe
  word = word\sub(2) if word\sub(1, 1) == "'"

  result = {}
  y_found = false

  for i = 1, #word
    char = word\sub(i, i)

    if char == 'y'
      -- Convert to Y if at beginning or after vowel
      if i == 1
        table.insert result, 'Y'
        y_found = true
      elseif i > 1 and is_vowel(word\sub(i - 1, i - 1))
        table.insert result, 'Y'
        y_found = true
      else
        table.insert result, char
    else
      table.insert result, char

  table.concat(result), y_found

-- Postlude: convert Y back to y
postlude = (word, y_found) ->
  return word unless y_found
  word\gsub('Y', 'y')

-- Exception list 1: special cases
exception1 = (word) ->
  exceptions = {
    skis: "ski"
    skies: "sky"
    idly: "idl"
    gently: "gentl"
    ugly: "ugli"
    early: "earli"
    only: "onli"
    singly: "singl"
    sky: "sky"
    news: "news"
    howe: "howe"
    atlas: "atlas"
    cosmos: "cosmos"
    bias: "bias"
    andes: "andes"
  }

  exceptions[word]

-- Step 1a: handle plural forms
step_1a = (word) ->
  -- Handle apostrophe forms
  if ends_with word, "'s'"
    return word\sub(1, -4)
  elseif ends_with word, "'s"
    return word\sub(1, -3)
  elseif ends_with word, "'"
    return word\sub(1, -2)

  -- Handle sses -> ss
  if ends_with word, "sses"
    return replace_suffix word, "sses", "ss"

  -- Handle ied, ies
  if ends_with word, "ied"
    if #word > 4
      return replace_suffix word, "ied", "i"
    else
      return replace_suffix word, "ied", "ie"

  if ends_with word, "ies"
    if #word > 4
      return replace_suffix word, "ies", "i"
    else
      return replace_suffix word, "ies", "ie"

  -- Handle s (but not us or ss)
  if ends_with(word, "s") and not ends_with(word, "us") and not ends_with(word, "ss")
    -- Only remove s if preceded by vowel somewhere in word
    stem = word\sub(1, -2)
    if contains_vowel stem
      return stem

  word

-- Step 1b: handle ed, ing, eed forms
step_1b = (word) ->
  -- Handle eed, eedly
  if ends_with word, "eedly"
    stem = word\sub(1, -6)
    if in_r1 word, #stem + 1
      -- Check for special cases
      if ends_with(stem, "proc") or ends_with(stem, "exc") or ends_with(stem, "succ")
        return word
      return stem .. "ee"
    return word

  if ends_with word, "eed"
    stem = word\sub(1, -4)
    if in_r1 word, #stem + 1
      if ends_with(stem, "proc") or ends_with(stem, "exc") or ends_with(stem, "succ")
        return word
      return stem .. "ee"
    return word

  -- Handle ed, edly, ing, ingly
  suffix_removed = false
  stem = word

  if ends_with word, "ingly"
    stem = word\sub(1, -6)
    suffix_removed = true
  elseif ends_with word, "edly"
    stem = word\sub(1, -5)
    suffix_removed = true
  elseif ends_with word, "ing"
    stem = word\sub(1, -4)
    suffix_removed = true
  elseif ends_with word, "ed"
    stem = word\sub(1, -3)
    suffix_removed = true

  if suffix_removed
    -- Only proceed if stem contains vowel
    return word unless contains_vowel stem

    -- Special handling for ing forms
    if ends_with word, "ing"
      -- dying -> die, lying -> lie, tying -> tie
      if ends_with(stem, "y") and #stem > 1
        prev = stem\sub(-2, -2)
        if is_consonant(prev) and #stem == 2
          return stem\sub(1, -2) .. "ie"

      -- inning, outing, canning stay as is
      if ends_with(stem, "inn") or ends_with(stem, "out") or ends_with(stem, "cann") or ends_with(stem, "herr") or ends_with(stem, "earr") or ends_with(stem, "even")
        return word

    -- Post-processing based on stem ending
    if ends_with(stem, "at") or ends_with(stem, "bl") or ends_with(stem, "iz")
      return stem .. "e"

    -- Handle double consonants (not aeo)
    if #stem >= 2
      last = stem\sub(-1, -1)
      prev = stem\sub(-2, -2)
      if last == prev and is_consonant(last)
        last_lower = last\lower!
        unless last_lower == 'a' or last_lower == 'e' or last_lower == 'o'
          -- Remove one of the double consonants (but check for special cases)
          if last_lower == 'b' or last_lower == 'd' or last_lower == 'f' or last_lower == 'g' or last_lower == 'm' or last_lower == 'n' or last_lower == 'p' or last_lower == 'r' or last_lower == 't'
            return stem\sub(1, -2)

    -- If R1 is null and ends with short syllable, add e
    if in_r1(word, #stem + 1) and ends_with_short_syllable stem
      return stem .. "e"

    return stem

  word

-- Step 1c: replace suffix y or Y by i if preceded by non-vowel which is not at the beginning
step_1c = (word) ->
  if #word > 2
    last = word\sub(-1, -1)
    prev = word\sub(-2, -2)

    if (last == 'y' or last == 'Y') and is_consonant(prev)
      return word\sub(1, -2) .. "i"

  word

-- Step 2: suffix removal for derivational suffixes
step_2 = (word) ->
  mappings = {
    {"ational", "ate"}
    {"tional", "tion"}
    {"enci", "ence"}
    {"anci", "ance"}
    {"abli", "able"}
    {"entli", "ent"}
    {"ization", "ize"}
    {"izer", "ize"}
    {"ation", "ate"}
    {"ator", "ate"}
    {"alism", "al"}
    {"aliti", "al"}
    {"alli", "al"}
    {"fulness", "ful"}
    {"ousli", "ous"}
    {"ousness", "ous"}
    {"iveness", "ive"}
    {"iviti", "ive"}
    {"biliti", "ble"}
    {"bli", "ble"}
    {"fulli", "ful"}
    {"lessli", "less"}
  }

  for pair in *mappings
    suffix, replacement = pair[1], pair[2]
    if ends_with word, suffix
      stem = word\sub(1, #word - #suffix)
      if in_r1 word, #stem + 1
        return stem .. replacement

  -- Special case: ogi -> og (when preceded by l)
  if ends_with word, "ogi"
    stem = word\sub(1, -4)
    if in_r1(word, #stem + 1) and ends_with(stem, "l")
      return stem .. "og"

  -- Special case: li -> delete (when preceded by valid_li)
  if ends_with word, "li"
    stem = word\sub(1, -3)
    if in_r1(word, #stem + 1) and #stem > 0
      last = stem\sub(-1, -1)
      if is_valid_li last
        return stem

  -- Special case: ogist -> og
  if ends_with word, "ogist"
    stem = word\sub(1, -5)
    if in_r1 word, #stem + 1
      return stem .. "og"

  word

-- Step 3: suffix removal
step_3 = (word) ->
  mappings = {
    {"ational", "ate"}
    {"tional", "tion"}
    {"alize", "al"}
    {"icate", "ic"}
    {"iciti", "ic"}
    {"ical", "ic"}
    {"ful", ""}
    {"ness", ""}
  }

  for pair in *mappings
    suffix, replacement = pair[1], pair[2]
    if ends_with word, suffix
      stem = word\sub(1, #word - #suffix)
      if in_r1 word, #stem + 1
        return stem .. replacement

  -- Special case: ative -> delete (in R2)
  if ends_with word, "ative"
    stem = word\sub(1, -6)
    if in_r2 word, #stem + 1
      return stem

  word

-- Step 4: suffix removal
step_4 = (word) ->
  suffixes = {
    "al", "ance", "ence", "er", "ic", "able", "ible",
    "ant", "ement", "ment", "ent", "ism", "ate",
    "iti", "ous", "ive", "ize"
  }

  for suffix in *suffixes
    if ends_with word, suffix
      stem = word\sub(1, #word - #suffix)
      if in_r2 word, #stem + 1
        return stem

  -- Special case: ion -> delete (when preceded by s or t in R2)
  if ends_with word, "ion"
    stem = word\sub(1, -4)
    if in_r2(word, #stem + 1) and #stem > 0
      last = stem\sub(-1, -1)
      if last == 's' or last == 't'
        return stem

  word

-- Step 5: suffix removal
step_5 = (word) ->
  -- Step 5a: remove trailing e
  if ends_with word, "e"
    stem = word\sub(1, -2)

    -- Delete if in R2
    if in_r2 word, #stem + 1
      return stem

    -- Delete if in R1 and not preceded by short syllable
    if in_r1(word, #stem + 1) and not ends_with_short_syllable(stem)
      return stem

  -- Step 5b: remove trailing l
  if ends_with(word, "ll") and in_r2(word, #word)
    return word\sub(1, -2)

  word

-- Main stemming function
stem_word = (word) ->
  return word unless word and type(word) == "string"
  return word if #word < 3

  word = word\lower!

  -- Check exceptions first
  exception = exception1 word
  return exception if exception

  -- If word is too short, return as-is
  return word if #word < 3

  -- Run through stemming steps
  word, y_found = prelude word

  word = step_1a word
  word = step_1b word
  word = step_1c word
  word = step_2 word
  word = step_3 word
  word = step_4 word
  word = step_5 word

  word = postlude word, y_found

  word

{
  :stem_word
}
