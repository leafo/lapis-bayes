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

    it "rejects visible characters", ->
      assert.falsy matches scripts.zero_width_character, "A"
      assert.falsy matches scripts.zero_width_character, " "
      assert.falsy matches scripts.zero_width_character, "漢"
