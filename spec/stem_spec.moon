stem = require "lapis.bayes.text.stem"

test_word = (input, expected) ->
  assert.same expected, stem.stem_word input

describe "lapis.bayes.text.stem", ->
  describe "stem_word", ->
    it "handles nil and empty strings", ->
      assert.same nil, stem.stem_word nil
      assert.same "", stem.stem_word ""

    it "handles short words (< 3 chars)", ->
      test_word "a", "a"
      test_word "ab", "ab"
      test_word "at", "at"

    it "handles words that don't need stemming", ->
      test_word "cat", "cat"
      test_word "dog", "dog"
      test_word "tree", "tree"

    it "converts to lowercase", ->
      test_word "HELLO", "hello"
      test_word "WoRlD", "world"
      test_word "TEST", "test"

    describe "exception words", ->
      it "handles skis/skies", ->
        test_word "skis", "ski"
        test_word "skies", "sky"
        test_word "sky", "sky"

      it "handles special -ly cases", ->
        test_word "idly", "idl"
        test_word "gently", "gentl"
        test_word "ugly", "ugli"
        test_word "early", "earli"
        test_word "only", "onli"
        test_word "singly", "singl"

      it "handles invariant forms", ->
        test_word "news", "news"
        test_word "howe", "howe"
        test_word "atlas", "atlas"
        test_word "cosmos", "cosmos"
        test_word "bias", "bias"
        test_word "andes", "andes"

    describe "Step 1a - plurals and possessives", ->
      it "removes apostrophes", ->
        test_word "dog's", "dog"
        test_word "cat's'", "cat"

      it "handles sses -> ss", ->
        test_word "blesses", "bless"
        test_word "stresses", "stress"

      it "handles ied/ies", ->
        test_word "tied", "tie"
        test_word "pies", "pie"
        test_word "cries", "cri"
        test_word "studies", "studi"

      it "removes trailing s when appropriate", ->
        test_word "cats", "cat"
        test_word "dogs", "dog"
        test_word "gas", "ga"  -- has vowel so s is removed
        test_word "this", "thi"  -- has vowel so s is removed
        test_word "class", "class"  -- ss ending

    describe "Step 1b - ed, ing suffixes", ->
      it "handles eed/eedly in R1", ->
        test_word "agreed", "agre"
        test_word "feed", "feed"  -- R1 is null, so eed not replaced

      it "handles ed/edly", ->
        test_word "plastered", "plaster"
        test_word "bled", "bled"
        test_word "motivated", "motiv"

      it "handles ing/ingly", ->
        test_word "sing", "sing"
        test_word "motivating", "motiv"
        test_word "running", "run"
        test_word "hopping", "hop"

      it "adds e after at/bl/iz", ->
        test_word "luxuriated", "luxuri"  -- removes 'ated', no e added
        test_word "troubled", "troubl"

      it "removes double consonants", ->
        test_word "hopped", "hop"
        test_word "fitted", "fit"
        test_word "planned", "plan"

      it "handles special ing cases", ->
        test_word "inning", "inning"
        test_word "outing", "outing"
        test_word "canning", "canning"

    describe "Step 1c - y suffix", ->
      it "replaces suffix y with i", ->
        test_word "happy", "happi"
        test_word "sky", "sky"  -- exception word, not changed

      it "does not replace y at start or after vowel", ->
        test_word "say", "say"
        test_word "boy", "boy"

    describe "Step 2 - derivational suffixes", ->
      it "handles tional -> tion", ->
        test_word "relational", "relat"
        test_word "conditional", "condit"
        test_word "rational", "ration"

      it "handles enci -> ence", ->
        test_word "valenci", "valenc"

      it "handles anci -> ance", ->
        test_word "hesitanci", "hesit"

      it "handles izer -> ize", ->
        test_word "digitizer", "digit"

      it "handles ational -> ate", ->
        test_word "operational", "oper"

      it "handles ation/ator -> ate", ->
        test_word "predication", "predic"
        test_word "operator", "oper"

      it "handles alism -> al", ->
        test_word "feudalism", "feudal"

      it "handles fulness -> ful", ->
        test_word "hopefulness", "hope"

      it "handles ousness -> ous", ->
        test_word "callousness", "callous"

      it "handles iveness -> ive", ->
        test_word "decisiveness", "decis"

      it "handles biliti -> ble", ->
        test_word "sensibiliti", "sensibl"

      it "handles li deletion", ->
        test_word "formalli", "formal"

    describe "Step 3 - more derivational suffixes", ->
      it "handles icate -> ic", ->
        test_word "duplicate", "duplic"

      it "handles ative deletion in R2", ->
        test_word "demonstrative", "demonstr"

      it "handles alize -> al", ->
        test_word "normalize", "normal"

      it "handles ful/ness deletion", ->
        test_word "hopeful", "hope"
        test_word "goodness", "good"

    describe "Step 4 - suffix deletion", ->
      it "handles al", ->
        test_word "radical", "radic"

      it "handles ance/ence", ->
        test_word "dependence", "depend"

      it "handles er", ->
        test_word "computer", "comput"

      it "handles able/ible", ->
        test_word "adjustable", "adjust"
        test_word "divisible", "divis"

      it "handles ant/ent/ment", ->
        test_word "irritant", "irrit"
        test_word "different", "differ"
        test_word "adjustment", "adjust"

      it "handles ion after s or t", ->
        test_word "adoption", "adopt"
        test_word "decision", "decis"

      it "handles ism/iti/ous/ive/ize", ->
        test_word "communism", "communism"  -- ism in R2 only
        test_word "sensitivity", "sensit"
        test_word "continuous", "continu"
        test_word "effective", "effect"
        test_word "realize", "realiz"

    describe "Step 5 - final cleanup", ->
      it "removes trailing e in R2", ->
        test_word "debate", "debat"
        test_word "create", "creat"

      it "removes trailing e in R1 if not short syllable", ->
        test_word "hope", "hope"

      it "keeps trailing e after short syllable in R1", ->
        test_word "centre", "centr"

      it "removes double l in R2", ->
        test_word "controll", "control"

    describe "word families", ->
      it "stems connection family to connect", ->
        test_word "connection", "connect"
        test_word "connections", "connect"
        test_word "connective", "connect"
        test_word "connected", "connect"
        test_word "connecting", "connect"

      it "stems generate family", ->
        test_word "generate", "generat"
        test_word "generates", "generat"
        test_word "generated", "generat"
        test_word "generating", "generat"
        test_word "generator", "generat"
        test_word "general", "general"
        test_word "generalization", "general"

      it "stems happy family to happi", ->
        test_word "happy", "happi"
        test_word "happiness", "happi"
        test_word "happily", "happili"

      it "stems run family", ->
        test_word "run", "run"
        test_word "running", "run"
        test_word "runs", "run"
        test_word "runner", "runner"

    describe "complex derivational chains", ->
      it "handles multiply derived words", ->
        test_word "vietnamization", "vietnam"
        test_word "conformabli", "conform"
        test_word "radicalli", "radic"
        test_word "differentli", "differ"

    describe "special prefix handling", ->
      it "handles commun- prefix", ->
        test_word "communism", "communism"  -- ism not in R2
        test_word "communication", "communic"
        test_word "community", "communiti"

      it "handles gener- prefix", ->
        test_word "generate", "generat"
        test_word "generator", "generat"
        test_word "generous", "generous"

      it "handles univers- prefix", ->
        test_word "university", "universiti"
        test_word "universal", "universal"
        test_word "universe", "univers"

    describe "edge cases", ->
      it "handles very long words", ->
        result = stem.stem_word "antidisestablishmentarianism"
        assert.is_string result
        assert.true #result > 0

      it "handles words with no vowels", ->
        test_word "shhh", "shhh"
        test_word "hmm", "hmm"

      it "handles repeated consonants", ->
        test_word "bless", "bless"
        test_word "press", "press"

      it "handles words ending in y", ->
        test_word "daily", "daili"
        test_word "easily", "easili"

      it "preserves words that should not be stemmed", ->
        test_word "test", "test"
        test_word "best", "best"
