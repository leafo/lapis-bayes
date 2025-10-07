punycode = require "lapis.bayes.text.punycode"

describe "lapis.bayes.text.punycode", ->
  describe "punycode_encode", ->
    fixtures = {
      { description: "German umlaut: münchen", label: "münchen", expected: "xn--mnchen-3ya" }
      { description: "German umlaut: müller", label: "müller", expected: "xn--mller-kva" }
      { description: "German umlaut: bücher", label: "bücher", expected: "xn--bcher-kva" }
      { description: "French accent: français", label: "français", expected: "xn--franais-xxa" }
      { description: "French accent: café", label: "café", expected: "xn--caf-dma" }
      { description: "Spanish tilde: español", label: "español", expected: "xn--espaol-zwa" }
      { description: "Spanish tilde: mañana", label: "mañana", expected: "xn--maana-pta" }
      { description: "Japanese kanji: 日本", label: "日本", expected: "xn--wgv71a" }
      { description: "Japanese hiragana: こんにちは", label: "こんにちは", expected: "xn--28j2a3ar1p" }
      { description: "Japanese katakana: テスト", label: "テスト", expected: "xn--zckzah" }
      { description: "Chinese simplified: 中国", label: "中国", expected: "xn--fiqs8s" }
      { description: "Chinese traditional: 中國", label: "中國", expected: "xn--fiqz9s" }
      { description: "Korean hangul: 한국", label: "한국", expected: "xn--3e0b707e" }
      { description: "Arabic: العربية", label: "العربية", expected: "xn--mgbcd4a2b0d2b" }
      { description: "Russian cyrillic: россия", label: "россия", expected: "xn--h1alffa9f" }
      { description: "Greek: ελληνικά", label: "ελληνικά", expected: "xn--hxargifdar" }
      { description: "Hebrew: עברית", label: "עברית", expected: "xn--5dbqzzl" }
      { description: "Thai: ไทย", label: "ไทย", expected: "xn--o3cw4h" }
      { description: "Mixed ASCII & Unicode: bücher-buch", label: "bücher-buch", expected: "xn--bcher-buch-9db" }
      { description: "Mixed ASCII & Unicode: hello世界", label: "hello世界", expected: "xn--hello-ck1hg65u" }
      { description: "Single Unicode codepoint: ü", label: "ü", expected: "xn--tda" }
      { description: "Single Unicode codepoint: ñ", label: "ñ", expected: "xn--ida" }
      { description: "Numeric suffix: 123ü", label: "123ü", expected: "xn--123-joa" }
      { description: "Leading hyphen: -ü", label: "-ü", expected: "xn----eha" }
      { description: "Swiss city: zürich", label: "zürich", expected: "xn--zrich-kva" }
      { description: "Russian city: москва", label: "москва", expected: "xn--80adxhks" }
      { description: "Arabic city: القاهرة", label: "القاهرة", expected: "xn--mgbag5a2flx" }
      { description: "Hyphen only label", label: "---", expected: "---" }
      { description: "German compound: bücher-bücherei", label: "bücher-bücherei", expected: "xn--bcher-bcherei-wobg" }
      { description: "Czech example", label: "Pročprostěnemluvíčesky", expected: "xn--Proprostnemluvesky-uyb24dma41a" }
      { description: "Chinese (simplified) example", label: "他们为什么不说中文", expected: "xn--ihqwcrb4cv8a8dqg056pqjye" }
      { description: "Chinese (traditional) example", label: "他們爲什麽不說中文", expected: "xn--ihqwctvzc91f659drss3x8bo0yb" }
      { description: "Arabic example", label: "ليهمابتكلموشعربي؟", expected: "xn--egbpdaj6bu4bxfgehfvwxn" }
      { description: "Hebrew example", label: "למההםפשוטלאמדבריםעברית", expected: "xn--4dbcagdahymbxekheh6e0a7fei0b" }
      { description: "Hindi example", label: "यहलोगहिन्दीक्योंनहींबोलसकतेहैं", expected: "xn--i1baa7eci9glrd9b2ae1bj0hfcgg6iyaf8o0a1dig0cd" }
      { description: "Japanese sentence", label: "なぜみんな日本語を話してくれないのか", expected: "xn--n8jok5ay5dzabd5bym9f0cm5685rrjetr6pdxa" }
      { description: "Korean example", label: "세계의모든사람들이한국어를이해한다면얼마나좋을까", expected: "xn--989aomsvi5e83db1d2a355cv1e0vak1dwrv93d5xbh15a0dt30a5jpsd879ccm6fea98c" }
      { description: "Russian example", label: "почемужеонинеговорятпорусски", expected: "xn--b1abfaaepdrnnbgefbadotcwatmq2g4l" }
      { description: "Spanish sentence", label: "PorquénopuedensimplementehablarenEspañol", expected: "xn--PorqunopuedensimplementehablarenEspaol-fmd56a" }
      { description: "Vietnamese example", label: "TạisaohọkhôngthểchỉnóitiếngViệt", expected: "xn--TisaohkhngthchnitingVit-kjcr8268qyxafd2f1b9g" }
      { description: "Mixed example: 3年B組金八先生", label: "3年B組金八先生", expected: "xn--3B-ww4c5e180e575a65lsy2b" }
      { description: "Mixed example: 安室奈美恵-with-SUPER-MONKEYS", label: "安室奈美恵-with-SUPER-MONKEYS", expected: "xn---with-SUPER-MONKEYS-pc58ag80a8qai00g7n9n" }
      { description: "Mixed example: Hello-Another-Way-それぞれの場所", label: "Hello-Another-Way-それぞれの場所", expected: "xn--Hello-Another-Way--fc4qua05auwb3674vfr0b" }
      { description: "Mixed example: ひとつ屋根の下2", label: "ひとつ屋根の下2", expected: "xn--2-u9tlzr9756bt3uc0v" }
      { description: "Mixed example: MajiでKoiする5秒前", label: "MajiでKoiする5秒前", expected: "xn--MajiKoi5-783gue6qz075azm5e" }
      { description: "Mixed example: パフィーdeルンバ", label: "パフィーdeルンバ", expected: "xn--de-jg4avhby1noc0d" }
      { description: "Mixed example: そのスピードで", label: "そのスピードで", expected: "xn--d9juau41awczczp" }
    }

    it "passes through ASCII-only strings unchanged", ->
      assert.same "example", punycode.punycode_encode "example"
      assert.same "test", punycode.punycode_encode "test"
      assert.same "hello-world", punycode.punycode_encode "hello-world"
      assert.same "abc123", punycode.punycode_encode "abc123"

    it "handles empty string", ->
      assert.same "", punycode.punycode_encode ""

    describe "fixture encodings", ->
      for case in *fixtures
        it "encodes #{case.description}", ->
          assert.same case.expected, punycode.punycode_encode case.label

    describe "ASCII boundary behaviour", ->
      it "preserves leading ASCII characters", ->
        result = punycode.punycode_encode "test日本"
        assert.true (result\match "^xn%-%-test") != nil

      it "handles trailing hyphen with Unicode", ->
        result = punycode.punycode_encode "test-ü"
        assert.true (result\match "^xn%-%-") != nil

      it "preserves case for ASCII characters", ->
        result = punycode.punycode_encode "Test日本"
        assert.true (result\match "Test") != nil

    it "handles emoji", ->
      result = punycode.punycode_encode "💩"
      assert.is_string result
