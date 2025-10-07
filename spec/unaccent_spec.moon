
unaccent = require "lapis.bayes.text.unaccent"

describe "lapis.bayes.text.unaccent", ->
  describe "unaccent_string", ->
    it "passes through basic ASCII unchanged", ->
      assert.same "hello world", unaccent.unaccent_string "hello world"
      assert.same "abc123", unaccent.unaccent_string "abc123"
      assert.same "test", unaccent.unaccent_string "test"

    it "handles empty string", ->
      assert.same "", unaccent.unaccent_string ""

    it "converts fullwidth characters to ASCII", ->
      assert.same "abc", unaccent.unaccent_string "ａｂｃ"
      assert.same "ABC", unaccent.unaccent_string "ＡＢＣ"
      assert.same "123", unaccent.unaccent_string "１２３"

    it "converts mathematical alphanumerics", ->
      assert.same "abc", unaccent.unaccent_string "𝕒𝕓𝕔"
      assert.same "xyz", unaccent.unaccent_string "𝚡𝚢𝚣"
      assert.same "ABC", unaccent.unaccent_string "𝓐𝓑𝓒"

    it "converts mathematical bold letters", ->
      assert.same "SaleIsLiveCheckNow", unaccent.unaccent_string "𝐒𝐚𝐥𝐞𝐈𝐬𝐋𝐢𝐯𝐞𝐂𝐡𝐞𝐜𝐤𝐍𝐨𝐰"
      assert.same "ABC", unaccent.unaccent_string "𝐀𝐁𝐂"
      assert.same "xyz", unaccent.unaccent_string "𝐱𝐲𝐳"

    it "removes accents from Latin characters", ->
      assert.same "aeiou", unaccent.unaccent_string "àéíóú"
      assert.same "AEIOU", unaccent.unaccent_string "ÀÉÍÓÚ"
      assert.same "nca", unaccent.unaccent_string "ñçä"

    it "converts Greek letters to Latin", ->
      assert.same "a", unaccent.unaccent_string "α"
      assert.same "y", unaccent.unaccent_string "γ"
      assert.same "n", unaccent.unaccent_string "π"
      assert.same "o", unaccent.unaccent_string "ο"

    it "converts Cyrillic letters to Latin", ->
      assert.same "a", unaccent.unaccent_string "а"
      assert.same "e", unaccent.unaccent_string "е"
      assert.same "o", unaccent.unaccent_string "о"

    it "normalizes special punctuation", ->
      assert.same ".", unaccent.unaccent_string "。"
      assert.same ",", unaccent.unaccent_string "，"
      assert.same ":", unaccent.unaccent_string "："
      assert.same "!", unaccent.unaccent_string "！"

    it "normalizes mathematical operators", ->
      assert.same "==", unaccent.unaccent_string "⩵"
      assert.same "===", unaccent.unaccent_string "⩶"
      assert.same "::=", unaccent.unaccent_string "⩴"

    it "normalizes brackets", ->
      assert.same "[", unaccent.unaccent_string "［"
      assert.same "]", unaccent.unaccent_string "］"
      assert.same "{", unaccent.unaccent_string "｛"
      assert.same "}", unaccent.unaccent_string "｝"

    it "converts special number forms", ->
      assert.same "0", unaccent.unaccent_string "０"
      assert.same " 1/2", unaccent.unaccent_string "½"
      assert.same " 1/4", unaccent.unaccent_string "¼"
      assert.same " 3/4", unaccent.unaccent_string "¾"

    it "converts Roman numerals", ->
      assert.same "1", unaccent.unaccent_string "Ⅰ"
      assert.same "IV", unaccent.unaccent_string "Ⅳ"
      assert.same "XII", unaccent.unaccent_string "Ⅻ"

    it "converts circled numbers", ->
      assert.same "1", unaccent.unaccent_string "①"
      assert.same "10", unaccent.unaccent_string "⑩"
      assert.same "20", unaccent.unaccent_string "⑳"

    it "converts enclosed alphanumerics", ->
      assert.same "(1)", unaccent.unaccent_string "⑴"
      assert.same "(a)", unaccent.unaccent_string "⒜"
      assert.same "1.", unaccent.unaccent_string "⒈"

    it "handles mixed character types", ->
      assert.same "hello123", unaccent.unaccent_string "ｈｅｌｌｏ１２３"
      assert.same "test.com", unaccent.unaccent_string "ｔｅｓｔ。ｃｏｍ"

    it "handles characters that should pass through", ->
      result = unaccent.unaccent_string "hello-world_test"
      assert.same "hello-world_test", result

    it "handles ligatures", ->
      assert.same "fi", unaccent.unaccent_string "ﬁ"
      assert.same "fl", unaccent.unaccent_string "ﬂ"
      assert.same "ffi", unaccent.unaccent_string "ﬃ"
      assert.same "ffl", unaccent.unaccent_string "ﬄ"
      assert.same "st", unaccent.unaccent_string "ﬆ"

    it "handles special letter forms", ->
      assert.same "ss", unaccent.unaccent_string "ß"
      assert.same "SS", unaccent.unaccent_string "ẞ"
      assert.same "ae", unaccent.unaccent_string "æ"
      assert.same "AE", unaccent.unaccent_string "Æ"
      assert.same "oe", unaccent.unaccent_string "œ"
      assert.same "OE", unaccent.unaccent_string "Œ"

    describe "comprehensive normalization tests from test.moon", ->
      -- Note: unaccent_string only does character transliteration, not case normalization
      -- Expected values show what unaccent_string outputs (with spaces removed)
      normalizes = {
        {"hello world", "helloworld"}
        {"baｍWaＲ7°ＣｏМ", "bamWaR7.CoM"}
        {"BaМwＡｒ7．СοM", "BaMwAr7.CoM"}
        {"b Ａ ｍ w A ｒ 7 ° ｃ Ｏ М", "bAmwAr7.coM"}
        {"B A Μ W а Ｒ 7 ㆍc o m", "BAMWaR7.com"}
        {"b ＡΜ ｗ А Ｒ 7．ｃＯм", "bAMwAR7.com"}
        {"ｂａｍｗａｒ７.ｃｏｍ", "bamwar7.com"}
        {"ＢＡＭ〉ＷＡＲ７.ｃｏｍ", "BAM>WAR7.com"}
        {"B A M W A R 7ㆍCOM", "BAMWAR7.COM"}
        {"ＢＡＭＷＡＲ７.ＣＯＭ", "BAMWAR7.CoM"}
        {"〚ｂａｍ〛ｗａｒ７.〚ｃｏｍ〛", "[bam]war7.[com]"}
        {"⒲⒲⒲.⒝⒜⒨⒲⒜⒭⑺.⒞⒪⒨", "(w)(w)(w).(b)(a)(m)(w)(a)(r)(7).(c)(o)(m)"}
        {" ⓦⓦⓦ.ⓑⓐⓜⓦⓐⓡ⑦.ⓒⓞⓜ", "www.bamwar7.com"}
        {"🇱🅔🅰🄵", "leaf"}
        {"ero588，C0M", "ero588,C0M"}
        {"RK772。CoM", "RK772.CoM"}
        {"MIO652。CoM", "MIO652.CoM"}
        {"ＫＢＳ４５４。ＣＯＭ", "KBS454.CoM"}
        {"MI738。CoM", "MI738.CoM"}
        {"mkmk35。COM", "mkmk35.COM"}
        {"79ESA。CｏM", "79ESA.CoM"}
        {"APA82。CoM", "APA82.CoM"}
        {"𝚟𝚘𝚙.𝚜𝚞", "vop.su"}
        {"ＭＭＯ77。ＣＯＭ", "MMo77.CoM"}
        {"ＭＩＯ６５２。ＣＯＭ", "Mio652.CoM"}
        {"kakao: dnj2016", "kakao:dnj2016"}
      }

      for {before, after} in *normalizes
        it "normalizes '#{before}'", ->
          result = unaccent.unaccent_string before
          -- Remove spaces for comparison since the test.moon examples show this
          result_normalized = result\gsub "%s", ""
          assert.same after, result_normalized

  describe "unaccent_table", ->
    it "exists and is a table", ->
      assert.is_table unaccent.unaccent_table

    it "has expected number of entries", ->
      count = 0
      for k, v in pairs unaccent.unaccent_table
        count += 1
      assert.true count > 2000, "Expected over 2000 mappings"

    it "contains specific mappings", ->
      assert.same "a", unaccent.unaccent_table["à"]
      assert.same "e", unaccent.unaccent_table["é"]
      assert.same "A", unaccent.unaccent_table["Ａ"]
      assert.same "0", unaccent.unaccent_table["０"]
      assert.same ".", unaccent.unaccent_table["。"]

    it "maps fullwidth characters", ->
      assert.same "a", unaccent.unaccent_table["ａ"]
      assert.same "z", unaccent.unaccent_table["ｚ"]
      assert.same "0", unaccent.unaccent_table["０"]
      assert.same "9", unaccent.unaccent_table["９"]

    it "maps Greek letters", ->
      assert.same "a", unaccent.unaccent_table["α"]
      assert.same "y", unaccent.unaccent_table["γ"]
      assert.same "n", unaccent.unaccent_table["π"]

    it "maps mathematical alphanumerics", ->
      assert.true unaccent.unaccent_table["𝕒"] != nil
      assert.true unaccent.unaccent_table["𝓐"] != nil
      assert.true unaccent.unaccent_table["𝚊"] != nil
