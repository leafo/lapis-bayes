SpamTokenizer = require "lapis.bayes.tokenizers.spam"

it_tokenizes = (label, input, expected_tokens, opts=nil) ->
  it "tokenizes #{label}", ->
    tokenizer = SpamTokenizer opts
    tokens = tokenizer\tokenize_text input
    assert.same expected_tokens, tokens, "Tokens for #{input\sub 1, 80}"

describe "lapis.bayes.tokenizers.spam", ->
  it "tokenizes spam-like text", ->
    tokenizer = SpamTokenizer!

    tokens = tokenizer\tokenize_text [[Cheap Rolex Watches for $199.99!!! Visit http://Dealz.EXAMPLE.com now or email SALES@EXAMPLE.com for 50% OFF!!!]]

    assert.same {
      "cheap"
      "rolex"
      "watches"
      "for"
      "199.99"
      "visit"
      "now"
      "or"
      "email"
      "50%"
      "off"
      "currency:$"
      "punct:!3"
      "domain:dealz.example.com"
      "domain:.example.com"
      "domain:.com"
      "email:sales@example.com"
      "email_user:sales"
      "domain:example.com"
      "caps:off"
    }, tokens

  it_tokenizes "with bigrams", "Buy Cheap meds now", {
    "buy"
    "cheap"
    "meds"
    "now"
    "buy cheap"
    "cheap meds"
    "meds now"
  }, {
    bigram_tokens: true
  }

  it_tokenizes "bigrams with numbers", "Only 50% off today", {
    "only"
    "50%"
    "off"
    "today"
    "only 50%"
    "50% off"
    "off today"
  }, {
    bigram_tokens: true
  }

  it_tokenizes "with default dedupe", "spam spam SPAM", {
    "spam"
    "caps:spam"
  }

  it_tokenizes "wit  duplicates when dedupe disabled", "spam spam", {
    "spam"
    "spam"
  }, {
    dedupe: false
  }

  it_tokenizes "limits tokens with sample_at_most", "alpha beta gamma delta", {
    "alpha"
    "beta"
  }, {
    sample_at_most: 2, dedupe: false
  }

  it_tokenizes "single word with bigrams enabled", "alpha", {
    "alpha"
  }, {
    bigram_tokens: true
  }

  it_tokenizes "limits bigrams with sample_at_most", "alpha beta gamma", {
    "alpha"
    "beta"
    "alpha beta"
    "beta gamma"
  }, {
    sample_at_most: 2, bigram_tokens: true, dedupe: false
  }

  it_tokenizes "chinese with url", "点击这里获取 50% 折扣!!! http://spam.cn/deal", {
    "点击这里获取"
    "50%"
    "折扣"
    "punct:!3"
    "domain:spam.cn"
    "domain:.cn"
  }

  it_tokenizes "html content", [[
    <div><p>Limited <strong>Offer</strong> <a href="http://example.com">Click</a> now!</p></div>
  ]], {
    "limited"
    "offer"
    "click"
    "now"
    "domain:example.com"
    "domain:.com"
  }

  it_tokenizes "ignored words", "Deal DEAL!!! Limited deal now NOW 10% NOW!!!", {
    "limited"
    "now"
    "10%"
    "punct:!3"
    "caps:now"
  }, {
    ignore_words: {
      deal: true
    }
  }

  it_tokenizes "Esperanto sentence", "Eble ĉiu ĵaŭdo ŝanĝiĝos al pli agrabla tago", {
    "eble"
    "ciu"
    "jaudo"
    "sangigos"
    "al"
    "pli"
    "agrabla"
    "tago"
  }

  it_tokenizes "Spanish sentence", "el juego esta disponible en español?", {
    "el"
    "juego"
    "esta"
    "disponible"
    "en"
    "espanol"
  }

  it_tokenizes "capitalized sentence", "MY GAME NOT WORKING. ERROR: LICENSE NOT FOUND. PLEASE HELP!", {
    "my"
    "game"
    "not"
    "working"
    "error"
    "license"
    "found"
    "please"
    "help"
    "caps:my"
    "caps:game"
    "caps:not"
    "caps:working"
    "caps:error"
    "caps:license"
    "caps:found"
    "caps:please"
    "caps:help"
  }

  describe "bigram dedupe", ->
    it_tokenizes "with bigrams with dupes", "spam spam spam", {
      "spam"
      "spam"
      "spam"
      "spam spam"
      "spam spam"
    }, {
      bigram_tokens: true, dedupe: false
    }


    it_tokenizes "with bigrams without dupes", "spam spam spam", {
      "spam"
      "spam spam"
    }, {
      bigram_tokens: true, dedupe: true
    }

  describe "with stemming", ->
    it_tokenizes "with stems", "running dogs created connections", {
      "run"
      "dog"
      "creat"
      "connect"
    }, {
      stem_words: true
    }

    it_tokenizes "with stems & caps", "RUNNING Dogs", {
      "run"
      "dog"
      "caps:run"
    }, {
      stem_words: true
    }

    it_tokenizes "with stems and bigrams", "running dogs", {
      "run"
      "dog"
      "run dog"
    }, {
      stem_words: true, bigram_tokens: true
    }

    it_tokenizes "with deduped stems", "running runs run", {
      "run"
    }, {
      stem_words: true
    }

    it_tokenizes "with bigrams and matching stems", "running runs run", {
      "run"
      "run run"
    }, {
      stem_words: true, bigram_tokens: true
    }

    it_tokenizes "with bigrams not deduped", "running runs run", {
      "run"
      "run"
      "run"
      "run run"
      "run run"
    }, {
      stem_words: true, bigram_tokens: true, dedupe: false
    }

    it_tokenizes "stemming combined with tagged tokens", "running at http://examples.com with $199.99 for sales@example.com", {
      "run"
      "at"
      "with"
      "199.99"
      "for"
      "domain:examples.com"
      "domain:.com"
      "currency:$"
      "email:sales@example.com"
      "email_user:sales"
      "domain:example.com"
    }, {
      stem_words: true
    }

  describe "colon character in text", ->
    it_tokenizes "text with colons", "Note: this is important", {
      "note"
      "this"
      "is"
      "important"
    }

    it_tokenizes "multiple colons", "Warning: urgent: read this now", {
      "warning"
      "urgent"
      "read"
      "this"
      "now"
    }

    it_tokenizes "ratio format", "Score is 10:1 or maybe 3:2", {
      "score"
      "is"
      "10"
      "1"
      "or"
      "maybe"
      "3"
      "2"
    }

    it_tokenizes "colons with url", "Check: http://example.com has deals", {
      "check"
      "has"
      "deals"
      "domain:example.com"
      "domain:.com"
    }

  describe "percent tokens", ->
    it_tokenizes "whole number percent", "Discount is 50% off", {
      "discount"
      "is"
      "50%"
      "off"
    }

    it_tokenizes "decimal percent", "Only 5.55% interest rate", {
      "only"
      "5.55%"
      "interest"
      "rate"
    }

    it_tokenizes "multiple percents", "Save 10% or even 15.5% today", {
      "save"
      "10%"
      "or"
      "even"
      "15.5%"
      "today"
    }

  describe "invalid byte handling", ->
    it_tokenizes "invalid UTF8 sequence", "Hello #{string.char(0xFF)} world", {
      "hello"
      "world"
      "invalid_byte:255"
    }

    it_tokenizes "multiple invalid bytes", "Test#{string.char(0xFE)}#{string.char(0xFF)}end", {
      "test"
      "end"
      "invalid_byte:254"
      "invalid_byte:255"
    }

    -- Note: Cyrillic "Привет" doesn't lowercase properly due to string.lower() not handling Unicode
    it_tokenizes "mixed valid unicode and invalid", "Привет#{string.char(0xFF)}世界", {
      "Пpиbet"
      "世界"
      "invalid_byte:255"
    }

  describe "punycode domain handling", ->
    it_tokenizes "ASCII domain unchanged", "Visit http://example.com now", {
      "visit"
      "now"
      "domain:example.com"
      "domain:.com"
    }

    it_tokenizes "German umlaut domain", "Check http://münchen.de today", {
      "check"
      "today"
      "domain:xn--mnchen-3ya.de"
      "domain:.de"
    }

    it_tokenizes "Japanese domain", "Visit http://日本.jp site", {
      "visit"
      "site"
      "domain:xn--wgv71a.jp"
      "domain:.jp"
    }

    it_tokenizes "Chinese domain", "See http://中国.cn here", {
      "see"
      "here"
      "domain:xn--fiqs8s.cn"
      "domain:.cn"
    }

    it_tokenizes "mixed subdomain", "Visit http://test.münchen.example.com now", {
      "visit"
      "now"
      "domain:test.xn--mnchen-3ya.example.com"
      "domain:.xn--mnchen-3ya.example.com"
      "domain:.example.com"
      "domain:.com"
    }

    it_tokenizes "hindi", [[
      <p>नमस्ते, मैं मोहम्मद निर्माता हूँ, या juegosruins68, भारत का एक प्रतिभाशाली गेम डेवलपर। मैंने 5 साल की उम्र से गेम बनाने शुरू किए, जब मैं मजबूरन E.A Games&trade; म</p>
    ]], {
      "नमस्ते"
      "मैं"
      "मोहम्मद"
      "निर्माता"
      "हूँ"
      "या"
      "juegosruins68"
      "भारत"
      "का"
      "एक"
      "गेम"
      "डेवलपर।"
      "मैंने"
      "5"
      "साल"
      "की"
      "उम्र"
      "से"
      "बनाने"
      "शुरू"
      "किए"
      "जब"
      "मजबूरन"
      "games&trade"
      "म"
    }

  describe "build_grammar", ->
    it "grammar types", ->
      tokenizer = SpamTokenizer!
      grammar = tokenizer\build_grammar!
      out = grammar\match "hello http://cool.leafo.net/fart.png is here"
      assert.same {
        "hello"
        {tag: "domain", value: "cool.leafo.net"}
        {tag: "domain", value: ".leafo.net"}
        {tag: "domain", value: ".net"}
        "rt"
        "png"
        "is"
        "here"
      }, out




