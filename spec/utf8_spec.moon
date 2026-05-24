scripts = require "lapis.bayes.text.utf8"
import C, P from require "lpeg"

capture = (pattern, text) ->
  (C(pattern) * -P(1))\match text

matches = (pattern, text) ->
  not not ((pattern * -P(1))\match text)

describe "lapis.bayes.text.utf8", ->
  describe "han_character", ->
    it "matches a basic Han ideograph", ->
      assert.same "漢", capture scripts.han_character, "漢"

    it "matches a supplementary plane character", ->
      assert.same "𠀋", capture scripts.han_character, "𠀋"

    it "does not match kana characters", ->
      assert.falsy matches scripts.han_character, "あ"
      assert.falsy matches scripts.han_character, "ア"

  describe "kana_character", ->
    it "matches hiragana and katakana", ->
      assert.same "あ", capture scripts.kana_character, "あ"
      assert.same "ア", capture scripts.kana_character, "ア"

    it "matches halfwidth katakana", ->
      assert.same "ｱ", capture scripts.kana_character, "ｱ"

    it "does not match Han or Latin letters", ->
      assert.falsy matches scripts.kana_character, "漢"
      assert.falsy matches scripts.kana_character, "A"

  describe "hangul_character", ->
    it "matches modern syllables and jamo", ->
      assert.same "한", capture scripts.hangul_character, "한"
      assert.same "ᄀ", capture scripts.hangul_character, "ᄀ"

    it "matches halfwidth Hangul letters", ->
      assert.same "ﾡ", capture scripts.hangul_character, "ﾡ"

    it "does not match kana", ->
      assert.falsy matches scripts.hangul_character, "ア"

  describe "cjk_character", ->
    it "matches characters across Han, Kana, and Hangul", ->
      assert.same "漢", capture scripts.cjk_character, "漢"
      assert.same "あ", capture scripts.cjk_character, "あ"
      assert.same "한", capture scripts.cjk_character, "한"

    it "rejects non-CJK characters", ->
      assert.falsy matches scripts.cjk_character, "A"
      assert.falsy matches scripts.cjk_character, "1"

  describe "zero_width_character", ->
    it "matches zero width space (U+200B)", ->
      assert.same "\226\128\139", capture scripts.zero_width_character, "\226\128\139"

    it "matches zero width non-joiner (U+200C)", ->
      assert.same "\226\128\140", capture scripts.zero_width_character, "\226\128\140"

    it "matches zero width joiner (U+200D)", ->
      assert.same "\226\128\141", capture scripts.zero_width_character, "\226\128\141"

    it "matches word joiner (U+2060)", ->
      assert.same "\226\129\160", capture scripts.zero_width_character, "\226\129\160"

    it "matches byte order mark (U+FEFF)", ->
      assert.same "\239\187\191", capture scripts.zero_width_character, "\239\187\191"

    it "matches soft hyphen (U+00AD)", ->
      assert.same "\194\173", capture scripts.zero_width_character, "\194\173"

    it "matches Arabic letter mark (U+061C)", ->
      assert.same "\216\156", capture scripts.zero_width_character, "\216\156"

    it "matches Mongolian vowel separator (U+180E)", ->
      assert.same "\225\160\142", capture scripts.zero_width_character, "\225\160\142"

    it "matches LRM (U+200E) and RLM (U+200F)", ->
      assert.same "\226\128\142", capture scripts.zero_width_character, "\226\128\142"
      assert.same "\226\128\143", capture scripts.zero_width_character, "\226\128\143"

    it "matches bidi formatting U+202A–U+202E", ->
      assert.same "\226\128\170", capture scripts.zero_width_character, "\226\128\170"
      assert.same "\226\128\174", capture scripts.zero_width_character, "\226\128\174"

    it "matches invisible operators U+2061–U+2064", ->
      assert.same "\226\129\161", capture scripts.zero_width_character, "\226\129\161"
      assert.same "\226\129\164", capture scripts.zero_width_character, "\226\129\164"

    it "matches bidi isolates and deprecated format controls U+2066–U+206F", ->
      assert.same "\226\129\166", capture scripts.zero_width_character, "\226\129\166"
      assert.same "\226\129\175", capture scripts.zero_width_character, "\226\129\175"

    it "matches combining grapheme joiner (U+034F)", ->
      assert.same "\205\143", capture scripts.zero_width_character, "\205\143"

    it "matches variation selectors U+FE00–U+FE0F", ->
      assert.same "\239\184\128", capture scripts.zero_width_character, "\239\184\128"
      assert.same "\239\184\143", capture scripts.zero_width_character, "\239\184\143"

    it "matches TAG block U+E0000–U+E007F", ->
      assert.same "\243\160\128\128", capture scripts.zero_width_character, "\243\160\128\128"
      assert.same "\243\160\129\191", capture scripts.zero_width_character, "\243\160\129\191"

    it "matches variation selectors supplement U+E0100–U+E01EF", ->
      assert.same "\243\160\132\128", capture scripts.zero_width_character, "\243\160\132\128"
      assert.same "\243\160\135\175", capture scripts.zero_width_character, "\243\160\135\175"

    it "rejects visible characters", ->
      assert.falsy matches scripts.zero_width_character, "A"
      assert.falsy matches scripts.zero_width_character, " "
      assert.falsy matches scripts.zero_width_character, "漢"

    it "rejects characters just outside ranges", ->
      assert.falsy matches scripts.zero_width_character, "\226\128\144" -- U+2010
      assert.falsy matches scripts.zero_width_character, "\226\128\175" -- U+202F NNBSP
      assert.falsy matches scripts.zero_width_character, "\226\129\159" -- U+205F MMSP
      assert.falsy matches scripts.zero_width_character, "\226\129\165" -- U+2065
      assert.falsy matches scripts.zero_width_character, "\243\160\135\176" -- U+E01F0

  describe "strip_zero_width_string", ->
    it "removes invisible format controls inside text", ->
      assert.same "example.com", scripts.strip_zero_width_string "ex\194\173am\226\129\166ple.com"

    it "preserves nil", ->
      assert.same nil, scripts.strip_zero_width_string nil
